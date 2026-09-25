"""Offline image-fitting regressions; requires the artwork Pillow/NumPy runtime."""
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from fit_unit_shells import fit


class ShellFitTests(unittest.TestCase):
    def test_upper_corner_and_edge_markers_survive_clearance(self):
        # The former rectangular name mask deleted the red shoulder marker.
        # The former four-pixel border mask deleted the blue crown tip.
        source = Image.new('RGB', (1774, 887), (0, 255, 0))
        d = ImageDraw.Draw(source)
        stone = (120, 105, 90)
        d.rectangle((60, 100, 260, 700), fill=stone)
        d.rectangle((1410, 60, 1710, 800), fill=stone)
        d.rectangle((250, 310, 1420, 355), fill=stone)
        d.rectangle((250, 485, 1420, 525), fill=stone)
        d.rectangle((250, 580, 1420, 640), fill=stone)
        d.rectangle((1280, 140, 1450, 210), fill=stone)
        d.rectangle((1280, 140, 1395, 180), fill=(255, 0, 0))
        d.rectangle((1520, 2, 1560, 62), fill=stone)
        d.rectangle((1520, 2, 1560, 9), fill=(0, 0, 255))
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'corner.png'
            source.save(path)
            image, measured = fit(path)
        a = np.asarray(image)
        self.assertTrue(((a[:, :, 0] > 220) & (a[:, :, 1] < 20) & (a[:, :, 3] > 100)).any())
        self.assertTrue(((a[:, :, 2] > 220) & (a[:, :, 0] < 20) & (a[:, :, 3] > 100)).any())
        for x1, y1, x2, y2 in ((96, 0, 396, 70), (96, 84, 396, 132), (96, 136, 396, 160)):
            self.assertFalse(a[y1:y2, x1:x2, 3].any())
        self.assertEqual(measured['name_pixels_discarded'], 0)
        self.assertEqual(measured['edge_pixels_discarded'], 0)

    def test_invalid_openings_fail_instead_of_exporting_a_partial_fit(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'invalid.png'
            Image.new('RGB', (512, 256), 'green').save(path)
            with self.assertRaises(AssertionError):
                fit(path)


if __name__ == '__main__':
    unittest.main()
