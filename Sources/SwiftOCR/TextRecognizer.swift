import CoreGraphics
import Foundation
import ImageIO
import Vision

/// Apple Vision text recognition, entirely on-device.
enum TextRecognizer {
    /// Loads an image through ImageIO — no NSImage detour.
    static func loadCGImage(at url: URL) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw PipelineError.unreadableImage(url)
        }
        return image
    }

    /// Returns recognized lines joined by newlines.
    static func recognizeText(in image: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        try VNImageRequestHandler(cgImage: image).perform([request])
        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
