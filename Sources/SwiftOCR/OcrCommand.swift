import ArgumentParser
import CoreImage
import Foundation

struct OcrCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ocr",
        abstract: "Recognize text in each image of a folder, writing <name>.md next to it."
    )

    @Argument(help: "Folder containing images. Defaults to the current directory.", completion: .directory)
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
        let images = try folderURL.contents(matching: ["png", "jpg", "jpeg", "tiff"])
        guard !images.isEmpty else { print("No images found in \(folderURL.path)"); return }

        let languages = lang.isEmpty ? nil : TextRecognizer.resolveLanguages(lang)
        let ciContext = enhance ? CIContext() : nil
        var osWarned = false

        var recognized = 0
        for image in images {
            do {
                var cgImage = try TextRecognizer.loadCGImage(at: image)
                if let ciContext { cgImage = TextRecognizer.enhanced(cgImage, using: ciContext) }

                let body: String
                if documents, #available(macOS 26.0, *) {
                    body = try DocumentsRecognizer.markdown(in: cgImage) ?? ""
                } else {
                    if documents && !osWarned {
                        note("WARN (--documents): needs macOS 26 — falling back to standard recognition")
                        osWarned = true
                    }
                    body = Layout.markdown(from: try TextRecognizer.recognizeLines(in: cgImage, languages: languages))
                }
                let output = image.deletingPathExtension().appendingPathExtension("md")
                let content = meta ? (FrontMatter.markdown(for: body) ?? "") + body : body
                try content.write(to: output, atomically: true, encoding: .utf8)
                print("\(image.lastPathComponent) -> \(output.lastPathComponent) (\(body.count) chars)")
                recognized += 1
            } catch {
                note("SKIP (ocr failed): \(image.lastPathComponent) — \(error.localizedDescription)")
            }
        }
        print("\(recognized)/\(images.count) image(s) recognized")
        if recognized == 0 { throw ExitCode.failure }
    }
}
