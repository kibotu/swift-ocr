import CoreGraphics

/// Reads an image into positioned document blocks with the best recognizer this OS
/// offers, so callers never branch on availability themselves.
enum Recognizer {
    struct Result {
        let blocks: [PositionedBlock]
        /// True when `structured` was requested but this system predates macOS 26.
        let fellBack: Bool
    }

    static func read(_ image: CGImage, languages: [String] = [], structured: Bool = false) throws -> Result {
        if structured, #available(macOS 26.0, *) {
            return Result(
                blocks: try DocumentsRecognizer.blocks(in: image, languages: languages),
                fellBack: false
            )
        }
        let lines = try TextRecognizer.recognizeLines(in: image, languages: languages)
        return Result(blocks: Layout.blocks(from: lines), fellBack: structured)
    }
}
