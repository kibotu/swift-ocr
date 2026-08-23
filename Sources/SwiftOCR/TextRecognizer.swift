import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import ImageIO
import NaturalLanguage
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

    /// Maps user-supplied codes (`de`, `en-US`) onto Vision's supported languages.
    /// Returns nil (Vision's own auto-detection) when nothing valid remains.
    static func resolveLanguages(_ requested: [String]) -> [String]? {
        let supported = (try? VNRecognizeTextRequest().supportedRecognitionLanguages()) ?? []
        let resolved = requested.compactMap { code in
            supported.first { $0.lowercased() == code.lowercased() }
                ?? supported.first { $0.lowercased().hasPrefix("\(code.lowercased())-") }
        }
        for dropped in requested where !resolved.contains(where: { $0.lowercased().hasPrefix(dropped.lowercased()) }) {
            note("WARN (unsupported language): \(dropped) — ignoring")
        }
        return resolved.isEmpty ? nil : resolved
    }

    /// Grayscale plus a contrast lift, for faint scans. Falls back to the input unchanged.
    static func enhanced(_ image: CGImage, using context: CoreImage.CIContext) -> CGImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = CIImage(cgImage: image)
        filter.saturation = 0
        filter.contrast = 1.2
        guard let output = filter.outputImage,
              let result = context.createCGImage(output, from: output.extent) else {
            note("WARN (enhance failed): continuing unprocessed")
            return image
        }
        return result
    }

    /// Returns recognized lines with their page positions, top-down reading order applied by `Layout`.
    static func recognizeLines(in image: CGImage, languages: [String]? = nil) throws -> [RecognizedLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages ?? ((try? request.supportedRecognitionLanguages()) ?? [])
        try VNImageRequestHandler(cgImage: image).perform([request])
        return (request.results ?? []).compactMap { observation in
            observation.topCandidates(1).first.map { RecognizedLine(text: $0.string, box: observation.boundingBox) }
        }
    }
}
