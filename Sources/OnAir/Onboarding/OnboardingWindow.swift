import AppKit
import ApplicationServices
import OnAirCore
import SwiftUI

struct StepRow<Accessory: View>: View {
    let number: Int
    let title: String
    let detail: String
    /// nil for an instruction-only step that can't be detected.
    let done: Bool?
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(done == true ? AnyShapeStyle(Color.green) : AnyShapeStyle(.quaternary))
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(done == true ? 1 : 0)
                Text("\(number)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .opacity(done == true ? 0 : 1)
            }
            .animation(.snappy, value: done)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            if done != true { accessory() }
        }
    }
}

struct OnboardingView: View {
    let prefs: Preferences
    let isHotkeyAvailable: () -> Bool
    let onAllow: () -> Void
    let onRecord: () -> Void
    let onDone: () -> Void

    var body: some View {
        // Re-read once a second so the checkmarks tick on their own when the user finishes a step elsewhere.
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let trusted = AXIsProcessTrusted()
            let hotkey = prefs.hotkey
            let hotkeyWorks = hotkey != nil && isHotkeyAvailable()
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 16) {
                    SignLabel(live: true, size: 13)
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .litGlass(true, in: Capsule())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome to OnAir").font(.title2.weight(.semibold))
                        Text("Always know if they can hear you.").foregroundStyle(.secondary)
                    }
                }
                StepRow(number: 1, title: "Allow Accessibility access",
                        detail: "OnAir reads Zoom's Meeting menu to see if you're muted, and presses Mute for you.",
                        done: trusted) {
                    Button("Allow…", action: onAllow).buttonStyle(.glass)
                }
                StepRow(number: 2, title: "Record your hotkey",
                        detail: hotkeyDetail(hotkey, works: hotkeyWorks),
                        done: hotkeyWorks) {
                    Button(hotkey == nil ? "Record…" : "Choose Another…", action: onRecord).buttonStyle(.glass)
                }
                StepRow(number: 3, title: "Turn off Zoom's shortcut",
                        detail: "In Zoom → Settings → Keyboard Shortcuts, untick “Enable Global Shortcut” for Mute/Unmute My Audio so the key isn't handled twice.",
                        done: nil) {
                    EmptyView()
                }
                HStack {
                    Spacer()
                    Button("Done", action: onDone)
                        .buttonStyle(.glassProminent)
                        .tint(Theme.signalRed)
                        .controlSize(.large)
                }
            }
            .padding(28)
            .frame(width: 480)
        }
    }

    private func hotkeyDetail(_ hotkey: KeyCombo?, works: Bool) -> String {
        guard let hotkey else { return "Tap to toggle, hold to talk." }
        return works
            ? "Using \(hotkey.displayString). Tap to toggle, hold to talk."
            : "\(hotkey.displayString) is taken by another app. Pick a different one."
    }
}

@MainActor
final class OnboardingWindow {
    private unowned let app: AppModel
    private var window: NSWindow?
    private var trustWatch: Timer?

    init(app: AppModel) {
        self.app = app
    }

    func show() {
        if window == nil {
            window = UtilityWindow.make(content: OnboardingView(
                prefs: app.prefs,
                isHotkeyAvailable: { [unowned app] in app.hotkeyAvailable },
                onAllow: { [weak self] in self?.allow() },
                onRecord: { [unowned app] in app.recordHotkey() },
                onDone: { [weak self] in self?.finish() }
            ))
        }
        if let window { UtilityWindow.present(window) }
    }

    /// The system prompt and System Settings come to the front (Stage Manager may tuck this window aside);
    /// bring it back once access is granted so the user sees step 1 tick.
    private func allow() {
        app.requestAccessibility()
        trustWatch?.invalidate()
        trustWatch = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard AXIsProcessTrusted() else { return }
                timer.invalidate()
                self?.show()
            }
        }
    }

    private func finish() {
        trustWatch?.invalidate()
        app.prefs.hasCompletedOnboarding = true
        window?.orderOut(nil)
        window = nil
    }
}
