import Foundation

enum PipelineError: LocalizedError {
    case cannotReadFolder(URL)
    case unreadablePDF(URL)
    case cannotEncodePNG(URL)
    case unreadableImage(URL)

    var errorDescription: String? {
        switch self {
        case .cannotReadFolder(let url): "Cannot read folder: \(url.path)"
        case .unreadablePDF(let url): "Cannot read PDF: \(url.path)"
        case .cannotEncodePNG(let url): "Cannot encode PNG: \(url.path)"
        case .unreadableImage(let url): "Cannot read image: \(url.path)"
        }
    }
}
