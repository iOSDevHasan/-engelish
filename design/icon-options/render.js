const { Resvg } = require('@resvg/resvg-js');
const fs = require('fs');
const [,, inp, out, size] = process.argv;
const svg = fs.readFileSync(inp, 'utf8');
const r = new Resvg(svg, { fitTo: { mode: 'width', value: parseInt(size || '1024') }, background: 'rgba(0,0,0,0)',
  font: { loadSystemFonts: false }, shapeRendering: 2 });
fs.writeFileSync(out, r.render().asPng());
