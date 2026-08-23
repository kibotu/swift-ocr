import Foundation
import Testing

@testable import SwiftOCR

@Suite
struct QuestionParserTests {
    @Test
    func parsesNumberAndFiltersAnswerNoise() {
        let text = """
        Some header noise 3 / 24
        Most like you
        Energetic
        =
        12
        Organised

        Least like you
        Quiet
        """
        #expect(QuestionParser.parse(text) == Question(number: 3, total: 24, answers: ["Energetic", "Organised"]))
    }

    @Test
    func toleratesSpacingAroundTheSlash() {
        #expect(QuestionParser.parse("7/24 Most like you A Least like you")?.number == 7)
        #expect(QuestionParser.parse("7 / 24 Most like you A Least like you")?.number == 7)
    }

    @Test
    func onlyAcceptsLeastMarkerAfterMost() {
        let reversed = "Least like you\n7 / 24\nMost like you\nA"
        #expect(QuestionParser.parse(reversed) == nil)
    }

    @Test
    func returnsNilWithoutHeadingOrMarkers() {
        #expect(QuestionParser.parse("no heading, no markers") == nil)
        #expect(QuestionParser.parse("12 / 24 but no markers") == nil)
    }
}

@Suite
struct CombinedDocumentTests {
    @Test
    func matchesLegacyPythonOutputByteForByte() {
        let markdown = CombinedDocument.markdown(for: [Question(number: 1, total: 24, answers: ["A", "B"])])
        #expect(markdown == "## Question 1/24\n\nMost like you\n\n1. A\n2. B\n\nLeast like you\n\n")
    }

    @Test
    func sortsByQuestionNumberAndCapsAnswersAtFour() throws {
        let markdown = CombinedDocument.markdown(for: [
            Question(number: 12, total: 24, answers: ["A", "B", "C", "D", "E"]),
            Question(number: 2, total: 30, answers: ["X"]),
        ])
        let second = try #require(markdown.range(of: "## Question 2/30")).lowerBound
        let twelfth = try #require(markdown.range(of: "## Question 12/24")).lowerBound
        #expect(second < twelfth)
        #expect(markdown.contains("4. D"))
        #expect(!markdown.contains("5. E"))
    }
}
