// Renders Resources/AppIcon.icns: two-way arrows in red-on-black (black tile, white + red arrows).
// Run from the repo root: swift scripts/make-icon.swift
import AppKit

let accentRed = NSColor(srgbRed: 1.0, green: 0.0, blue: 0.33, alpha: 1) // #FF0055

func png(_ size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(size)
    // macOS icon grid: 824/1024 body with ~18% corner radius
    let body = NSRect(x: s * 0.098, y: s * 0.098, width: s * 0.804, height: s * 0.804)
    let path = NSBezierPath(roundedRect: body, xRadius: s * 0.18, yRadius: s * 0.18)
    NSGradient(starting: NSColor(srgbRed: 0.13, green: 0.13, blue: 0.15, alpha: 1),
               ending: NSColor(srgbRed: 0.05, green: 0.05, blue: 0.06, alpha: 1))!.draw(in: path, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: s * 0.42, weight: .bold)
        .applying(.init(paletteColors: [.white, accentRed]))
    let arrows = NSImage(systemSymbolName: "arrow.left.arrow.right", accessibilityDescription: nil)!
        .withSymbolConfiguration(config)!
    let a = arrows.size
    arrows.draw(in: NSRect(x: (s - a.width) / 2, y: (s - a.height) / 2, width: a.width, height: a.height))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! png(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! png(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! p.run()
p.waitUntilExit()
print("wrote Resources/AppIcon.icns")
