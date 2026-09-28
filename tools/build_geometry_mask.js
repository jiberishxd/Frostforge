// Engineering mask, not decorative artwork: preserve pixels outside a rectangle.
// CLAMP sampling extends its opaque perimeter; the central half is transparent.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const root = path.resolve(__dirname, '..');
const file = 'Frostforge/Media/outside-rect.tga';
const bytes = Buffer.alloc(18 + 8 * 8 * 4);
bytes[2] = 2; bytes.writeUInt16LE(8, 12); bytes.writeUInt16LE(8, 14);
bytes[16] = 32; bytes[17] = 40;
for (let y = 0; y < 8; y++) for (let x = 0; x < 8; x++) {
  const i = 18 + (y * 8 + x) * 4;
  bytes[i] = bytes[i + 1] = bytes[i + 2] = 255;
  bytes[i + 3] = x >= 2 && x < 6 && y >= 2 && y < 6 ? 0 : 255;
}
fs.writeFileSync(path.join(root, file), bytes);
const manifestPath = path.join(root, 'docs/assets.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
manifest.assets = manifest.assets.filter(asset => asset.file !== file);
manifest.assets.push({file, source: 'tools/build_geometry_mask.js', crop: null,
  transform: 'opaque outside a central half-width/half-height rectangle; CLAMP with nearest filtering',
  size: [8, 8], alphaBounds: [0, 0, 8, 8],
  sha256: crypto.createHash('sha256').update(bytes).digest('hex')});
manifest.assets.sort((a, b) => a.file.localeCompare(b.file));
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
