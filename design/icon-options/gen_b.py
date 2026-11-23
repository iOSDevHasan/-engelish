# Option B — Kalemo hero: big expressive pencil mascot writing an "E" into a glowing crossword cell.
TIPX, TIPY, ANG, SC = 330, 768, 36, 0.93

def star(cx, cy, r, color, op=1):
    k = r*0.22
    return (f'<path d="M {cx} {cy-r} Q {cx+k} {cy-k} {cx+r} {cy} Q {cx+k} {cy+k} {cx} {cy+r} '
            f'Q {cx-k} {cy+k} {cx-r} {cy} Q {cx-k} {cy-k} {cx} {cy-r} Z" fill="{color}" opacity="{op}"/>')

# background crossword cells (faint)
bgcells = []
P, C = 150, 136
for i in range(-1, 8):
    for j in range(-1, 8):
        x = 106 + i*P - 150*1; y = 560 + j*P - 150*4
        bgcells.append(f'<rect x="{x}" y="{y}" width="{C}" height="{C}" rx="26" fill="#FFFFFF" opacity="0.06"/>')

# the glowing cell (aligned to the background grid)
cx0, cy0, cs = 106, 560, P + C   # spans a 2x2 block of the background grid
pencil = f'''
<g transform="translate({TIPX},{TIPY}) rotate({ANG}) scale({SC}) translate(0,-700)">
  <!-- eraser -->
  <rect x="-112" y="-215" width="224" height="150" rx="58" fill="url(#eraser)"/>
  <rect x="-84" y="-196" width="60" height="22" rx="11" fill="#FFFFFF" opacity="0.45"/>
  <!-- ferrule -->
  <rect x="-124" y="-96" width="248" height="104" rx="18" fill="url(#ferrule)"/>
  <rect x="-124" y="-62" width="248" height="10" fill="#9C97C9" opacity="0.6"/>
  <rect x="-124" y="-30" width="248" height="10" fill="#9C97C9" opacity="0.6"/>
  <!-- body -->
  <path d="M -120 0 H 120 V 498 H -120 Z" fill="url(#body)"/>
  <!-- wood cone with scalloped edge -->
  <path d="M -120 470 Q -80 500 -40 470 Q 0 500 40 470 Q 80 500 120 470 L 0 700 Z" fill="url(#wood)"/>
  <path d="M -37 629 Q -18 644 0 632 Q 18 644 37 629 L 0 700 Z" fill="#24204D"/>
  <path d="M -6 650 L 4 650 L 0 690 Z" fill="#FFFFFF" opacity="0.25"/>
  <!-- face -->
  <ellipse cx="-58" cy="300" rx="27" ry="16" fill="#FF6B9D" opacity="0.55"/>
  <ellipse cx="62" cy="300" rx="27" ry="16" fill="#FF6B9D" opacity="0.55"/>
  <g>
    <ellipse cx="-44" cy="232" rx="34" ry="42" fill="#24204D"/>
    <ellipse cx="46" cy="232" rx="34" ry="42" fill="#24204D"/>
    <circle cx="-34" cy="216" r="13" fill="#FFFFFF"/><circle cx="56" cy="216" r="13" fill="#FFFFFF"/>
    <circle cx="-52" cy="250" r="6" fill="#FFFFFF" opacity="0.8"/><circle cx="38" cy="250" r="6" fill="#FFFFFF" opacity="0.8"/>
  </g>
  <path d="M -74 168 Q -46 150 -18 164" fill="none" stroke="#24204D" stroke-width="10" stroke-linecap="round"/>
  <path d="M 18 162 Q 46 148 74 166" fill="none" stroke="#24204D" stroke-width="10" stroke-linecap="round"/>
  <path d="M -34 296 Q 2 300 36 294 Q 34 346 1 348 Q -32 348 -34 296 Z" fill="#24204D"/>
  <path d="M -18 332 Q 1 318 20 332 Q 12 345 1 345 Q -10 345 -18 332 Z" fill="#FF6B9D"/>
</g>'''

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="0.6" y2="1">
    <stop offset="0" stop-color="#9483FF"/><stop offset="0.55" stop-color="#6C5CE7"/><stop offset="1" stop-color="#3E2FB3"/>
  </linearGradient>
  <radialGradient id="halo" cx="0.6" cy="0.38" r="0.5"><stop offset="0" stop-color="#FFB3D0" stop-opacity="0.55"/><stop offset="1" stop-color="#FF6B9D" stop-opacity="0"/></radialGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE38A" stop-opacity="0.95"/><stop offset="0.45" stop-color="#FFC93C" stop-opacity="0.45"/><stop offset="1" stop-color="#FFC93C" stop-opacity="0"/></radialGradient>
  <linearGradient id="cell" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFDF7"/><stop offset="1" stop-color="#FFF0D2"/></linearGradient>
  <linearGradient id="eraser" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#F0508A"/><stop offset="0.45" stop-color="#FF8DB3"/><stop offset="1" stop-color="#FF6B9D"/></linearGradient>
  <linearGradient id="ferrule" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#B7B2E0"/><stop offset="0.45" stop-color="#F4F2FF"/><stop offset="1" stop-color="#CFCBEF"/></linearGradient>
  <linearGradient id="body" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#F0A800"/><stop offset="0.333" stop-color="#F7B514"/>
    <stop offset="0.333" stop-color="#FFC93C"/><stop offset="0.666" stop-color="#FFD255"/>
    <stop offset="0.666" stop-color="#FFE07D"/><stop offset="1" stop-color="#FFD966"/></linearGradient>
  <linearGradient id="wood" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E8B57A"/><stop offset="0.5" stop-color="#F8DBAE"/><stop offset="1" stop-color="#FBE6C4"/></linearGradient>
  <filter id="sh" x="-40%" y="-40%" width="180%" height="180%"><feDropShadow dx="-10" dy="22" stdDeviation="20" flood-color="#1E1460" flood-opacity="0.45"/></filter>
  <filter id="sh2" x="-40%" y="-40%" width="180%" height="180%"><feDropShadow dx="0" dy="14" stdDeviation="14" flood-color="#1E1460" flood-opacity="0.4"/></filter>
</defs>
<rect width="1024" height="1024" fill="url(#bg)"/>
{''.join(bgcells)}
<rect width="1024" height="1024" fill="url(#halo)"/>
<circle cx="{cx0+cs/2}" cy="{cy0+cs/2}" r="{cs*0.95}" fill="url(#glow)"/>
<g filter="url(#sh2)">
  <rect x="{cx0}" y="{cy0+12}" width="{cs}" height="{cs}" rx="44" fill="#E3A520"/>
  <rect x="{cx0}" y="{cy0}" width="{cs}" height="{cs}" rx="44" fill="url(#cell)" stroke="#FFC93C" stroke-width="10"/>
</g>
<g transform="translate({cx0},{cy0})" fill="none" stroke="#6C5CE7" stroke-width="22" stroke-linecap="round" stroke-linejoin="round">
  <path d="M 172 70 Q 128 62 84 70 Q 78 136 80 204 Q 150 214 222 206"/>
  <path d="M 84 136 Q 112 132 146 134"/>
</g>
{star(830, 640, 40, "#FFC93C")}{star(880, 520, 20, "#FFFFFF", 0.9)}{star(150, 300, 26, "#FFFFFF", 0.85)}{star(236, 200, 14, "#FFC93C", 0.9)}
<g filter="url(#sh)">{pencil}</g>
</svg>'''
open('option-b.svg','w').write(svg)
