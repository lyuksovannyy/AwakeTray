import Foundation
import IOKit.pwr_mgt

/// Owns the configuration and the power assertion that keeps the Mac awake.
@MainActor
final class AwakeController: ObservableObject {
    enum Session: Equatable {
        case indefinite
        case timed(start: Date, end: Date)
    }

    static let minutesRange = 1...(24 * 60)

    /// `nil` while sleep is allowed.
    @Published private(set) var session: Session?
    /// Ticks once a second during a timed session so views can show the time left.
    @Published private(set) var now = Date()

    // Changing the configuration during a session restarts it with the new values.
    @Published var hasTimeLimit: Bool {
        didSet {
            guard hasTimeLimit != oldValue else { return }
            defaults.set(hasTimeLimit, forKey: Keys.hasTimeLimit)
            restartIfActive()
        }
    }
    @Published var minutes: Int {
        didSet {
            guard minutes != oldValue else { return }
            defaults.set(minutes, forKey: Keys.minutes)
            if hasTimeLimit { restartIfActive() }
        }
    }
    @Published var keepDisplayOn: Bool {
        didSet {
            guard keepDisplayOn != oldValue else { return }
            defaults.set(keepDisplayOn, forKey: Keys.keepDisplayOn)
            restartIfActive()
        }
    }

    var isActive: Bool { session != nil }

    private enum Keys {
        static let hasTimeLimit = "hasTimeLimit"
        static let minutes = "minutes"
        static let keepDisplayOn = "keepDisplayOn"
    }

    private let defaults = UserDefaults.standard
    private var assertionID = IOPMAssertionID(0)
    private var timer: Timer?

    init() {
        defaults.register(defaults: [Keys.hasTimeLimit: false, Keys.minutes: 60, Keys.keepDisplayOn: true])
        hasTimeLimit = defaults.bool(forKey: Keys.hasTimeLimit)
        let stored = defaults.integer(forKey: Keys.minutes)
        minutes = min(max(stored, Self.minutesRange.lowerBound), Self.minutesRange.upperBound)
        keepDisplayOn = defaults.bool(forKey: Keys.keepDisplayOn)
    }

    func toggle() {
        if isActive { stop() } else { start() }
    }

    func start() {
        stop()
        guard acquireAssertion() else { return }

        now = Date()
        if hasTimeLimit {
            session = .timed(start: now, end: now.addingTimeInterval(TimeInterval(minutes * 60)))
            let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.tick() }
            }
            // .common keeps the countdown running while the menu bar is tracking the mouse.
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        } else {
            session = .indefinite
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
        session = nil
    }

    private func restartIfActive() {
        if isActive { start() }
    }

    private func tick() {
        now = Date()
        if case .timed(_, let end) = session, now >= end {
            stop()
        }
    }

    private func acquireAssertion() -> Bool {
        let type = keepDisplayOn ? kIOPMAssertionTypePreventUserIdleDisplaySleep
                                 : kIOPMAssertionTypePreventUserIdleSystemSleep
        let result = IOPMAssertionCreateWithName(type as CFString,
                                                 IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                 "AwakeTray is keeping this Mac awake" as CFString,
                                                 &assertionID)
        if result != kIOReturnSuccess {
            assertionID = 0
            NSLog("AwakeTray: could not create power assertion (%d)", result)
        }
        return result == kIOReturnSuccess
    }
}

extension AwakeController {
    /// Seconds left in a timed session, `nil` otherwise.
    var secondsLeft: Int? {
        guard case .timed(_, let end) = session else { return nil }
        return max(0, Int(end.timeIntervalSince(now).rounded(.up)))
    }

    static func iconState(session: Session?, now: Date) -> TrayIconState {
        switch session {
        case nil:
            return .inactive
        case .indefinite:
            return .indefinite
        case .timed(let start, let end):
            let total = end.timeIntervalSince(start)
            return .timed(remaining: total > 0 ? end.timeIntervalSince(now) / total : 0)
        }
    }
}
