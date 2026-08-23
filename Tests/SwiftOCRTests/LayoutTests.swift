import CoreGraphics
import Foundation
import Testing

@testable import SwiftOCR

@Suite
struct LayoutTests {
    /// `y` is the top edge, in page conventions.
    private func line(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat = 0.5, height: CGFloat = 0.04) -> RecognizedLine {
        RecognizedLine(text: text, region: PageRect(minX: x, minY: y, maxX: x + width, maxY: y + height))
    }

    private func markdown(_ lines: [RecognizedLine]) -> String {
        DocumentRenderer.markdown(from: Layout.blocks(from: lines))
    }

    @Test
    func closeLinesFormOneParagraph() {
        #expect(markdown([
            line("Second half of the", x: 0.1, y: 0.86),
            line("sentence wraps here.", x: 0.1, y: 0.90),
        ]) == "Second half of the sentence wraps here.\n")
    }

    @Test
    func largeGapStartsNewParagraph() {
        #expect(markdown([
            line("First paragraph.", x: 0.1, y: 0.10),
            line("Second paragraph.", x: 0.1, y: 0.70),
        ]) == "First paragraph.\n\nSecond paragraph.\n")
    }

    @Test
    func tallLineBecomesHeading() {
        #expect(markdown([
            line("Invoice", x: 0.1, y: 0.05, width: 0.2, height: 0.08),
            line("Amount due 42 EUR", x: 0.1, y: 0.80),
        ]) == "# Invoice\n\nAmount due 42 EUR\n")
    }

    @Test
    func consecutiveBulletsGroupIntoOneList() {
        #expect(markdown([
            line("• first item", x: 0.1, y: 0.50),
            line("• second item", x: 0.1, y: 0.54),
        ]) == "- first item\n- second item\n")
    }

    @Test
    func inlineMarkersSplitIntoItems() {
        #expect(markdown([line("• alpha • beta", x: 0.1, y: 0.5)]) == "- alpha\n- beta\n")
    }

    @Test
    func listsAndParagraphsInterleaveInReadingOrder() {
        #expect(markdown([
            line("• only item", x: 0.1, y: 0.20),
            line("plain paragraph", x: 0.1, y: 0.50),
            line("▪ trailing item", x: 0.1, y: 0.80),
        ]) == "- only item\n\nplain paragraph\n\n- trailing item\n")
    }

    @Test
    func sortsTopDownRegardlessOfInputOrder() {
        #expect(markdown([
            line("bottom line", x: 0.1, y: 0.80),
            line("top line", x: 0.1, y: 0.20),
        ]) == "top line\n\nbottom line\n")
    }

    @Test
    func emptyInputYieldsEmptyOutput() {
        #expect(DocumentRenderer.markdown(from: []) == "")
    }
}

@Suite
struct DocumentRendererTests {
    private let block = PositionedBlock(block: .paragraph("x"), region: PageRect(minX: 0, minY: 0, maxX: 1, maxY: 1))

    @Test
    func rendersTablesWithSeparatorRow() {
        let table = PositionedBlock(block: .table([["a", "b|c"], ["1", "2"]]), region: block.region)
        #expect(DocumentRenderer.markdown(from: [table]) == "| a | b\\|c |\n| --- | --- |\n| 1 | 2 |\n")
    }

    @Test
    func emptyTableDoesNotCrash() {
        let table = PositionedBlock(block: .table([]), region: block.region)
        #expect(!DocumentRenderer.markdown(from: [table]).contains("|"))
    }
}

@Suite
struct PageRectTests {
    /// Floating-point origin flips need a tolerance, not exact equality.
    private func expectClose(_ a: CGFloat, _ b: CGFloat) -> Bool {
        abs(a - b) < 0.0001
    }

    @Test
    func flipsVisionOriginToPageTopLeft() {
        // Vision box occupying the top tenth of the page (bottom-left origin).
        let page = PageRect(visionBox: CGRect(x: 0.1, y: 0.90, width: 0.5, height: 0.08))
        #expect(expectClose(page.minY, 0.02))
        #expect(expectClose(page.maxY, 0.10))
        #expect(page.minX == 0.1)
        #expect(expectClose(page.width, 0.5))
        #expect(expectClose(page.height, 0.08))
    }
}
