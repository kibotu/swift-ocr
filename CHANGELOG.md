# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-08-23

Initial release.

### Added

- `pdf2png` — render every page of each PDF in a folder to PNG via CoreGraphics.
- `ocr` — recognize text in each image of a folder with Apple Vision, writing `<name>.md`.
- `combine` — merge OCR'd Markdown questionnaire files into one sorted `combined.md`.
- Fully on-device processing; nothing leaves the machine.

[Unreleased]: https://github.com/kibotu/swift-ocr/compare/1.0.0...HEAD
[1.0.0]: https://github.com/kibotu/swift-ocr/releases/tag/1.0.0
