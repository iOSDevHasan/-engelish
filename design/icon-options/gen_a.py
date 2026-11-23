# Option A — "Çengel" cell cluster: crossword cells form a bold Ç, cedilla is a gold hook.
P, C, R = 140, 130, 32           # pitch, cell size, corner radius
cells = [(1,0),(2,0),(3,0),(0,1),(4,1),(0,2),(0,3),(4,3),(1,4),(2,4),(3,4)]
W = 4*P + C; H = 4*P + C
x0 = (1024 - W)//2; y0 = 98

def cell(cx, cy, kind):
    x = x0 + cx*P; y = y0 + cy*P
    face = {'cream':'url(#cream)','gold':'url(#gold)','pink':'url(#pink)'}[kind]
    side = {'cream':'#B9AAF2','gold':'#E08A1E','pink':'#D9437A'}[kind]
    s = f'<g filter="url(#sh)">'
    s += f'<rect x="{x}" y="{y+12}" width="{C}" height="{C}" rx="{R}" fill="{side}"/>'
    s += f'<rect x="{x}" y="{y}" width="{C}" height="{C}" rx="{R}" fill="{face}"/>'
    s += '</g>'
    s += f'<rect x="{x+3}" y="{y+3}" width="{C-6}" height="{C*0.42:.0f}" rx="{R-4}" fill="url(#gloss)"/>'
    return s, x, y

body = []
special = {(1,0):'gold',(2,0):'pink'}
for c in cells:
    s, x, y = cell(*c, special.get(c,'cream'))
    body.append(s)
    if c == (1,0):   # clue cell: tiny text lines + arrow pointing left into the word
        body.append(f'<g fill="#24204D" opacity="0.85"><rect x="{x+26}" y="{y+40}" width="60" height="9" rx="4.5"/>'
                    f'<rect x="{x+26}" y="{y+60}" width="44" height="9" rx="4.5"/></g>')
        body.append(f'<path d="M {x+C+2} {y+C/2+14} l -22 -16 v 32 z" fill="#24204D"/>')
    if c == (2,0):   # handwritten E (white, on the active pink cell)
        body.append(f'<g transform="translate({x},{y}) scale(1.2)" fill="none" stroke="#FFFFFF" stroke-width="13" stroke-linecap="round" stroke-linejoin="round">'
                    '<path d="M 73 27 Q 55 23 38 27 Q 35 52 36 80 Q 55 84 75 79"/>'
                    '<path d="M 38 53 Q 52 51 65 52"/></g>')

# cedilla hook under the C
hx = x0 + 2*P + C/2; hy = y0 + 4*P + C - 24
hook = (f'<path d="M {hx} {hy} L {hx} {hy+64} C {hx+64} {hy+60} {hx+80} {hy+104} {hx+60} {hy+130} '
        f'C {hx+42} {hy+154} {hx-4} {hy+160} {hx-40} {hy+146}" fill="none" stroke-linecap="round" stroke-linejoin="round"')
hookg = f'<g filter="url(#sh)">{hook} stroke="#E0701E" stroke-width="40" transform="translate(0,10)"/>{hook} stroke="url(#hookg)" stroke-width="40"/></g>'
body.insert(0, hookg)

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#9C8BFF"/><stop offset="0.5" stop-color="#6C5CE7"/><stop offset="1" stop-color="#3B2DAE"/>
  </linearGradient>
  <radialGradient id="glowP" cx="0.92" cy="0.95" r="0.6"><stop offset="0" stop-color="#FF6B9D" stop-opacity="0.55"/><stop offset="1" stop-color="#FF6B9D" stop-opacity="0"/></radialGradient>
  <radialGradient id="glowL" cx="0.15" cy="0.08" r="0.55"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.2"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
  <linearGradient id="cream" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#FFF3E0"/></linearGradient>
  <linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFD966"/><stop offset="1" stop-color="#FFB627"/></linearGradient>
  <linearGradient id="pink" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF8DB3"/><stop offset="1" stop-color="#FF5C8F"/></linearGradient>
  <linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.55"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>
  <linearGradient id="hookg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFD24D"/><stop offset="1" stop-color="#FF8A3D"/></linearGradient>
  <filter id="sh" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="18" stdDeviation="16" flood-color="#1E1460" flood-opacity="0.45"/></filter>
</defs>
<rect width="1024" height="1024" fill="url(#bg)"/>
<rect width="1024" height="1024" fill="url(#glowP)"/>
<rect width="1024" height="1024" fill="url(#glowL)"/>
{''.join(body)}
</svg>'''
open('option-a.svg','w').write(svg)
