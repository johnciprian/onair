import AppKit
import OnAirCore
import SwiftUI

/// The menu bar item and its menu. A standard NSMenu, as Apple's guidelines ask of menu bar extras: it gets the
/// system's glass, hover highlight, keyboard navigation and VoiceOver. Only the status row at the top is a custom
/// view; everything else is an ordinary menu item.
@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private unowned let app: AppModel
    private let settings: SettingsWindow
    /// Kept so an open menu can follow live state changes (Zoom toggled while the menu is showing).
    private var statusRow: NSHostingView<StatusRow>?
    private var muteItem: NSMenuItem?

    init(app: AppModel) {
        self.app = app
        settings = SettingsWindow(app: app)
        super.init()
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
        update()
    }

    /// Shows the current state in the menu bar (macOS sizes the variable-length item to the image) and in an open menu.
    func update() {
        let state = app.monitor.state
        statusItem.button?.image = MenuBarIcon.image(for: state)
        statusItem.button?.setAccessibilityLabel("OnAir: \(state.menuTitle)")
        statusRow?.rootView = StatusRow(state: state)
        if let muteItem { configureMute(muteItem, for: state) }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let state = app.monitor.state

        let status = NSMenuItem()
        let row = NSHostingView(rootView: StatusRow(state: state))
        row.frame = NSRect(origin: .zero, size: NSSize(width: 250, height: row.fittingSize.height))
        status.view = row
        statusRow = row
        menu.addItem(status)

        if state == .noPermission {
            menu.addItem(item("Allow Accessibility Access…", #selector(grantAccess)))
        }

        let mute = item("Mute", #selector(toggleMute))
        configureMute(mute, for: state)
        muteItem = mute
        menu.addItem(mute)

        menu.addItem(.separator())
        menu.addItem(.sectionHeader(title: "Show On Screen"))
        menu.addItem(item("Floating Badge", #selector(toggleBadge), on: app.prefs.showBadge))
        menu.addItem(item("Screen-Edge Glow", #selector(toggleGlow), on: app.prefs.showGlow))
        menu.addItem(item("Toggle Flash", #selector(toggleFlash), on: app.prefs.showFlash))

        menu.addItem(.separator())
        menu.addItem(item("Settings…", #selector(openSettings), key: ","))
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit OnAir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    func menuDidClose(_ menu: NSMenu) {
        statusRow = nil
        muteItem = nil
    }

    /// "Mute" or "Unmute" depending on the state, with the hotkey shown the native way at the trailing edge.
    private func configureMute(_ item: NSMenuItem, for state: MicState) {
        item.title = state == .muted ? "Unmute" : "Mute"
        item.image = NSImage(systemSymbolName: state == .muted ? "mic" : "mic.slash", accessibilityDescription: nil)
        item.isEnabled = state.isInMeeting
        if let combo = app.prefs.hotkey, let key = combo.menuKeyEquivalent {
            item.keyEquivalent = key
            item.keyEquivalentModifierMask = combo.modifierFlags
        }
    }

    private func item(_ title: String, _ action: Selector, on: Bool? = nil, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        if let on { item.state = on ? .on : .off }
        return item
    }

    @objc private func toggleMute() { app.toggleMute() }
    @objc private func toggleBadge() { app.prefs.showBadge.toggle(); app.render() }
    @objc private func toggleGlow() { app.prefs.showGlow.toggle(); app.render() }
    @objc private func toggleFlash() { app.prefs.showFlash.toggle() }
    @objc private func grantAccess() { app.requestAccessibility() }
    @objc private func openSettings() { settings.show() }
}

/// The one custom row: a status light, the state in words, and where it comes from.
struct StatusRow: View {
    let state: MicState

    var body: some View {
        HStack(spacing: 10) {
            light
            VStack(alignment: .leading, spacing: 1) {
                Text(state.statusTitle).font(.system(size: 13, weight: .semibold))
                Text(state.statusDetail).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var light: some View {
        switch state {
        case .live:
            Circle().fill(Theme.signalRed).frame(width: 10, height: 10).shadow(color: Theme.signalRed, radius: 4)
        case .muted:
            Circle().fill(.secondary).frame(width: 10, height: 10)
        case .noPermission:
            Circle().fill(.yellow).frame(width: 10, height: 10)
        case .noMeeting, .notRunning:
            Circle().strokeBorder(.secondary, lineWidth: 1.5).frame(width: 10, height: 10)
        }
    }
}
