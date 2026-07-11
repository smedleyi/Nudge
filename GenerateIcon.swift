import AppKit

// One-off icon generator: run with `swift GenerateIcon.swift`, then
// `iconutil -c icns AppIcon.iconset -o AppIcon.icns`.

// Renders directly into a pixel-exact bitmap context so output size never
// depends on the screen's backing scale factor (NSImage.lockFocus does).
func makeIconRep(pixelSize: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixelSize, pixelsHigh: pixelSize, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let size = CGFloat(pixelSize)
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.2237  // macOS "squircle" convention
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    path.addClip()

    let gradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.36, green: 0.68, blue: 1.0, alpha: 1.0),
            NSColor(calibratedRed: 0.09, green: 0.35, blue: 0.88, alpha: 1.0),
        ])
    gradient?.draw(in: rect, angle: -90)

    if let symbol = NSImage(
        systemSymbolName: "cursorarrow.motionlines", accessibilityDescription: nil)
    {
        let config = NSImage.SymbolConfiguration(pointSize: size * 0.5, weight: .medium)
            .applying(.init(paletteColors: [.white]))
        if let white = symbol.withSymbolConfiguration(config) {
            let symSize = white.size
            let scale = (size * 0.62) / max(symSize.width, symSize.height)
            let drawSize = NSSize(width: symSize.width * scale, height: symSize.height * scale)
            let origin = NSPoint(x: (size - drawSize.width) / 2, y: (size - drawSize.height) / 2)
            white.draw(
                in: NSRect(origin: origin, size: drawSize), from: .zero, operation: .sourceOver,
                fraction: 1.0)
        }
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func savePNG(_ rep: NSBitmapImageRep, to path: String) throws {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to encode \(path)")
    }
    try data.write(to: URL(fileURLWithPath: path))
}

let iconsetPath = "AppIcon.iconset"
try? FileManager.default.createDirectory(
    atPath: iconsetPath, withIntermediateDirectories: true)

let specs: [(String, Int, Int)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2),
]

for (name, points, scale) in specs {
    let pixelSize = points * scale
    let rep = makeIconRep(pixelSize: pixelSize)
    try savePNG(rep, to: "\(iconsetPath)/\(name)")
    print("Wrote \(name) (\(pixelSize)x\(pixelSize))")
}
