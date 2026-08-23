import ArgumentParser
import Foundation

/// Concatenates every OCR'd page's Markdown into one document, in name order.
struct CombineCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "combine",
        abstract: "Merge all Markdown files into one combined.md, sorted by name."
    )

    @Argument(help: "Markdown file or folder containing Markdown. Defaults to the current directory.", completion: .file())
    var folder = "."

    /// Writes all Markdown files concatenated (blank line between files) to `output`.
    /// Returns how many files contributed.
    @discardableResult
    static func concatenate(_ files: [URL], into output: URL) throws -> Int {
        var sections: [String] = []
        for file in files {
            do {
                sections.append(try String(contentsOf: file, encoding: .utf8)
                    .trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                note("SKIP (unreadable): \(file.lastPathComponent)")
            }
        }
        guard !sections.isEmpty else { return 0 }
        try sections.joined(separator: "\n\n").appending("\n").write(to: output, atomically: true, encoding: .utf8)
        return sections.count
    }

    mutating func run() throws {
        let folderURL = URL(fileURLWithPath: folder)
        let files = (try folderURL.inputs(matching: ["md"])).filter { $0.lastPathComponent != "combined.md" }
        guard !files.isEmpty else { print("No Markdown found in \(folderURL.path)"); return }

        let output = folderURL.appending(path: "combined.md")
        let combined = try CombineCommand.concatenate(files, into: output)
        guard combined > 0 else {
            note("No readable Markdown in \(folderURL.path)")
            throw ExitCode.failure
        }
        print("Combined \(combined) file(s) -> \(output.path)")
    }
}
