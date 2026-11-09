#!/usr/bin/env python3
"""Çengelish içerik üretici.

words.psv kelime havuzundan seviye paketleri ve günlük bulmacalar üretir.

Izgara düzeni (çengel / İsveç tipi):
  - 0. satırın tek sütunları aşağı (↓) ipucu kutusu, 0. sütunun tek satırları sağa (→) ipucu kutusu.
  - Tek satır × tek sütun kesişimleri iki kelimeye de aittir.
  - Bir satır/sütun çift konumda bölünebilir (araya ipucu kutusu) ya da kısaltılabilir (blok).

Çıktılar:
  - ../../Cengelish/AppCore/ContentKit/Sources/Resources/starter.json  (uygulamaya gömülü)
  - out/firestore/*.json ve out/storage/packs/*.json.gz (Firebase'e yükleme için)

Kullanım: python3 generate.py [--seed 7] [--start 2026-11-09] [--days 30]
"""
from __future__ import annotations

import argparse
import datetime as dt
import gzip
import json
import random
from dataclasses import dataclass, field
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP_RESOURCES = HERE.parent.parent / "Cengelish/AppCore/ContentKit/Sources/Resources"
OUT = HERE / "out"
LEVELS = ["A1", "A2", "B1", "B2", "C1"]
CONTENT_VERSION = 1


# MARK: - Word bank


@dataclass(frozen=True)
class Word:
    en: str
    level: str
    pos: str
    clue: str
    meaning: str
    ipa: str
    example: str
    tags: tuple[str, ...]

    @property
    def answer(self) -> str:
        return self.en.upper()

    @property
    def wid(self) -> str:
        return "w_" + self.en.lower()


def load_words() -> list[Word]:
    words: list[Word] = []
    seen: set[str] = set()
    for raw in (HERE / "words.psv").read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.startswith("#"):
            continue
        parts = raw.split("|")
        if len(parts) != 8:
            raise SystemExit(f"Bozuk satır: {raw}")
        en, level, pos, clue, meaning, ipa, example, tags = parts
        if not en.isalpha() or not en.isascii():
            raise SystemExit(f"Cevap sadece A-Z olmalı: {en}")
        if en.lower() in seen:
            raise SystemExit(f"Tekrar eden kelime: {en}")
        seen.add(en.lower())
        words.append(
            Word(en, level, pos, clue, meaning, ipa, example, tuple(t for t in tags.split(",") if t))
        )
    return words


# MARK: - Template


@dataclass
class Slot:
    clue_cell: tuple[int, int]
    direction: str  # "across" | "down"
    cells: list[tuple[int, int]]


@dataclass
class Template:
    width: int
    height: int
    slots: list[Slot] = field(default_factory=list)


def segments(
    length: int, rng: random.Random, prefer_long: bool, lengths: dict[int, int]
) -> list[tuple[int, int, str]]:
    """Bir satır/sütun için kelime parçalarını (başlangıç, uzunluk, tür) seçer.

    0..length-1 indeksli bir hat. Her parçanın önündeki hücre (başlangıç-1) çift indeksli bir
    ipucu kutusu, arkasındaki hücre ise çift indeksli bir kutu ya da hat sonudur.
    """
    options: list[list[tuple[int, int, str]]] = []

    def walk(pos: int, acc: list[tuple[int, int, str]]) -> None:
        # pos: bir sonraki parçanın ipucu kutusunun olabileceği en erken çift indeks
        if acc:
            options.append(list(acc))
        for clue in range(pos, length - 1, 2):
            start = clue + 1
            for end in range(start + 2, length):
                if end + 1 != length and (end + 1) % 2 != 0:
                    continue
                ln = end - start + 1
                if ln < 3 or lengths.get(ln, 0) < 12:
                    continue
                acc.append((start, ln, "seg"))
                walk(end + 1, acc)
                acc.pop()

    walk(0, [])
    if not options:
        return []
    weights = [
        (sum(ln for _, ln, _ in o) ** (2 if prefer_long else 1.4)) / (1 + 0.6 * (len(o) - 1))
        for o in options
    ]
    return rng.choices(options, weights=weights)[0]


def build_template(
    width: int, height: int, rng: random.Random, prefer_long: bool, lengths: dict[int, int]
) -> Template:
    t = Template(width, height)
    for r in range(1, height, 2):
        for start, ln, _ in segments(width, rng, prefer_long, lengths):
            t.slots.append(Slot((r, start - 1), "across", [(r, c) for c in range(start, start + ln)]))
    for c in range(1, width, 2):
        for start, ln, _ in segments(height, rng, prefer_long, lengths):
            t.slots.append(Slot((start - 1, c), "down", [(r, c) for r in range(start, start + ln)]))
    return t


