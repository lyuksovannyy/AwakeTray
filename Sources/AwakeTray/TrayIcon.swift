import AppKit

enum TrayIconState: Equatable {
    /// Sleep is allowed: closed eye.
    case inactive
    /// Keeping awake for a fixed duration; `remaining` is the fraction of time left (1...0).
    case timed(remaining: Double)
    /// Keeping awake until stopped: eye with veins.
    case indefinite
}

/// Draws the menu bar icon. Everything is vector so it stays crisp at any scale,
/// and the progress bar can be redrawn as time runs out.
enum TrayIcon {
    static let size = CGSize(width: 22, height: 18)
    static let barColor = CGColor(srgbRed: 0.04, green: 0.52, blue: 1.0, alpha: 1)
    /// How far the veins lean from the eye colour towards red (0 = same colour, 1 = red).
    static let veinRedness: CGFloat = 0.3

    static func image(for state: TrayIconState) -> NSImage {
        let image = NSImage(size: size, flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            draw(state, in: ctx, primary: NSColor.labelColor.cgColor)
            return true
        }
        // Only the closed eye is monochrome; the active states carry colour.
        image.isTemplate = state == .inactive
        return image
    }

    /// Draws into a `size`-point canvas with the origin at the bottom left.
    static func draw(_ state: TrayIconState, in ctx: CGContext, primary: CGColor) {
        ctx.saveGState()
        defer { ctx.restoreGState() }
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(primary)
        ctx.setFillColor(primary)

        let midX = size.width / 2
        switch state {
        case .inactive:
            drawClosedEye(in: ctx, center: CGPoint(x: midX, y: 9))
        case .indefinite:
            drawOpenEye(in: ctx, center: CGPoint(x: midX, y: 9), veins: true, primary: primary)
        case .timed(let remaining):
            // The eye moves up a little to make room for the bar.
            drawOpenEye(in: ctx, center: CGPoint(x: midX, y: 11), veins: false, primary: primary)
            drawBar(in: ctx, remaining: remaining, primary: primary)
        }
    }

    /// Almond shape whose corners sit on `center.y`.
    static func eyePath(center c: CGPoint, halfWidth w: CGFloat, halfHeight h: CGFloat) -> CGPath {
        // A cubic peaks at 3/4 of its control height.
        let k = h * 4 / 3
        let path = CGMutablePath()
        path.move(to: CGPoint(x: c.x - w, y: c.y))
        path.addCurve(to: CGPoint(x: c.x + w, y: c.y),
                      control1: CGPoint(x: c.x - w / 2, y: c.y + k),
                      control2: CGPoint(x: c.x + w / 2, y: c.y + k))
        path.addCurve(to: CGPoint(x: c.x - w, y: c.y),
                      control1: CGPoint(x: c.x + w / 2, y: c.y - k),
                      control2: CGPoint(x: c.x - w / 2, y: c.y - k))
        path.closeSubpath()
        return path
    }

    private static func drawOpenEye(in ctx: CGContext, center c: CGPoint, veins: Bool, primary: CGColor) {
        let outline = eyePath(center: c, halfWidth: 9.5, halfHeight: 5.25)

        if veins {
            ctx.saveGState()
            ctx.addPath(outline)
            ctx.clip()
            ctx.setStrokeColor(veinColor(primary: primary))
            ctx.setLineWidth(0.8)
            // Offsets from the centre for the right side; the left side is point-mirrored
            // so the two halves don't look stamped.
            let veins: [[CGPoint]] = [
                [CGPoint(x: 9.2, y: 0.3), CGPoint(x: 7.2, y: 1.4), CGPoint(x: 5.8, y: 0.7), CGPoint(x: 4.6, y: 1.3)],
                [CGPoint(x: 7.2, y: 1.4), CGPoint(x: 6.0, y: 3.0)],
                [CGPoint(x: 9.0, y: -0.6), CGPoint(x: 7.0, y: -1.7), CGPoint(x: 5.2, y: -1.2)],
                [CGPoint(x: 7.0, y: -1.7), CGPoint(x: 5.9, y: -3.2)],
            ]
            for side: CGFloat in [1, -1] {
                for vein in veins {
                    ctx.addLines(between: vein.map { CGPoint(x: c.x + $0.x * side, y: c.y + $0.y * side) })
                }
            }
            ctx.strokePath()
            ctx.restoreGState()
        }

        ctx.setLineWidth(1.5)
        ctx.addPath(outline)
        ctx.strokePath()

        // Iris with a highlight punched out (even-odd keeps it transparent, not painted).
        ctx.addEllipse(in: CGRect(x: c.x - 3.3, y: c.y - 3.3, width: 6.6, height: 6.6))
        ctx.addEllipse(in: CGRect(x: c.x + 0.2, y: c.y + 0.2, width: 2, height: 2))
        ctx.fillPath(using: .evenOdd)
    }

