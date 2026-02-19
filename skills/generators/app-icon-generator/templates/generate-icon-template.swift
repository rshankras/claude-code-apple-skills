#!/usr/bin/env swift
//
// App Icon Generator Template
// Customize the CONFIGURATION section and variant functions for your app.
//
// Usage: swift generate-icon.swift
// Output: icon-variants/*.png (1024x1024)
//

import AppKit
import CoreGraphics

// ============================================================================
// MARK: - CONFIGURATION (customize per app)
// ============================================================================

let size: CGFloat = 1024
let outputDir = FileManager.default.currentDirectoryPath + "/icon-variants"

// Background palettes (from, to)
// Deep Blue/Indigo:  (0x0f0c29, 0x302b63)
// Teal/Cyan:         (0x0a1628, 0x1a4a6b)
// Purple/Violet:     (0x1a0533, 0x4a1a8a)
// Warm/Dark Red:     (0x2d1117, 0x6b1a1a)
// Dark Gray:         (0x1a1a2e, 0x2d2d44)
// Dark Green:        (0x0a2e1a, 0x1a6b3a)

// Accent colors (gradient top, gradient bottom)
// Red:    (0xff453a, 0xd63031)
// Blue:   (0x007aff, 0x0056b3)
// Green:  (0x34c759, 0x248a3d)
// Gold:   (0xffd60a, 0xc7a600)
// Orange: (0xff9500, 0xcc7700)

// ============================================================================
// MARK: - Drawing Helpers (reusable building blocks)
// ============================================================================

func color(_ hex: UInt32, alpha: CGFloat = 1.0) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255.0,
        green: CGFloat((hex >> 8) & 0xFF) / 255.0,
        blue: CGFloat(hex & 0xFF) / 255.0,
        alpha: alpha
    )
}

let colorSpace = CGColorSpaceCreateDeviceRGB()

/// Fill the canvas with a top-to-bottom linear gradient.
func drawGradientBackground(_ ctx: CGContext, from: UInt32, to: UInt32) {
    let colors = [color(from).cgColor, color(to).cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: size / 2, y: size),
        end: CGPoint(x: size / 2, y: 0),
        options: []
    )
}

/// Soft radial glow behind a focal element.
func drawRadialGlow(_ ctx: CGContext, center: CGPoint, radius: CGFloat, hex: UInt32, alpha: CGFloat = 0.15) {
    let colors = [color(hex, alpha: alpha).cgColor, color(hex, alpha: 0).cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
    ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
}

/// Filled circle with a vertical gradient.
func drawGradientCircle(_ ctx: CGContext, center: CGPoint, radius: CGFloat, topColor: UInt32, bottomColor: UInt32) {
    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    ctx.saveGState()
    ctx.addEllipse(in: rect)
    ctx.clip()
    let colors = [color(topColor).cgColor, color(bottomColor).cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: center.x, y: center.y + radius), end: CGPoint(x: center.x, y: center.y - radius), options: [])
    ctx.restoreGState()
}

/// Stroked circle ring.
func drawRing(_ ctx: CGContext, center: CGPoint, radius: CGFloat, color ringColor: UInt32, alpha: CGFloat = 0.2, lineWidth: CGFloat? = nil) {
    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    ctx.setStrokeColor(color(ringColor, alpha: alpha).cgColor)
    ctx.setLineWidth(lineWidth ?? size * 0.015)
    ctx.addEllipse(in: rect)
    ctx.strokePath()
}

/// Specular shine highlight on upper portion of a circle.
func drawShine(_ ctx: CGContext, center: CGPoint, radius: CGFloat, intensity: CGFloat = 0.25) {
    ctx.saveGState()
    let shineRect = CGRect(
        x: center.x - radius * 0.6, y: center.y + radius * 0.05,
        width: radius * 1.2, height: radius * 0.85
    )
    ctx.addEllipse(in: shineRect)
    ctx.clip()
    let colors = [NSColor.white.withAlphaComponent(intensity).cgColor, NSColor.white.withAlphaComponent(0).cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: center.x, y: center.y + radius), end: CGPoint(x: center.x, y: center.y), options: [])
    ctx.restoreGState()
}

/// Rounded rectangle (filled).
func drawRoundedRect(_ ctx: CGContext, rect: CGRect, cornerRadius: CGFloat, fillColor: UInt32, alpha: CGFloat = 1.0) {
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(color(fillColor, alpha: alpha).cgColor)
    ctx.fillPath()
}

