#!/usr/bin/env swift
// OCR every .png in a folder (default: current dir) into <name>.md files.
import Foundation
import Vision
import AppKit

let folder = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

guard let files = try? FileManager.default.contentsOfDirectory(
    at: folder, includingPropertiesForKeys: nil
) else { fatalError("Cannot read folder: \(folder.path)") }

for file in files where file.pathExtension.lowercased() == "png" {
    guard let image = NSImage(contentsOf: file),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("SKIP (unreadable): \(file.lastPathComponent)")
        continue
    }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    try? VNImageRequestHandler(cgImage: cgImage).perform([request])

    let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    let out = file.deletingPathExtension().appendingPathExtension("md")
    try? text.write(to: out, atomically: true, encoding: .utf8)
    print("\(file.lastPathComponent) -> \(out.lastPathComponent) (\(text.count) chars)")
}
