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
            menu.addItem(item("Allow Accessibility Access…", #selector(grantAccess), symbol: "hand.raised"))
        }

        let mute = item("Mute", #selector(toggleMute))
        configureMute(mute, for: state)
        muteItem = mute
        menu.addItem(mute)

        menu.addItem(.separator())
        menu.addItem(.sectionHeader(title: "Show On Screen"))
        menu.addItem(switchItem("Floating Badge", isOn: app.prefs.showBadge) { [unowned app] on in
            app.prefs.showBadge = on
            app.render()
        })
        menu.addItem(switchItem("Screen-Edge Glow", isOn: app.prefs.showGlow) { [unowned app] on in
            app.prefs.showGlow = on
            app.render()
        })
        menu.addItem(switchItem("Toggle Flash", isOn: app.prefs.showFlash) { [unowned app] on in
            app.prefs.showFlash = on
        })

        // Every action item has an icon; the switch rows don't need one (the switch is their visual).
        menu.addItem(.separator())
        menu.addItem(item("About OnAir", #selector(showAbout), symbol: "info.circle"))
        menu.addItem(item(app.updater.hasUnseenUpdate ? "Update Available…" : "Check for Updates…",
                          #selector(checkForUpdates), symbol: "arrow.down.circle"))
        menu.addItem(.separator())
        menu.addItem(item("Settings…", #selector(openSettings), symbol: "gearshape", key: ","))
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit OnAir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        setIcon(quit, "power")
        menu.addItem(quit)
    }

    func menuDidClose(_ menu: NSMenu) {
        statusRow = nil
        muteItem = nil
    }

    /// "Mute" or "Unmute" depending on the state, with the hotkey shown the native way at the trailing edge.
    private func configureMute(_ item: NSMenuItem, for state: MicState) {
        item.title = state == .muted ? "Unmute" : "Mute"
        setIcon(item, state == .muted ? "mic" : "mic.slash")
        item.isEnabled = state.isInMeeting
        if let combo = app.prefs.hotkey, let key = combo.menuKeyEquivalent {
            item.keyEquivalent = key
            item.keyEquivalentModifierMask = combo.modifierFlags
        }
    }

    private func item(_ title: String, _ action: Selector, symbol: String? = nil, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        if let symbol { setIcon(item, symbol) }
        return item
    }

    /// macOS 27 hides menu item icons unless an item asks for its icon to stay visible.
    private func setIcon(_ item: NSMenuItem, _ symbol: String) {
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        if #available(macOS 27, *) { item.preferredImageVisibility = .visible }
    }

    private func switchItem(_ title: String, isOn: Bool, set: @escaping (Bool) -> Void) -> NSMenuItem {
        let item = NSMenuItem()
        let row = NSHostingView(rootView: SwitchRow(title: title, isOn: isOn, set: set))
        row.frame = NSRect(origin: .zero, size: NSSize(width: 250, height: row.fittingSize.height))
        row.autoresizingMask = .width  // stretch to the menu's width, so the switch lines up with the shortcuts
        item.view = row
        return item
    }

    @objc private func toggleMute() { app.toggleMute() }
    @objc private func grantAccess() { app.requestAccessibility() }
    @objc private func showAbout() { About.show() }
    @objc private func openSettings() { settings.show() }
    @objc private func checkForUpdates() { app.updater.checkForUpdates() }
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

/// A row with a switch. Clicking a regular menu item always closes the menu; a control inside a view row
/// doesn't, so several displays can be switched in one go (the same pattern as the Wi-Fi and Bluetooth menus).
struct SwitchRow: View {
    let title: String
    @State var isOn: Bool
    let set: (Bool) -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(Font(NSFont.menuFont(ofSize: 0)))
                .accessibilityHidden(true)  // the switch carries the same label for VoiceOver
            Spacer(minLength: 12)
            Toggle(title, isOn: $isOn)
                .toggleStyle(MenuSwitchStyle())
                .labelsHidden()
        }
        .padding(.leading, 36)  // lines the name up with the other items' titles, after their icons
        .padding(.trailing, 14)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { isOn.toggle() }  // clicking the name works too
        .onChange(of: isOn) { _, on in set(on) }
    }
}

/// A switch drawn in the system switch's shape and size. A menu is never the key window, so the system switch
/// always draws in its grey inactive style there (SwiftUI's active-state overrides don't reach it); this one
/// shows the accent color when on, like the switches in Control Center.
private struct MenuSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(configuration.isOn ? Color.accentColor : Color.primary.opacity(0.15))
            .frame(width: 32, height: 18)
            .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 0.5, y: 0.5)
                    .padding(2)
            }
            .animation(.snappy(duration: 0.15), value: configuration.isOn)
            .onTapGesture { configuration.isOn.toggle() }
    }
}
