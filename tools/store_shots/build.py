"""Çengelish mağaza ekran görüntüleri: panoramik marka gradyanı, harf karoları, cihaz çerçevesi.

Kullanım:
  python3 tools/store_shots/build.py <cihaz> <ham-klasör> <çıktı-klasör> [set]
    cihaz: iphone (1320x2868, 6,9") | ipad (2064x2752, 13") | duo (2853x2007, iPhone Duo iç ekran)
    set:   main (ürün sayfası, varsayılan) | cpp-yds | cpp-lgs | cpp-ielts (özel ürün sayfaları)

Ham görüntüler: Debug derlemeyi `-screenshotDemo` argümanıyla iPhone 17 Pro Max / iPad Pro 13"
simülatöründe açıp `xcrun simctl io <id> screenshot` ile çekilir. Dosya adları SLIDES'taki `shot`.
Kareler HTML olarak üretilir ve Playwright (Chromium) ile PNG'ye çevrilir; `STORE_CHROMIUM`
ile tarayıcı yolu verilebilir.

İnceleme kuralları (App Review 2.3): ekranlarda yalnızca gerçek uygulama görüntüsü; fiyat yok;
Plus gerektiren içerik ekranda PLUS rozetiyle görünür; Apple ürün görseli taklidi yok.
"""
import os
import pathlib
import sys
import tempfile

from PIL import Image
from playwright.sync_api import sync_playwright

# Splash ekranındaki marka gradyanı; karelere panorama olarak yayılır.
STOPS = ["#FFB547", "#FF8A5C", "#FF6F7D", "#EC5FA8", "#C062C8", "#8E5FE0", "#6C5CE7", "#5B4FD6"]

DEVICES = {
    "iphone": dict(W=1320, H=2868, u=1.0, frame_w=1010, pad=26, radius=168, inner=142, top=830,
                   chip_gap=130, island=True, prefix="iphone69"),
    "ipad": dict(W=2064, H=2752, u=1.32, frame_w=1720, pad=30, radius=96, inner=66, top=930,
                 chip_gap=175, island=False, prefix="ipad13"),
    # iPhone Duo açık iç ekran (yatay). ASC: 2853x2007.
    "duo": dict(W=2853, H=2007, u=1.0, frame_w=2010, pad=28, radius=72, inner=46, top=590,
                chip_gap=150, island=False, prefix="duo"),
}

