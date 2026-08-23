import CoreGraphics

/// A rectangle on a page in document conventions: normalized 0–1, origin top-left,
/// y grows downward — unlike Vision's bottom-left origins, which are converted once
/// at the recognition boundary and never leak past it.
struct PageRect: Equatable {
    let minX: CGFloat
    let minY: CGFloat
    let maxX: CGFloat
    let maxY: CGFloat

    init(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }

    /// Converts from Vision's normalized bottom-left origin box.
    init(visionBox box: CGRect) {
        self.init(minX: box.minX, minY: 1 - box.maxY, maxX: box.maxX, maxY: 1 - box.minY)
    }

    var width: CGFloat { maxX - minX }
    var height: CGFloat { maxY - minY }
    /// Vertical center; smaller values sit higher up the page.
    var midY: CGFloat { (minY + maxY) / 2 }
}

/// One structural element of a document.
enum RecognizedBlock: Equatable {
    case heading(String)
    case paragraph(String)
    case list([String])
    case table([[String]])
}

/// A block with its page position, so reading order can be established centrally.
struct PositionedBlock {
    let block: RecognizedBlock
    let region: PageRect
}

/// The one Markdown renderer and reading-order sort for every recognizer.
enum DocumentRenderer {
    /// Top-down, left-to-right among equals; blocks separated by blank lines.
    static func markdown(from blocks: [PositionedBlock]) -> String {
        let rendered = blocks
            .sorted {
                $0.region.midY != $1.region.midY ? $0.region.midY < $1.region.midY : $0.region.minX < $1.region.minX
            }
            .map(render)
        guard !rendered.isEmpty else { return "" }
        return rendered.joined(separator: "\n\n") + "\n"
    }

    private static func render(_ positioned: PositionedBlock) -> String {
        switch positioned.block {
        case .heading(let text):
            return "# \(text)"
        case .paragraph(let text):
            return text
        case .list(let items):
            return items.map { "- \($0)" }.joined(separator: "\n")
        case .table(let rows):
            guard !rows.isEmpty else { return "" }
            let escaped = rows.map { row in
                "| " + row.map { $0.replacingOccurrences(of: "|", with: "\\|") }.joined(separator: " | ") + " |"
            }
            let separator = "| " + Array(repeating: "---", count: rows[0].count).joined(separator: " | ") + " |"
            return ([escaped[0], separator] + escaped.dropFirst()).joined(separator: "\n")
        }
    }
}
