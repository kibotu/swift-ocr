import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Renders PDF pages to PNG bitmaps with CoreGraphics only — no AppKit, no deprecated lockFocus.
enum PdfToPng {
    /// Renders every page of the PDF and writes PNGs next to it. Returns the written URLs.
    static func render(pdfAt url: URL, scale: Double) throws -> [URL] {
        guard let document = CGPDFDocument(url as CFURL) else {
            throw PipelineError.unreadablePDF(url)
        }
        let pageCount = document.numberOfPages
        guard pageCount > 0 else { return [] }

        var outputs: [URL] = []
        for pageNumber in 1...pageCount {
            guard let page = document.page(at: pageNumber),
                  let image = bitmap(for: page, scale: scale) else { continue }
            let output = outputURL(for: url, page: pageNumber, pageCount: pageCount)
            try encodePNG(image, to: output)
            outputs.append(output)
        }
        return outputs
    }

    /// Single-page PDFs keep their base name; multi-page ones get a `_p<N>` suffix.
    static func outputURL(for pdf: URL, page: Int, pageCount: Int) -> URL {
        pageCount == 1
            ? pdf.deletingPathExtension().appendingPathExtension("png")
            : URL(fileURLWithPath: pdf.deletingPathExtension().path + "_p\(page).png")
    }

    private static func bitmap(for page: CGPDFPage, scale: Double) -> CGImage? {
        let box = page.getBoxRect(.mediaBox)
        let width = max(Int((box.width * scale).rounded()), 1)
        let height = max(Int((box.height * scale).rounded()), 1)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // White backdrop: PDFs may paint nothing, and OCR wants dark-on-light.
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        context.scaleBy(x: scale, y: scale)
        context.drawPDFPage(page)
        return context.makeImage()
    }

    private static func encodePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw PipelineError.cannotEncodePNG(url)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw PipelineError.cannotEncodePNG(url)
        }
    }
}
