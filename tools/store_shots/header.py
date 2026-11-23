"""App Store ürün sayfası başlığı (Header) ve arama sonucu (Search Results) görselleri.

Kullanım: python3 tools/store_shots/header.py <çıktı-klasör>

Apple ölçüleri (creative assets, iOS 27+):
  header:  3840x1646 (21:9), güvenli alan 1646x661 @ (1097, 493)
  search:  3840x2560 (3:2),  güvenli alan 2168x1030 @ (836, 765)
Ana öğeler (logo karoları + kısa ifade) güvenli alanda; kenarlardaki bulmaca parçaları süs ve
yönlere göre kırpılabilir. Fiyat, indirim, ödül iddiası, URL ve başka platform logosu yok.
"""
import os
import pathlib
import sys
import tempfile

from PIL import Image
from playwright.sync_api import sync_playwright

ASSETS = {
    "header": dict(W=3840, H=1646, safe=(1097, 493, 1646, 661), tile=150, phrase=78),
    "search": dict(W=3840, H=2560, safe=(836, 765, 2168, 1030), tile=214, phrase=116),
}
WORD = "ÇENGELİSH"
PHRASE = "Kalemle çöz, <em>İngilizce</em> öğren"

# Kenar süsleri: uygulamadaki ızgaradan parçalar. (tür, metin) — tür: clue | ink | print | empty
LEFT = [
    [("clue", "Sıcak ▸"), ("ink", "H"), ("ink", "O"), ("ink", "T")],
    [("empty", ""), ("print", "E"), ("empty", ""), ("clue", "Nasıl? ▾")],
    [("clue", "Duymak ▸"), ("print", "H"), ("print", "E"), ("print", "A")],
]
RIGHT = [
    [("print", "B"), ("clue", "On ▸"), ("print", "T"), ("print", "E")],
    [("print", "I"), ("empty", ""), ("ink", "O"), ("empty", "")],
    [("print", "G"), ("clue", "Avukat ▸"), ("ink", "W"), ("ink", "A")],
]


# Uygulamadaki kalem yazısı gibi el çizimi harfler (100x100 kutuda SVG vuruşları; font yok).
STROKES = {
    "H": "M27 16 L26 84 M73 15 L74 85 M25 51 L75 49",
    "O": "M52 15 C28 14 20 38 22 55 C24 76 40 86 55 84 C74 81 80 60 78 44 C76 26 64 15 50 16",
    "T": "M17 19 L83 17 M50 18 L51 86",
    "W": "M14 18 L31 83 L50 37 L68 83 L86 17",
    "A": "M17 86 L50 14 L83 86 M30 60 L70 60",
}


def ink(letter):
    return (f'<svg viewBox="0 0 100 100" width="62%" height="62%"><path d="{STROKES[letter]}" '
            'fill="none" stroke="#3B2BB8" stroke-width="6" stroke-linecap="round" '
            'stroke-linejoin="round"/></svg>')


def grid(rows, x, y, cell, rot):
    out = []
    for r, row in enumerate(rows):
        for c, (kind, text) in enumerate(row):
            out.append(
                f'<div class="cell {kind}" style="left:{x + c * (cell + 14)}px;top:{y + r * (cell + 14)}px;'
                f'width:{cell}px;height:{cell}px;font-size:{int(cell * (0.2 if kind == "clue" else 0.6))}px">'
                f"{ink(text) if kind == 'ink' else text}</div>")
    return f'<div class="grid" style="transform:rotate({rot}deg)">{"".join(out)}</div>'


