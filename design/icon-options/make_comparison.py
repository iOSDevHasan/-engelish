# Builds comparison.png: options A–D at 512px (iOS-masked preview), plus rows at 120px and 60px.
from PIL import Image, ImageDraw, ImageFont
import os
here = os.path.dirname(os.path.abspath(__file__))
names = ['a', 'b', 'c', 'd']
icons = [Image.open(os.path.join(here, f'option-{n}.png')).convert('RGB') for n in names]

def masked(img, size):
    # iOS-style rounded mask (approximation: radius ≈ 22.37% of side), supersampled for smooth edges
    big = img.resize((size*4, size*4), Image.LANCZOS)
    m = Image.new('L', big.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, big.size[0]-1, big.size[1]-1], radius=int(big.size[0]*0.2237), fill=255)
    out = Image.new('RGBA', big.size, (0, 0, 0, 0)); out.paste(big, (0, 0), m)
    return out.resize((size, size), Image.LANCZOS)

BG = (246, 244, 252); INK = (36, 32, 77)
pad, big, mid, small = 48, 512, 120, 60
W = pad + 4*(big+pad)
H = pad + 60 + big + pad + 40 + mid + pad + 40 + small + pad
sheet = Image.new('RGB', (W, H), BG)
d = ImageDraw.Draw(sheet)
f_big = ImageFont.truetype('/System/Library/Fonts/HelveticaNeue.ttc', 44, index=1)
f_sm = ImageFont.truetype('/System/Library/Fonts/HelveticaNeue.ttc', 26, index=0)
y = pad
for i, n in enumerate(names):
    x = pad + i*(big+pad)
    d.text((x, y), f'Option {n.upper()}', font=f_big, fill=INK)
y += 60
for i, img in enumerate(icons):
    x = pad + i*(big+pad)
    m = masked(img, big); sheet.paste(m, (x, y), m)
y += big + pad
d.text((pad, y), '120 px', font=f_sm, fill=(110, 104, 150)); y += 40
for i, img in enumerate(icons):
    x = pad + i*(big+pad)
    m = masked(img, mid); sheet.paste(m, (x, y), m)
    d.text((x + mid + 24, y + mid//2 - 22), n_ := names[i].upper(), font=f_big, fill=INK)
y += mid + pad
d.text((pad, y), '60 px', font=f_sm, fill=(110, 104, 150)); y += 40
for i, img in enumerate(icons):
    x = pad + i*(big+pad)
    m = masked(img, small); sheet.paste(m, (x, y), m)
    d.text((x + small + 24, y + small//2 - 22), names[i].upper(), font=f_big, fill=INK)
sheet.save(os.path.join(here, 'comparison.png'))
print(sheet.size)
