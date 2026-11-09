#!/usr/bin/env python3
"""Kalemo maskotlu uygulama ikonu (1024×1024) üretir. Çizim DesignKit/KalemoView ile aynı koordinatları kullanır."""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

S = 2048  # süper örnekleme
OUT = Path(__file__).resolve().parents[2] / "Cengelish/App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"


def hexc(h, a=255):
    return ((h >> 16) & 255, (h >> 8) & 255, h & 255, a)


img = Image.new("RGBA", (S, S))
# Mor gradyan zemin
top, bottom = hexc(0x7B6CF0), hexc(0x5A49D6)
px = img.load()
for y in range(S):
    t = y / S
    col = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3)) + (255,)
    for x in range(S):
        px[x, y] = col
d = ImageDraw.Draw(img, "RGBA")

# Arka planda soluk çengel ızgarası
cell, gap = 300, 34
start = (S - (cell * 3 + gap * 2)) // 2
for r in range(3):
    for c in range(3):
        x0, y0 = start + c * (cell + gap), start + r * (cell + gap) + 60
        fill = (255, 255, 255, 46) if (r + c) % 2 == 0 else (255, 255, 255, 26)
        d.rounded_rectangle([x0, y0, x0 + cell, y0 + cell], radius=56, fill=fill)
# Vurgulu kutu (sarı)
x0, y0 = start + 1 * (cell + gap), start + 1 * (cell + gap) + 60
d.rounded_rectangle([x0, y0, x0 + cell, y0 + cell], radius=56, fill=hexc(0xFFD45C, 235))

# Kalemo: viewBox 0 -16 120 146, -14° döndürülmüş (60,65 etrafında)
scale = S * 0.78 / 146
ox = S / 2 - 60 * scale
oy = S / 2 - 57 * scale
ang = math.radians(-14)


def tp(x, y):
    dx, dy = x - 60, y - 65
    rx = dx * math.cos(ang) - dy * math.sin(ang) + 60
    ry = dx * math.sin(ang) + dy * math.cos(ang) + 65
    return (ox + rx * scale, oy + ry * scale)


def poly(points, fill):
    d.polygon([tp(*p) for p in points], fill=fill)


def rrect(x, y, w, h, r, fill, steps=10):
    pts = []
    for cx, cy, a0 in [(x + w - r, y + r, -90), (x + w - r, y + h - r, 0), (x + r, y + h - r, 90), (x + r, y + r, 180)]:
        for i in range(steps + 1):
            a = math.radians(a0 + 90 * i / steps)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    poly(pts, fill)


def ellipse(cx, cy, rx, ry, fill, n=40):
    poly([(cx + rx * math.cos(2 * math.pi * i / n), cy + ry * math.sin(2 * math.pi * i / n)) for i in range(n)], fill)


ink = hexc(0x24204D)
# gölge
shadow = Image.new("RGBA", (S, S))
sd = ImageDraw.Draw(shadow)
sd.ellipse([S * 0.33, S * 0.86, S * 0.67, S * 0.92], fill=(30, 20, 90, 110))
img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(30)))
d = ImageDraw.Draw(img, "RGBA")

rrect(40, 22, 40, 66, 8, hexc(0xFFC93C))
poly([(40, 30), (53, 30), (53, 88), (40, 88)], hexc(0xE6A800, 115))
rrect(40, 10, 40, 18, 8, hexc(0xFF8FA3))
poly([(40, 25), (80, 25), (80, 32), (40, 32)], hexc(0xC9CBE0))
poly([(40, 86), (60, 116), (80, 86)], hexc(0xF6D7A7))
poly([(53.5, 106), (60, 116), (66.5, 106)], ink)
for x in (51, 69):
    ellipse(x, 54, 5.5, 6.5, ink)
    ellipse(x + 2, 52, 2, 2, (255, 255, 255, 255))
# gülümseme
smile = []
for i in range(21):
    t = i / 20
    x = (1 - t) ** 2 * 52 + 2 * (1 - t) * t * 60 + t ** 2 * 68
    y = (1 - t) ** 2 * 68 + 2 * (1 - t) * t * 75 + t ** 2 * 68
    smile.append(tp(x, y))
d.line(smile, fill=ink, width=int(3.2 * scale), joint="curve")
for p in (smile[0], smile[-1]):
    r = 1.6 * scale
    d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=ink)
ellipse(45, 65, 4, 4, hexc(0xFF8FA3, 150))
ellipse(75, 65, 4, 4, hexc(0xFF8FA3, 150))

OUT.parent.mkdir(parents=True, exist_ok=True)
img.convert("RGB").resize((1024, 1024), Image.LANCZOS).save(OUT)
print("yazıldı:", OUT)
