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
        guard #available(macOS 26.0, *) else { return } // older runners exercise only the fallback path
        let image = try TestImages.rasterizedText(text: "Quarterly Report\nTotal due is 42 EUR")
        let result = try Recognizer.read(image, structured: true)

        #expect(!result.fellBack)
        #expect(DocumentRenderer.markdown(from: result.blocks).contains("42 EUR"))
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

    /// Wraps a rasterized-text bitmap in a one-page PDF — the shape of a scanned page.
    static func rasterizedTextPDF(text: String, in directory: URL) throws -> URL {
        let image = try rasterizedText(text: text)
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
    func keepsPerPageSizesForMixedDocuments() throws {
        // Page 1 portrait, page 2 landscape: the searchable PDF must keep both boxes.
        let url = directory.appending(path: "mixed.pdf")
        let consumer = try #require(CGDataConsumer(url: url as CFURL))
        var firstBox = CGRect(x: 0, y: 0, width: 100, height: 140)
        let context = try #require(CGContext(consumer: consumer, mediaBox: &firstBox, nil))
        for box in [firstBox, CGRect(x: 0, y: 0, width: 220, height: 80)] {
            // Per-page boxes here too — otherwise this source PDF has uniform pages
            // and the test proves nothing.
            let info = [kCGPDFContextMediaBox: withUnsafeBytes(of: box) { Data($0) } as CFData] as CFDictionary
            context.beginPDFPage(info)
            context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            context.fill(box)
            context.endPDFPage()
        }
        context.closePDF()

        let output = try PdfToPdf.render(pdfAt: url, scale: 2)
        let document = try #require(PDFDocument(url: output))
        #expect(document.pageCount == 2)
        #expect(document.page(at: 0)!.bounds(for: .mediaBox).size == CGSize(width: 100, height: 140))
        #expect(document.page(at: 1)!.bounds(for: .mediaBox).size == CGSize(width: 220, height: 80))
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

    private func rasterizedTextPDF(text: String) throws -> URL {
        try TestImages.rasterizedTextPDF(text: text, in: directory)
    }
}

