import AppKit

// Menu-bar-only app (LSUIElement); an AppKit entry point because the app is a status item plus panels.
// Top-level code isn't main-actor isolated in Swift 5 mode, but it does run on the main thread.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
