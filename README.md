# swift-ocr

[![Build](https://github.com/kibotu/swift-ocr/actions/workflows/build.yml/badge.svg)](https://github.com/kibotu/swift-ocr/actions/workflows/build.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

PDF → PNG → Markdown, entirely on your Mac. No cloud API, no Python stack, no third-party OCR.
One binary, three subcommands, zero data leaving the machine.

## Why

I had stacks of scanned documents — tax letters, invoices, handouts — and every solution
on offer wanted to upload them somewhere. Your Mac already ships a first-class OCR engine
([Vision](https://developer.apple.com/documentation/vision)) and a PDF renderer
([CoreGraphics](https://developer.apple.com/documentation/coregraphics)). This tool just
wires them together in a batch pipeline and gets out of the way.

Compared to the usual suspects:

| Alternative | The catch |
|-------------|-----------|
| Cloud OCR (Google Vision, AWS Textract, Azure) | Your tax letters and invoices leave your machine. API keys, SDKs, and a bill that scales with every page. |
| Tesseract / OCRmyPDF | A Homebrew dependency dance with language packs, and noticeably worse accuracy on receipts and low-quality scans out of the box. |
| Python OCR stacks (pytesseract, EasyOCR) | pip environments plus native dependencies just to run one batch job on your own files. |
| Apple Vision | Already installed, accurate, free, offline, handles 20+ languages — but it only speaks Swift. |

swift-ocr is the CLI wrapper Vision was missing: no Homebrew formulas, no models to
download, no account to create — install it with Mint or a plain `swift build`. The
honest trade-offs: macOS only (Vision is an Apple framework), and recognition quality
is whatever Apple shipped — you can't fine-tune it, which for scanned documents is
rarely a problem.

The whole thing fits in your head:

| Stage | What it does |
|-------|--------------|
| `pdf2png` | Renders every page of each PDF to a PNG at 2× scale (~144 dpi) via CoreGraphics |
| `ocr` | Feeds each image through `VNRecognizeTextRequest` (accurate, language-corrected) and writes `<name>.md` next to it |
| `combine` | Merges question-style Markdown files into one sorted `combined.md` |

Single-page PDFs keep their base name (`letter.pdf` → `letter.png`); multi-page ones get
a page suffix (`handout.pdf` → `handout_p1.png`, `handout_p2.png`, …).

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

Each subcommand takes a folder argument and defaults to the current directory.

Typical end-to-end run over a folder of scans:

```bash
swift-ocr pdf2png ~/Documents/scans
swift-ocr ocr ~/Documents/scans
swift-ocr combine ~/Documents/scans   # optional, for questionnaire-style documents
```

Options:

```bash
swift-ocr pdf2png --scale 3 ~/Documents/scans   # higher resolution for small print
swift-ocr --help                                # everything else
```

Output lands next to the input: `letter.pdf` → `letter_p1.png` → `letter_p1.md`.
Warnings go to stderr; stdout stays clean for scripting.

## Requirements

- **macOS 13+** — Vision text recognition and Swift Concurrency
- **Xcode 15+** or matching command line tools — `xcode-select --install`

There are no other dependencies beyond [swift-argument-parser](https://github.com/apple/swift-argument-parser),
and nothing ever leaves your machine.

## Development

```bash
swift build       # debug build
swift test        # unit tests (parser, renderer, output format)
swift run swift-ocr --help
```

CI builds, tests, and smoke-runs the CLI on a macOS runner for every push and PR.

## Design notes

- Rendering goes straight through `CGContext` → `CGImageDestination`. No AppKit image
  objects, no TIFF round-trip, no deprecated APIs. Pages are composited onto an opaque
  white backdrop because OCR wants dark-on-light and PDFs may paint nothing at all.
- Images load through ImageIO (`CGImageSource`) rather than `NSImage` for the same reason.
- `combine` parses a `N / M` heading plus the answer block between *Most like you* /
  *Least like you* markers, drops noise lines (blanks, bare digits, `=`), caps four
  answers per question, and reproduces the original script's output byte-for-byte.
  It exists because I had twenty-four personality-question scans; delete it if you don't.

## Contributing

PRs welcome. Keep it small, keep it dependency-free, keep it on-device.

## Support

If swift-ocr saved you a few hours gluing together an OCR stack — or kept your scanned
documents off someone else's servers — consider [buying me a coffee](https://buymeacoffee.com/kibotu).

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
