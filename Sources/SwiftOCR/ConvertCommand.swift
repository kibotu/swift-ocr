import ArgumentParser
import Foundation

/// The do-it-all default: PDFs become PNGs, every image becomes Markdown,
/// all Markdown merges into one combined.md.
/// Point it at a folder or a single file and it runs the whole pipeline.
struct ConvertCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Render PDFs to PNGs, recognize text into Markdown and merge it into one combined.md."
    )

    @Argument(help: "Folder, PDF or image. Defaults to the current directory.", completion: .file())
    var input = "."

    @Option(help: "Rendering scale; 2 ≈ 144 dpi, plenty for OCR.")
    var scale = 2.0

    @Option(parsing: .singleValue, help: "Recognition language hint, repeatable: --lang de --lang fr. Omit for Vision's auto-detection.")
    var lang: [String] = []

    @Flag(help: "Prepend YAML front-matter with detected dates, phone numbers, links and addresses.")
    var meta = false

    @Flag(help: "Boost contrast and drop color before recognition — for faint scans.")
    var enhance = false

    @Flag(help: "Use Apple's document recognizer: native headings, lists and tables (macOS 26+).")
    var documents = false

    mutating func run() throws {
        let inputURL = URL(fileURLWithPath: input)
        let inputs = try inputURL.inputs(matching: ["pdf", "png", "jpg", "jpeg", "tiff"])
            .filter { !$0.isOcrOutput }
        guard !inputs.isEmpty else {
            print("No PDFs or images found at \(inputURL.path)")
            return
        }

        let hint = TextRecognizer.resolveLanguages(lang)
        for code in hint.rejected { note("WARN (unsupported language): \(code) — ignoring") }

        var converted = 0
        for file in inputs {
            do {
                // Each processed file gets its own directory: pages' PNGs in png/,
                // pages' Markdown in md/, all pages merged into <stem>.md.
                let stem = file.deletingPathExtension().lastPathComponent
                let outputDirectory = file.deletingLastPathComponent().appending(path: stem)
                let pngDirectory = outputDirectory.appending(path: "png")
                let mdDirectory = outputDirectory.appending(path: "md")

                var pages: [URL] = []
                if file.pathExtension.lowercased() == "pdf" {
                    try FileManager.default.createDirectory(at: pngDirectory, withIntermediateDirectories: true)
                    pages = try PdfToPng.render(pdfAt: file, scale: scale, into: pngDirectory)
                } else {
                    pages = [file]
                }
                try FileManager.default.createDirectory(at: mdDirectory, withIntermediateDirectories: true)

                let recognized = ImageOcr.recognize(
                    pages,
                    languages: hint.resolved,
                    enhance: enhance,
                    structured: documents,
                    frontMatter: meta,
                    writingInto: mdDirectory
                )
                guard recognized > 0 else {
                    note("SKIP (nothing recognized): \(file.lastPathComponent)")
                    continue
                }

                let pageMarkdowns = try mdDirectory.inputs(matching: ["md"])
                let combined = try CombineCommand.concatenate(
                    pageMarkdowns,
                    into: outputDirectory.appending(path: "\(stem).md")
                )
                print("\(file.lastPathComponent) -> \(stem)/\(stem).md (\(combined) page(s))")
                converted += 1
            } catch {
                note("SKIP (failed): \(file.lastPathComponent) — \(error.localizedDescription)")
            }
        }
        print("\(converted)/\(inputs.count) file(s) converted")
        if converted == 0 { throw ExitCode.failure }
    }
}
