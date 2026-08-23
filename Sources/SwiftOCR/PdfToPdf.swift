import CoreGraphics
import CoreText
import Foundation

/// Writes PDFs with an invisible OCR text layer — searchable and selectable, while the visible
/// surface stays the rendered scan.
enum PdfToPdf {
    /// Renders each page, recognizes its text and draws it invisibly over the page image.
    static func render(pdfAt url: URL, scale: Double, languages: [String] = []) throws -> URL {
        guard let document = CGPDFDocument(url as CFURL) else {
            throw PipelineError.unreadablePDF(url)
        }
        let pageCount = document.numberOfPages
        guard pageCount > 0 else { throw PipelineError.unreadablePDF(url) }

        let output = url.deletingPathExtension().appendingPathExtension("ocr.pdf")
        guard let consumer = CGDataConsumer(url: output as CFURL),
              var mediaBox = document.page(at: 1)?.getBoxRect(.mediaBox),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PipelineError.cannotEncodePDF(output)
        }

        for pageNumber in 1...pageCount {
            guard let page = document.page(at: pageNumber),
                  let bitmap = PdfToPng.bitmap(for: page, scale: scale) else {
                note("SKIP (page \(pageNumber)): \(url.lastPathComponent) — could not be rendered")
                continue
            }
            let box = page.getBoxRect(.mediaBox)
            // Mixed-size documents need per-page boxes; CGPDFContext.h requires
            // them as CFData wrapping the CGRect by value.
            context.beginPDFPage([kCGPDFContextMediaBox: withUnsafeBytes(of: box) { Data($0) } as CFData] as CFDictionary)
            context.draw(bitmap, in: box)

            context.setTextDrawingMode(.invisible)
            for line in try TextRecognizer.recognizeLines(in: bitmap, languages: languages) {
                draw(line, onPage: box, on: context)
            }
            context.endPDFPage()
        }
        context.closePDF()
        return output
    }

    /// The one conversion between page conventions (top-left origin, normalized)
    /// and CoreGraphics PDF space (bottom-left origin, points).
    private static func frame(_ region: PageRect, in page: CGRect) -> CGRect {
        CGRect(
            x: page.minX + region.minX * page.width,
            y: page.minY + (1 - region.maxY) * page.height,
            width: region.width * page.width,
            height: region.height * page.height
        )
    }

    private static func draw(_ line: RecognizedLine, onPage page: CGRect, on context: CGContext) {
        let rect = frame(line.region, in: page)
        guard rect.width > 0, rect.height > 0 else { return }
        let font = CTFontCreateWithName("Helvetica" as CFString, rect.height * 0.85, nil)
        guard let attributed = CFAttributedStringCreate(nil, line.text as CFString, [kCTFontAttributeName: font] as CFDictionary) else { return }
        context.textPosition = CGPoint(x: rect.minX, y: rect.minY)
        CTLineDraw(CTLineCreateWithAttributedString(attributed), context)
    }
}