/// Rounded rectangle (stroked).
func drawRoundedRectStroke(_ ctx: CGContext, rect: CGRect, cornerRadius: CGFloat, strokeColor: UInt32, alpha: CGFloat = 0.7, lineWidth: CGFloat? = nil) {
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(path)
    ctx.setStrokeColor(color(strokeColor, alpha: alpha).cgColor)
    ctx.setLineWidth(lineWidth ?? size * 0.012)
    ctx.strokePath()
}

/// Viewfinder corner brackets (4 corners).
func drawViewfinderBrackets(_ ctx: CGContext, center: CGPoint, bracketSize: CGFloat, bracketLength: CGFloat, lineWidth: CGFloat? = nil, bracketColor: UInt32 = 0xFFFFFF, alpha: CGFloat = 0.85) {
    let w = lineWidth ?? size * 0.02
    let r = size * 0.015 // corner radius

    ctx.setStrokeColor(color(bracketColor, alpha: alpha).cgColor)
    ctx.setLineWidth(w)
    ctx.setLineCap(.round)

    // Top-left
    let tl = CGPoint(x: center.x - bracketSize, y: center.y + bracketSize)
    ctx.move(to: CGPoint(x: tl.x, y: tl.y - bracketLength))
    ctx.addLine(to: CGPoint(x: tl.x, y: tl.y - r))
    ctx.addArc(center: CGPoint(x: tl.x + r, y: tl.y - r), radius: r, startAngle: .pi, endAngle: .pi / 2, clockwise: true)
    ctx.addLine(to: CGPoint(x: tl.x + bracketLength, y: tl.y))
    ctx.strokePath()

    // Top-right
    let tr = CGPoint(x: center.x + bracketSize, y: center.y + bracketSize)
    ctx.move(to: CGPoint(x: tr.x, y: tr.y - bracketLength))
    ctx.addLine(to: CGPoint(x: tr.x, y: tr.y - r))
    ctx.addArc(center: CGPoint(x: tr.x - r, y: tr.y - r), radius: r, startAngle: 0, endAngle: .pi / 2, clockwise: false)
    ctx.addLine(to: CGPoint(x: tr.x - bracketLength, y: tr.y))
    ctx.strokePath()

    // Bottom-left
    let bl = CGPoint(x: center.x - bracketSize, y: center.y - bracketSize)
    ctx.move(to: CGPoint(x: bl.x, y: bl.y + bracketLength))
    ctx.addLine(to: CGPoint(x: bl.x, y: bl.y + r))
    ctx.addArc(center: CGPoint(x: bl.x + r, y: bl.y + r), radius: r, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: false)
    ctx.addLine(to: CGPoint(x: bl.x + bracketLength, y: bl.y))
    ctx.strokePath()

    // Bottom-right
    let br = CGPoint(x: center.x + bracketSize, y: center.y - bracketSize)
    ctx.move(to: CGPoint(x: br.x, y: br.y + bracketLength))
    ctx.addLine(to: CGPoint(x: br.x, y: br.y + r))
    ctx.addArc(center: CGPoint(x: br.x - r, y: br.y + r), radius: r, startAngle: 0, endAngle: 3 * .pi / 2, clockwise: true)
    ctx.addLine(to: CGPoint(x: br.x - bracketLength, y: br.y))
    ctx.strokePath()
}

/// Monitor shape (screen + stand + base).
func drawMonitor(_ ctx: CGContext, center: CGPoint, screenWidth: CGFloat, screenHeight: CGFloat, strokeColor: UInt32 = 0xFFFFFF, alpha: CGFloat = 0.7) {
    let screenY = center.y + size * 0.02
    let screenRect = CGRect(x: center.x - screenWidth / 2, y: screenY - screenHeight / 2, width: screenWidth, height: screenHeight)

    // Screen fill
    drawRoundedRect(ctx, rect: screenRect, cornerRadius: size * 0.025, fillColor: 0x1a2a3a)
    // Screen border
    drawRoundedRectStroke(ctx, rect: screenRect, cornerRadius: size * 0.025, strokeColor: strokeColor, alpha: alpha)

    // Stand
    let standW = size * 0.08
    let standH = size * 0.06
    ctx.setFillColor(color(strokeColor, alpha: alpha).cgColor)
    ctx.fill(CGRect(x: center.x - standW / 2, y: screenY - screenHeight / 2 - standH, width: standW, height: standH))

    // Base
    let baseW = size * 0.18
    let baseH = size * 0.012
    let baseRect = CGRect(x: center.x - baseW / 2, y: screenY - screenHeight / 2 - standH - baseH, width: baseW, height: baseH)
    let basePath = CGPath(roundedRect: baseRect, cornerWidth: baseH / 2, cornerHeight: baseH / 2, transform: nil)
    ctx.addPath(basePath)
    ctx.setFillColor(color(strokeColor, alpha: alpha).cgColor)
    ctx.fillPath()
}