SETS = {
    "main": {
        "iphone": [
            # Arama sonucunda video (poster: bulmaca) + ilk 2 kare görünür: üçü farklı vaat.
            dict(shot="explore_all", tiles="SINAV", title="paketleri hazır",
                 sub="YDS · YÖKDİL · LGS · IELTS · TOEFL", chip=("🎓", "Her sınav için 60 bulmaca")),
            dict(shot="home", title="Her gün\n<em>yeni</em> bir bulmaca",
                 sub="Serini koru, günün kelimesini öğren", chip=("🔥", "14 gün seri")),
            dict(shot="puzzle_hand", tiles="İNGİLİZCE", title="bulmacayla öğren",
                 sub="Türkçe ipucu, İngilizce cevap", chip=("✍️", "Kalemle yaz")),
            dict(shot="answerkey", title="Yaz, sonra\n<em>kendin</em> kontrol et",
                 sub="Cevap anahtarı her kelimeyi gösterir",
                 chip=("✓", "Doğru · yanlış senin elinde")),
            dict(shot="notebook", title="Bilemediğin\nkelime <em>deftere</em>",
                 sub="Tekrar ettikçe kalıcı öğren", chip=("📒", "Tekrar listen hazır")),
            dict(shot="profile", title="Rozet topla,\n<em>serini</em> büyüt",
                 sub="Hesap yok, verilerin cihazında", chip=("🏅", "15 rozet seni bekliyor")),
            dict(shot="paywall", tiles="ÖMÜR", title="boyu Plus",
                 sub="Abonelik yok · tek ödeme", chip=("👑", "Tüm sınav ve tema paketleri"),
                 top=1000),
        ],
        "ipad": [
            dict(shot="puzzle_hand", tiles="KALEMLE", title="yaz, <em>öğren</em>",
                 sub="Apple Pencil ile gerçek bulmaca hissi", chip=("✍️", "Apple Pencil desteği"),
                 pencil=(745, 2605)),
            dict(shot="answerkey", title="Yaz, sonra <em>kendin</em> kontrol et",
                 sub="Cevap anahtarı her kelimeyi gösterir",
                 chip=("✓", "Doğru · yanlış senin elinde")),
            dict(shot="explore_all", tiles="SINAV", title="paketleri hazır",
                 sub="YDS · YÖKDİL · LGS · IELTS · TOEFL", chip=("🎓", "Her sınav için 60 bulmaca")),
            dict(shot="home", title="Her gün <em>yeni</em>\nbir bulmaca",
                 sub="Serini koru, günün kelimesini öğren", chip=("🔥", "14 gün seri")),
            dict(shot="notebook", title="Bilemediğin kelime <em>deftere</em>",
                 sub="Tekrar ettikçe kalıcı öğren", chip=("📒", "Tekrar listen hazır")),
            dict(shot="profile", title="Rozet topla, <em>serini</em> büyüt",
                 sub="Hesap yok, verilerin cihazında", chip=("🏅", "15 rozet seni bekliyor")),
        ],
        "duo": [
            dict(shot="answerkey", title="Kalemle yaz, <em>kendin</em> kontrol et",
                 sub="Büyük ekranda gerçek bulmaca hissi", chip=("✍️", "El yazınla çöz")),
            dict(shot="explore_all", title="YDS · YÖKDİL · LGS · <em>IELTS · TOEFL</em>",
                 sub="Sınav ve tema paketleri, A1'den C1'e seviyeler",
                 chip=("🎓", "Her sınav için 60 bulmaca")),
            dict(shot="home", title="Her gün <em>yeni</em> bir bulmaca",
                 sub="Serini koru, günün kelimesini öğren", chip=("🔥", "14 gün seri")),
            dict(shot="notebook", title="Bilemediğin kelime <em>deftere</em>",
                 sub="Tekrar ettikçe kalıcı öğren", chip=("📒", "Tekrar listen hazır")),
            dict(shot="profile", title="Rozet topla, <em>serini</em> büyüt",
                 sub="Hesap yok, verilerin cihazında", chip=("🏅", "15 rozet seni bekliyor")),
        ],
    },
    # Özel ürün sayfaları (CPP): Search Ads reklam varyasyonları ve sınav anahtar kelimeleri için.
    "cpp-yds": {"iphone": [
        dict(shot="pack_yds", tiles="YDS", title="kelimelerini\n<em>bulmacayla</em> çalış",
             sub="280 akademik kelime · 60 bulmaca", chip=("🎓", "YDS ve YÖKDİL paketleri")),
        dict(shot="puzzle_hand", title="Türkçe ipucu,\n<em>İngilizce</em> cevap",
             sub="Kalemle yaz, kendin kontrol et", chip=("✍️", "Kalemle yaz")),
        dict(shot="notebook", title="Bilemediğin\nkelime <em>deftere</em>",
             sub="Sınav öncesi tekrar listen hazır", chip=("📒", "Aralıklı tekrar")),
        dict(shot="answerkey", title="Yaz, sonra\n<em>kendin</em> kontrol et",
             sub="Cevap anahtarı her kelimeyi gösterir", chip=("✓", "Doğru · yanlış senin elinde")),
        dict(shot="explore_all", tiles="5", title="sınav, tek uygulama",
             sub="YDS · YÖKDİL · LGS · IELTS · TOEFL", chip=("👑", "Tek paket ya da Plus")),
    ]},
    "cpp-lgs": {"iphone": [
        dict(shot="pack_lgs", tiles="LGS", title="İngilizcesine\n<em>hazırlan</em>",
             sub="8. sınıf müfredatından 291 kelime", chip=("🎓", "60 LGS bulmacası")),
        dict(shot="puzzle_hand", title="Oyun gibi\n<em>kelime</em> öğren",
             sub="Türkçe ipucu, İngilizce cevap", chip=("✍️", "Kalemle yaz")),
        dict(shot="home", title="Günde birkaç\n<em>dakika</em> yeter",
             sub="Günün bulmacasıyla alışkanlık kazan", chip=("🔥", "Seri tut")),
        dict(shot="answerkey", title="Yaz, sonra\n<em>kendin</em> kontrol et",
             sub="Cevap anahtarı her kelimeyi gösterir", chip=("✓", "Doğru · yanlış senin elinde")),
        dict(shot="profile", title="Rozet topla,\n<em>serini</em> büyüt",
             sub="Reklam yok, hesap yok", chip=("🏅", "15 rozet")),
    ]},
    "cpp-ielts": {"iphone": [
        dict(shot="pack_ielts", tiles="IELTS", title="ve <em>TOEFL</em> kelimeleri",
             sub="B1–C1 akademik ve günlük kelimeler", chip=("🎓", "Her sınav için 60 bulmaca")),
        dict(shot="puzzle_hand", title="Türkçe ipucu,\n<em>İngilizce</em> cevap",
             sub="Kalemle yaz, kendin kontrol et", chip=("✍️", "Kalemle yaz")),
        dict(shot="notebook", title="Bilemediğin\nkelime <em>deftere</em>",
             sub="Tekrar ettikçe kalıcı öğren", chip=("📒", "Aralıklı tekrar")),
        dict(shot="answerkey", title="Yaz, sonra\n<em>kendin</em> kontrol et",
             sub="Cevap anahtarı her kelimeyi gösterir", chip=("✓", "Doğru · yanlış senin elinde")),
        dict(shot="explore_all", tiles="5", title="sınav, tek uygulama",
             sub="YDS · YÖKDİL · LGS · IELTS · TOEFL", chip=("👑", "Tek paket ya da Plus")),
    ]},
}

