# Option D — "Çeviri" bubbles: a Turkish Ç speech-cell hooks (via the arrow-crossword ↳ arrow) into an English E speech-cell.
def bubble(x, y, s, r, tail):
    # rounded square with a tail; tail = 'bl' (bottom-left, points down-left) or 'br'
    if tail == 'bl':
        t = f'L {x+r+96} {y+s} L {x+44} {y+s+74} L {x+r-14} {y+s-4}'
        return (f'M {x+r} {y} H {x+s-r} Q {x+s} {y} {x+s} {y+r} V {y+s-r} Q {x+s} {y+s} {x+s-r} {y+s} '
                f'{t} Q {x} {y+s} {x} {y+s-r} V {y+r} Q {x} {y} {x+r} {y} Z')
    else:
        t = f'L {x+s-r+14} {y+s-4} L {x+s-44} {y+s+74} L {x+s-r-96} {y+s}'
        return (f'M {x+r} {y} H {x+s-r} Q {x+s} {y} {x+s} {y+r} V {y+s-r} Q {x+s} {y+s} {x+s-r} {y+s} '
                f'{t} H {x+r} Q {x} {y+s} {x} {y+s-r} V {y+r} Q {x} {y} {x+r} {y} Z')

A = (128, 118, 380, 96)   # Ç bubble
B = (490, 470, 410, 104)  # E bubble
ba = bubble(*A, 'bl'); bb = bubble(*B, 'br')

# handwritten Ç (white) centered in A
ax, ay, s = A[0], A[1], A[2]
cC = f'M {ax+262} {ay+112} C {ax+232} {ay+80} {ax+180} {ay+74} {ax+146} {ay+96} C {ax+104} {ay+124} {ax+96} {ay+176} {ax+100} {ay+204} C {ax+108} {ay+256} {ax+150} {ay+280} {ax+194} {ay+278} C {ax+226} {ay+276} {ax+252} {ay+262} {ax+268} {ay+242}'
cced = f'M {ax+192} {ay+290} C {ax+191} {ay+300} {ax+189} {ay+308} {ax+186} {ay+314} C {ax+214} {ay+312} {ax+228} {ay+326} {ax+221} {ay+342} C {ax+214} {ay+358} {ax+188} {ay+362} {ax+168} {ay+354}'
# handwritten E (purple) centered in B
bx, by = B[0], B[1]
cE = f'M {bx+274} {by+108} Q {bx+212} {by+96} {bx+148} {by+106} Q {bx+140} {by+204} {bx+144} {by+304} Q {bx+212} {by+314} {bx+280} {by+302}'
cE2 = f'M {bx+148} {by+204} Q {bx+192} {by+198} {bx+240} {by+202}'

# bent clue arrow (↳) from A down and into B
arrow = 'M 318 556 V 690 Q 318 718 346 718 H 420'
head = 'M 404 682 L 450 718 L 404 754'

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7B6BF0"/><stop offset="0.55" stop-color="#5443D6"/><stop offset="1" stop-color="#2E2378"/></linearGradient>
  <radialGradient id="glow" cx="0.3" cy="0.25" r="0.5"><stop offset="0" stop-color="#FF8DB3" stop-opacity="0.45"/><stop offset="1" stop-color="#FF8DB3" stop-opacity="0"/></radialGradient>
  <radialGradient id="glow2" cx="0.72" cy="0.7" r="0.45"><stop offset="0" stop-color="#FFC93C" stop-opacity="0.3"/><stop offset="1" stop-color="#FFC93C" stop-opacity="0"/></radialGradient>
  <linearGradient id="hot" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FF9F4A"/><stop offset="0.55" stop-color="#FF7A7A"/><stop offset="1" stop-color="#FF5C99"/></linearGradient>
  <linearGradient id="cream" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#FFF1DC"/></linearGradient>
  <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFE07A"/><stop offset="1" stop-color="#FFB524"/></linearGradient>
  <linearGradient id="ink" gradientUnits="userSpaceOnUse" x1="600" y1="560" x2="800" y2="800"><stop offset="0" stop-color="#8E7CF8"/><stop offset="1" stop-color="#4E3DD0"/></linearGradient>
  <linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.5"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>
  <filter id="sh" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="26" stdDeviation="26" flood-color="#140C4A" flood-opacity="0.55"/></filter>
  <clipPath id="ca"><path d="{ba}"/></clipPath><clipPath id="cb"><path d="{bb}"/></clipPath>
</defs>
<rect width="1024" height="1024" fill="url(#bg)"/>
<rect width="1024" height="1024" fill="url(#glow)"/>
<rect width="1024" height="1024" fill="url(#glow2)"/>
<g transform="translate(512 520) scale(0.95) translate(-512 -520)">
<!-- bubble A (Turkish) -->
<g filter="url(#sh)"><path d="{ba}" fill="#D9437A" transform="translate(0,16)"/><path d="{ba}" fill="url(#hot)"/></g>
<rect x="{A[0]}" y="{A[1]}" width="{A[2]}" height="150" fill="url(#gloss)" clip-path="url(#ca)" opacity="0.6"/>
<g fill="none" stroke="#FFFFFF" stroke-linecap="round" stroke-linejoin="round" transform="translate({ax+190},{ay+186}) scale(0.9) translate({-(ax+190)},{-(ay+214)})">
  <path d="{cC}" stroke-width="45"/><path d="{cced}" stroke-width="28"/>
</g>
<!-- bubble B (English) -->
<g filter="url(#sh)"><path d="{bb}" fill="#BBAEF5" transform="translate(0,16)"/><path d="{bb}" fill="url(#cream)"/></g>
<rect x="{B[0]}" y="{B[1]}" width="{B[2]}" height="150" fill="url(#gloss)" clip-path="url(#cb)" opacity="0.7"/>
<g fill="none" stroke="url(#ink)" stroke-linecap="round" stroke-linejoin="round">
  <path d="{cE}" stroke-width="40"/><path d="{cE2}" stroke-width="40"/>
</g>
<!-- the çengel arrow -->
<g fill="none" stroke-linecap="round" stroke-linejoin="round" filter="url(#sh)">
  <path d="{arrow}" stroke="url(#gold)" stroke-width="34"/>
  <path d="{head}" stroke="url(#gold)" stroke-width="34"/>
</g>
</g>
</svg>'''
open('option-d.svg','w').write(svg)
