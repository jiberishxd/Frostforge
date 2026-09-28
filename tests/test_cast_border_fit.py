"""Validate runtime fitting against painted pixels, not transparent canvas bounds."""
import json
import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from measure_cast_borders import OUTPUT, source


class CastBorderFitTests(unittest.TestCase):
    def test_measurements_match_unchanged_runtime_art(self):
        self.assertEqual(OUTPUT.read_text(), source())

    def test_every_painted_opening_matches_the_same_bar_at_every_preview_size(self):
        data = json.loads((ROOT / 'docs/artwork/cast-borders.js').read_text()
                          .split('window.castBorders=', 1)[1].rstrip(';\n'))
        scales = {}
        for identity, theme in data['themes'].items():
            with Image.open(ROOT / 'Frostforge/Media/CastBars' / (theme['file'] + '.png')) as image:
                solid = np.asarray(image.convert('RGBA'))[:, :, 3] >= 128
            # Independently find actual solid-pixel transitions near each rail's
            # middle, then project them using exported runtime texture geometry.
            left = [max(x for x in range(48) if solid[y,x]) + 1 for y in range(56,72)]
            right = [min(x for x in range(464,512) if solid[y,x]) for y in range(56,72)]
            top = [max(y for y in range(48) if solid[y,x]) + 1 for x in range(152,360)]
            bottom = [min(y for y in range(80,128) if solid[y,x]) for x in range(152,360)]
            self.assertEqual(len(theme['fittings']),25)
            for fitting, styles in theme['fittings'].items():
                width_percent, height_percent = map(int, fitting.split('x'))
                width, height = 180*width_percent/100, 16*height_percent/100
                expected = [(180-width)/2-1, (180+width)/2+1,
                            (16-height)/2-1, (16+height)/2+1]
                pieces = styles['CAPPED']

                def project(name, coordinates, axis):
                    p = pieces[name]
                    size, offset, uv, dimension = ('w','x','u',512) if axis == 'x' else ('h','y','v',128)
                    low, high = p[uv+'1']*dimension, p[uv+'2']*dimension
                    return [p[offset]+(v-low)*p[size]/(high-low) for v in coordinates]

                projected = [project('21',left,'x'),project('23',right,'x'),
                             project('12',top,'y'),project('32',bottom,'y')]
                with self.subTest(identity=identity,fitting=fitting):
                    for coordinates, edge in zip(projected,expected):
                        self.assertAlmostEqual(float(np.median(coordinates)),edge,places=5)
                    scale = pieces['11']['w']/48
                    self.assertAlmostEqual(scale,pieces['11']['h']/48,places=6)
                    self.assertAlmostEqual(scale,scales.setdefault(fitting,scale),places=6)


if __name__ == '__main__':
    unittest.main()
