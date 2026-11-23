#!/bin/zsh
# Regenerates all SVGs, renders 1024px PNGs (via @resvg/resvg-js), flattens to opaque RGB, builds comparison.png.
# Usage: RENDER_JS=./render.js ./build.sh  (needs `npm i @resvg/resvg-js@2.6.2` where render.js can resolve it)
set -e
cd "$(dirname "$0")"
for o in a b c d; do
  python3 gen_$o.py
  node "$RENDER_JS" option-$o.svg option-$o.png 1024
  python3 -c "from PIL import Image; im=Image.open('option-$o.png').convert('RGB'); im.save('option-$o.png')"
done
python3 make_comparison.py
