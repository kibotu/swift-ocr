import ArgumentParser
import Foundation

@main
struct SwiftOCR: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "On-device PDF → PNG → Markdown OCR pipeline built on Apple Vision.",
        version: "1.2.0",
        subcommands: [PdfToPngCommand.self, OcrCommand.self, PdfToPdfCommand.self, CombineCommand.self]
    )
}

/// Prints a warning to stderr so stdout stays parseable.
func note(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

extension URL {
    /// Directory entries with a matching extension, sorted Finder-style (numeric-aware).
    func contents(matching extensions: Set<String>) throws -> [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
                .filter { extensions.contains($0.pathExtension.lowercased()) }
                .sorted(by: { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending })
        } catch {
            throw PipelineError.cannotReadFolder(self)
        }
    }
}