def page(a):
    W, H = a["W"], a["H"]
    sx, sy, sw, sh = a["safe"]
    t = a["tile"]
    tiles = "".join(f"<span>{ch}</span>" for ch in WORD)
    # Yan ızgaralar güvenli alanın dışındaki kenar boşluklarına ortalanır (süs; kırpılabilir).
    cell = min(int(t * 1.05), int(sx * .78 / 4) - 14)
    gw, gh = 4 * cell + 3 * 14, 3 * cell + 2 * 14
    gy = int(H * .5 - gh / 2)
    left = grid(LEFT, int(sx / 2 - gw / 2), gy, cell, -8)
    right = grid(RIGHT, int(sx + sw + (W - sx - sw) / 2 - gw / 2), gy, cell, 7)
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
@font-face {{ font-family: R; src: url(file:///System/Library/Fonts/SFNSRounded.ttf); }}
* {{ margin: 0; box-sizing: border-box; }}
html, body {{ width: {W}px; height: {H}px; overflow: hidden; }}
body {{ font-family: R, -apple-system, sans-serif; position: relative;
  background: linear-gradient(115deg, #FFB547 0%, #FF7A6B 30%, #EC5FA8 58%, #8E5FE0 82%, #5B4FD6 100%); }}
body::before {{ content: ""; position: absolute; inset: 0;
  background: radial-gradient({int(W * .45)}px {int(H * .55)}px at 50% 48%, rgba(255,255,255,.30), transparent 70%); }}
.lines {{ position: absolute; inset: 0; opacity: .12;
  background-image: linear-gradient(#fff 4px, transparent 4px), linear-gradient(90deg, #fff 4px, transparent 4px);
  background-size: {cell + 14}px {cell + 14}px; }}
.center {{ position: absolute; left: {sx}px; top: {sy}px; width: {sw}px; height: {sh}px;
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: {int(t * .32)}px; }}
.tiles {{ display: flex; gap: {int(t * .1)}px; }}
.tiles span {{ width: {t}px; height: {int(t * 1.1)}px; border-radius: {int(t * .24)}px; background: #fff; color: #5B4FD6;
  display: grid; place-items: center; font-weight: 900; font-size: {int(t * .68)}px;
  box-shadow: 0 {int(t * .07)}px 0 rgba(70,40,160,.25), 0 {int(t * .14)}px {int(t * .3)}px rgba(50,20,120,.30); }}
.tiles span:nth-child(odd) {{ transform: translateY(-{int(t * .04)}px) rotate(-3deg); }}
.tiles span:nth-child(even) {{ transform: translateY({int(t * .04)}px) rotate(3deg); }}
.tiles span:first-child {{ background: #5B4FD6; color: #fff; }}
p {{ color: #fff; font-weight: 800; font-size: {a["phrase"]}px; letter-spacing: -1px;
  text-shadow: 0 6px 30px rgba(60,20,120,.3); }}
p em {{ font-style: normal; color: #FFE27A; }}
.grid {{ position: absolute; inset: 0; transform-origin: center; }}
.cell {{ position: absolute; border-radius: 22%; display: grid; place-items: center; font-weight: 900;
  box-shadow: 0 10px 28px rgba(40,10,100,.25); }}
.cell.print {{ background: #FFFDF8; color: #FF6B2C; }}
.cell.ink {{ background: #FFF3C4; }}
.cell.empty {{ background: #FFFDF8; }}
.cell.clue {{ background: #E9E4FF; color: #3B2BB8; font-weight: 800; text-align: center; padding: 8px; }}
</style></head><body><div class="lines"></div>{left}{right}
<div class="center"><div class="tiles">{tiles}</div><p>{PHRASE}</p></div>
</body></html>"""


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp, sync_playwright() as pw:
        browser = pw.chromium.launch(executable_path=os.environ.get("STORE_CHROMIUM") or None)
        for name, a in ASSETS.items():
            html = pathlib.Path(tmp, f"{name}.html")
            html.write_text(page(a), encoding="utf-8")
            tab = browser.new_page(viewport={"width": a["W"], "height": a["H"]}, device_scale_factor=1)
            tab.goto(html.as_uri())
            tab.evaluate("document.fonts.ready")
            png = pathlib.Path(out, f"{name}-{a['W']}x{a['H']}.png")
            tab.screenshot(path=str(png))
            Image.open(png).convert("RGB").save(png)  # alfa kanalı olmamalı
            tab.close()
            print(png)
        browser.close()


if __name__ == "__main__":
    main()
