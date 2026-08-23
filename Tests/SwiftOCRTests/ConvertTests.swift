import Foundation
import Testing

@testable import SwiftOCR

@Suite
final class InputResolutionTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "swift-ocr-inputs-\(UUID().uuidString)")

    init() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func expandsFoldersToMatchingFilesSorted() throws {
        try Data("x".utf8).write(to: directory.appending(path: "b.jpg"))
        try Data("x".utf8).write(to: directory.appending(path: "a.png"))
        try Data("x".utf8).write(to: directory.appending(path: "ignored.txt"))

        let urls = try directory.inputs(matching: ["png", "jpg"])
        #expect(urls.map(\.lastPathComponent) == ["a.png", "b.jpg"])
    }

    @Test
    func passesSingleMatchingFileThrough() throws {
        let file = directory.appending(path: "single.pdf")
        try Data("x".utf8).write(to: file)

        #expect(try file.inputs(matching: ["pdf"]) == [file])
    }

    @Test
    func rejectsSingleFileWithForeignExtension() throws {
        let file = directory.appending(path: "notes.doc")
        try Data("x".utf8).write(to: file)

        #expect(throws: PipelineError.self) { try file.inputs(matching: ["pdf"]) }
    }

    @Test
    func throwsOnMissingPath() {
        #expect(throws: PipelineError.self) {
            try directory.appending(path: "nope").inputs(matching: ["pdf"])
        }
    }

    @Test
    func recognizesItsOwnSearchableOutput() {
        #expect(directory.appending(path: "letter.ocr.pdf").isOcrOutput)
        #expect(!directory.appending(path: "letter.pdf").isOcrOutput)
    }
}

@Suite
final class ConvertTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "swift-ocr-convert-\(UUID().uuidString)")

    init() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func runsWholePipelineOverAFolderOfScans() throws {
        _ = try TestImages.rasterizedTextPDF(text: "End to end pipeline99", in: directory)
        try convert()

        let markdown = try String(contentsOf: directory.appending(path: "sample.md"), encoding: .utf8)
        #expect(markdown.contains("pipeline99"))
    }

    @Test
    func acceptsSingleFileInput() throws {
        let pdf = try TestImages.rasterizedTextPDF(text: "Single file needle42", in: directory)
        try convert(input: pdf.path)

        #expect(FileManager.default.fileExists(atPath: pdf.deletingPathExtension().appendingPathExtension("md").path))
    }

    private func convert(input: String? = nil) throws {
        // Property-wrapper reads trap unless values came through parsing,
        // so drive the command the same way the CLI does.
        var command = try ConvertCommand.parse([input ?? directory.path, "--scale", "3"])
        try command.run()
    }
}
