#!/usr/bin/env python3
"""new/ altındaki tema dosyalarını words.psv'ye katar.

- new/theme_*.psv: yeni kelimeler sona eklenir (words.psv'de ya da önceki dosyalarda olan atlanır).
- new/retag_*.txt: `en|etiket` satırları mevcut kelimenin etiketlerine eklenir.

Kullanım: python3 merge_new.py new/theme_a.psv new/retag_a.txt ...
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
path = HERE / "words.psv"
lines = path.read_text(encoding="utf-8").splitlines()
index = {l.split("|")[0].lower(): i for i, l in enumerate(lines) if l.strip() and not l.startswith("#")}

added = skipped = retagged = 0
for name in sys.argv[1:]:
    if not name.endswith(".psv"):
        continue
    for raw in Path(name).read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.startswith("#"):
            continue
        key = raw.split("|")[0].lower()
        if key in index:
            skipped += 1
            continue
        index[key] = len(lines)
        lines.append(raw)
        added += 1

for name in sys.argv[1:]:
    if not name.endswith(".txt"):
        continue
    for raw in Path(name).read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.startswith("#"):
            continue
        en, _, tag = raw.partition("|")
        i = index.get(en.lower())
        if i is None:
            continue
        parts = lines[i].split("|")
        tags = [t for t in parts[9].split(",") if t]
        if tag.strip() not in tags:
            tags.append(tag.strip())
            parts[9] = ",".join(tags)
            lines[i] = "|".join(parts)
            retagged += 1

path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"{added} kelime eklendi, {skipped} tekrar atlandı, {retagged} etiket eklendi")
