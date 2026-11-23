#!/usr/bin/env python3
"""Yeni kelime (.psv) ve etiket (retag .txt) dosyalarını words.psv'ye göre doğrular.

Kullanım: python3 validate_new.py new/theme_x.psv [new/retag_x.txt]
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
LEVELS = {"A1", "A2", "B1", "B2", "C1"}
POS = {"noun", "verb", "adj", "adv", "prep", "conj", "pron", "phrase", "det", "num", "interj"}

existing = {}
for raw in (HERE / "words.psv").read_text(encoding="utf-8").splitlines():
    if raw.strip() and not raw.startswith("#"):
        existing[raw.split("|")[0].lower()] = raw

errors, seen, count = [], set(), 0
for path in sys.argv[1:]:
    for n, raw in enumerate(Path(path).read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip() or raw.startswith("#"):
            continue
        where = f"{path}:{n}"
        if path.endswith(".txt"):
            en, _, tag = raw.partition("|")
            if en.lower() not in existing:
                errors.append(f"{where} retag: '{en}' words.psv'de yok")
            elif not tag.strip():
                errors.append(f"{where} retag: etiket boş")
            count += 1
            continue
        parts = raw.split("|")
        if len(parts) != 10:
            errors.append(f"{where} 10 alan olmalı ({len(parts)})")
            continue
        en, level, pos, clue, meaning, ipa, ipa_uk, ex, ex_tr, tags = parts
        key = en.lower()
        if not (en.isalpha() and en.isascii()):
            errors.append(f"{where} cevap yalnızca A-Z: {en}")
        if not 3 <= len(en) <= 7:
            errors.append(f"{where} cevap 3-7 harf olmalı: {en}")
        if key in existing:
            errors.append(f"{where} words.psv'de zaten var: {en}")
        if key in seen:
            errors.append(f"{where} dosyada tekrar: {en}")
        seen.add(key)
        if level not in LEVELS:
            errors.append(f"{where} seviye: {level}")
        if pos not in POS:
            errors.append(f"{where} tür: {pos}")
        if not clue or len(clue) > 16:
            errors.append(f"{where} ipucu 1-16 karakter: '{clue}' ({len(clue)})")
        if key in clue.lower():
            errors.append(f"{where} ipucu cevabı ele veriyor: {clue}")
        for name, value in (("ipa", ipa), ("ipa_uk", ipa_uk)):
            if not (value.startswith("/") and value.endswith("/") and len(value) > 2):
                errors.append(f"{where} {name} /.../ biçiminde olmalı: {value}")
        if not ex or not ex_tr or not meaning:
            errors.append(f"{where} anlam/örnek boş")
        if not tags:
            errors.append(f"{where} etiket boş")
        count += 1

print("\n".join(errors) if errors else f"OK ({count} satır)")
sys.exit(1 if errors else 0)
