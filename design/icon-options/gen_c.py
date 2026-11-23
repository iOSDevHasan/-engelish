# Option C — Glossy letter tile: one chunky 3D cream tile with a handwritten "Ç" and a gold clue-arrow corner.
T = 620; R = 140; TX = (1024 - T)/2; TY = 168; D = 40   # tile size, radius, position, depth
ROT = -6
tile = f'M {TX+R} {TY} H {TX+T-R} Q {TX+T} {TY} {TX+T} {TY+R} V {TY+T-R} Q {TX+T} {TY+T} {TX+T-R} {TY+T} H {TX+R} Q {TX} {TY+T} {TX} {TY+T-R} V {TY+R} Q {TX} {TY} {TX+R} {TY} Z'
cx, cy = 512, TY + T/2
glyph_C = 'M 652 352 C 600 290 500 282 440 318 C 370 360 346 440 352 500 C 360 590 430 640 512 640 C 570 640 620 616 656 576'
cedilla = 'M 514 650 C 512 668 508 682 503 694 C 550 690 576 712 564 740 C 552 768 506 774 470 760'

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#FFB03D"/><stop offset="0.38" stop-color="#FF7A6B"/><stop offset="0.7" stop-color="#E35FB0"/><stop offset="1" stop-color="#6C5CE7"/>
  </linearGradient>
  <radialGradient id="lite" cx="0.25" cy="0.15" r="0.6"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.35"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
  <linearGradient id="face" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#FFEFD9"/></linearGradient>
  <linearGradient id="side" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E9C9A6"/><stop offset="1" stop-color="#D6A57E"/></linearGradient>
  <linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>
  <linearGradient id="ink" gradientUnits="userSpaceOnUse" x1="350" y1="290" x2="660" y2="780"><stop offset="0" stop-color="#8E7CF8"/><stop offset="1" stop-color="#4E3DD0"/></linearGradient>
  <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFE07A"/><stop offset="1" stop-color="#FFB524"/></linearGradient>
  <clipPath id="tileclip"><path d="{tile}"/></clipPath>
  <filter id="sh" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="36" stdDeviation="34" flood-color="#5A1A6E" flood-opacity="0.45"/></filter>
  <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="3"/></filter>
</defs>
<rect width="1024" height="1024" fill="url(#bg)"/>
<rect width="1024" height="1024" fill="url(#lite)"/>
<g transform="rotate({ROT} {cx} {cy})">
  <g filter="url(#sh)">
    <path d="{tile}" fill="url(#side)" transform="translate(0,{D})"/>
    <path d="{tile}" fill="url(#face)"/>
  </g>
  <g clip-path="url(#tileclip)">
    <!-- clue corner -->
    <path d="M {TX+T-210} {TY} H {TX+T} V {TY+210} Z" fill="url(#gold)"/>
    <path d="M {TX+T-210} {TY} L {TX+T} {TY+210}" stroke="#E79A12" stroke-width="6" opacity="0.6"/>
    <!-- glossy top sheen -->
    <path d="M {TX} {TY} H {TX+T} V {TY+150} Q {cx} {TY+230} {TX} {TY+150} Z" fill="url(#gloss)" opacity="0.55"/>
  </g>
  <!-- small bent clue arrow (↳) in the corner -->
  <g fill="none" stroke="#24204D" stroke-width="14" stroke-linecap="round" stroke-linejoin="round">
    <path d="M {TX+T-92} {TY+40} V {TY+88} H {TX+T-46}"/>
    <path d="M {TX+T-62} {TY+72} L {TX+T-44} {TY+88} L {TX+T-62} {TY+104}"/>
  </g>
  <!-- inner rim -->
  <path d="{tile}" fill="none" stroke="#FFFFFF" stroke-width="6" opacity="0.8"/>
  <!-- handwritten Ç: soft shadow + stroke -->
  <g fill="none" stroke-linecap="round" stroke-linejoin="round" transform="translate(0,-6)">
    <path d="{glyph_C}" stroke="#3B2DAE" stroke-opacity="0.18" stroke-width="78" transform="translate(4,10)" filter="url(#soft)"/>
    <path d="{cedilla}" stroke="#3B2DAE" stroke-opacity="0.18" stroke-width="42" transform="translate(4,10)" filter="url(#soft)"/>
    <path d="{glyph_C}" stroke="url(#ink)" stroke-width="78"/>
    <path d="{cedilla}" stroke="url(#ink)" stroke-width="42"/>
    <path d="M 430 340 C 384 372 372 424 372 470" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="14"/>
  </g>
</g>
</svg>'''
open('option-c.svg','w').write(svg)
