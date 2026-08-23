import ArgumentParser
import CoreGraphics
import Foundation

struct PdfToPngCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pdf2png",
        abstract: "Render a PDF, or every PDF in a folder, to one PNG per page."
    )

    @Argument(help: "PDF file or folder containing PDFs. Defaults to the current directory.", completion: .file())
    var folder = "."

    @Option(help: "Rendering scale; 2 ≈ 144 dpi, plenty for OCR.")
    var scale = 2.0

    mutating func run() throws {
        let folderURL = URL(fileURLWithPath: folder)
        let pdfs = try folderURL.inputs(matching: ["pdf"]).filter { !$0.isOcrOutput }
        guard !pdfs.isEmpty else { print("No PDFs found in \(folderURL.path)"); return }

        var rendered = 0
        for pdf in pdfs {
            do {
                for output in try PdfToPng.render(pdfAt: pdf, scale: scale) {
                    print("\(pdf.lastPathComponent) -> \(output.lastPathComponent)")
                    rendered += 1
                }
            } catch {
                note("SKIP (render failed): \(pdf.lastPathComponent) — \(error.localizedDescription)")
            }
        }
        print("\(rendered) page(s) rendered from \(pdfs.count) PDF(s)")
        if rendered == 0 { throw ExitCode.failure }
    }
}
