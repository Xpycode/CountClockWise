import Cocoa
let output = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let transform = NSAffineTransform()
        transform.scale(by: CGFloat(pixels) / 1024)
        transform.concat()
        NSColor(calibratedWhite: 0.10, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 185, yRadius: 185).fill()
        NSColor(calibratedWhite: 0.95, alpha: 1).setStroke()
        let ring = NSBezierPath(ovalIn: NSRect(x: 210, y: 210, width: 604, height: 604))
        ring.lineWidth = 22; ring.stroke()
        for hour in 0..<12 {
            let angle = Double(hour) * .pi / 6
            let tick = NSBezierPath()
            tick.move(to: NSPoint(x: 512 + sin(angle) * 262, y: 512 + cos(angle) * 262))
            tick.line(to: NSPoint(x: 512 + sin(angle) * 282, y: 512 + cos(angle) * 282))
            tick.lineWidth = 15; tick.lineCapStyle = .round; tick.stroke()
        }
        let hands = NSBezierPath(); hands.move(to: NSPoint(x: 390, y: 603)); hands.line(to: NSPoint(x: 512, y: 512)); hands.line(to: NSPoint(x: 666, y: 667))
        hands.lineWidth = 37; hands.lineCapStyle = .round; hands.lineJoinStyle = .round; hands.stroke()
        NSColor.systemOrange.setStroke()
        let seconds = NSBezierPath(); seconds.move(to: NSPoint(x: 512, y: 550)); seconds.line(to: NSPoint(x: 512, y: 274)); seconds.lineWidth = 16; seconds.lineCapStyle = .round; seconds.stroke()
        NSColor.systemOrange.setFill(); NSBezierPath(ovalIn: NSRect(x: 489, y: 489, width: 46, height: 46)).fill()
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        let file = "\(output)/icon_\(size)x\(size)\(suffix).png"
        try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: file))
    }
}
