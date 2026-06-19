#!/usr/bin/env swift
import AppKit
import CoreGraphics

let iconsetDir = ".build/Karacookie.iconset"
let outIcns = "Resources/Karacookie.icns"

func drawIcon(_ size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }

    // ── 1. Rounded-rect background, "cookie" coral gradient ──────────────
    let radius = size * 0.225
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()

    let colorspace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(srgbRed: 1.00, green: 0.72, blue: 0.46, alpha: 1.0),   // top: warm cookie
        CGColor(srgbRed: 1.00, green: 0.45, blue: 0.30, alpha: 1.0),   // bottom: deeper coral
        CGColor(srgbRed: 0.85, green: 0.30, blue: 0.18, alpha: 1.0)    // base: baked edge
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorspace, colors: colors, locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: size * 0.2, y: size),
                           end: CGPoint(x: size * 0.8, y: 0),
                           options: [])

    // Subtle inner highlight
    ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.12))
    ctx.fillEllipse(in: CGRect(x: size * 0.05, y: size * 0.45,
                               width: size * 0.85, height: size * 0.6))

    // ── 2. Chocolate chips ──────────────────────────────────────────────
    let chipColor = CGColor(srgbRed: 0.18, green: 0.08, blue: 0.04, alpha: 0.95)
    let chipShine = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.22)
    let chips: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
        (0.20, 0.74, 0.075),
        (0.78, 0.62, 0.065),
        (0.30, 0.32, 0.060),
        (0.74, 0.26, 0.080),
        (0.50, 0.85, 0.055)
    ]
    for chip in chips {
        let r = chip.r * size
        let cx = chip.x * size
        let cy = chip.y * size
        ctx.setFillColor(chipColor)
        ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        // tiny highlight on each chip
        ctx.setFillColor(chipShine)
        let hr = r * 0.4
        ctx.fillEllipse(in: CGRect(x: cx - hr * 0.5, y: cy + r * 0.2,
                                   width: hr, height: hr * 0.6))
    }

    // ── 3. Music note glyph, centered ──────────────────────────────────
    let noteFontSize = size * 0.48
    let font = NSFont.systemFont(ofSize: noteFontSize, weight: .black)
    let text = "♪" as NSString
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(white: 0, alpha: 0.35)
    shadow.shadowBlurRadius = size * 0.03
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.01)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .shadow: shadow
    ]
    let textSize = text.size(withAttributes: attrs)
    let textRect = CGRect(
        x: (size - textSize.width) / 2,
        y: (size - textSize.height) / 2 - size * 0.04,
        width: textSize.width,
        height: textSize.height
    )
    text.draw(in: textRect, withAttributes: attrs)

    ctx.restoreGState()

    img.unlockFocus()
    return img
}

func writePNG(_ image: NSImage, to path: String, pixelSize: Int) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize, pixelsHigh: pixelSize,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 32
    )!
    rep.size = NSSize(width: pixelSize, height: pixelSize)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
               from: NSRect(origin: .zero, size: image.size),
               operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: path))
}

let fm = FileManager.default
try? fm.removeItem(atPath: iconsetDir)
try fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)
try? fm.createDirectory(
    atPath: (outIcns as NSString).deletingLastPathComponent,
    withIntermediateDirectories: true
)

let entries: [(filename: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

// Render once at the highest size we need, then downscale per entry.
let master = drawIcon(1024)
for entry in entries {
    let path = "\(iconsetDir)/\(entry.filename)"
    writePNG(master, to: path, pixelSize: entry.size)
}

// Convert to .icns via iconutil
let p = Process()
p.launchPath = "/usr/bin/iconutil"
p.arguments = ["-c", "icns", iconsetDir, "-o", outIcns]
try p.run()
p.waitUntilExit()
guard p.terminationStatus == 0 else {
    FileHandle.standardError.write("iconutil failed (\(p.terminationStatus))\n".data(using: .utf8)!)
    exit(1)
}
print("✓ wrote \(outIcns)")
