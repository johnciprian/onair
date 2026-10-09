import AppKit
import ApplicationServices
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
    let onAllow: () -> Void
    let onRecord: () -> Void
    let onDone: () -> Void

    var body: some View {
        // Re-read once a second so the checkmarks tick on their own when the user finishes a step elsewhere.
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let trusted = AXIsProcessTrusted()
            let hotkey = prefs.hotkey
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
                        detail: hotkey.map { "Using \($0.displayString). Tap to toggle, hold to talk." } ?? "Tap to toggle, hold to talk.",
                        done: hotkey != nil) {
                    Button("Record…", action: onRecord).buttonStyle(.glass)
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
            .glassEffect(.regular, in: .rect(cornerRadius: 32))
        }
    }
}

@MainActor
final class OnboardingWindow {
    private unowned let app: AppModel
    private var panel: NSPanel?

    init(app: AppModel) {
        self.app = app
    }

    func show() {
        if panel == nil {
            panel = GlassWindow.make(content: OnboardingView(
                prefs: app.prefs,
                onAllow: { [unowned app] in app.requestAccessibility() },
                onRecord: { [unowned app] in app.recordHotkey() },
                onDone: { [weak self] in self?.finish() }
            ))
        }
        NSApp.activate()
        panel?.center()
        panel?.makeKeyAndOrderFront(nil)
    }

    private func finish() {
        app.prefs.hasCompletedOnboarding = true
        panel?.orderOut(nil)
        panel = nil
    }
}
