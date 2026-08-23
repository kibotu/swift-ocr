import CoreGraphics
import Foundation
import Testing

@testable import SwiftOCR

@Suite
struct OcrOptionTests {
    @Test
    func detectsDatesPhonesAndLinks() throws {
        let text = "Invoice dated 23 August 2026. Call +49 30 12345678 or visit https://example.com/ok."
        let front = FrontMatter.markdown(for: text)
        #expect(!front.isEmpty)
        #expect(front.hasPrefix("---\n"))
        #expect(front.contains("language: \"de\"") || front.contains("language: \"en\""))
        #expect(front.contains("- \"https://example.com/ok\""))
        #expect(front.contains("- \"+49 30 12345678\"") || front.contains("493012345678"))
        #expect(front.contains("- \"2026-08-23"))
    }

    @Test
    func plainTextYieldsNoFrontMatter() {
        #expect(FrontMatter.markdown(for: "Most like you\nLeast like you").isEmpty)
        #expect(FrontMatter.markdown(for: "").isEmpty)
    }

    @Test
    func resolvesShortLanguageCodes() {
        // Depends on the installed Vision language pack; German and English ship with macOS.
        let hint = TextRecognizer.resolveLanguages(["de", "en-US"])
        #expect(hint.resolved.contains("de-DE"))
        #expect(hint.resolved.contains("en-US"))
        #expect(hint.rejected.isEmpty)
    }

    @Test
    func reportsUnknownLanguagesAsRejected() {
        let hint = TextRecognizer.resolveLanguages(["xx-klingon"])
        #expect(hint.resolved.isEmpty)
        #expect(hint.rejected == ["xx-klingon"])
    }
}

@Suite
struct RecognizerForwardingTests {
    /// Vision silently ignores unknown language codes, so the strongest observable
    /// assertion is: both recognition paths succeed end-to-end with a valid hint.
    /// (The original bug — hints never reaching `--documents` — lives at this seam.)
    @Test
    func validLanguageHintSucceedsOnBothPaths() throws {
        let image = try TestImages.rasterizedText(text: "Sprachprüfung öäü")

        let plain = try Recognizer.read(image, languages: ["de"], structured: false)
        #expect(DocumentRenderer.markdown(from: plain.blocks).contains("Sprachprüfung"))

        if #available(macOS 26.0, *) {
            let structured = try Recognizer.read(image, languages: ["de"], structured: true)
            #expect(!structured.fellBack)
            #expect(DocumentRenderer.markdown(from: structured.blocks).contains("Sprachprüfung"))
        }
    }
}