# Kenarlara taşan süs karoları (harf, x oranı, y oranı, boyut, açı); ekran içeriğini kapatmaz.
FLOATS = [
    [("Ç", -.02, .81, 150, -12), ("E", .913, .715, 130, 10), ("N", .92, .89, 110, -6)],
    [("A", .905, .78, 140, 9), ("B", -.02, .87, 120, -10)],
    [("Y", -.02, .795, 130, -8), ("D", .91, .86, 140, 12), ("S", .93, .72, 100, -4)],
    [("G", .905, .80, 140, -9), ("Ü", -.015, .72, 110, 8), ("N", -.02, .89, 130, -5)],
    [("K", -.02, .80, 140, 10), ("E", .913, .74, 120, -8)],
    [("R", .905, .80, 140, 8), ("O", -.02, .73, 120, -10), ("Z", -.015, .895, 110, 6)],
    [("P", -.02, .79, 140, -8), ("L", .913, .725, 120, 9), ("U", .917, .885, 120, -6)],
]

PENCIL_SVG = """<svg class="pencil" style="left:{x}px;top:{y}px" width="900" height="900"
 viewBox="0 0 900 900"><defs>
 <linearGradient id="b" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#ffffff"/>
 <stop offset=".55" stop-color="#F1EEFF"/><stop offset="1" stop-color="#D9D3F5"/></linearGradient>
 <filter id="s" x="-20%" y="-20%" width="140%" height="140%">
 <feDropShadow dx="18" dy="30" stdDeviation="22" flood-color="#2A1060" flood-opacity=".35"/></filter></defs>
 <g filter="url(#s)" transform="rotate(-40 0 0)">
  <path d="M0 0 L34 96 L-34 96 Z" fill="#3B2F6B"/>
  <path d="M-34 96 L34 96 L44 180 L-44 180 Z" fill="#EDE9FB"/>
  <rect x="-44" y="178" width="88" height="900" rx="10" fill="url(#b)"/>
  <rect x="-44" y="300" width="88" height="16" fill="#6C5CE7" opacity=".85"/>
 </g></svg>"""


def clean_corner(src, dst):
    """iPadOS pencere boyutlandırma tutamacını (sistem öğesi) arka plan rengiyle örter."""
    im = Image.open(src).convert("RGB")
    w, h = im.size
    if w == 2064:
        color = im.getpixel((w - 120, h - 12))
        im.paste(color, (w - 110, h - 110, w, h))
    im.save(dst)


