"""Character proportions must survive both fitting and runtime atlas encoding."""
import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from fit_event_art import fit_hub, fit_minimap


def red_shape_dimensions(image):
    pixels = np.asarray(image)
    y, x = np.where((pixels[:, :, 0] > 220) & (pixels[:, :, 1] < 30)
                    & (pixels[:, :, 2] < 30) & (pixels[:, :, 3] > 200))
    return x.max()-x.min()+1, y.max()-y.min()+1


class EventArtFitTests(unittest.TestCase):
    def test_hub_character_stays_round_through_storage_and_display(self):
        source = Image.new('RGBA', (1600, 800))
        draw = ImageDraw.Draw(source)
        draw.rectangle((60,40,380,740), fill='#404060')
        draw.rectangle((1220,40,1540,740), fill='#404060')
        draw.rectangle((380,550,1220,610), fill='#909090')
        draw.ellipse((140,180,300,340), fill='#ff0000')
        fitted, report = fit_hub(source, (550,611))
        self.assertEqual(report['ornament_scale_xy'][0], report['ornament_scale_xy'][1])
        encoded = fitted.resize((1024,512), Image.Resampling.LANCZOS)
        displayed = encoded.resize((2172,724), Image.Resampling.LANCZOS)
        width, height = red_shape_dimensions(displayed)
        self.assertLessEqual(abs(width-height), 2)
        self.assertIsNone(fitted.crop((620,0,1552,440)).getchannel('A').getbbox())

    def test_minimap_fits_opening_without_bending_character(self):
        source = Image.new('RGBA', (512,512))
        draw = ImageDraw.Draw(source)
        draw.ellipse((48,48,464,464), fill='#808080')
        draw.ellipse((120,120,392,392), fill=(0,0,0,0))
        draw.ellipse((72,72,124,124), fill='#ff0000')
        fitted, report = fit_minimap(source)
        width, height = red_shape_dimensions(fitted)
        self.assertLessEqual(abs(width-height), 1)
        self.assertEqual(report['margin_pixels_removed'], 0)
        yy, xx = np.mgrid[:512,:512]
        self.assertFalse(np.asarray(fitted)[:, :, 3][(xx-256)**2+(yy-256)**2 <= 149**2].any())


if __name__ == '__main__':
    unittest.main()
