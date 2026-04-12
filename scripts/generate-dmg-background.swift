#!/usr/bin/env swift
import Cocoa

// DMG background image generator for Clip Holder
// Matches the Figma "DMG Installer — Dark Theme" design
// Icons are NOT included — Finder renders real icons on top

let width: CGFloat = 660
let height: CGFloat = 400
let scale: CGFloat = 2 // Retina

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width * scale),
    pixelsHigh: Int(height * scale),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
rep.size = NSSize(width: width, height: height)

NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("No CG context") }

// Flip so y=0 is at top (matches Figma coords)
ctx.translateBy(x: 0, y: height)
ctx.scaleBy(x: 1, y: -1)

let colorSpace = CGColorSpaceCreateDeviceRGB()

// ---- Background gradient (horizontal, dark purple) ----
let bgColors: [CGFloat] = [
    0.08, 0.06, 0.14, 1.0,
    0.13, 0.10, 0.24, 1.0,
    0.08, 0.06, 0.14, 1.0
]
let bgGradient = CGGradient(
    colorSpace: colorSpace,
    colorComponents: bgColors,
    locations: [0.0, 0.5, 1.0],
    count: 3
)!
ctx.drawLinearGradient(
    bgGradient,
    start: CGPoint(x: 0, y: 0),
    end: CGPoint(x: width, y: 0),
    options: []
)

// ---- Center glow (radial) ----
let glowColors: [CGFloat] = [
    0.4, 0.25, 0.7, 0.15,
    0.4, 0.25, 0.7, 0.0
]
let glowGradient = CGGradient(
    colorSpace: colorSpace,
    colorComponents: glowColors,
    locations: [0.0, 1.0],
    count: 2
)!
let center = CGPoint(x: width / 2, y: height / 2 - 10)
ctx.drawRadialGradient(
    glowGradient,
    startCenter: center, startRadius: 0,
    endCenter: center, endRadius: 200,
    options: []
)

// ---- Top accent bar ----
ctx.saveGState()
ctx.clip(to: CGRect(x: 0, y: 0, width: width, height: 3))
let accentColors: [CGFloat] = [
    0.55, 0.36, 0.95, 0.0,
    0.55, 0.36, 0.95, 0.8,
    0.55, 0.36, 0.95, 0.0
]
let accentGradient = CGGradient(
    colorSpace: colorSpace,
    colorComponents: accentColors,
    locations: [0.0, 0.5, 1.0],
    count: 3
)!
ctx.drawLinearGradient(
    accentGradient,
    start: CGPoint(x: 0, y: 1),
    end: CGPoint(x: width, y: 1),
    options: []
)
ctx.restoreGState()

// ---- Applications folder icon (background guide) ----
// Folder centered at x=445, icon area top ~105
let folderX: CGFloat = 385
let folderY: CGFloat = 115
let folderW: CGFloat = 120
let folderH: CGFloat = 100

// Folder tab
let tabPath = CGMutablePath()
tabPath.addRoundedRect(in: CGRect(x: folderX + 8, y: folderY - 9, width: 42, height: 16), cornerWidth: 5, cornerHeight: 5)
ctx.saveGState()
ctx.addPath(tabPath)
ctx.setFillColor(red: 0.25, green: 0.38, blue: 0.65, alpha: 1.0)
ctx.fillPath()
ctx.restoreGState()

// Folder body
let folderPath = CGMutablePath()
folderPath.addRoundedRect(in: CGRect(x: folderX, y: folderY, width: folderW, height: folderH), cornerWidth: 8, cornerHeight: 8)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 6), blur: 16, color: CGColor(red: 0.15, green: 0.25, blue: 0.55, alpha: 0.35))
ctx.addPath(folderPath)

// Folder gradient fill
let folderColors: [CGFloat] = [
    0.25, 0.38, 0.65, 1.0,
    0.18, 0.28, 0.55, 1.0
]
let folderGradient = CGGradient(
    colorSpace: colorSpace,
    colorComponents: folderColors,
    locations: [0.0, 1.0],
    count: 2
)!
ctx.clip()
ctx.drawLinearGradient(
    folderGradient,
    start: CGPoint(x: folderX, y: folderY),
    end: CGPoint(x: folderX, y: folderY + folderH),
    options: []
)
ctx.restoreGState()

// "A" letter on folder
ctx.saveGState()
ctx.translateBy(x: 0, y: height)
ctx.scaleBy(x: 1, y: -1)
let folderAAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 40, weight: .bold),
    .foregroundColor: NSColor(red: 0.4, green: 0.55, blue: 0.85, alpha: 0.45)
]
let aStr = "A" as NSString
let aSize = aStr.size(withAttributes: folderAAttrs)
let aX = folderX + (folderW - aSize.width) / 2
let aY = height - (folderY + 35 + aSize.height / 2) // flip Y, center in folder
aStr.draw(at: CGPoint(x: aX, y: aY), withAttributes: folderAAttrs)
ctx.restoreGState()

// ---- Arrow (between icon positions) ----
// App icon center ~225, Applications center ~445, vertical center ~165
let arrowY: CGFloat = 165
let arrowX1: CGFloat = 298
let arrowX2: CGFloat = 368

ctx.setStrokeColor(red: 0.6, green: 0.5, blue: 0.85, alpha: 0.7)
ctx.setLineWidth(2.5)
ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: arrowX1, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowX2 - 10, y: arrowY))
ctx.strokePath()

// Arrow head
ctx.setFillColor(red: 0.6, green: 0.5, blue: 0.85, alpha: 0.7)
ctx.move(to: CGPoint(x: arrowX2, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowX2 - 14, y: arrowY - 8))
ctx.addLine(to: CGPoint(x: arrowX2 - 14, y: arrowY + 8))
ctx.closePath()
ctx.fillPath()

// ---- Text labels (rendered in flipped context) ----
ctx.saveGState()
ctx.translateBy(x: 0, y: height)
ctx.scaleBy(x: 1, y: -1)

// Instruction text
let instrAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 12, weight: .regular),
    .foregroundColor: NSColor(red: 0.55, green: 0.50, blue: 0.65, alpha: 0.6)
]
let instruction = "Clip Holder を Applications にドラッグしてインストール" as NSString
let instrSize = instruction.size(withAttributes: instrAttrs)
instruction.draw(
    at: CGPoint(x: (width - instrSize.width) / 2, y: height - 320),
    withAttributes: instrAttrs
)

ctx.restoreGState()

NSGraphicsContext.current = nil

// ---- Save as PNG ----
guard let pngData = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to create PNG data")
}

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let outputURL = scriptDir.appendingPathComponent("dmg-background.png")
try! pngData.write(to: outputURL)

print("DMG background generated: \(outputURL.path)")
