"""Remove generated neutral backdrop using user-authorized local processing.

Only neutral pixels connected to the exterior or bar openings are keyed; the
painted stone, embedded mask and elemental stones remain intact.
"""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'artwork/unit-frames/sculpted'
SOURCE = ART / 'revisions/shaman-elemental-totem-rgb.png'
OUTPUT = ART / 'references/class_shaman.png'


def main():
    rgb = np.asarray(Image.open(SOURCE).convert('RGB'))
    low, high = rgb.min(axis=2).astype(int), rgb.max(axis=2).astype(int)
    candidate = (high - low <= 14) & (low >= 80)
    mask = Image.fromarray(np.uint8(candidate) * 255).copy()
    h, w = candidate.shape
    seeds = [(0, 0), (w-1, 0), (0, h-1), (w-1, h-1), (w//2, 410), (w//2, 550)]
    for seed in seeds:
        if mask.getpixel(seed) == 255:
            ImageDraw.floodfill(mask, seed, 128)
    alpha = np.where(np.asarray(mask) == 128, 0, 255).astype('uint8')
    # Remove detached checker flecks, retaining the one continuous sculpted shell.
    connected = Image.fromarray(alpha).copy()
    assert connected.getpixel((w//2, 325)) == 255
    ImageDraw.floodfill(connected, (w//2, 325), 128)
    alpha = np.where(np.asarray(connected) == 128, 255, 0).astype('uint8')
    rgba = np.dstack((rgb.copy(), alpha))
    rgba[alpha == 0, :3] = 0
    result = Image.fromarray(rgba)
    result.save(OUTPUT)
    assert not alpha[365:475, 280:1390].any()
    assert not alpha[529:575, 270:1400].any()
    assert 0.25 < (alpha > 0).mean() < 0.60
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    report = dict(source=str(SOURCE.relative_to(ROOT)), source_sha256=sha(SOURCE),
                  output=str(OUTPUT.relative_to(ROOT)), output_sha256=sha(OUTPUT),
                  size=list(result.size), alpha_bounds=list(result.getchannel('A').getbbox()),
                  method='Exterior/opening neutral flood; retain connected shell; preserve retained RGB',
                  authorization='User explicitly authorized local Python image processing')
    (ART / 'shaman-alpha-report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
