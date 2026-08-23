# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-08-23

### Added

- `convert` — the new default subcommand: renders PDFs to PNGs and recognizes
  every image into Markdown in one pass (`swift-ocr ~/scans` just works).
  Forwards `--scale`, `--lang`, `--meta`, `--enhance` and `--documents`.
- Every subcommand now accepts a single file as well as a folder — e.g.
  `swift-ocr ocr letter.png` or `swift-ocr pdf2pdf letter.pdf`. A file with
  an unsupported extension fails with a clear error instead of a silent no-op.

### Fixed

- `pdf2pdf` keeps each page's own media box, so mixed portrait/landscape
  documents are no longer clipped to the first page's size.
- Re-running `pdf2pdf`, `pdf2png` or `convert` skips existing
  `<name>.ocr.pdf` outputs instead of nesting `letter.ocr.ocr.pdf`.
- `pdf2pdf` warns on stderr when a page cannot be rendered instead of
  silently dropping it from the searchable output.
- Front-matter values escape quotes and backslashes so odd OCR text cannot
  produce invalid YAML.

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

[1.3.0]: https://github.com/kibotu/swift-ocr/compare/1.2.0...1.3.0
[1.2.0]: https://github.com/kibotu/swift-ocr/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/kibotu/swift-ocr/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/kibotu/swift-ocr/releases/tag/1.0.0
