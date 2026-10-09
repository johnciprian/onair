import AppKit
import OnAirCore
import SwiftUI

/// SwiftUI host that lets clicks fall through to the status bar button underneath, which opens the panel.
final class PassthroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

@MainActor
final class MenuBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let pill: PassthroughHostingView<MenuBarPill>
    /// A popover rather than a custom window: macOS draws its glass, shape and shadow, and closes it on outside clicks.
    private let popover = NSPopover()
    private unowned let app: AppModel

    init(app: AppModel) {
        self.app = app
        pill = PassthroughHostingView(rootView: MenuBarPill(monitor: app.monitor))
        super.init()
        // A SwiftUI subview (rather than a rendered image) keeps the pill's animations and follows the
        // menu bar's light/dark appearance automatically.
        let button = statusItem.button!
        pill.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(pill)
        NSLayoutConstraint.activate([
            pill.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            pill.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        button.target = self
        button.action = #selector(togglePanel)
        popover.behavior = .transient
        update()
    }

    /// Fits the status item to the new state. Measured from the state on its own: mid-animation the live pill
    /// still holds the outgoing view, so its size would be the wider of the two (a mic glyph in an ON AIR-wide slot).
    func update() {
        let state = app.monitor.state
        statusItem.length = NSHostingView(rootView: MenuBarPillContent(state: state)).fittingSize.width + 6
        statusItem.button?.setAccessibilityLabel("OnAir: \(state.menuTitle)")
    }

    @objc private func togglePanel() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        let controller = NSHostingController(rootView: MenuPanel(app: app, close: { [weak self] in self?.popover.performClose(nil) }))
        controller.sizingOptions = .preferredContentSize
        popover.contentViewController = controller
        // Activate so the panel's switches respond to the first click and an outside click closes it.
        NSApp.activate()
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
