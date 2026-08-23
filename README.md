# swift-ocr

[![Build](https://github.com/kibotu/swift-ocr/actions/workflows/build.yml/badge.svg)](https://github.com/kibotu/swift-ocr/actions/workflows/build.yml) [![GitHub Release](https://img.shields.io/github/v/release/kibotu/swift-ocr)](https://github.com/kibotu/swift-ocr/releases) [![Static Badge](https://img.shields.io/badge/macOS%2013%20-blue)](https://developer.apple.com/documentation/macos-release-notes)
[![Static Badge](https://img.shields.io/badge/Swift%206.0%20-%20orange)](https://www.swift.org/blog/announcing-swift-6/)

Batch-convert PDF scans to Markdown on your Mac. Apple Vision does the recognition,
CoreGraphics renders the pages, and nothing leaves your machine.

## Install

With [Mint](https://github.com/yonaskolb/Mint):

```bash
mint install kibotu/swift-ocr
```

From source:

```bash
git clone https://github.com/kibotu/swift-ocr.git
cd swift-ocr
swift build -c release
# binary at .build/release/swift-ocr
```

## Requirements

- **macOS 13+** — Vision text recognition and Swift Concurrency (`--documents` needs macOS 26+)
- **Xcode 15+** or matching command line tools — `xcode-select --install`

One dependency besides the system frameworks: [swift-argument-parser](https://github.com/apple/swift-argument-parser).

## Usage

```text
USAGE: swift-ocr <subcommand>

SUBCOMMANDS:
  convert   Render PDFs to PNGs and recognize text into Markdown (default)
  pdf2png   Render a PDF, or every PDF in a folder, to one PNG per page
  ocr       Recognize text in an image or each image of a folder, writing <name>.md
  pdf2pdf   Add an invisible OCR text layer to each PDF, making it searchable
  combine   Merge OCR'd Markdown files into one combined.md
```

Each subcommand accepts a folder or a single file. If you omit it, the tool
uses the current directory. The default `convert` runs everything: PDFs are
rendered to PNGs, then every image is recognized into `<name>.md`.

Convert all scans in a folder — one command:

```bash
swift-ocr ~/Documents/scans
```

Or step through the pipeline yourself:

```bash
swift-ocr pdf2png ~/Documents/scans
swift-ocr ocr ~/Documents/scans
swift-ocr combine ~/Documents/scans   # optional, see below
```

Options:

```bash
swift-ocr pdf2png --scale 3 ~/Documents/scans          # higher resolution for small print
swift-ocr ocr --lang de --lang fr ~/Documents/scans    # explicit recognition languages
swift-ocr ocr --meta --enhance ~/Documents/scans       # YAML front-matter, faint-scan boost
swift-ocr ocr --documents ~/Documents/scans            # native headings/lists/tables (macOS 26+)
swift-ocr pdf2pdf ~/Documents/scans                    # searchable PDFs: letter.pdf → letter.ocr.pdf
swift-ocr --help                                       # all options
```

Output files appear next to their inputs. A single-page PDF keeps its base name
(`letter.pdf` → `letter.png`); a multi-page PDF gets a suffix per page (`handout.pdf` →
`handout_p1.png`, `handout_p1.md`, …). Warnings go to stderr; stdout carries results
only, so scripts can parse it.

`combine` concatenates every `<name>.md` in a folder into one `combined.md`,
sorted by name — so `handout_p1.md`, `handout_p2.md`, … become a single
document, with pages separated by blank lines.

## Why

I needed a tool that converts scanned documents — tax letters, invoices, handouts — to
text. Most tools send these documents to a server first. macOS already includes an
accurate OCR engine and a PDF renderer; this tool connects them in one batch pipeline.

Comparison with other solutions:

| Alternative | Disadvantages |
|-------------|---------------|
| Cloud OCR (Google Vision, AWS Textract, Azure) | Documents go to another company's servers. You need API keys and SDKs. Cost increases with each page. |
| Tesseract / OCRmyPDF | Installation needs Homebrew formulas and language packs. Accuracy on receipts and low-quality scans is lower than Vision. |
| Python OCR tools (pytesseract, EasyOCR) | Setup needs pip environments and native libraries before you can process one folder. |
| Apple Vision | Already installed, accurate, free, offline, supports many languages — but it gives you no command-line tool. |

Limitations: this tool runs on macOS only, because Vision is an Apple framework.
Recognition quality depends on Apple's models, and you cannot fine-tune them. For
scanned documents, this is rarely a problem.

## Design notes

- Rendering writes directly from `CGContext` to `CGImageDestination`: no AppKit image
  objects, no TIFF conversion, no deprecated APIs. Each page gets an opaque white
  background, because OCR needs dark text on a light surface.
- Images load through ImageIO (`CGImageSource`), not `NSImage`.
- `pdf2pdf` draws recognized lines with invisible text over the page image — the
  visible surface stays the scan, while Preview, Spotlight and Acrobat can search it.
- `ocr` reconstructs paragraphs and headings from line bounding boxes; on macOS 26+
  `--documents` hands the job to Apple's document recognizer instead.
- `combine` joins every page's Markdown into one `combined.md`, sorted by name.
- Notable changes are tracked in [CHANGELOG.md](CHANGELOG.md) (Keep a Changelog).

## Development

```bash
swift build                 # debug build
swift test                  # unit tests: parser, renderer, output format
swift run swift-ocr --help
```

CI builds the package, runs the tests, and starts the CLI on a macOS runner for every
push and pull request.

## Contributing

Pull requests are welcome. Keep changes small. Do not add dependencies. Keep all
processing local.

## Support

Did swift-ocr save some time? Did your scanned documents stay on your
machine? Then please consider [buying me a coffee](https://buymeacoffee.com/kibotu).

## License

```
Copyright 2026 Jan Rabe

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
