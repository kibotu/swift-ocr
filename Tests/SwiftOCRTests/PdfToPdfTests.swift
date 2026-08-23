import CoreGraphics
import CoreText
import Foundation
import PDFKit
import Testing
import UniformTypeIdentifiers

@testable import SwiftOCR

@Suite
struct DocumentsRecognizerTests {
    @Test
    func recognizesDocumentStructure() throws {
        guard #available(macOS 26.0, *) else { return } // older runners fall back to Layout
        let image = try TestImages.rasterizedText(text: "Quarterly Report\nTotal due is 42 EUR")
        let markdown = try #require(try DocumentsRecognizer.markdown(in: image))
        #expect(markdown.contains("42 EUR"))
    }
}

enum TestImages {
    /// Renders `text` as pixels — no vector text, exactly what a scan looks like.
    static func rasterizedText(text: String) throws -> CGImage {
        let width = 800, height = 240
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw PipelineError.unreadableImage(URL(fileURLWithPath: "/dev/null")) }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        let font = CTFontCreateWithName("Helvetica" as CFString, 36, nil)
        context.textPosition = CGPoint(x: 30, y: 100)
        CTLineDraw(CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font])), context)
        return try #require(context.makeImage())
    }
}

@Suite
final class PdfToPdfTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "swift-ocr-pdf2pdf-\(UUID().uuidString)")

    init() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func makesSearchablePdfFromScannedPage() throws {
        // A scan: text rendered into a bitmap, wrapped in a PDF — exactly what pdf2png + scan input produces.
        let pdf = try rasterizedTextPDF(text: "Searchable haystack needle42")
        let output = try PdfToPdf.render(pdfAt: pdf, scale: 3)

        #expect(output.lastPathComponent == "sample.ocr.pdf")
        let extracted = try #require(PDFDocument(url: output)?.string)
        #expect(extracted.contains("haystack"))
    }

    @Test
    func throwsOnGarbageInput() throws {
        let url = directory.appending(path: "garbage.pdf")
        try Data("not a pdf".utf8).write(to: url)

        #expect(throws: PipelineError.self) {
            try PdfToPdf.render(pdfAt: url, scale: 2)
        }
    }

    // MARK: - Fixtures

    /// Wraps a rasterized-text bitmap in a one-page PDF — the shape of a scanned page.
    private func rasterizedTextPDF(text: String) throws -> URL {
        let image = try TestImages.rasterizedText(text: text)
        let url = directory.appending(path: "sample.pdf")
        var mediaBox = CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height))
        let consumer = try #require(CGDataConsumer(url: url as CFURL))
        let pdfContext = try #require(CGContext(consumer: consumer, mediaBox: &mediaBox, nil))
        pdfContext.beginPDFPage(nil as CFDictionary?)
        pdfContext.draw(image, in: mediaBox)
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        return url
    }
}

