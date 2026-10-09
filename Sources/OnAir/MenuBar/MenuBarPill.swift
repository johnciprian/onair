import AppKit
import OnAirCore
import SwiftUI

/// The status item's image for each state. It's a plain image in the standard status bar button, so macOS
/// sizes, highlights and (for template images) tints it like any other menu bar icon. (A SwiftUI view layered on
/// the button instead needed click pass-through and hand-measured widths, which went wrong.)
@MainActor
enum MenuBarIcon {
    static func image(for state: MicState) -> NSImage? {
        switch state {
        case .live:
            return render(MenuBarSign(live: true), template: false)  // full color: the lit red sign
        case .muted:
            return render(MenuBarSign(live: false), template: true)  // monochrome: macOS tints it for light/dark bars
        case .noMeeting, .notRunning:
            let mic = NSImage(systemSymbolName: "mic", accessibilityDescription: nil)?
                .withSymbolConfiguration(.init(pointSize: 14, weight: .medium))
            mic?.isTemplate = true
            return mic
        case .noPermission:
            return NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                    .applying(.init(paletteColors: [.systemYellow])))
        }
    }

    private static func render(_ view: some View, template: Bool) -> NSImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage
        image?.isTemplate = template
        return image
    }
}

/// ON AIR / OFF AIR at menu bar size. The OFF AIR version is drawn in black because it's used as a template
/// image — only its shape matters, and macOS supplies the color.
private struct MenuBarSign: View {
    let live: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(live ? Color.white : Color.clear)
                .overlay(Circle().strokeBorder(live ? Color.clear : Color.black, lineWidth: 1))
                .frame(width: 6, height: 6)
            Text(live ? "ON AIR" : "OFF AIR")
                .font(Theme.signFont(size: 9.5))
                .tracking(Theme.signTracking(size: 9.5))
                .foregroundStyle(live ? Color.white : Color.black)
        }
        .padding(.horizontal, 8)
        .frame(height: 18)
        .background(Capsule().fill(live ? AnyShapeStyle(Theme.signalGradient) : AnyShapeStyle(Color.clear)))
        // Live: a faint top highlight so the fill reads as lit glass. Muted: the outline is the whole shape.
        .overlay(Capsule().strokeBorder(
            live ? AnyShapeStyle(LinearGradient(colors: [.white.opacity(0.25), .clear], startPoint: .top, endPoint: .center))
                 : AnyShapeStyle(Color.black.opacity(0.6)),
            lineWidth: 1))
    }
}
