import AppKit
import Carbon.HIToolbox
import Observation
import OnAirCore
import SwiftUI

@MainActor @Observable
final class RecorderModel {
    var combo: KeyCombo?
    var held: NSEvent.ModifierFlags = []
    var rejected = false

    /// The recorded combo, or — while a new one is being pressed — just the modifiers held so far.
    var caps: [String] {
        if let combo, held.isSubset(of: combo.modifierFlags) { return combo.keycaps }
        return KeyCombo.symbols(for: held)
    }
}

struct RecorderView: View {
    let model: RecorderModel
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("Set Hotkey").font(.headline)
            HStack(spacing: 8) {
                if model.caps.isEmpty {
                    Text("Press your shortcut…").font(.title3).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(model.caps.enumerated()), id: \.offset) { _, cap in
                        Keycap(label: cap).transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
            }
            .frame(height: 52)
            .animation(.snappy, value: model.caps)
            Text(model.rejected ? "Add ⌃, ⌥ or ⌘ — or use F13–F20 on its own." : "Tap toggles · Hold to talk")
                .font(.callout)
                .foregroundStyle(model.rejected ? AnyShapeStyle(Theme.signalRed) : AnyShapeStyle(.secondary))
            HStack(spacing: 12) {
                Button("Cancel", action: onCancel).buttonStyle(.glass)
                Button("Save", action: onSave).buttonStyle(.glassProminent).tint(Theme.signalRed).disabled(model.combo == nil)
            }
        }
        .padding(24)
        .frame(width: 360)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}

/// Captures the next key combo. While open it swallows all key presses so they don't reach other apps' menus.
@MainActor
final class HotkeyRecorder {
    private let model = RecorderModel()
    private var panel: NSPanel?
    private var keyMonitor: Any?
    private var completion: ((KeyCombo?) -> Void)?

    func show(current: KeyCombo?, completion: @escaping (KeyCombo?) -> Void) {
        if let panel { panel.makeKeyAndOrderFront(nil); return }
        self.completion = completion
        model.combo = current
        model.held = []
        model.rejected = false
        let panel = GlassWindow.make(content: RecorderView(
            model: model,
            onSave: { [weak self] in self?.finish(self?.model.combo) },
            onCancel: { [weak self] in self?.finish(nil) }
        ))
        self.panel = panel
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
            return nil
        }
        NSApp.activate()
        panel.center()
        panel.makeKeyAndOrderFront(nil)
    }

    private func handle(_ event: NSEvent) {
        if event.type == .flagsChanged {
            model.held = event.modifierFlags.intersection([.control, .option, .shift, .command])
            model.rejected = false
        } else if event.keyCode == UInt16(kVK_Escape) {
            finish(nil)
        } else if let combo = KeyCombo(keyCode: event.keyCode, modifierFlags: event.modifierFlags, characters: event.charactersIgnoringModifiers) {
            model.combo = combo
            model.rejected = false
        } else {
            model.rejected = true
            NSSound.beep()
        }
    }

    private func finish(_ combo: KeyCombo?) {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        panel?.orderOut(nil)
        panel = nil
        let completion = self.completion
        self.completion = nil
        completion?(combo)
    }
}
