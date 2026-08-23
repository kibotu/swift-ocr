import CoreGraphics
import Foundation
import Vision

/// Apple's document recognizer (macOS 26+) — headings, paragraphs, lists and tables
/// as first-class structure instead of reconstructed geometry.
/// Availability is gated by `Recognizer`; this type assumes macOS 26.
@available(macOS 26.0, *)
enum DocumentsRecognizer {
    /// Returns positioned document blocks, or an empty array when nothing was recognized.
    static func blocks(in image: CGImage, languages: [String] = []) throws -> [PositionedBlock] {
        var request = RecognizeDocumentsRequest()
        request.textRecognitionOptions.automaticallyDetectLanguage = true
        if !languages.isEmpty {
            request.textRecognitionOptions.recognitionLanguages = languages.map { Locale.Language(identifier: $0) }
        }

        // The new Vision API is async-only; our pipeline is sequential and synchronous.
        let call = BlockingCall<[DocumentObservation]>()
        Task {
            do { call.fulfill(.success(try await request.perform(on: image))) }
            catch { call.fulfill(.failure(error)) }
        }
        guard let document = try call.wait().first?.document else { return [] }
        return collect(document)
    }

    /// Bridges one async call into synchronous code. Fulfill-before-signal ordering
    /// guarantees the storage invariant inside `wait()`.
    private final class BlockingCall<T: Sendable>: @unchecked Sendable {
        private let semaphore = DispatchSemaphore(value: 0)
        private var storage: Result<T, any Error>?

        func fulfill(_ result: Result<T, any Error>) {
            storage = result
            semaphore.signal()
        }

        func wait() throws -> T {
            semaphore.wait()
            return try storage!.get()
        }
    }

    private static func collect(_ document: DocumentObservation.Container) -> [PositionedBlock] {
        var blocks: [PositionedBlock] = []
        // The recognizer often reports the page's top line as both title and paragraph;
        // keeping both would print it twice.
        let title = document.title.flatMap { $0.transcript.isEmpty ? nil : $0 }
        for paragraph in document.paragraphs where !paragraph.transcript.isEmpty {
            guard title == nil || paragraph.transcript != title?.transcript else { continue }
            blocks.append(PositionedBlock(block: .paragraph(paragraph.transcript), region: rect(paragraph.boundingRegion)))
        }
        if let title {
            blocks.append(PositionedBlock(block: .heading(title.transcript), region: rect(title.boundingRegion)))
        }
        for list in document.lists where !list.items.isEmpty {
            blocks.append(PositionedBlock(block: .list(list.items.map(\.itemString)), region: rect(list.boundingRegion)))
        }
        for table in document.tables where !table.rows.isEmpty {
            blocks.append(PositionedBlock(
                block: .table(table.rows.map { $0.map { transcript($0.content) } }),
                region: rect(table.boundingRegion)
            ))
        }
        return blocks
    }

    /// Flattens nested container content (e.g. inside table cells) to plain text.
    private static func transcript(_ container: DocumentObservation.Container) -> String {
        if !container.text.transcript.isEmpty { return container.text.transcript }
        return container.paragraphs.map(\.transcript).joined(separator: " ")
    }

    /// Bounding rectangles arrive as contours; their points are enough for reading order.
    /// Contour points share Vision's bottom-left origin — converted once here.
    private static func rect(_ region: NormalizedRegion) -> PageRect {
        let points = region.normalizedPoints
        guard !points.isEmpty else { return PageRect(minX: 0, minY: 0, maxX: 0, maxY: 0) }
        let xs = points.map(\.x), ys = points.map(\.y)
        let minX = CGFloat(xs.min()!), minY = CGFloat(ys.min()!)
        return PageRect(visionBox: CGRect(
            x: minX,
            y: minY,
            width: CGFloat(xs.max()!) - minX,
            height: CGFloat(ys.max()!) - minY
        ))
    }
}
