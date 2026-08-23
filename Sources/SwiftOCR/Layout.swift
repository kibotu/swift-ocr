import CoreGraphics
import Foundation

/// One recognized text line with its position in page conventions.
struct RecognizedLine {
    let text: String
    let region: PageRect
}

/// Rebuilds document structure from line geometry: paragraphs from proximity,
/// headings from line height, runs of bullets into lists.
enum Layout {
    /// Lines closer than this fraction of the median height belong to one paragraph.
    private static let paragraphGap = 0.6 as CGFloat
    /// A single line this much taller than the body text reads as a heading.
    private static let headingRatio = 1.5 as CGFloat
    /// Characters treated as list markers when they lead a line.
    private static let bulletCharacters = Set("•●▪·‣")

    // ponytail: naive top-down sort scrambles multi-column pages; column detection only if it hurts.
    static func blocks(from lines: [RecognizedLine]) -> [PositionedBlock] {
        let sorted = lines.sorted {
            $0.region.minY != $1.region.minY ? $0.region.minY < $1.region.minY : $0.region.minX < $1.region.minX
        }
        guard !sorted.isEmpty else { return [] }

        let heights = sorted.map { $0.region.height }.sorted()
        // Lower middle: dominated by many short body lines, so one tall heading can't inflate it.
        let medianHeight = heights[(heights.count - 1) / 2]

        var blocks: [PositionedBlock] = []
        var paragraph: [RecognizedLine] = []
        var listItems: [String] = []
        var listRegions: [PageRect] = []

        func flushList() {
            guard let firstRegion = listRegions.first else { return }
            blocks.append(PositionedBlock(
                block: .list(listItems),
                region: listRegions.dropFirst().reduce(firstRegion) { $0.union($1) }
            ))
            listItems = []
            listRegions = []
        }

        func flushParagraph() {
            defer { paragraph = [] }
            guard let first = paragraph.first else { return }
            let text = paragraph.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespaces)

            if paragraph.count == 1 && first.region.height >= headingRatio * medianHeight {
                flushList()
                blocks.append(PositionedBlock(block: .heading(text), region: first.region))
                return
            }
            if let items = splitItems(from: text) {
                listItems.append(contentsOf: items)
                listRegions.append(union(of: paragraph))
                return
            }
            flushList()
            blocks.append(PositionedBlock(block: .paragraph(text), region: union(of: paragraph)))
        }

        for line in sorted {
            if let previous = paragraph.last, joins(previous, line, median: medianHeight) {
                paragraph.append(line)
            } else {
                flushParagraph()
                paragraph = [line]
            }
        }
        flushParagraph()
        flushList()
        return blocks
    }

    /// Two lines join into one paragraph when they sit close together and share a column.
    /// Bullet-led lines never join — each marker starts its own item.
    private static func joins(_ a: RecognizedLine, _ b: RecognizedLine, median: CGFloat) -> Bool {
        guard !startsWithBullet(a.text), !startsWithBullet(b.text) else { return false }
        guard b.region.minY - a.region.maxY <= paragraphGap * median else { return false }
        return a.region.minX < b.region.maxX && b.region.minX < a.region.maxX
    }

    /// Splits a bullet-led line into its items at every marker; nil when none leads.
    private static func splitItems(from text: String) -> [String]? {
        guard startsWithBullet(text) else { return nil }
        return text.split(whereSeparator: { bulletCharacters.contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func startsWithBullet(_ text: String) -> Bool {
        text.first.map { bulletCharacters.contains($0) } ?? false
    }

    private static func union(of lines: [RecognizedLine]) -> PageRect {
        lines.dropFirst().reduce(lines[0].region) { $0.union($1.region) }
    }
}

extension PageRect {
    /// The smallest rectangle covering both.
    func union(_ other: PageRect) -> PageRect {
        PageRect(
            minX: Swift.min(minX, other.minX),
            minY: Swift.min(minY, other.minY),
            maxX: Swift.max(maxX, other.maxX),
            maxY: Swift.max(maxY, other.maxY)
        )
    }
}