    /// The eye's own colour nudged slightly towards red.
    private static func veinColor(primary: CGColor) -> CGColor {
        guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
              let rgb = primary.converted(to: sRGB, intent: .defaultIntent, options: nil)?.components,
              rgb.count >= 3 else { return primary }
        let red: [CGFloat] = [1.0, 0.2, 0.15]
        let mixed = (0..<3).map { rgb[$0] + (red[$0] - rgb[$0]) * veinRedness }
        return CGColor(srgbRed: mixed[0], green: mixed[1], blue: mixed[2], alpha: primary.alpha)
    }

    private static func drawClosedEye(in ctx: CGContext, center c: CGPoint) {
        let p0 = CGPoint(x: c.x - 9, y: c.y + 3)
        let p1 = CGPoint(x: c.x - 4.5, y: c.y - 2.6)
        let p2 = CGPoint(x: c.x + 4.5, y: c.y - 2.6)
        let p3 = CGPoint(x: c.x + 9, y: c.y + 3)

        ctx.setLineWidth(1.5)
        ctx.move(to: p0)
        ctx.addCurve(to: p3, control1: p1, control2: p2)

        // Lashes fan out along the lid's downward normal.
        for t: CGFloat in [0.1, 0.3, 0.5, 0.7, 0.9] {
            let u = 1 - t
            let x = u * u * u * p0.x + 3 * u * u * t * p1.x + 3 * u * t * t * p2.x + t * t * t * p3.x
            let y = u * u * u * p0.y + 3 * u * u * t * p1.y + 3 * u * t * t * p2.y + t * t * t * p3.y
            let dx = 3 * u * u * (p1.x - p0.x) + 6 * u * t * (p2.x - p1.x) + 3 * t * t * (p3.x - p2.x)
            let dy = 3 * u * u * (p1.y - p0.y) + 6 * u * t * (p2.y - p1.y) + 3 * t * t * (p3.y - p2.y)
            let length = (dx * dx + dy * dy).squareRoot()
            ctx.move(to: CGPoint(x: x, y: y))
            ctx.addLine(to: CGPoint(x: x + dy / length * 2.4, y: y - dx / length * 2.4))
        }
        ctx.strokePath()
    }

    private static func drawBar(in ctx: CGContext, remaining: Double, primary: CGColor) {
        let track = CGRect(x: 2, y: 1, width: size.width - 4, height: 2.5)
        let radius = track.height / 2
        let trackPath = CGPath(roundedRect: track, cornerWidth: radius, cornerHeight: radius, transform: nil)

        ctx.addPath(trackPath)
        ctx.setFillColor(primary.copy(alpha: 0.25) ?? primary)
        ctx.fillPath()

        // Clip to the track so a nearly empty bar keeps rounded ends.
        ctx.saveGState()
        ctx.addPath(trackPath)
        ctx.clip()
        let fraction = CGFloat(min(max(remaining, 0), 1))
        ctx.setFillColor(barColor)
        ctx.fill(CGRect(x: track.minX, y: track.minY, width: track.width * fraction, height: track.height))
        ctx.restoreGState()
    }
}
