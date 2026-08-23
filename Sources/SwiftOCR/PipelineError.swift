import Foundation

enum PipelineError: LocalizedError {
    case cannotRead(URL)
    case unsupportedInput(URL)
    case unreadablePDF(URL)
    case cannotEncodePNG(URL)
    case cannotEncodePDF(URL)
    case unreadableImage(URL)
    case recognitionTimedOut

    var errorDescription: String? {
        switch self {
        case .cannotRead(let url): "Cannot read: \(url.path)"
        case .unsupportedInput(let url): "Not a supported input file: \(url.path)"
        case .unreadablePDF(let url): "Cannot read PDF: \(url.path)"
        case .cannotEncodePNG(let url): "Cannot encode PNG: \(url.path)"
        case .cannotEncodePDF(let url): "Cannot encode PDF: \(url.path)"
        case .unreadableImage(let url): "Cannot read image: \(url.path)"
        case .recognitionTimedOut: "Text recognition did not complete in time"
        }
    }
}
