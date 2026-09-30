// Renders Resources/AppIcon.icns and the preview images in docs/.
// Run via Scripts/generate-icons.sh.

import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath)
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

func gradient(_ stops: [(CGFloat, CGColor)]) -> CGGradient {
    CGGradient(colorsSpace: sRGB, colors: stops.map(\.1) as CFArray, locations: stops.map(\.0))!
}

func render(width: Int, height: Int, _ body: (CGContext) -> Void) -> CGImage {
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: sRGB, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    body(ctx)
    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(url.path)") }
}

// MARK: - App icon

/// Draws the app icon in a 1024-unit space. `scale` is the context's scale,
/// needed because shadows are specified in device pixels.
func drawAppIcon(in ctx: CGContext, scale: CGFloat) {
    let plate = CGPath(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824),
                       cornerWidth: 185, cornerHeight: 185, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12 * scale), blur: 28 * scale, color: rgb(0x000000, 0.35))
    ctx.addPath(plate)
    ctx.setFillColor(rgb(0x0A0F2C))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(plate)
    ctx.clip()
    ctx.drawLinearGradient(gradient([(0, rgb(0x2A459C)), (1, rgb(0x0A0F2C))]),
                           start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

    let center = CGPoint(x: 512, y: 572)
    ctx.drawRadialGradient(gradient([(0, rgb(0x4F7DFF, 0.45)), (1, rgb(0x4F7DFF, 0))]),
                           startCenter: center, startRadius: 0, endCenter: center, endRadius: 440, options: [])

    // Eye
    let eye = TrayIcon.eyePath(center: center, halfWidth: 330, halfHeight: 190)
    ctx.saveGState()
    ctx.addPath(eye)
    ctx.clip()
    // Sclera, shaded under the upper lid.
    ctx.drawLinearGradient(gradient([(0, rgb(0xC3CFEA)), (0.45, rgb(0xFFFFFF)), (1, rgb(0xF2F5FC))]),
                           start: CGPoint(x: 512, y: center.y + 190), end: CGPoint(x: 512, y: center.y - 190),
                           options: [])
    // Iris
    let irisRadius: CGFloat = 152
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: center.x - irisRadius, y: center.y - irisRadius,
                              width: irisRadius * 2, height: irisRadius * 2))
    ctx.clip()
    ctx.drawRadialGradient(gradient([(0, rgb(0x7FDBFF)), (0.55, rgb(0x0A84FF)), (1, rgb(0x0B3A9E))]),
                           startCenter: center, startRadius: 0, endCenter: center, endRadius: irisRadius, options: [])
    ctx.restoreGState()
    ctx.setStrokeColor(rgb(0x08276E))
    ctx.setLineWidth(10)
    ctx.strokeEllipse(in: CGRect(x: center.x - irisRadius, y: center.y - irisRadius,
                                 width: irisRadius * 2, height: irisRadius * 2))
    // Pupil and highlights
    ctx.setFillColor(rgb(0x050A1E))
    ctx.fillEllipse(in: CGRect(x: center.x - 68, y: center.y - 68, width: 136, height: 136))
    ctx.setFillColor(rgb(0xFFFFFF, 0.95))
    ctx.fillEllipse(in: CGRect(x: center.x + 26, y: center.y + 30, width: 64, height: 64))
    ctx.setFillColor(rgb(0xFFFFFF, 0.45))
    ctx.fillEllipse(in: CGRect(x: center.x - 62, y: center.y - 66, width: 26, height: 26))
    ctx.restoreGState()

    // Progress bar, echoing the menu bar icon.
    let track = CGRect(x: 262, y: 248, width: 500, height: 44)
    let trackPath = CGPath(roundedRect: track, cornerWidth: 22, cornerHeight: 22, transform: nil)
    ctx.addPath(trackPath)
    ctx.setFillColor(rgb(0xFFFFFF, 0.16))
    ctx.fillPath()
    let filled = track.width * 0.62
    ctx.addPath(trackPath)
    ctx.clip()
    ctx.clip(to: CGRect(x: track.minX, y: track.minY, width: filled, height: track.height))
    ctx.drawLinearGradient(gradient([(0, rgb(0x0A84FF)), (1, rgb(0x5AC8FA))]),
                           start: CGPoint(x: track.minX, y: 0), end: CGPoint(x: track.minX + filled, y: 0),
                           options: [])
    ctx.restoreGState()
}

func appIcon(pixels: Int) -> CGImage {
    render(width: pixels, height: pixels) { ctx in
        let scale = CGFloat(pixels) / 1024
        ctx.scaleBy(x: scale, y: scale)
        drawAppIcon(in: ctx, scale: scale)
    }
}

let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AwakeTray-\(getpid())/AppIcon.iconset")
for points in [16, 32, 128, 256, 512] {
    writePNG(appIcon(pixels: points), to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    writePNG(appIcon(pixels: points * 2), to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}

let icns = root.appendingPathComponent("Resources/AppIcon.icns")
try! FileManager.default.createDirectory(at: icns.deletingLastPathComponent(), withIntermediateDirectories: true)
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try! iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { fatalError("iconutil failed") }
try? FileManager.default.removeItem(at: iconset.deletingLastPathComponent())

writePNG(appIcon(pixels: 1024), to: root.appendingPathComponent("docs/app-icon.png"))

// MARK: - Tray icon preview

// Columns: inactive, timed (70% left), timed (25% left), indefinite.
// Top band is a light menu bar, bottom band a dark one; each shows 8x and true 2x size.
let states: [TrayIconState] = [.inactive, .timed(remaining: 0.7), .timed(remaining: 0.25), .indefinite]
let big: CGFloat = 8, small: CGFloat = 2, pad: CGFloat = 40
let cellWidth = TrayIcon.size.width * big
let bandHeight = pad + TrayIcon.size.height * big + 24 + TrayIcon.size.height * small + pad
let sheetWidth = pad + CGFloat(states.count) * (cellWidth + pad)

let sheet = render(width: Int(sheetWidth), height: Int(bandHeight * 2)) { ctx in
    let bands: [(background: CGColor, primary: CGColor)] = [
        (rgb(0x16181D), rgb(0xFFFFFF)),
        (rgb(0xE9EAEE), rgb(0x000000)),
    ]
    for (row, band) in bands.enumerated() {
        let originY = CGFloat(row) * bandHeight
        ctx.setFillColor(band.background)
        ctx.fill(CGRect(x: 0, y: originY, width: sheetWidth, height: bandHeight))

        for (column, state) in states.enumerated() {
            let x = pad + CGFloat(column) * (cellWidth + pad)
            let smallY = originY + pad
            let bigY = smallY + TrayIcon.size.height * small + 24

            ctx.saveGState()
            ctx.translateBy(x: x, y: bigY)
            ctx.scaleBy(x: big, y: big)
            TrayIcon.draw(state, in: ctx, primary: band.primary)
            ctx.restoreGState()

            ctx.saveGState()
            ctx.translateBy(x: x + (cellWidth - TrayIcon.size.width * small) / 2, y: smallY)
            ctx.scaleBy(x: small, y: small)
            TrayIcon.draw(state, in: ctx, primary: band.primary)
            ctx.restoreGState()
        }
    }
}
writePNG(sheet, to: root.appendingPathComponent("docs/tray-icons.png"))

print("Wrote \(icns.path), docs/app-icon.png, docs/tray-icons.png")
