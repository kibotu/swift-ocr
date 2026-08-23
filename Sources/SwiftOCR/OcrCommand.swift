import ArgumentParser
import Foundation
import CoreImage

/// One image in, `<stem>.md` beside it — the recognition step every OCR-ing command shares.
enum ImageOcr {
    /// Loads, optionally enhances, recognizes and writes the Markdown for one image —
    /// into `directory` (default: beside the image).
    static func writeMarkdown(
        for image: URL,
        languages: [String],
        enhance: Bool = false,
        using ciContext: CIContext? = nil,
        structured: Bool = false,
        frontMatter: Bool = false,
        writingInto directory: URL? = nil
    ) throws -> (output: URL, characters: Int, fellBack: Bool) {
        var cgImage = try TextRecognizer.loadCGImage(at: image)
        if enhance, let ciContext {
            if let processed = TextRecognizer.enhanced(cgImage, using: ciContext) {
                cgImage = processed
            } else {
                note("WARN (enhance failed): \(image.lastPathComponent) — continuing unprocessed")
            }
        }

        let result = try Recognizer.read(cgImage, languages: languages, structured: structured)
        let body = DocumentRenderer.markdown(from: result.blocks)
        let directory = directory ?? image.deletingLastPathComponent()
        let output = directory.appending(path: image.lastPathComponent)
            .deletingPathExtension().appendingPathExtension("md")
        let content = frontMatter ? FrontMatter.markdown(for: body) + body : body
        try content.write(to: output, atomically: true, encoding: .utf8)
        return (output, body.count, result.fellBack)
    }
    /// Recognizes every image, writing `<stem>.md` beside each, reporting progress on
    /// stdout and skips on stderr. Returns how many images were recognized.
    @discardableResult
    static func recognize(
        _ images: [URL],
        languages: [String],
        enhance: Bool,
        structured: Bool,
        frontMatter: Bool,
        writingInto directory: URL? = nil
    ) -> Int {
        let ciContext = enhance ? CIContext() : nil
        var osWarned = false
        var recognized = 0
        for image in images {
            do {
                let result = try writeMarkdown(
                    for: image,
                    languages: languages,
                    enhance: enhance,
                    using: ciContext,
                    structured: structured,
                    frontMatter: frontMatter,
                    writingInto: directory
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
        return recognized
    }
}

struct OcrCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ocr",
        abstract: "Recognize text in an image or each image of a folder, writing <name>.md next to it."
    )

    @Argument(help: "Image or folder containing images. Defaults to the current directory.", completion: .file())
    var folder = "."

    @Option(parsing: .singleValue, help: "Recognition language hint, repeatable: --lang de --lang fr. Omit for Vision's auto-detection.")
    var lang: [String] = []

    @Flag(help: "Prepend YAML front-matter with detected dates, phone numbers, links and addresses.")
    var meta = false

    @Flag(help: "Boost contrast and drop color before recognition — for faint scans.")
    var enhance = false

    @Flag(help: "Use Apple's document recognizer: native headings, lists and tables (macOS 26+).")
    var documents = false

    mutating func run() throws {
        let folderURL = URL(fileURLWithPath: folder)
        let images = try folderURL.inputs(matching: ["png", "jpg", "jpeg", "tiff"])
        guard !images.isEmpty else { print("No images found in \(folderURL.path)"); return }

        let hint = TextRecognizer.resolveLanguages(lang)
        for code in hint.rejected { note("WARN (unsupported language): \(code) — ignoring") }

        let recognized = ImageOcr.recognize(images, languages: hint.resolved, enhance: enhance, structured: documents, frontMatter: meta)
        print("\(recognized)/\(images.count) image(s) recognized")
        if recognized == 0 { throw ExitCode.failure }
    }
}
