import AppKit

/// Menu-bar version of the app icon's S-shaped two-way arrow (scripts/make-icon.swift),
/// without the tile. A template image, so macOS tints it for light/dark menu bars.
func menuIcon(size: CGFloat = 18) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
        // Same unit-space path as the app icon; its ink spans ~0.2...0.8, so stretch that to the full size.
        var t = CGAffineTransform(scaleX: size / 0.62, y: size / 0.62).translatedBy(x: -0.19, y: -0.19)
        let a = CGPoint(x: 0.31, y: 0.30), b = CGPoint(x: 0.69, y: 0.70), h: CGFloat = 0.09
        let path = CGMutablePath()
        path.move(to: a)
        path.addCurve(to: b, control1: CGPoint(x: 0.31, y: 0.90), control2: CGPoint(x: 0.69, y: 0.10))
        path.move(to: CGPoint(x: a.x - h, y: a.y + h)); path.addLine(to: a); path.addLine(to: CGPoint(x: a.x + h, y: a.y + h))
        path.move(to: CGPoint(x: b.x - h, y: b.y - h)); path.addLine(to: b); path.addLine(to: CGPoint(x: b.x + h, y: b.y - h))
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.addPath(path.copy(using: &t)!)
        ctx.setLineWidth(size * 0.11)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.strokePath()
        return true
    }
    image.isTemplate = true
    image.accessibilityDescription = "TypingFixer"
    return image
}
