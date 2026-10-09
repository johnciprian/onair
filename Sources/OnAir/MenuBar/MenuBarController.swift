import AppKit
import OnAirCore
import SwiftUI

/// SwiftUI host that lets clicks fall through to the status bar button underneath, which owns the menu.
final class PassthroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let pill: PassthroughHostingView<MenuBarPill>
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
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        update()
    }

    /// Fits the status item to the pill. Deferred one run-loop turn so SwiftUI has rendered the new state first.
    func update() {
        DispatchQueue.main.async { [self] in
            statusItem.length = pill.fittingSize.width + 6
            statusItem.button?.setAccessibilityLabel("OnAir: \(app.monitor.state.menuTitle)")
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let state = app.monitor.state
        let status = NSMenuItem(title: state.menuTitle, action: nil, keyEquivalent: "")
        status.image = NSImage(systemSymbolName: state.menuSymbol, accessibilityDescription: nil)
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())
        menu.addItem(item("Floating Badge", #selector(toggleBadge), on: app.prefs.showBadge))
        menu.addItem(item("Screen-Edge Glow", #selector(toggleGlow), on: app.prefs.showGlow))
        menu.addItem(item("Toggle Flash", #selector(toggleFlash), on: app.prefs.showFlash))
        menu.addItem(.separator())
        menu.addItem(item("Launch at Login", #selector(toggleLogin), on: LoginItem.isEnabled))
        if state == .noPermission {
            menu.addItem(item("Grant Accessibility Access…", #selector(grantAccess)))
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit OnAir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func item(_ title: String, _ action: Selector, on: Bool? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        if let on { item.state = on ? .on : .off }
        return item
    }

    @objc private func toggleBadge() { app.prefs.showBadge.toggle(); app.render() }
    @objc private func toggleGlow() { app.prefs.showGlow.toggle(); app.render() }
    @objc private func toggleFlash() { app.prefs.showFlash.toggle() }
    @objc private func toggleLogin() { LoginItem.isEnabled.toggle() }
    @objc private func grantAccess() { app.requestAccessibility() }
}