/// Simple person silhouette (head + shoulders) clipped to a circle.
func drawPersonInCircle(_ ctx: CGContext, center: CGPoint, radius: CGFloat, fillColor: UInt32 = 0xFFFFFF, alpha: CGFloat = 0.8) {
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    ctx.clip()
    let headR = radius * 0.3
    ctx.addEllipse(in: CGRect(x: center.x - headR, y: center.y + radius * 0.05, width: headR * 2, height: headR * 2))
    ctx.setFillColor(color(fillColor, alpha: alpha).cgColor)
    ctx.fillPath()
    let shoulderR = radius * 0.55
    ctx.addEllipse(in: CGRect(x: center.x - shoulderR, y: center.y - radius * 0.7, width: shoulderR * 2, height: shoulderR * 1.2))
    ctx.fillPath()
    ctx.restoreGState()
}

/// Crosshair (thin + / x centered).
func drawCrosshair(_ ctx: CGContext, center: CGPoint, armLength: CGFloat, color crossColor: UInt32 = 0xFFFFFF, alpha: CGFloat = 0.3) {
    ctx.setStrokeColor(color(crossColor, alpha: alpha).cgColor)
    ctx.setLineWidth(size * 0.008)
    ctx.move(to: CGPoint(x: center.x - armLength, y: center.y))
    ctx.addLine(to: CGPoint(x: center.x + armLength, y: center.y))
    ctx.strokePath()
    ctx.move(to: CGPoint(x: center.x, y: center.y - armLength))
    ctx.addLine(to: CGPoint(x: center.x, y: center.y + armLength))
    ctx.strokePath()
}

