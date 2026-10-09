import AppKit
import OnAirCore
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    /// A popover rather than a custom window: macOS draws its glass, shape and shadow, and closes it on outside clicks.
    private let popover = NSPopover()
    private unowned let app: AppModel

    init(app: AppModel) {
        self.app = app
        super.init()
        let button = statusItem.button!
        button.target = self
        button.action = #selector(togglePanel)
        popover.behavior = .transient
        update()
    }

    /// Shows the current state. The status item is variable-length, so macOS sizes it to the image.
    func update() {
        let state = app.monitor.state
        statusItem.button?.image = MenuBarIcon.image(for: state)
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
