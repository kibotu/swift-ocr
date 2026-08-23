import CoreGraphics
import Foundation

/// One recognized text line with its position in the page (normalized, origin bottom-left).
struct RecognizedLine {
    let text: String
    let box: CGRect
}

/// Rebuilds paragraphs and headings from line geometry — the flat line dump gets structure.
enum Layout {
    /// Lines closer than this fraction of the median height belong to one paragraph.
    private static let paragraphGap = 0.6 as CGFloat
    /// A line this much taller than the body text reads as a heading.
    private static let headingRatio = 1.5 as CGFloat

    static func markdown(from lines: [RecognizedLine]) -> String {
        // ponytail: naive top-down sort scrambles multi-column pages; column detection only if it hurts.
        let sorted = lines.sorted {
            $0.box.minY != $1.box.minY ? $0.box.minY > $1.box.minY : $0.box.minX < $1.box.minX
        }
        guard !sorted.isEmpty else { return "" }

        let heights = sorted.map(\.box.height).sorted()
        // Lower middle: dominated by the many short body lines, so one tall heading can't inflate it.
        let medianHeight = heights[(heights.count - 1) / 2]

        var paragraphs: [[RecognizedLine]] = []
        var current: [RecognizedLine] = []
        for line in sorted {
            if let previous = current.last, joins(previous, line, median: medianHeight) {
                current.append(line)
            } else {
                if !current.isEmpty { paragraphs.append(current) }
                current = [line]
            }
        }
        if !current.isEmpty { paragraphs.append(current) }

        return paragraphs.map { paragraph in
            let text = paragraph.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespaces)
            let isHeading = paragraph.count == 1 && paragraph[0].box.height >= headingRatio * medianHeight
            return isHeading ? "## \(text)" : bullet(text)
        }
        .joined(separator: "\n\n") + "\n"
    }

    /// Two lines join into one paragraph when they sit close together and share a column.
    private static func joins(_ a: RecognizedLine, _ b: RecognizedLine, median: CGFloat) -> Bool {
        guard a.box.minY - b.box.maxY <= paragraphGap * median else { return false }
        return a.box.minX < b.box.maxX && b.box.minX < a.box.maxX
    }

    /// Normalizes common OCR bullet characters to Markdown lists.
    private static func bullet(_ text: String) -> String {
        let trimmed = text.drop { $0 == "•" || $0 == "●" || $0 == "▪" || $0 == "·" || $0 == "‣" }
        return trimmed.count < text.count ? "- \(trimmed.trimmingCharacters(in: .whitespaces))" : text
    }
}
