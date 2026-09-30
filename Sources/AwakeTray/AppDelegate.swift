import AppKit
import Combine
import SwiftUI

@main
@MainActor
enum AwakeTrayApp {
    // NSApplication only holds its delegate weakly; a local would be freed before run().
    private static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        // Menu bar only: no Dock icon, no main menu.
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    /// How long a single click waits for a second one before the menu opens.
    private static let singleClickDelay: TimeInterval = 0.25

    private let awake = AwakeController()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem!
    private var pendingOpen: DispatchWorkItem?
    private var lastPopoverClose = Date.distantPast
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseDown])

        let hosting = NSHostingController(rootView: ConfigView(awake: awake))
        hosting.sizingOptions = .preferredContentSize
        popover.contentViewController = hosting
        popover.behavior = .transient
        popover.delegate = self

        awake.$session.combineLatest(awake.$now)
            .map { AwakeController.iconState(session: $0, now: $1) }
            .removeDuplicates()
            .sink { [weak button] state in
                button?.image = TrayIcon.image(for: state)
                button?.toolTip = state == .inactive
                    ? "AwakeTray: sleep allowed. Double-click to keep awake."
                    : "AwakeTray: keeping awake. Double-click to stop."
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        awake.stop()
    }

    @objc private func statusItemClicked() {
        let clicks = NSApp.currentEvent?.clickCount ?? 1

        if clicks >= 2 {
            // Double click: toggle right away, and never leave the menu open behind it.
            pendingOpen?.cancel()
            pendingOpen = nil
            if popover.isShown { popover.performClose(nil) }
            if clicks == 2 { awake.toggle() }
            return
        }

        if popover.isShown {
            popover.performClose(nil)
            return
        }
        // The transient popover closes itself on this same mouse-down; don't reopen it.
        if Date().timeIntervalSince(lastPopoverClose) < 0.2 { return }

        let open = DispatchWorkItem { [weak self] in self?.showPopover() }
        pendingOpen = open
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.singleClickDelay, execute: open)
    }

    private func showPopover() {
        pendingOpen = nil
        guard let button = statusItem.button, !popover.isShown else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func popoverDidClose(_ notification: Notification) {
        lastPopoverClose = Date()
    }
}
