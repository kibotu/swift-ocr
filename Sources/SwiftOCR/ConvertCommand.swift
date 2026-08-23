import ArgumentParser
import CoreImage
import Foundation

/// The do-it-all default: PDFs become PNGs, every image becomes Markdown.
/// Point it at a folder or a single file and it runs the whole pipeline.
struct ConvertCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Render PDFs to PNGs and recognize text into Markdown — the whole pipeline in one pass."
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
        let files = try inputURL.inputs(matching: ["pdf", "png", "jpg", "jpeg", "tiff"])
        let pdfs = files.filter { $0.pathExtension.lowercased() == "pdf" && !$0.isOcrOutput }

        // Rendered pages join any loose images in the recognition queue.
        var queue = files.filter { $0.pathExtension.lowercased() != "pdf" }
        guard !queue.isEmpty || !pdfs.isEmpty else {
            print("No PDFs or images found at \(inputURL.path)")
            return
        }
        for pdf in pdfs {
            do { queue += try PdfToPng.render(pdfAt: pdf, scale: scale) }
            catch { note("SKIP (render failed): \(pdf.lastPathComponent) — \(error.localizedDescription)") }
        }

        queue.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        let hint = TextRecognizer.resolveLanguages(lang)
        for code in hint.rejected { note("WARN (unsupported language): \(code) — ignoring") }
        let ciContext = enhance ? CIContext() : nil
        var osWarned = false

        var recognized = 0
        for image in queue {
            do {
                let result = try ImageOcr.writeMarkdown(
                    for: image,
                    languages: hint.resolved,
                    enhance: enhance,
                    using: ciContext,
                    structured: documents,
                    frontMatter: meta
                )
                if result.fellBack && !osWarned {
                    note("WARN (--documents): needs macOS 26 — falling back to geometric layout")
                    osWarned = true
                }
                print("\(image.lastPathComponent) -> \(result.output.lastPathComponent) (\(result.characters) chars)")
                recognized += 1
            } catch {
                note("SKIP (ocr failed): \(image.lastPathComponent) — \(error.localizedDescription)")
            }
        }
        print("\(recognized)/\(queue.count) file(s) converted")
        if recognized == 0 { throw ExitCode.failure }
    }
}
