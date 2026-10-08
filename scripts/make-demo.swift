// Renders docs/demo.gif: "אני אוהב את האפליקציה" typed with the English layout on, animated.
// Simulated (drawn, not screen-recorded); keys come from the real layout map below.
// Run from the repo root: swift scripts/make-demo.swift [out.gif]
import AppKit
import ImageIO
import UniformTypeIdentifiers

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs/demo.gif"
let W: CGFloat = 900, H: CGFloat = 250, scale: CGFloat = 2
let red = NSColor(srgbRed: 1.0, green: 0.0, blue: 0.33, alpha: 1)
let muted = NSColor(white: 0.6, alpha: 1)

// Same map as Sources/LayoutFix/Layout.swift (US key -> macOS Hebrew layout)
let enToHe: [Character: Character] = [
    "q": "/", "w": "׳", "e": "ק", "r": "ר", "t": "א", "y": "ט", "u": "ו", "i": "ן", "o": "ם", "p": "פ",
    "a": "ש", "s": "ד", "d": "ג", "f": "כ", "g": "ע", "h": "י", "j": "ח", "k": "ל", "l": "ך", ";": "ף", "'": ",",
    "z": "ז", "x": "ס", "c": "ב", "v": "ה", "b": "נ", "n": "מ", "m": "צ", ",": "ת", ".": "ץ", "/": ".",
]

struct Frame { var screen: String; var keys: String; var hebrew: Bool; var toast: Bool; var ms: Int }

// --- timeline ---
let keys = Array("tbh tuvc t, vtpkhemhv")
let fixAt = 8 // index of the space after "tuvc"
var frames = [Frame(screen: "", keys: "", hebrew: false, toast: false, ms: 900)]
var screen = ""
for (i, k) in keys.enumerated() {
    let typed = String(keys[...i])
    if i == fixAt {
        frames.append(Frame(screen: screen + " ", keys: typed, hebrew: false, toast: false, ms: 350))
        screen = "אני אוהב "
        frames.append(Frame(screen: screen, keys: typed, hebrew: true, toast: true, ms: 1700))
        continue
    }
    screen.append(i < fixAt ? k : (k == " " ? " " : enToHe[k]!))
    frames.append(Frame(screen: screen, keys: typed, hebrew: i > fixAt, toast: false, ms: k == " " ? 220 : 120))
}
frames.append(Frame(screen: screen, keys: String(keys), hebrew: true, toast: false, ms: 3000))

// --- drawing ---
func attr(_ s: String, _ size: CGFloat, _ color: NSColor, _ weight: NSFont.Weight = .regular, mono: Bool = false,
          align: NSTextAlignment = .left) -> NSAttributedString {
    let p = NSMutableParagraphStyle()
    p.alignment = align
    let font = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: weight) : NSFont.systemFont(ofSize: size, weight: weight)
    return NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: p])
}

func box(_ r: NSRect, _ color: NSColor, _ radius: CGFloat) {
    color.setFill()
    NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius).fill()
}

func render(_ f: Frame) -> CGImage {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W * scale), pixelsHigh: Int(H * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: W, height: H)
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    ctx.cgContext.translateBy(x: 0, y: H)          // top-left origin, y down
    ctx.cgContext.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx.cgContext, flipped: true)

    NSColor(white: 0.06, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: W, height: H).fill()

    // text field
    let field = NSRect(x: 40, y: 20, width: W - 80, height: 96)
    box(field, NSColor(white: 0.13, alpha: 1), 14)
    (f.toast ? red : NSColor(white: 0.24, alpha: 1)).setStroke()
    let border = NSBezierPath(roundedRect: field.insetBy(dx: 0.5, dy: 0.5), xRadius: 14, yRadius: 14)
    border.lineWidth = f.toast ? 2 : 1
    border.stroke()

    let rtl = f.screen.unicodeScalars.contains { (0x05D0...0x05EA).contains($0.value) }
    let text = attr(f.screen, 38, .white, .medium, align: rtl ? .right : .left)
    let inner = field.insetBy(dx: 28, dy: 22)
    text.draw(in: inner)
    // caret at the end of the line: right of LTR text, left of RTL text
    let tw = text.size().width
    let caretX = rtl ? inner.maxX - tw - 4 : inner.minX + tw + 3
    box(NSRect(x: caretX, y: inner.minY + 6, width: 3, height: 42), red, 1.5)

    // keys pressed + current input source
    attr("KEYS PRESSED", 12, muted, .semibold).draw(at: NSPoint(x: 42, y: 140))
    attr(f.keys.isEmpty ? " " : f.keys, 22, NSColor(white: 0.85, alpha: 1), .medium, mono: true).draw(at: NSPoint(x: 40, y: 160))
    attr("INPUT SOURCE", 12, muted, .semibold, align: .right).draw(in: NSRect(x: W - 240, y: 140, width: 200, height: 20))
    let badge = attr(f.hebrew ? "עברית" : "ABC", 18, .white, .semibold)
    let bw = badge.size().width + 28
    let br = NSRect(x: W - 40 - bw, y: 162, width: bw, height: 32)
    box(br, f.hebrew ? red : NSColor(white: 0.22, alpha: 1), 8)
    badge.draw(at: NSPoint(x: br.minX + 14, y: br.minY + 5))

    if f.toast {
        let msg = attr("fixed:  tbh tuvc  →  אני אוהב   ·   switched to Hebrew   ·   Blow sound", 15, .white, .medium)
        let mw = msg.size().width + 36
        let mr = NSRect(x: (W - mw) / 2, y: 206, width: mw, height: 32)
        box(mr, red, 16)
        msg.draw(at: NSPoint(x: mr.minX + 18, y: mr.minY + 6))
    }
    NSGraphicsContext.current = nil
    return rep.cgImage!
}

// --- encode ---
try! FileManager.default.createDirectory(atPath: (out as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.gif.identifier as CFString, frames.count, nil)!
CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
for f in frames {
    let delay = Double(f.ms) / 1000
    CGImageDestinationAddImage(dest, render(f), [kCGImagePropertyGIFDictionary: [
        kCGImagePropertyGIFDelayTime: delay, kCGImagePropertyGIFUnclampedDelayTime: delay]] as CFDictionary)
}
precondition(CGImageDestinationFinalize(dest), "gif encode failed")
print("wrote \(out) (\(frames.count) frames)")