def template_is_valid(t: Template) -> bool:
    clue_cells = {s.clue_cell for s in t.slots}
    letters = [cell for s in t.slots for cell in s.cells]
    if clue_cells & set(letters):
        return False
    if len(clue_cells) != len(t.slots):
        return False
    covered = set(letters)
    # Her tek×tek kesişim hücresi en az bir kelimede olmalı; aksi hâlde ızgara çok boş kalır.
    holes = sum(
        1 for r in range(1, t.height, 2) for c in range(1, t.width, 2) if (r, c) not in covered
    )
    return 6 <= len(t.slots) <= 14 and holes <= 1


# MARK: - Filling


class Filler:
    def __init__(self, pool: list[Word], usage: dict[str, int], rng: random.Random):
        self.rng = rng
        self.usage = usage
        self.by_len: dict[int, list[Word]] = {}
        for w in pool:
            self.by_len.setdefault(len(w.answer), []).append(w)
        self.nodes = 0

    def candidates(self, slot: Slot, grid: dict, used: set[str]) -> list[Word]:
        pattern = [grid.get(cell) for cell in slot.cells]
        out = []
        for w in self.by_len.get(len(slot.cells), []):
            if w.answer in used:
                continue
            if all(p is None or p == ch for p, ch in zip(pattern, w.answer)):
                out.append(w)
        self.rng.shuffle(out)
        out.sort(key=lambda w: self.usage.get(w.en, 0))
        return out

    def fill(self, t: Template) -> dict[int, Word] | None:
        self.nodes = 0
        assignment: dict[int, Word] = {}
        grid: dict[tuple[int, int], str] = {}
        return assignment if self._solve(t, assignment, grid, set()) else None

    def _solve(self, t: Template, assignment, grid, used) -> bool:
        self.nodes += 1
        if self.nodes > 4000:
            return False
        open_slots = [i for i in range(len(t.slots)) if i not in assignment]
        if not open_slots:
            return True
        best, best_cands = None, None
        for i in open_slots:
            cands = self.candidates(t.slots[i], grid, used)
            if not cands:
                return False
            if best_cands is None or len(cands) < len(best_cands):
                best, best_cands = i, cands
        slot = t.slots[best]
        for w in best_cands[:25]:
            placed = []
            for cell, ch in zip(slot.cells, w.answer):
                if cell not in grid:
                    grid[cell] = ch
                    placed.append(cell)
            assignment[best] = w
            used.add(w.answer)
            if self._solve(t, assignment, grid, used):
                return True
            del assignment[best]
            used.discard(w.answer)
            for cell in placed:
                del grid[cell]
        return False


def make_puzzle(pid, pack_id, level, kind, size, pool, usage, rng, prefer_long) -> dict:
    width, height = size
    filler = Filler(pool, usage, rng)
    lengths = {n: len(ws) for n, ws in filler.by_len.items()}
    for _ in range(3000):
        t = build_template(width, height, rng, prefer_long, lengths)
        if not template_is_valid(t):
            continue
        result = filler.fill(t)
        if result is None:
            continue
        entries = []
        for i, slot in enumerate(t.slots):
            w = result[i]
            usage[w.en] = usage.get(w.en, 0) + 1
            r, c = slot.cells[0]
            entries.append(
                {
                    "wordId": w.wid,
                    "answer": w.answer,
                    "clue": w.clue,
                    "row": r,
                    "col": c,
                    "dir": slot.direction,
                    "clueRow": slot.clue_cell[0],
                    "clueCol": slot.clue_cell[1],
                }
            )
        entries.sort(key=lambda e: (e["dir"] != "across", e["clueRow"], e["clueCol"]))
        return {
            "id": pid,
            "packId": pack_id,
            "kind": kind,
            "level": level,
            "width": width,
            "height": height,
            "entries": entries,
            "version": 1,
        }
    raise SystemExit(f"{pid} üretilemedi; havuzu büyütün.")


# MARK: - Packs

PACKS = [
    # id, başlık, alt başlık, tür, seviye, adet, ücretsiz adet, boyut, ürün kimliği
    ("a1", "A1 · Başlangıç", "Renkler, sayılar, aile, ev", "level", "A1", 12, 8, (7, 7), None),
    ("a2", "A2 · Temel", "Günlük hayat, seyahat, hava", "level", "A2", 12, 6, (7, 9), None),
    ("b1", "B1 · Orta", "Duygular, iş, toplum", "level", "B1", 12, 0, (7, 9), None),
    ("b2", "B2 · İleri-orta", "Soyut kavramlar, sınav kelimeleri", "level", "B2", 10, 0, (7, 9), None),
    ("yds", "YDS Kelime Paketi", "YDS'de sık çıkan akademik kelimeler", "exam", "C1", 10, 0, (7, 9),
     "com.hasangurbuz.cengelish.pack.yds"),
]


