import CoreGraphics
import Foundation
import Testing

@testable import SwiftOCR

@Suite
struct LayoutTests {
    private func line(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat = 0.5, height: CGFloat = 0.04) -> RecognizedLine {
        RecognizedLine(text: text, box: CGRect(x: x, y: y, width: width, height: height))
    }

    @Test
    func closeLinesFormOneParagraph() {
        let markdown = Layout.markdown(from: [
            line("Second half of the", x: 0.1, y: 0.90),
            line("sentence wraps here.", x: 0.1, y: 0.86),
        ])
        #expect(markdown == "Second half of the sentence wraps here.\n")
    }

    @Test
    func largeGapStartsNewParagraph() {
        let markdown = Layout.markdown(from: [
            line("First paragraph.", x: 0.1, y: 0.90),
            line("Second paragraph.", x: 0.1, y: 0.70),
        ])
        #expect(markdown == "First paragraph.\n\nSecond paragraph.\n")
    }

    @Test
    func tallLineBecomesHeading() {
        let markdown = Layout.markdown(from: [
            line("Invoice", x: 0.1, y: 0.95, width: 0.2, height: 0.08),
            line("Amount due 42 EUR", x: 0.1, y: 0.80),
        ])
        #expect(markdown == "## Invoice\n\nAmount due 42 EUR\n")
    }

    @Test
    func normalizesBulletCharacters() {
        let markdown = Layout.markdown(from: [line("• first item", x: 0.1, y: 0.5)])
        #expect(markdown == "- first item\n")
    }

    @Test
    func sortsTopDownRegardlessOfInputOrder() {
        let markdown = Layout.markdown(from: [
            line("bottom line", x: 0.1, y: 0.2),
            line("top line", x: 0.1, y: 0.8),
        ])
        #expect(markdown == "top line\n\nbottom line\n")
    }

    @Test
    func emptyInputYieldsEmptyOutput() {
        #expect(Layout.markdown(from: []) == "")
    }
}
