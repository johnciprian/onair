import AppKit
import SwiftUI

/// The setup and hotkey-recorder windows: a standard macOS window with its title bar hidden — the look picked in a
/// side-by-side comparison. macOS draws the rounded corners, shadow and active/inactive appearance, and the hidden
/// title bar strip drags the window. (Custom borderless glass panels drew a rectangular box while active —
/// NSGlassEffectView adds a tint layer the size of the whole window — and needed drag and activation workarounds.)
@MainActor
enum UtilityWindow {
    static func make<Content: View>(content: Content) -> NSWindow {
        // Content runs under the hidden title bar; without this SwiftUI pads for it and the window grows.
        let host = NSHostingView(rootView: content.ignoresSafeArea())
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: host.fittingSize),
                              styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        window.contentView = host
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(button)?.isHidden = true
        }
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        return window
    }

    /// Centers and brings the window forward. `orderFrontRegardless` covers macOS declining to activate a
    /// menu bar app that was just launched, so the window can't open buried behind other apps.
    static func present(_ window: NSWindow) {
        NSApp.activate()
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}