/// Waveform bars (audio apps).
func drawWaveform(_ ctx: CGContext, center: CGPoint, barCount: Int = 5, maxHeight: CGFloat, barWidth: CGFloat, barColor: UInt32, alpha: CGFloat = 0.9) {
    let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barWidth * 0.6
    let startX = center.x - totalWidth / 2
    let heights: [CGFloat] = [0.4, 0.7, 1.0, 0.7, 0.4] // symmetric pattern

    for i in 0..<barCount {
        let h = maxHeight * heights[i % heights.count]
        let x = startX + CGFloat(i) * barWidth * 1.6
        let rect = CGRect(x: x, y: center.y - h / 2, width: barWidth, height: h)
        let path = CGPath(roundedRect: rect, cornerWidth: barWidth / 2, cornerHeight: barWidth / 2, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(color(barColor, alpha: alpha).cgColor)
        ctx.fillPath()
    }
}

/// Gear/cog shape (utility apps).
func drawGear(_ ctx: CGContext, center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat, teeth: Int = 8, gearColor: UInt32, alpha: CGFloat = 0.9) {
    let path = CGMutablePath()
    let toothDepth = outerRadius - innerRadius

    for i in 0..<(teeth * 2) {
        let angle = CGFloat(i) * .pi / CGFloat(teeth)
        let r = i % 2 == 0 ? outerRadius : outerRadius - toothDepth
        let x = center.x + r * cos(angle)
        let y = center.y + r * sin(angle)
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
        else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()

    // Center hole
    let holeRadius = innerRadius * 0.4
    path.addEllipse(in: CGRect(x: center.x - holeRadius, y: center.y - holeRadius, width: holeRadius * 2, height: holeRadius * 2))

    ctx.addPath(path)
    ctx.setFillColor(color(gearColor, alpha: alpha).cgColor)
    ctx.fillPath(using: .evenOdd)
}

/// Shield outline (security apps).
func drawShield(_ ctx: CGContext, center: CGPoint, width: CGFloat, height: CGFloat, shieldColor: UInt32, alpha: CGFloat = 0.9) {
    let path = CGMutablePath()
    let top = CGPoint(x: center.x, y: center.y + height / 2)
    let left = CGPoint(x: center.x - width / 2, y: center.y + height * 0.15)
    let right = CGPoint(x: center.x + width / 2, y: center.y + height * 0.15)
    let bottom = CGPoint(x: center.x, y: center.y - height / 2)

    path.move(to: top)
    path.addQuadCurve(to: left, control: CGPoint(x: center.x - width / 2, y: center.y + height / 2))
    path.addQuadCurve(to: bottom, control: CGPoint(x: center.x - width / 2, y: center.y - height * 0.15))
    path.addQuadCurve(to: right, control: CGPoint(x: center.x + width / 2, y: center.y - height * 0.15))
    path.addQuadCurve(to: top, control: CGPoint(x: center.x + width / 2, y: center.y + height / 2))

    ctx.addPath(path)
    ctx.setFillColor(color(shieldColor, alpha: alpha).cgColor)
    ctx.fillPath()
}

// ============================================================================
// MARK: - Image Save Helper
// ============================================================================

func saveImage(_ image: NSImage, name: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Failed to save \(name)")
        return
    }
    let url = URL(fileURLWithPath: "\(outputDir)/\(name).png")
    try? png.write(to: url)
    print("Saved: \(url.path)")
}

func createCanvas() -> (NSImage, CGContext) {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    return (image, ctx)
}

func finishCanvas(_ image: NSImage) {
    image.unlockFocus()
}

// ============================================================================
// MARK: - VARIANT FUNCTIONS (customize these for your app)
// ============================================================================

// EXAMPLE: Bold Record Button (Creative/Media app)
func generateVariantBoldSymbol() -> NSImage {
    let (image, ctx) = createCanvas()
    let center = CGPoint(x: size / 2, y: size / 2)

    drawGradientBackground(ctx, from: 0x0f0c29, to: 0x302b63)
    drawRadialGlow(ctx, center: center, radius: size * 0.55, hex: 0xff3b30, alpha: 0.15)
    drawRing(ctx, center: center, radius: size * 0.34, color: 0xFFFFFF)
    drawGradientCircle(ctx, center: center, radius: size * 0.28, topColor: 0xff453a, bottomColor: 0xd63031)
    drawShine(ctx, center: center, radius: size * 0.28)

    finishCanvas(image)
    return image
}

// EXAMPLE: Screen + Camera (Creative/Media app)
func generateVariantContainedScene() -> NSImage {
    let (image, ctx) = createCanvas()
    let center = CGPoint(x: size / 2, y: size / 2)

    drawGradientBackground(ctx, from: 0x0a1628, to: 0x1b3a5c)
    drawMonitor(ctx, center: center, screenWidth: size * 0.58, screenHeight: size * 0.38)

    // Record dot
    let dotCenter = CGPoint(x: center.x + size * 0.22, y: center.y + size * 0.14)
    drawGradientCircle(ctx, center: dotCenter, radius: size * 0.035, topColor: 0xff453a, bottomColor: 0xd63031)
    drawRadialGlow(ctx, center: dotCenter, radius: size * 0.1, hex: 0xff3b30, alpha: 0.4)

    // Camera circle
    let camCenter = CGPoint(x: center.x + size * 0.22, y: center.y - size * 0.18)
    drawGradientCircle(ctx, center: camCenter, radius: size * 0.09, topColor: 0x4a90d9, bottomColor: 0x3a70b9)
    drawRing(ctx, center: camCenter, radius: size * 0.09, color: 0xFFFFFF, alpha: 0.8, lineWidth: size * 0.008)
    drawPersonInCircle(ctx, center: camCenter, radius: size * 0.09)

    finishCanvas(image)
    return image
}

// EXAMPLE: Viewfinder + Record (Creative/Media app)
func generateVariantAbstractMark() -> NSImage {
    let (image, ctx) = createCanvas()
    let center = CGPoint(x: size / 2, y: size / 2)

    drawGradientBackground(ctx, from: 0x0f0c29, to: 0x24243e)
    drawRadialGlow(ctx, center: center, radius: size * 0.5, hex: 0x6c5ce7, alpha: 0.15)
    drawViewfinderBrackets(ctx, center: center, bracketSize: size * 0.28, bracketLength: size * 0.1)
    drawCrosshair(ctx, center: center, armLength: size * 0.04)
    drawGradientCircle(ctx, center: center, radius: size * 0.08, topColor: 0xff453a, bottomColor: 0xd63031)
    drawRadialGlow(ctx, center: center, radius: size * 0.2, hex: 0xff3b30, alpha: 0.2)

    finishCanvas(image)
    return image
}

// ============================================================================
// MARK: - Generate
// ============================================================================

try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
print("Generating icon variants at \(Int(size))x\(Int(size))...")

saveImage(generateVariantBoldSymbol(), name: "variant1-bold-symbol")
saveImage(generateVariantContainedScene(), name: "variant2-contained-scene")
saveImage(generateVariantAbstractMark(), name: "variant3-abstract-mark")

print("Done! Check \(outputDir)/")
