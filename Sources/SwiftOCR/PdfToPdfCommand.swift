import ArgumentParser
import Foundation

struct PdfToPdfCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pdf2pdf",
        abstract: "Make a PDF, or each PDF in a folder, searchable by adding an invisible OCR text layer."
    )

    @Argument(help: "PDF file or folder containing PDFs. Defaults to the current directory.", completion: .file())
    var folder = "."

    @Option(help: "Rendering scale for recognition; 2 ≈ 144 dpi, plenty.")
    var scale = 2.0

    @Option(parsing: .singleValue, help: "Recognition language hint, repeatable: --lang de --lang fr.")
    var lang: [String] = []

    mutating func run() throws {
        let folderURL = URL(fileURLWithPath: folder)
        let pdfs = try folderURL.inputs(matching: ["pdf"]).filter { !$0.isOcrOutput }
        guard !pdfs.isEmpty else { print("No PDFs found in \(folderURL.path)"); return }

        let hint = TextRecognizer.resolveLanguages(lang)
        for code in hint.rejected { note("WARN (unsupported language): \(code) — ignoring") }

        var converted = 0
        for pdf in pdfs {
            do {
                let output = try PdfToPdf.render(pdfAt: pdf, scale: scale, languages: hint.resolved)
                print("\(pdf.lastPathComponent) -> \(output.lastPathComponent)")
                converted += 1
            } catch {
                note("SKIP (conversion failed): \(pdf.lastPathComponent) — \(error.localizedDescription)")
            }
        }
        print("\(converted)/\(pdfs.count) PDF(s) made searchable")
        if converted == 0 { throw ExitCode.failure }
    }
}
