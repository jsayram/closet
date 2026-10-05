// Builds labelled contact sheets from a folder of screenshots.
// Usage: swift Tools/make_contact_sheet.swift <input-dir> <output.png> "<title>" [columns]
import AppKit

let args = CommandLine.arguments
guard args.count >= 4 else { print("usage: make_contact_sheet <dir> <out.png> <title> [columns]"); exit(1) }
let dir = URL(fileURLWithPath: args[1])
let out = URL(fileURLWithPath: args[2])
let title = args[3]
let columns = args.count > 4 ? Int(args[4]) ?? 6 : 6

let files = (try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil))
    .filter { $0.pathExtension.lowercased() == "png" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }
guard !files.isEmpty else { print("no pngs in \(dir.path)"); exit(1) }

let images = files.compactMap { url -> (String, NSImage)? in
    guard let img = NSImage(contentsOf: url) else { return nil }
    return (url.deletingPathExtension().lastPathComponent, img)
}
let thumbWidth: CGFloat = 300
let maxAspect = images.map { $0.1.size.height / max($0.1.size.width, 1) }.max() ?? 2
let thumbHeight = thumbWidth * min(maxAspect, 2.3)
let labelHeight: CGFloat = 44
let pad: CGFloat = 24
let header: CGFloat = 90
let rows = Int(ceil(Double(images.count) / Double(columns)))
let width = pad + CGFloat(columns) * (thumbWidth + pad)
let height = header + CGFloat(rows) * (thumbHeight + labelHeight + pad) + pad

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width), pixelsHigh: Int(height), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSColor(srgbRed: 0xFA / 255, green: 0xF7 / 255, blue: 0xF2 / 255, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
let ink = NSColor(srgbRed: 0x29 / 255, green: 0x24 / 255, blue: 0x2A / 255, alpha: 1)
let taupe = NSColor(srgbRed: 0x6E / 255, green: 0x62 / 255, blue: 0x6A / 255, alpha: 1)
(title as NSString).draw(at: NSPoint(x: pad, y: height - 56), withAttributes: [.font: NSFont(name: "Georgia-Bold", size: 30) ?? NSFont.boldSystemFont(ofSize: 30), .foregroundColor: ink])
("Native SwiftUI simulator captures · fictional data · simulated services" as NSString).draw(at: NSPoint(x: pad, y: height - 82), withAttributes: [.font: NSFont.systemFont(ofSize: 14), .foregroundColor: taupe])
for (i, item) in images.enumerated() {
    let col = i % columns
    let row = i / columns
    let x = pad + CGFloat(col) * (thumbWidth + pad)
    let yTop = height - header - CGFloat(row) * (thumbHeight + labelHeight + pad)
    let aspect = item.1.size.height / max(item.1.size.width, 1)
    var w = thumbWidth
    var h = thumbWidth * aspect
    if h > thumbHeight { h = thumbHeight; w = h / aspect }
    let rect = NSRect(x: x + (thumbWidth - w) / 2, y: yTop - h, width: w, height: h)
    item.1.draw(in: rect)
    NSColor(srgbRed: 0xDE / 255, green: 0xD5 / 255, blue: 0xDA / 255, alpha: 1).setStroke()
    NSBezierPath(rect: rect).stroke()
    let para = NSMutableParagraphStyle(); para.lineBreakMode = .byWordWrapping
    (item.0.replacingOccurrences(of: "__", with: " · ") as NSString).draw(in: NSRect(x: x, y: yTop - thumbHeight - labelHeight + 4, width: thumbWidth, height: labelHeight - 4),
        withAttributes: [.font: NSFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: ink, .paragraphStyle: para])
}
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: out)
print("wrote \(out.path) with \(images.count) screenshots")
