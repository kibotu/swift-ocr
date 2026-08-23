import CoreGraphics
import Foundation
import Vision

/// Apple's document recognizer (macOS 26+) — headings, paragraphs, lists and tables as
/// first-class structure instead of reconstructed geometry.
enum DocumentsRecognizer {
    /// One recognized block of document structure, positioned for reading order.
    private enum Block {
        case heading(String)
        case paragraph(String)
        case list([String])
        case table([[String]])
    }

    /// Returns structured Markdown, or nil when nothing was recognized.
    /// Falls back to `Layout`-based recognition on older systems (see OcrCommand).
    @available(macOS 26.0, *)
    static func markdown(in image: CGImage, languages: [String]? = nil) throws -> String? {
        var request = RecognizeDocumentsRequest()
        request.textRecognitionOptions.automaticallyDetectLanguage = true
        if let languages {
            request.textRecognitionOptions.recognitionLanguages = languages.map { Locale.Language(identifier: $0) }
        }

        // The new Vision API is async-only; our pipeline is sequential and synchronous.
        let box = ResultBox<[DocumentObservation]>()
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do { box.result = .success(try await request.perform(on: image)) }
            catch { box.result = .failure(error) }
            semaphore.signal()
        }
        semaphore.wait()
        guard let document = try box.result!.get().first?.document else { return nil }
        return render(document)
    }

    private final class ResultBox<T: Sendable>: @unchecked Sendable {
        var result: Result<T, any Error>?
    }

    // MARK: - Rendering

    @available(macOS 26.0, *)
    private static func render(_ document: DocumentObservation.Container) -> String {
        var blocks: [(Block, CGRect)] = []
        if let title = document.title, !title.transcript.isEmpty {
            blocks.append((.heading(title.transcript), rect(title.boundingRegion)))
        }
        for paragraph in document.paragraphs where !paragraph.transcript.isEmpty {
            blocks.append((.paragraph(paragraph.transcript), rect(paragraph.boundingRegion)))
        }
        for list in document.lists where !list.items.isEmpty {
            blocks.append((.list(list.items.map(\.itemString)), rect(list.boundingRegion)))
        }
        for table in document.tables where !table.rows.isEmpty {
            blocks.append((.table(table.rows.map { $0.map { transcript($0.content) } }), rect(table.boundingRegion)))
        }

        // Vision reports lower-left origins; higher y means higher up the page.
        let sorted = blocks.sorted {
            $0.1.midY != $1.1.midY ? $0.1.midY > $1.1.midY : $0.1.minX < $1.1.minX
        }
        let rendered = sorted.map { markdown($0.0) }
        guard !rendered.isEmpty else { return "" }
        return rendered.joined(separator: "\n\n") + "\n"
    }

    @available(macOS 26.0, *)
    private static func markdown(_ block: Block) -> String {
        switch block {
        case .heading(let text):
            return "# \(text)"
        case .paragraph(let text):
            return text
        case .list(let items):
            return items.map { "- \($0)" }.joined(separator: "\n")
        case .table(let rows):
            let escaped = rows.map { row in
                "| " + row.map { $0.replacingOccurrences(of: "|", with: "\\|") }.joined(separator: " | ") + " |"
            }
            let separator = "| " + Array(repeating: "---", count: rows[0].count).joined(separator: " | ") + " |"
            return ([escaped[0], separator] + escaped.dropFirst()).joined(separator: "\n")
        }
    }

    @available(macOS 26.0, *)
    private static func transcript(_ container: DocumentObservation.Container) -> String {
        if !container.text.transcript.isEmpty { return container.text.transcript }
        return container.paragraphs.map(\.transcript).joined(separator: " ")
    }

    /// Bounding rectangles arrive as contours; their points are enough for reading order.
    @available(macOS 26.0, *)
    private static func rect(_ region: NormalizedRegion) -> CGRect {
        let points = region.normalizedPoints
        guard !points.isEmpty else { return .zero }
        let xs = points.map(\.x), ys = points.map(\.y)
        let minX = CGFloat(xs.min()!), minY = CGFloat(ys.min()!)
        return CGRect(x: minX, y: minY, width: CGFloat(xs.max()!) - minX, height: CGFloat(ys.max()!) - minY)
    }
}
