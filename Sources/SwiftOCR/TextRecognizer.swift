import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import ImageIO
import Vision

/// Apple Vision text recognition, entirely on-device. Pure computation — callers own all output.
enum TextRecognizer {
    /// Loads an image through ImageIO — no NSImage detour.
    static func loadCGImage(at url: URL) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw PipelineError.unreadableImage(url)
        }
        return image
    }

    /// Maps user-supplied codes (`de`, `en-US`) onto Vision's supported languages,
    /// reporting what could not be matched so the caller decides what to say about it.
    static func resolveLanguages(_ codes: [String]) -> (resolved: [String], rejected: [String]) {
        let supported = (try? VNRecognizeTextRequest().supportedRecognitionLanguages()) ?? []
        var resolved: [String] = []
        var rejected: [String] = []
        for code in codes {
            let lowered = code.lowercased()
            if let match = supported.first(where: { $0.lowercased() == lowered })
                ?? supported.first(where: { $0.lowercased().hasPrefix("\(lowered)-") }) {
                resolved.append(match)
            } else {
                rejected.append(code)
            }
        }
        return (resolved, rejected)
    }

    /// Grayscale plus a contrast lift, for faint scans; nil when processing failed.
    static func enhanced(_ image: CGImage, using context: CIContext) -> CGImage? {
        let filter = CIFilter.colorControls()
        filter.inputImage = CIImage(cgImage: image)
        filter.saturation = 0
        filter.contrast = 1.2
        guard let output = filter.outputImage else { return nil }
        return context.createCGImage(output, from: output.extent)
    }

    /// Returns recognized lines with their page positions in document conventions.
    /// An empty `languages` array keeps Vision's own auto-detection.
    static func recognizeLines(in image: CGImage, languages: [String] = []) throws -> [RecognizedLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        if !languages.isEmpty { request.recognitionLanguages = languages }
        try VNImageRequestHandler(cgImage: image).perform([request])
        return (request.results ?? []).compactMap { observation in
            observation.topCandidates(1).first.map { candidate in
                RecognizedLine(text: candidate.string, region: PageRect(visionBox: observation.boundingBox))
            }
        }
    }
}
