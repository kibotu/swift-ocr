import CoreGraphics
import Foundation
import ImageIO
import Testing

@testable import SwiftOCR

@Suite
final class PdfToPngTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "swift-ocr-tests-\(UUID().uuidString)")

    init() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func rendersSinglePageUnderBaseName() throws {
        let pdf = try makePDF(pages: 1)
        let outputs = try PdfToPng.render(pdfAt: pdf, scale: 2)

        #expect(outputs.map(\.lastPathComponent) == ["sample.png"])
        #expect(pixelSize(of: outputs[0]) == CGSize(width: 200, height: 100))
    }

    @Test
    func rendersEveryPageWithPageSuffix() throws {
        let outputs = try PdfToPng.render(pdfAt: makePDF(pages: 3), scale: 2)

        #expect(outputs.map(\.lastPathComponent) == ["sample_p1.png", "sample_p2.png", "sample_p3.png"])
        #expect(outputs.allSatisfy { pixelSize(of: $0) == CGSize(width: 200, height: 100) })
    }

    @Test
    func throwsOnGarbageInput() throws {
        let url = directory.appending(path: "garbage.pdf")
        try Data("not a pdf".utf8).write(to: url)

        #expect(throws: PipelineError.self) {
            try PdfToPng.render(pdfAt: url, scale: 2)
        }
    }

    // MARK: - Fixtures

    private func makePDF(pages: Int) throws -> URL {
        let url = directory.appending(path: "sample.pdf")
        let box = CGRect(x: 0, y: 0, width: 100, height: 50)
        guard let consumer = CGDataConsumer(url: url as CFURL) else {
            throw PipelineError.unreadablePDF(url)
        }
        var mediaBox = box
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PipelineError.unreadablePDF(url)
        }
        let red = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        for _ in 0..<pages {
            context.beginPDFPage(nil as CFDictionary?)
            context.setFillColor(red)
            context.fill(box)
            context.endPDFPage()
        }
        context.closePDF()
        return url
    }

    private func pixelSize(of url: URL) -> CGSize {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else { return .zero }
        return CGSize(width: width, height: height)
    }
}
