#!/usr/bin/env swift
// Render every page of each .pdf in a folder (default: current dir) to .png files.
import Foundation
import CoreGraphics
import AppKit

let folder = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

guard let files = try? FileManager.default.contentsOfDirectory(
    at: folder, includingPropertiesForKeys: nil
) else { fatalError("Cannot read folder: \(folder.path)") }

let scale: CGFloat = 2 // ~144 dpi, plenty for Vision OCR

for file in files where file.pathExtension.lowercased() == "pdf" {
    guard let pdf = CGPDFDocument(file as CFURL) else {
        print("SKIP (unreadable): \(file.lastPathComponent)")
        continue
    }
    let pageCount = pdf.numberOfPages
    for pageN in 1...pageCount {
        guard let page = pdf.page(at: pageN) else { continue }
        let box = page.getBoxRect(.mediaBox)
        let image = NSImage(size: NSSize(width: box.width * scale, height: box.height * scale))
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            print("SKIP (no context) page \(pageN)")
            continue
        }
        ctx.scaleBy(x: scale, y: scale)
        ctx.drawPDFPage(page)
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            print("SKIP (encode) page \(pageN)")
            continue
        }
        let out = pageCount == 1
            ? file.deletingPathExtension().appendingPathExtension("png")
            : URL(fileURLWithPath: file.deletingPathExtension().path + "_p\(pageN).png")
        try? png.write(to: out)
        print("\(file.lastPathComponent) p\(pageN) -> \(out.lastPathComponent)")
    }
}
