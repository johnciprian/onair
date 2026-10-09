// Renders the layers of Resources/AppIcon.icon (an Icon Composer document). Run from the repo root:
//   swift scripts/make-icon.swift
// The sign plate and the letters are separate layers so macOS gives each its own depth and glass highlights.
import AppKit
import SwiftUI

let assets = URL(fileURLWithPath: "Resources/AppIcon.icon/Assets")
try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)

let red = Color(red: 1.0, green: 0.231, blue: 0.188)   // Theme.signalRed
let deep = Color(red: 0.878, green: 0.145, blue: 0.106) // Theme.signalRedDeep

let plate = RoundedRectangle(cornerRadius: 96, style: .continuous)
    .fill(LinearGradient(colors: [red, deep], startPoint: .top, endPoint: .bottom))
    .frame(width: 820, height: 380)

let letters = Text("ON AIR")
    .font(.system(size: 120, weight: .black).width(.expanded))
    .tracking(14)
    .foregroundStyle(.white)

@MainActor func save(_ view: some View, as name: String) throws {
    let renderer = ImageRenderer(content: view.frame(width: 1024, height: 1024))
    renderer.scale = 1
    guard let image = renderer.cgImage,
          let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    else { throw CocoaError(.fileWriteUnknown) }
    try png.write(to: assets.appendingPathComponent(name))
}

try MainActor.assumeIsolated {
    try save(plate, as: "plate.png")
    try save(letters, as: "letters.png")
}
print("Wrote \(assets.path)")
exit(0)  // ImageRenderer leaves the run loop alive; without this the script never returns.
