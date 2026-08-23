# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-08-23

### Fixed

- `ocr --documents` now forwards `--lang` hints to the document recognizer
  instead of silently dropping them.

### Changed

- The document recognizer no longer prints a page's top line twice (it is
  reported as both title and paragraph; only the heading survives).
- Bullet-led lines become Markdown list items, and consecutive items group
  into one list.
- Headings render as `#`.

## [1.1.0] - 2026-08-23

### Added

- `pdf2pdf` — makes each PDF in a folder searchable by adding an invisible OCR
  text layer over the rendered pages; output is `<name>_ocr.pdf`.
- `--documents` flag on `ocr` — uses Apple's document recognizer to emit native
  Markdown headings, lists and tables instead of reconstructed geometry.
  Requires macOS 26 or newer; older systems fall back with a warning.
- `--lang` flag on `ocr` and `pdf2pdf` — explicit recognition languages,
  repeatable (`--lang de --lang fr`). Without it, Vision auto-detects.
- `--meta` flag on `ocr` — prepends YAML front-matter listing detected dates,
  phone numbers, links and addresses.
- `--enhance` flag on `ocr` — grayscale plus contrast lift before recognition,
  for faint scans.

### Changed

- `ocr` output preserves layout: paragraphs are rebuilt from line geometry,
  oversized lines become headings, common bullet characters become Markdown
  lists. Plain text lines remain separated by blank lines between paragraphs.

## [1.0.0] - 2026-08-23

Initial release.

### Added

- `pdf2png` — render every page of each PDF in a folder to PNG via CoreGraphics.
- `ocr` — recognize text in each image of a folder with Apple Vision, writing `<name>.md`.
- `combine` — merge OCR'd Markdown questionnaire files into one sorted `combined.md`.
- Fully on-device processing; nothing leaves the machine.

[1.2.0]: https://github.com/kibotu/swift-ocr/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/kibotu/swift-ocr/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/kibotu/swift-ocr/releases/tag/1.0.0
