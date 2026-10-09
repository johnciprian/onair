import AppKit

/// The standard macOS About window: icon, name, version and copyright come from Info.plist; the credits add
/// where the code lives and its license.
@MainActor
enum About {
    static let repository = URL(string: "https://github.com/johnciprian/onair")!

    static func show() {
        let credits = NSMutableAttributedString()
        credits.append(text("github.com/johnciprian/onair", link: repository))
        credits.append(text("\nFree to use, including at work, but not for resale.\n"))
        credits.append(text("MIT License with the Commons Clause", link: repository.appending(path: "blob/main/LICENSE")))
        NSApp.activate()  // a menu bar app isn't frontmost, so the window would otherwise open behind others
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }

    private static func text(_ string: String, link: URL? = nil) -> NSAttributedString {
        let centered = NSMutableParagraphStyle()
        centered.alignment = .center
        var attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: centered,
        ]
        attributes[.link] = link
        return NSAttributedString(string: string, attributes: attributes)
    }
}
