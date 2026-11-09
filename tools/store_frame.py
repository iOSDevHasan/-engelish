"""Mağaza ekran görüntüsü çerçeveleyici: renkli zemin + başlık + yuvarlatılmış ekran.

Kullanım: python3 tools/store_frame.py <klasör> <ham-önek> <çıktı-önek> <ipad:0/1>
Ham görüntüler: Debug derlemeyi `-screenshotDemo` argümanıyla açıp simülatörden çek.
"""
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = "/System/Library/Fonts/SFNSRounded.ttf"
SHOTS = [
    ("puzzle", "Türkçe ipucu,\nİngilizce cevap", "Kalemle yaz, cevap anahtarıyla kontrol et"),
    ("home", "Her gün yeni\nbir bulmaca", "Serini koru, günün kelimesini öğren"),
    ("explore", "YDS, YÖKDİL, LGS,\nIELTS ve TOEFL", "A1'den C1'e seviye ve tema paketleri"),
    ("notebook", "Bilemediğin\nkelimeler deftere", "Aralıklı tekrarla kalıcı öğren"),
    ("profile", "Rozet topla,\nserini büyüt", "Hesap yok, verilerin cihazında"),
]
TOP = (108, 92, 231)
BOTTOM = (142, 124, 248)


def font(size, weight):
    f = ImageFont.truetype(FONT, size)
    f.set_variation_by_name(weight)
    return f


def gradient(w, h):
    img = Image.new("RGB", (w, h), TOP)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)))
    return img


def frame(src, dst, title, sub, ipad):
    shot = Image.open(src).convert("RGB")
    w, h = shot.size
    canvas = gradient(w, h)
    d = ImageDraw.Draw(canvas)
    unit = w / 1320 if not ipad else w / 2064 * 1.15
    tf, sf = font(int(118 * unit), "Black"), font(int(52 * unit), "Bold")
    y = int(150 * unit)
    d.multiline_text((w / 2, y), title, font=tf, fill="white", anchor="ma", align="center",
                     spacing=int(14 * unit))
    tb = d.multiline_textbbox((w / 2, y), title, font=tf, anchor="ma", align="center",
                              spacing=int(14 * unit))
    d.text((w / 2, tb[3] + int(36 * unit)), sub, font=sf, fill=(235, 231, 255), anchor="ma")
    scale = 0.80 if not ipad else 0.78
    sw, sh = int(w * scale), int(h * scale)
    small = shot.resize((sw, sh), Image.LANCZOS)
    radius = int(sw * (0.11 if not ipad else 0.035))
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw, sh], radius, fill=255)
    x, top = (w - sw) // 2, int(h * (0.30 if not ipad else 0.27))
    shadow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(shadow).rounded_rectangle([x, top + 30, x + sw, top + sh + 30], radius, fill=110)
    shadow = shadow.filter(ImageFilter.GaussianBlur(40))
    canvas.paste((40, 30, 110), (0, 0), shadow)
    border = int(10 * unit)
    ImageDraw.Draw(canvas).rounded_rectangle(
        [x - border, top - border, x + sw + border, top + sh + border], radius + border,
        fill=(30, 26, 60))
    canvas.paste(small, (x, top), mask)
    canvas.save(dst, "PNG")


if __name__ == "__main__":
    folder, prefix, out_prefix, ipad = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
    for i, (name, title, sub) in enumerate(SHOTS, 1):
        frame(f"{folder}/{prefix}{name}.png", f"{folder}/{out_prefix}{i}-{name}.png", title, sub, ipad)
        print("ok", out_prefix, i, name)
