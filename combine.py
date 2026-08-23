#!/usr/bin/env python3
"""Combine OCR'd question .md files into one markdown, sorted by question number."""
import re
from pathlib import Path

files = []
for f in Path('.').glob('*.md'):
    if f.name == 'combined.md':
        continue
    text = f.read_text()
    m = re.search(r'(\d+)\s*/\s*24', text)
    if not m:
        print(f'SKIP (no question number): {f.name}')
        continue
    start = text.find('Most like you')
    end = text.find('Least like you', start)
    answers = [ln.strip() for ln in text[start + len('Most like you'):end].splitlines()
               if ln.strip() and not ln.strip().isdigit() and ln.strip() != '=']
    files.append((int(m.group(1)), answers))

out = []
for num, answers in sorted(files):
    out.append(f'## Question {num}/24\n')
    out.append('Most like you\n')
    out += [f'{i}. {a}' for i, a in enumerate(answers[:4], 1)]
    out.append('Least like you\n')

Path('combined.md').write_text('\n'.join(out) + '\n')
print(f'Combined {len(files)} questions -> combined.md')
for num, answers in sorted(files):
    print(num, len(answers), 'answers')
