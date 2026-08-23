import ArgumentParser
import Foundation

/// One questionnaire question extracted from OCR'd Markdown.
struct Question: Equatable {
    let number: Int
    let total: Int
    var answers: [String]
}

enum QuestionParser {
    static let mostMarker = "Most like you"
    static let leastMarker = "Least like you"

    /// Extracts the `N / M` heading and the answer lines between the two markers. nil when either is missing.
    static func parse(_ text: String) -> Question? {
        guard let match = text.firstMatch(of: /(?<number>\d+)\s*\/\s*(?<total>\d+)/),
              let most = text.range(of: mostMarker),
              let least = text.range(of: leastMarker, range: most.upperBound..<text.endIndex)
        else { return nil }

        let answers = text[most.upperBound..<least.lowerBound]
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "=" && !($0.allSatisfy(\.isNumber)) }

        return Question(number: Int(match.number)!, total: Int(match.total)!, answers: answers)
    }
}

enum CombinedDocument {
    /// Renders questions sorted by number, at most four answers each — byte-identical to the original combine.py output.
    static func markdown(for questions: [Question]) -> String {
        var sections: [String] = []
        for question in questions.sorted(by: { ($0.number, $0.total) < ($1.number, $1.total) }) {
            sections.append("## Question \(question.number)/\(question.total)\n")
            sections.append("\(QuestionParser.mostMarker)\n")
            sections.append(
                contentsOf: question.answers.prefix(4).enumerated().map { "\($0.offset + 1). \($0.element)" }
            )
            sections.append("\(QuestionParser.leastMarker)\n")
        }
        return sections.joined(separator: "\n") + "\n"
    }
}

struct CombineCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "combine",
        abstract: "Merge OCR'd Markdown files into one combined.md, sorted by question number."
    )

    @Argument(help: "Folder containing the OCR'd Markdown files. Defaults to the current directory.", completion: .directory)
    var folder = "."

    mutating func run() throws {
        let folderURL = URL(fileURLWithPath: folder)
        let files = try folderURL.contents(matching: ["md"]).filter { $0.lastPathComponent != "combined.md" }
        guard !files.isEmpty else { print("No Markdown found in \(folderURL.path)"); return }

        var questions: [Question] = []
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            if let question = QuestionParser.parse(text) {
                questions.append(question)
            } else {
                note("SKIP (no question): \(file.lastPathComponent)")
            }
        }
        guard !questions.isEmpty else {
            note("No question numbers found in \(folderURL.path)")
            throw ExitCode.failure
        }

        let output = folderURL.appending(path: "combined.md")
        try CombinedDocument.markdown(for: questions).write(to: output, atomically: true, encoding: .utf8)
        print("Combined \(questions.count) question(s) -> \(output.path)")
    }
}
