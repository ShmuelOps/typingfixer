// Renders Resources/AppIcon.icns: an S-shaped two-way arrow in red-on-black
// (black tile, red #FF0055), plus docs/logo.png (arrow only, transparent) for the README.
// Run from the repo root: swift scripts/make-icon.swift [preview.png]
import AppKit

let accentRed = CGColor(srgbRed: 1.0, green: 0.0, blue: 0.33, alpha: 1)
let accentPink = CGColor(srgbRed: 1.0, green: 0.42, blue: 0.62, alpha: 1)

func png(_ size: Int, tile drawTile: Bool = true) -> Data {
    let s = CGFloat(size)
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    var px = CGAffineTransform(scaleX: s, y: s) // paths are drawn in unit coordinates, y up
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

    // macOS icon grid: 824/1024 body with ~18% corner radius
    let tile = CGPath(roundedRect: CGRect(x: 0.098, y: 0.098, width: 0.804, height: 0.804),
                      cornerWidth: 0.18, cornerHeight: 0.18, transform: &px)
    if drawTile {
    ctx.saveGState()
    ctx.addPath(tile)
    ctx.clip()
    ctx.drawLinearGradient(CGGradient(colorsSpace: nil, colors: [CGColor(gray: 0.15, alpha: 1), CGColor(gray: 0.05, alpha: 1)] as CFArray, locations: nil)!,
                           start: pt(0.5, 0.9), end: pt(0.5, 0.1), options: [])
    ctx.restoreGState()
    }

    // One S-stroke: arrow down at bottom-left, rises, sweeps across, arrow up at top-right
    let a = CGPoint(x: 0.31, y: 0.30), b = CGPoint(x: 0.69, y: 0.70)
    let wave = CGMutablePath()
    wave.move(to: a)
    wave.addCurve(to: b, control1: CGPoint(x: 0.31, y: 0.90), control2: CGPoint(x: 0.69, y: 0.10))
    // arrowheads: chevrons at both ends
    let h: CGFloat = 0.09
    wave.move(to: CGPoint(x: a.x - h, y: a.y + h)); wave.addLine(to: a); wave.addLine(to: CGPoint(x: a.x + h, y: a.y + h))
    wave.move(to: CGPoint(x: b.x - h, y: b.y - h)); wave.addLine(to: b); wave.addLine(to: CGPoint(x: b.x + h, y: b.y - h))

    let stroke = wave.copy(using: &px)!.copy(strokingWithWidth: 0.075 * s, lineCap: .round, lineJoin: .round, miterLimit: 10)
    ctx.addPath(stroke)
    ctx.clip()
    ctx.drawLinearGradient(CGGradient(colorsSpace: nil, colors: [accentRed, accentPink] as CFArray, locations: nil)!,
                           start: pt(0.25, 0.25), end: pt(0.75, 0.75), options: [])
    return NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
}

if CommandLine.arguments.count > 1 {
    try! png(1024).write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    exit(0)
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
try! png(512, tile: false).write(to: URL(fileURLWithPath: "docs/logo.png"))
print("wrote Resources/AppIcon.icns, docs/logo.png")
