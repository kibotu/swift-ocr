import CoreGraphics
import CoreText
import Foundation

/// Writes PDFs with an invisible OCR text layer — searchable and selectable, while the visible
/// surface stays the rendered scan.
enum PdfToPdf {
    /// Renders each page, recognizes its text and draws it invisibly over the page image.
    static func render(pdfAt url: URL, scale: Double, languages: [String]? = nil) throws -> URL {
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
                  let bitmap = PdfToPng.bitmap(for: page, scale: scale) else { continue }
            let box = page.getBoxRect(.mediaBox)
            context.beginPDFPage(nil as CFDictionary?)
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

    /// Normalized Vision coordinates map straight onto the page rectangle.
    /// ponytail: one text run per line — selection highlights whole lines; carry VNRecognizedText
    /// and use its bounds(for:) per word if per-word highlighting matters someday.
    private static func draw(_ line: RecognizedLine, onPage box: CGRect, on context: CGContext) {
        let rect = CGRect(
            x: box.minX + line.box.minX * box.width,
            y: box.minY + line.box.minY * box.height,
            width: line.box.width * box.width,
            height: line.box.height * box.height
        )
        guard rect.width > 0, rect.height > 0 else { return }
        let font = CTFontCreateWithName("Helvetica" as CFString, rect.height * 0.85, nil)
        guard let attributed = CFAttributedStringCreate(nil, line.text as CFString, [kCTFontAttributeName: font] as CFDictionary) else { return }
        context.textPosition = CGPoint(x: rect.minX, y: rect.minY)
        CTLineDraw(CTLineCreateWithAttributedString(attributed), context)
    }
}