def pool_for(level: str, words: list[Word], exam_tag: str | None = None) -> list[Word]:
    idx = LEVELS.index(level)
    main = [w for w in words if w.level == level and (exam_tag is None or exam_tag in w.tags)]
    lower = [w for w in words if LEVELS.index(w.level) == idx - 1]
    # Ana seviye kelimeleri öne, bir alt seviye dolgu olarak.
    return main + lower


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--start", default="2026-11-09")
    ap.add_argument("--days", type=int, default=30)
    args = ap.parse_args()
    rng = random.Random(args.seed)
    words = load_words()
    usage: dict[str, int] = {}

    packs, puzzles = [], []
    for order, (pid, title, subtitle, kind, level, count, free, size, product) in enumerate(PACKS):
        pool = pool_for(level, words, "yds" if pid == "yds" else None)
        ids = []
        for n in range(1, count + 1):
            pz = make_puzzle(
                f"{pid}_{n:02d}", pid, level, "pack", size, pool, usage, rng, prefer_long=level != "A1"
            )
            puzzles.append(pz)
            ids.append(pz["id"])
        packs.append(
            {
                "id": pid,
                "title": title,
                "subtitle": subtitle,
                "kind": kind,
                "level": level,
                "order": order,
                "freeCount": free,
                "productId": product,
                "puzzleIds": ids,
                "wordCount": len({e["wordId"] for p in puzzles if p["packId"] == pid for e in p["entries"]}),
            }
        )

    dailies = []
    start = dt.date.fromisoformat(args.start)
    daily_pool = pool_for("A2", words) + [w for w in words if w.level == "B1"]
    for d in range(args.days):
        day = start + dt.timedelta(days=d)
        pz = make_puzzle(
            f"daily_{day.isoformat()}", None, "B1" if d % 2 else "A2", "daily", (7, 9),
            daily_pool, usage, rng, prefer_long=True,
        )
        puzzles.append(pz)
        dailies.append({"date": day.isoformat(), "puzzleId": pz["id"]})

    used_ids = {e["wordId"] for p in puzzles for e in p["entries"]}
    word_json = [
        {
            "id": w.wid,
            "en": w.en,
            "level": w.level,
            "pos": w.pos,
            "clue": w.clue,
            "meaning": w.meaning,
            "ipa": w.ipa,
            "example": w.example,
            "tags": list(w.tags),
        }
        for w in words
        if w.wid in used_ids
    ]

    bundle = {
        "version": CONTENT_VERSION,
        "generatedAt": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "words": word_json,
        "packs": packs,
        "puzzles": puzzles,
        "dailies": dailies,
    }
    APP_RESOURCES.mkdir(parents=True, exist_ok=True)
    (APP_RESOURCES / "starter.json").write_text(
        json.dumps(bundle, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )

    # Firebase çıktıları: Firestore manifest + Storage paket dosyaları.
    fs = OUT / "firestore"
    st = OUT / "storage" / "packs"
    fs.mkdir(parents=True, exist_ok=True)
    st.mkdir(parents=True, exist_ok=True)
    word_by_id = {w["id"]: w for w in word_json}
    manifest = []
    for p in packs:
        pz = [x for x in puzzles if x["packId"] == p["id"]]
        wids = {e["wordId"] for x in pz for e in x["entries"]}
        payload = {"pack": p, "puzzles": pz, "words": [word_by_id[i] for i in sorted(wids)]}
        path = f"packs/{p['id']}_v{CONTENT_VERSION}.json.gz"
        (OUT / "storage" / path).write_bytes(
            gzip.compress(json.dumps(payload, ensure_ascii=False).encode("utf-8"))
        )
        manifest.append({**p, "contentPath": path, "contentVersion": CONTENT_VERSION})
    (fs / "packs.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8")
    daily_docs = []
    for d in dailies:
        pz = next(x for x in puzzles if x["id"] == d["puzzleId"])
        wids = {e["wordId"] for e in pz["entries"]}
        daily_docs.append({**d, "puzzle": pz, "words": [word_by_id[i] for i in sorted(wids)]})
    (fs / "dailies.json").write_text(json.dumps(daily_docs, ensure_ascii=False, indent=1), encoding="utf-8")

    size_kb = (APP_RESOURCES / "starter.json").stat().st_size / 1024
    print(f"{len(puzzles)} bulmaca, {len(word_json)}/{len(words)} kelime kullanıldı, starter.json {size_kb:.0f} KB")
    for p in packs:
        print(f"  {p['id']}: {len(p['puzzleIds'])} bulmaca, {p['wordCount']} kelime")


if __name__ == "__main__":
    main()
