import AppKit
import OnAirCore
import SwiftUI

/// What drops down from the menu bar pill: the live status as a big sign, then the settings laid out like
/// System Settings (icon tiles, switches, grouped rows). Built fresh each time it opens, so it starts from the
/// current preferences.
struct MenuPanel: View {
    let app: AppModel
    let close: () -> Void
    @State private var showBadge: Bool
    @State private var showGlow: Bool
    @State private var showFlash: Bool
    @State private var launchAtLogin: Bool

    init(app: AppModel, close: @escaping () -> Void) {
        self.app = app
        self.close = close
        _showBadge = State(initialValue: app.prefs.showBadge)
        _showGlow = State(initialValue: app.prefs.showGlow)
        _showFlash = State(initialValue: app.prefs.showFlash)
        _launchAtLogin = State(initialValue: LoginItem.isEnabled)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatusHeader(state: app.monitor.state, onGrant: app.requestAccessibility)

            SectionTitle("Displays")
            VStack(spacing: 0) {
                SettingRow(symbol: "capsule.fill", tint: .red, title: "Floating Badge") {
                    Toggle("Floating Badge", isOn: $showBadge)
                }
                RowDivider()
                SettingRow(symbol: "rays", tint: .orange, title: "Screen-Edge Glow") {
                    Toggle("Screen-Edge Glow", isOn: $showGlow)
                }
                RowDivider()
                SettingRow(symbol: "bolt.fill", tint: .yellow, title: "Toggle Flash") {
                    Toggle("Toggle Flash", isOn: $showFlash)
                }
            }
            .settingsGroup()

            SectionTitle("General")
            VStack(spacing: 0) {
                SettingRow(symbol: "keyboard.fill", tint: .indigo, title: "Hotkey", detail: hotkeyProblem) {
                    HStack(spacing: 8) {
                        if let combo = app.prefs.hotkey {
                            MiniKeycaps(caps: combo.keycaps)
                        }
                        Button(app.prefs.hotkey == nil ? "Record…" : "Change…") {
                            close()
                            app.recordHotkey()
                        }
                        .controlSize(.small)
                    }
                }
                RowDivider()
                SettingRow(symbol: "power", tint: .green, title: "Launch at Login") {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                }
            }
            .settingsGroup()

            HStack {
                Text("OnAir").font(.caption).foregroundStyle(.tertiary)
                Spacer()
                Button("Quit OnAir") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .frame(width: 320)
        .toggleStyle(.switch)
        .labelsHidden()
        .onChange(of: showBadge) { _, on in app.prefs.showBadge = on; app.render() }
        .onChange(of: showGlow) { _, on in app.prefs.showGlow = on; app.render() }
        .onChange(of: showFlash) { _, on in app.prefs.showFlash = on }
        .onChange(of: launchAtLogin) { _, on in
            LoginItem.isEnabled = on
            launchAtLogin = LoginItem.isEnabled  // registration can fail; show what actually happened
        }
    }

    /// Why the hotkey won't work, if it won't — shown in red under the row instead of failing silently.
    private var hotkeyProblem: String? {
        guard app.prefs.hotkey != nil else { return "Not set" }
        if !app.hotkeyAvailable { return "Taken by another app" }
        if app.hotkeyConflictsWithZoom { return "Zoom uses this too — change it in Zoom" }
        return nil
    }
}

/// The big sign at the top: lit red when live, smoked glass when muted, a glyph otherwise.
private struct StatusHeader: View {
    let state: MicState
    let onGrant: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if state.isInMeeting {
                SignLabel(live: state == .live, size: 16)
                    .padding(.horizontal, 22)
                    .frame(height: 44)
                    .litGlass(state == .live, in: Capsule())
            } else {
                Image(systemName: state.menuSymbol)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(state == .noPermission ? AnyShapeStyle(.yellow) : AnyShapeStyle(.secondary))
                    .frame(height: 44)
            }
            Text(state.panelSubtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
            if state == .noPermission {
                Button("Grant Access…", action: onGrant)
                    .buttonStyle(.glassProminent)
                    .tint(Theme.signalRed)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .animation(.snappy, value: state)
    }
}

private struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.bottom, -8)
    }
}

/// A System Settings–style row: colored icon tile, title (with an optional red note), control on the right.
private struct SettingRow<Trailing: View>: View {
    let symbol: String
    let tint: Color
    let title: String
    var detail: String?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(tint.gradient))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(Theme.signalRed)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

/// Indented like System Settings, so it starts under the row titles rather than the icon tiles.
private struct RowDivider: View {
    var body: some View { Divider().padding(.leading, 44) }
}

/// The hotkey as small keycaps, matching the recorder's large ones.
private struct MiniKeycaps: View {
    let caps: [String]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(caps.enumerated()), id: \.offset) { _, cap in
                Text(cap)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 5)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.primary.opacity(0.08)))
            }
        }
    }
}

private extension View {
    /// The rounded, faintly filled group that System Settings puts rows in.
    func settingsGroup() -> some View {
        background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.primary.opacity(0.05)))
    }
}
