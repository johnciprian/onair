import AppKit
import ApplicationServices
import OnAirCore
import SwiftUI

/// The set-once options, out of the menu: the hotkey, launch at login, and Accessibility access.
/// A standard titled window with a grouped form, like System Settings.
struct SettingsView: View {
    let app: AppModel
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        // Re-read once a second so the hotkey and access rows update after the recorder or System Settings.
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            Form {
                Section {
                    LabeledContent("Mute / Unmute") {
                        // The shortcut itself is the button: click it to record a new one.
                        Button(app.prefs.hotkey?.displayString ?? "Record Shortcut") { app.recordHotkey() }
                            .font(.system(.body, design: .rounded).monospacedDigit())
                    }
                    if let problem = app.hotkeyProblem {
                        Text(problem).font(.callout).foregroundStyle(Theme.signalRed)
                    }
                } header: {
                    Text("Hotkey")
                } footer: {
                    Text("Tap to mute or unmute. Hold to talk while muted.")
                }
                Section {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                }
                Section("Accessibility") {
                    LabeledContent("Read and control Zoom") {
                        if AXIsProcessTrusted() {
                            Label("Allowed", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        } else {
                            Button("Allow…") { app.requestAccessibility() }
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 440, height: 330)
        .onChange(of: launchAtLogin) { _, on in
            LoginItem.isEnabled = on
            launchAtLogin = LoginItem.isEnabled  // registration can fail; show what actually happened
        }
    }
}

@MainActor
final class SettingsWindow {
    private unowned let app: AppModel
    private var window: NSWindow?

    init(app: AppModel) {
        self.app = app
    }

    func show() {
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(app: app)))
            window.title = "OnAir Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            self.window = window
        }
        if let window { UtilityWindow.present(window) }
    }
}
