import SwiftUI

struct ConfigView: View {
    @ObservedObject var awake: AwakeController

    private static let presets = [15, 30, 60, 120, 240, 480]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("AwakeTray").font(.headline)
                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Divider()

            Toggle("Stop after a set time", isOn: $awake.hasTimeLimit)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    Stepper("\(awake.minutes / 60) h", value: hours, in: 0...24)
                    Stepper("\(awake.minutes % 60) min", value: minutesPart, in: 0...59)
                }
                .monospacedDigit()

                HStack(spacing: 4) {
                    ForEach(Self.presets, id: \.self) { preset in
                        Button(Self.label(for: preset)) { awake.minutes = preset }
                            .buttonStyle(.bordered)
                            .tint(awake.minutes == preset ? .accentColor : nil)
                    }
                }
                .controlSize(.small)
            }
            .disabled(!awake.hasTimeLimit)

            Toggle("Keep the display on too", isOn: $awake.keepDisplayOn)

            Divider()

            HStack {
                Button(awake.isActive ? "Stop" : "Keep Awake") { awake.toggle() }
                    .keyboardShortcut(.defaultAction)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }

            Text("Tip: double-click the eye to start or stop.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 280)
    }

    private var status: String {
        switch awake.session {
        case nil:
            return "Off. Your Mac can sleep."
        case .indefinite:
            return "Keeping awake until you stop it."
        case .timed:
            return "Keeping awake, \(Self.clock(awake.secondsLeft ?? 0)) left."
        }
    }

    private var hours: Binding<Int> {
        Binding(get: { awake.minutes / 60 },
                set: { setMinutes($0 * 60 + awake.minutes % 60) })
    }

    private var minutesPart: Binding<Int> {
        Binding(get: { awake.minutes % 60 },
                set: { setMinutes(awake.minutes / 60 * 60 + $0) })
    }

    private func setMinutes(_ value: Int) {
        let range = AwakeController.minutesRange
        awake.minutes = min(max(value, range.lowerBound), range.upperBound)
    }

    private static func label(for minutes: Int) -> String {
        minutes < 60 ? "\(minutes)m" : "\(minutes / 60)h"
    }

    private static func clock(_ seconds: Int) -> String {
        let h = seconds / 3600, m = seconds % 3600 / 60, s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
