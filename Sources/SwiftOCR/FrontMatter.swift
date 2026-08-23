import Foundation
import NaturalLanguage

/// Detects entities with NSDataDetector and renders them as YAML front-matter.
enum FrontMatter {
    /// Returns a `---\n…\n---\n` block for the given text — empty when nothing was found.
    static func markdown(for text: String) -> String {
        let types: NSTextCheckingResult.CheckingType = [.date, .address, .phoneNumber, .link]
        guard let detector = try? NSDataDetector(types: types.rawValue) else { return "" }

        let matches = detector.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
        let iso8601 = ISO8601DateFormatter()
        let dates = Set(matches.compactMap { $0.date }.map(iso8601.string(from:)))
        let phones = Set(matches.compactMap(\.phoneNumber))
        let links = Set(matches.compactMap { $0.url?.absoluteString })
        let addresses = Set(matches.compactMap {
            $0.addressComponents?
                .sorted { ($0.key.rawValue, $0.value) < ($1.key.rawValue, $1.value) }
                .map(\.value)
                .joined(separator: ", ")
        }.filter { !$0.isEmpty })

        guard !dates.isEmpty || !phones.isEmpty || !links.isEmpty || !addresses.isEmpty else { return "" }

        var lines: [String] = []
        if let language = NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue {
            lines.append("language: \(quoted(language))")
        }
        for (name, values) in [("dates", dates), ("phones", phones), ("links", links), ("addresses", addresses)]
        where !values.isEmpty {
            lines.append("\(name):")
            for value in values.sorted() { lines.append("  - \(quoted(value))") }
        }
        return "---\n" + lines.joined(separator: "\n") + "\n---\n"
    }

    /// OCR text can contain quotes; escape them so the YAML stays parseable.
    private static func quoted(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
