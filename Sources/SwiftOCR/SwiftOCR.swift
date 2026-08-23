import ArgumentParser
import Foundation

@main
struct SwiftOCR: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "On-device PDF → PNG → Markdown OCR pipeline built on Apple Vision.",
        version: "1.4.0",
        subcommands: [ConvertCommand.self, PdfToPngCommand.self, OcrCommand.self, PdfToPdfCommand.self, CombineCommand.self],
        defaultSubcommand: ConvertCommand.self
    )
}

/// Prints a warning to stderr so stdout stays parseable.
func note(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

extension URL {
    /// True for this tool's own searchable-PDF output (`<name>.ocr.pdf`),
    /// so re-runs skip it instead of nesting another `.ocr` layer.
    var isOcrOutput: Bool { deletingPathExtension().pathExtension == "ocr" }

    /// Directory entries, or the file itself — filtered by extension and sorted
    /// Finder-style (numeric-aware). Lets every subcommand take a folder or a single file.
    func inputs(matching extensions: Set<String>) throws -> [URL] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw PipelineError.cannotRead(self)
        }
        if !isDirectory.boolValue {
            guard extensions.contains(pathExtension.lowercased()) else {
                throw PipelineError.unsupportedInput(self)
            }
            return [self]
        }
        do {
            return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
                .filter { extensions.contains($0.pathExtension.lowercased()) }
                .sorted(by: { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending })
        } catch {
            throw PipelineError.cannotRead(self)
        }
    }
}
