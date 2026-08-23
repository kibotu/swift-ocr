import ArgumentParser
import Foundation

struct OcrCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ocr",
        abstract: "Recognize text in each image of a folder, writing <name>.md next to it."
    )

    @Argument(help: "Folder containing images. Defaults to the current directory.", completion: .directory)
    var folder = "."

    mutating func run() throws {
        let folderURL = URL(fileURLWithPath: folder)
        let images = try folderURL.contents(matching: ["png", "jpg", "jpeg", "tiff"])
        guard !images.isEmpty else { print("No images found in \(folderURL.path)"); return }

        var recognized = 0
        for image in images {
            do {
                let cgImage = try TextRecognizer.loadCGImage(at: image)
                let text = try TextRecognizer.recognizeText(in: cgImage)
                let output = image.deletingPathExtension().appendingPathExtension("md")
                try text.write(to: output, atomically: true, encoding: .utf8)
                print("\(image.lastPathComponent) -> \(output.lastPathComponent) (\(text.count) chars)")
                recognized += 1
            } catch {
                note("SKIP (ocr failed): \(image.lastPathComponent) — \(error.localizedDescription)")
            }
        }
        print("\(recognized)/\(images.count) image(s) recognized")
        if recognized == 0 { throw ExitCode.failure }
    }
}
