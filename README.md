# swift-ocr

[![Build](https://github.com/kibotu/swift-ocr/actions/workflows/build.yml/badge.svg)](https://github.com/kibotu/swift-ocr/actions/workflows/build.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Convert PDF scans to Markdown files on your Mac. No cloud API. No Python. No third-party
OCR engine. One binary, three subcommands. Your documents do not leave your machine.

## Why

I needed a tool that converts scanned documents — tax letters, invoices, handouts — to
text. Most tools send these documents to a server first. macOS already includes an
accurate OCR engine ([Vision](https://developer.apple.com/documentation/vision)) and a
PDF renderer ([CoreGraphics](https://developer.apple.com/documentation/coregraphics)).
This tool connects them in one batch pipeline.

Comparison with other solutions:

| Alternative | Disadvantages |
|-------------|---------------|
| Cloud OCR (Google Vision, AWS Textract, Azure) | Documents go to another company's servers. You need API keys and SDKs. Cost increases with each page. |
| Tesseract / OCRmyPDF | Installation needs Homebrew formulas and language packs. Accuracy on receipts and low-quality scans is lower than Vision. |
| Python OCR tools (pytesseract, EasyOCR) | Setup needs pip environments and native libraries before you can process one folder. |
| Apple Vision | Already installed, accurate, free, offline, supports many languages — but it gives you no command-line tool. |

swift-ocr adds the missing command-line interface. No Homebrew formulas, no model
downloads, no account. Install it with Mint, or build it with Swift directly.
Limitations: the tool runs on macOS only, because Vision is an Apple framework.
Recognition quality depends on Apple's models, and you cannot fine-tune them. For
scanned documents, this is rarely a problem.

The pipeline has three stages:

| Stage | Operation |
|-------|-----------|
| `pdf2png` | Renders each PDF page to a PNG at 2× scale (~144 dpi) with CoreGraphics |
| `ocr` | Reads each image with Vision (`VNRecognizeTextRequest`, accurate mode, language correction) and writes `<name>.md` next to it |
| `combine` | Merges question-style Markdown files into one sorted `combined.md` |

File naming: a single-page PDF keeps its base name (`letter.pdf` → `letter.png`). A
multi-page PDF gets a suffix for each page (`handout.pdf` → `handout_p1.png`,
`handout_p2.png`).

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

## Usage

```text
USAGE: swift-ocr <subcommand>

SUBCOMMANDS:
  pdf2png   Render every page of each PDF in a folder to a PNG
  ocr       Recognize text in each image of a folder, writing <name>.md
  combine   Merge OCR'd Markdown files into one combined.md
```

Each subcommand accepts a folder argument. If you omit the folder, the tool uses the
current directory.

Example — convert all scans in a folder:

```bash
swift-ocr pdf2png ~/Documents/scans
swift-ocr ocr ~/Documents/scans
swift-ocr combine ~/Documents/scans   # optional, for questionnaire-style documents
```

Options:

```bash
swift-ocr pdf2png --scale 3 ~/Documents/scans   # higher resolution for small print
swift-ocr --help                                # all options
```

Output files appear next to the input files: `letter.pdf` → `letter_p1.png` →
`letter_p1.md`. Warnings go to stderr. stdout contains only results, so scripts can
parse it.

## Requirements

- **macOS 13+** — for Vision text recognition and Swift Concurrency
- **Xcode 15+** or matching command line tools — install with `xcode-select --install`

No other dependencies, except [swift-argument-parser](https://github.com/apple/swift-argument-parser).
All processing runs on your machine.

## Development

```bash
swift build                 # debug build
swift test                  # unit tests: parser, renderer, output format
swift run swift-ocr --help
```

CI builds the package, runs the tests, and starts the CLI on a macOS runner for every
push and pull request.

## Design notes

- Rendering writes directly from `CGContext` to `CGImageDestination`. The code uses no
  AppKit image objects, no TIFF conversion, and no deprecated APIs. Each page gets an
  opaque white background, because OCR needs dark text on a light surface.
- Images load through ImageIO (`CGImageSource`), not through `NSImage`.
- `combine` reads a `N / M` heading and the answer lines between the *Most like you* and
  *Least like you* markers. It removes noise lines (empty lines, numbers, `=`), keeps a
  maximum of four answers per question, and produces the same output as the original
  Python script. This subcommand exists because I had twenty-four personality-question
  scans. Remove it if you do not need it.

## Contributing

Pull requests are welcome. Keep changes small. Do not add dependencies. Keep all
processing local.

## Support

Did swift-ocr save you hours of setup work? Did your scanned documents stay on your
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
