#!/usr/bin/env swift
// Generates a 1024×1024 app icon PNG for ToothHurts.
// Run: swift tool/generate_icon.swift assets/icon.png
import AppKit

let size: CGFloat = 1024
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "assets/icon.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// ── Background: sky-blue gradient (playful, baby-themed) ─────────────────────
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bgColors = [
    CGColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1),  // #87CEEB  top
    CGColor(red: 0.60, green: 0.89, blue: 1.00, alpha: 1),  // #99E3FF  bottom
] as CFArray
let bgGrad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0,1] as [CGFloat])!
ctx.drawLinearGradient(bgGrad,
    start: CGPoint(x: size/2, y: size), end: CGPoint(x: size/2, y: 0), options: [])

// ── Mouth geometry ────────────────────────────────────────────────────────────
let mouthCX: CGFloat = size / 2
let mouthCY: CGFloat = size / 2 + 20    // slightly below center
let mouthW:  CGFloat = 840
let mouthH:  CGFloat = 460
let mouthL = mouthCX - mouthW / 2
let mouthT = mouthCY + mouthH / 2      // top of mouth (AppKit Y-up)
let mouthB = mouthCY - mouthH / 2      // bottom of mouth

// Outer lip path — rounded rect that looks like an open mouth
let mouthPath = NSBezierPath(roundedRect:
    NSRect(x: mouthL, y: mouthB, width: mouthW, height: mouthH),
    xRadius: mouthH / 2, yRadius: mouthH / 2)

// Lips: coral-pink fill behind the opening
NSColor(red: 0.95, green: 0.35, blue: 0.50, alpha: 1).setFill()
mouthPath.fill()

// ── Dark mouth interior (clip teeth to this) ──────────────────────────────────
let interiorInset: CGFloat = 52
let interiorPath = NSBezierPath(roundedRect:
    NSRect(x: mouthL + interiorInset, y: mouthB + interiorInset,
           width: mouthW - interiorInset*2, height: mouthH - interiorInset*2),
    xRadius: (mouthH - interiorInset*2) / 2, yRadius: (mouthH - interiorInset*2) / 2)

NSColor(red: 0.20, green: 0.00, blue: 0.02, alpha: 1).setFill()
interiorPath.fill()

// ── Helper: draw a row of N teeth ─────────────────────────────────────────────
func drawTeeth(n: Int, gumY: CGFloat, toothDown: Bool,
               gumH: CGFloat, toothH: CGFloat,
               rowW: CGFloat, centerX: CGFloat) {
    let gap:    CGFloat = 28
    let toothW: CGFloat = (rowW - gap * CGFloat(n - 1)) / CGFloat(n)
    let startX  = centerX - rowW / 2

    for i in 0..<n {
        let tx = startX + CGFloat(i) * (toothW + gap)
        let ty = toothDown ? gumY - toothH : gumY   // Y of tooth body start

        // Tooth body (white rounded-bottom rectangle)
        let cornerR: CGFloat = toothW * 0.28
        let toothRect = NSRect(x: tx, y: ty, width: toothW, height: toothH)
        let toothPath = NSBezierPath(roundedRect: toothRect,
                                     xRadius: cornerR, yRadius: cornerR)
        NSColor(red: 0.97, green: 0.97, blue: 0.94, alpha: 1).setFill()
        toothPath.fill()

        // Subtle shadow on right side of each tooth
        NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.08).setFill()
        let shadePath = NSBezierPath()
        if toothDown {
            shadePath.move(to:  NSPoint(x: tx + toothW * 0.72, y: gumY))
            shadePath.line(to:  NSPoint(x: tx + toothW,         y: gumY))
            shadePath.line(to:  NSPoint(x: tx + toothW,         y: ty + cornerR))
            shadePath.curve(to: NSPoint(x: tx + toothW - cornerR, y: ty),
                            controlPoint1: NSPoint(x: tx + toothW, y: ty),
                            controlPoint2: NSPoint(x: tx + toothW, y: ty))
            shadePath.line(to:  NSPoint(x: tx + toothW * 0.78, y: ty))
        } else {
            shadePath.move(to:  NSPoint(x: tx + toothW * 0.72, y: gumY + gumH))
            shadePath.line(to:  NSPoint(x: tx + toothW,         y: gumY + gumH))
            shadePath.line(to:  NSPoint(x: tx + toothW,         y: gumY + toothH - cornerR))
            shadePath.curve(to: NSPoint(x: tx + toothW - cornerR, y: gumY + toothH),
                            controlPoint1: NSPoint(x: tx + toothW, y: gumY + toothH),
                            controlPoint2: NSPoint(x: tx + toothW, y: gumY + toothH))
            shadePath.line(to:  NSPoint(x: tx + toothW * 0.78, y: gumY + toothH))
        }
        shadePath.close()
        shadePath.fill()
    }

    // Gum strip
    let gumRect = NSRect(x: centerX - rowW/2 - 20, y: gumY - (toothDown ? gumH : 0),
                          width: rowW + 40, height: gumH)
    NSColor(red: 1.0, green: 0.42, blue: 0.57, alpha: 1).setFill()
    NSBezierPath.fill(gumRect)

    // Gum line border (slightly darker)
    NSColor(red: 0.85, green: 0.25, blue: 0.40, alpha: 0.6).setFill()
    let borderH: CGFloat = 5
    let borderRect = NSRect(x: gumRect.minX, y: toothDown ? gumY - gumH : gumY + gumH - borderH,
                             width: gumRect.width, height: borderH)
    NSBezierPath.fill(borderRect)
}

// Clip subsequent drawing to mouth interior
ctx.saveGState()
interiorPath.addClip()

let gumH:    CGFloat = 55
let toothH:  CGFloat = 140
// Top teeth row: 2 teeth, widely spaced
drawTeeth(n: 2, gumY: mouthT - interiorInset,
          toothDown: true, gumH: gumH, toothH: toothH,
          rowW: 500, centerX: mouthCX)

// Bottom teeth row: 3 teeth, widely spaced
drawTeeth(n: 3, gumY: mouthB + interiorInset,
          toothDown: false, gumH: gumH, toothH: toothH,
          rowW: 580, centerX: mouthCX)

ctx.restoreGState()

// ── Lip gloss highlight ───────────────────────────────────────────────────────
let glossPath = NSBezierPath(roundedRect:
    NSRect(x: mouthL + 80, y: mouthT - 28, width: mouthW - 300, height: 18),
    xRadius: 9, yRadius: 9)
NSColor(red: 1, green: 1, blue: 1, alpha: 0.30).setFill()
glossPath.fill()

image.unlockFocus()

// ── Write PNG ──────────────────────────────────────────────────────────────────
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("✓ Icon written to \(outPath)")
