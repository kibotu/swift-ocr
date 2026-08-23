import Foundation
import Testing

@testable import SwiftOCR

@Suite
final class CombineTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "swift-ocr-combine-\(UUID().uuidString)")

    init() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func mergesAllMarkdownSortedIntoOneFile() throws {
        try "second page".write(to: directory.appending(path: "b.md"), atomically: true, encoding: .utf8)
        try "first page".write(to: directory.appending(path: "a.md"), atomically: true, encoding: .utf8)

        var command = try CombineCommand.parse([directory.path])
        try command.run()

        let combined = try String(contentsOf: directory.appending(path: "combined.md"), encoding: .utf8)
        #expect(combined == "first page\n\nsecond page\n")
    }

    @Test
    func excludesItsOwnOutputFromReruns() throws {
        try "only page".write(to: directory.appending(path: "page.md"), atomically: true, encoding: .utf8)

        var command = try CombineCommand.parse([directory.path])
        try command.run()
        try command.run()

        let combined = try String(contentsOf: directory.appending(path: "combined.md"), encoding: .utf8)
        #expect(combined == "only page\n")
    }
}
