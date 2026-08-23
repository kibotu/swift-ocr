# swift-ocr

[![Build](https://github.com/kibotu/swift-ocr/actions/workflows/build.yml/badge.svg)](https://github.com/kibotu/swift-ocr/actions/workflows/build.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Zero-dependency PDF → PNG → Markdown pipeline for macOS. Render every page of every PDF in a folder, run Apple's Vision framework over the images, and collect the results as plain Markdown — no Python OCR stack, no cloud API, no third-party packages.

## Intro

This project started as a way to digitize stacks of scanned documents (tax letters, invoices, handouts) with nothing but the tools already on a Mac. Two small Swift scripts do all the work:

1. **`pdf2png.swift`** renders every page of each `.pdf` in a folder to a `.png` at 2× scale (~144 dpi) using CoreGraphics.
2. **`ocr.swift`** feeds every `.png` through `VNRecognizeTextRequest` (accurate mode) and writes the recognized text next to the image as a `.md` file.

A tiny helper, **`combine.py`**, can merge multiple OCR'd Markdown files into one document sorted by question number.

Everything is a self-contained script — read it in a minute, change it in two.

## Features

- 📄 **Batch PDF rendering** — every page of every PDF in a folder, single-page PDFs keep their base name, multi-page ones get a `_p<N>` suffix
- 🔍 **On-device OCR** — Apple Vision framework, `.accurate` recognition level, no data leaves your machine
- ✍️ **Markdown output** — one `.md` per image, same base name, ready for notes apps and version control
- 🧩 **Composable** — pass any folder as an argument, or none to use the current directory
- 📦 **Zero dependencies** — Foundation, CoreGraphics, AppKit, Vision; ships with macOS
- 🤖 **CI-ready** — GitHub Action builds both Swift sources on a macOS runner

## Requirements

- **macOS** 12+ (Vision text recognition)
- **Xcode command line tools**: `xcode-select --install` (provides `swiftc`)
- **Python 3** — only needed for `combine.py`

## How to Run

Clone and go — the scripts are interpreted via their shebang or compiled up front:

```bash
git clone https://github.com/kibotu/swift-ocr.git
cd swift-ocr

# Run directly (shebang)
./pdf2png.swift path/to/pdfs
./ocr.swift path/to/pngs

# Or compile first
swiftc -O -o pdf2png pdf2png.swift
swiftc -O -o ocr ocr.swift
./pdf2png ~/Documents/scans && ./ocr ~/Documents/scans
```

Typical end-to-end conversion of a folder of PDFs:

```bash
./pdf2png.swift taxes   # renders every page of each PDF to PNG
./ocr.swift taxes       # writes <name>.md next to each PNG
python3 combine.py      # optional: merge OCR'd files into combined.md
```

Output lands next to the input images: `letter.pdf` → `letter_p1.png`, `letter_p1.md`, …

### Make it executable once

```bash
chmod +x pdf2png.swift ocr.swift
```

## Project Layout

```
├── pdf2png.swift        # PDF → PNG renderer (CoreGraphics)
├── ocr.swift            # PNG → Markdown OCR (Apple Vision)
├── combine.py           # optional: merge OCR'd Markdown files
└── .github/workflows/
    └── build.yml        # compiles both Swift sources in CI
```

## Contributing

PRs are welcome. Keep scripts dependency-free and self-contained.

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