def page(i, s, raw, d):
    W, H, u = d["W"], d["H"], d["u"]
    a, b = STOPS[i % 7], STOPS[i % 7 + 1]
    shot = pathlib.Path(raw, f"{s['shot']}.png").resolve().as_uri()
    title = s["title"].replace("\n", "<br>")
    if s.get("tiles"):
        tiles = "".join(f"<span>{c}</span>" for c in s["tiles"])
        head = f'<div class="tiles">{tiles}</div><h1 class="after">{title}</h1>'
    else:
        head = f"<h1>{title}</h1>"
    floats = "".join(
        f'<div class="ft" style="left:{int(x * W)}px;top:{int(y * H)}px;width:{int(z * u)}px;'
        f'height:{int(z * u)}px;font-size:{int(z * u * .58)}px;transform:rotate({r}deg)">{c}</div>'
        for c, x, y, z, r in FLOATS[i % 7])
    pencil = PENCIL_SVG.format(x=s["pencil"][0], y=s["pencil"][1]) if s.get("pencil") else ""
    icon, chip = s["chip"]
    top = s.get("top", d["top"])
    fw, pad = d["frame_w"], d["pad"]
    island = '<div class="island"></div>' if d["island"] else ""
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
@font-face {{ font-family: R; src: url(file:///System/Library/Fonts/SFNSRounded.ttf); }}
* {{ margin: 0; box-sizing: border-box; }}
html, body {{ width: {W}px; height: {H}px; overflow: hidden; }}
body {{ font-family: R, -apple-system, sans-serif; color: #fff; position: relative;
  background: linear-gradient(105deg, {a} 0%, {b} 100%); }}
body::before {{ content: ""; position: absolute; inset: 0;
  background: radial-gradient({int(1100 * u)}px {int(700 * u)}px at 50% 0%, rgba(255,255,255,.28), transparent 70%),
              radial-gradient({int(900 * u)}px {int(900 * u)}px at 50% 105%, rgba(40,20,110,.28), transparent 70%); }}
.grid {{ position: absolute; inset: 0; opacity: .10;
  background-image: linear-gradient(#fff 3px, transparent 3px), linear-gradient(90deg, #fff 3px, transparent 3px);
  background-size: {int(132 * u)}px {int(132 * u)}px; background-position: -2px -2px;
  -webkit-mask-image: linear-gradient(#000, transparent 38%); }}
header {{ position: absolute; top: {int(150 * u * .9)}px; left: 0; right: 0; text-align: center; padding: 0 70px; }}
h1 {{ font-weight: 900; font-size: {int(128 * u)}px; line-height: 1.04; letter-spacing: -2px;
  text-shadow: 0 6px 30px rgba(60,20,120,.25); }}
h1.after {{ margin-top: {int(26 * u)}px; }}
h1 em {{ font-style: normal; color: #FFE27A; }}
.tiles {{ display: flex; justify-content: center; gap: {int(14 * u)}px; flex-wrap: nowrap; }}
.tiles span {{ width: {int(118 * u)}px; height: {int(132 * u)}px; border-radius: {int(28 * u)}px;
  background: #fff; color: #5B4FD6; display: grid; place-items: center; font-weight: 900;
  font-size: {int(84 * u)}px; box-shadow: 0 10px 0 rgba(70,40,160,.22), 0 18px 40px rgba(50,20,120,.25); }}
.tiles span:nth-child(odd) {{ transform: translateY(-6px) rotate(-3deg); }}
.tiles span:nth-child(even) {{ transform: translateY(6px) rotate(3deg); }}
.sub {{ margin-top: {int(30 * u)}px; font-weight: 700; font-size: {int(54 * u)}px; color: rgba(255,255,255,.93); }}
.phone {{ position: absolute; left: 50%; top: {top}px; width: {fw}px; transform: translateX(-50%);
  padding: {pad}px; border-radius: {d["radius"]}px; background: #17122b;
  box-shadow: 0 0 0 6px rgba(255,255,255,.35), 0 60px 120px rgba(40,10,100,.45); }}
.phone img {{ display: block; width: 100%; border-radius: {d["inner"]}px; }}
.island {{ position: absolute; left: 369px; top: 56px; width: 272px; height: 80px;
  border-radius: 40px; background: #000; }}
.chip {{ position: absolute; left: 50%; top: {top - d["chip_gap"]}px; transform: translateX(-50%); z-index: 3;
  display: flex; align-items: center; gap: 18px; white-space: nowrap;
  padding: {int(24 * u)}px {int(44 * u)}px; border-radius: 999px; background: #fff; color: #2A1F5C;
  font-weight: 800; font-size: {int(48 * u)}px; box-shadow: 0 14px 40px rgba(40,10,100,.30); }}
.chip b {{ font-size: {int(52 * u)}px; }}
.ft {{ position: absolute; z-index: 4; border-radius: 26%; background: #fff; color: #5B4FD6;
  display: grid; place-items: center; font-weight: 900;
  box-shadow: 0 9px 0 rgba(70,40,160,.25), 0 20px 50px rgba(40,10,100,.35); }}
.pencil {{ position: absolute; z-index: 5; overflow: visible; }}
</style></head><body><div class="grid"></div>
<header>{head}<p class="sub">{s["sub"]}</p></header>
<div class="chip"><b>{icon}</b>{chip}</div>
<div class="phone"><img src="{shot}">{island}</div>{floats}{pencil}
</body></html>"""


def build(device, raw, out, set_name="main"):
    d = DEVICES[device]
    slides = SETS[set_name][device]
    os.makedirs(out, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp, sync_playwright() as pw:
        for s in slides:
            clean_corner(pathlib.Path(raw, f"{s['shot']}.png"), pathlib.Path(tmp, f"{s['shot']}.png"))
        browser = pw.chromium.launch(
            executable_path=os.environ.get("STORE_CHROMIUM") or None,
            args=["--allow-file-access-from-files"])
        tab = browser.new_page(viewport={"width": d["W"], "height": d["H"]}, device_scale_factor=1)
        tag = "" if set_name == "main" else f"{set_name}-"
        for i, s in enumerate(slides):
            html = pathlib.Path(tmp, f"s{i}.html")
            html.write_text(page(i, s, tmp, d), encoding="utf-8")
            tab.goto(html.as_uri())
            tab.wait_for_load_state("networkidle")
            tab.evaluate("document.fonts.ready")
            png = pathlib.Path(out, f"{d['prefix']}-{tag}{i + 1}-{s['shot']}.png")
            tab.screenshot(path=str(png))
            Image.open(png).convert("RGB").save(png)  # ASC alfa kanallı PNG kabul etmez.
            print(png)
        browser.close()


if __name__ == "__main__":
    build(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else "main")
