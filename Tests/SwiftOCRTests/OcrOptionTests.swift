import Foundation
import Testing

@testable import SwiftOCR

@Suite
struct OcrOptionTests {
    @Test
    func detectsDatesPhonesAndLinks() throws {
        let text = "Invoice dated 23 August 2026. Call +49 30 12345678 or visit https://example.com/ok."
        let front = try #require(FrontMatter.markdown(for: text))
        #expect(front.hasPrefix("---\n"))
        #expect(front.contains("language: \"de\"") || front.contains("language: \"en\""))
        #expect(front.contains("- \"https://example.com/ok\""))
        #expect(front.contains("- \"+49 30 12345678\"") || front.contains("493012345678"))
        #expect(front.contains("- \"2026-08-23"))
    }

    @Test
    func plainTextYieldsNoFrontMatter() {
        #expect(FrontMatter.markdown(for: "Most like you\nLeast like you") == nil)
        #expect(FrontMatter.markdown(for: "") == nil)
    }

    @Test
    func resolvesShortLanguageCodes() {
        // Depends on the installed Vision language pack; German and English ship with macOS.
        let resolved = TextRecognizer.resolveLanguages(["de", "en-US"])
        #expect(resolved?.contains("de-DE") == true)
        #expect(resolved?.contains("en-US") == true)
    }

    @Test
    func dropsUnknownLanguagesToNil() {
        #expect(TextRecognizer.resolveLanguages(["xx-klingon"]) == nil)
    }
}
