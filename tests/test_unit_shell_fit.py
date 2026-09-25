"""Guard source silhouettes, thick rails, transparency and unrelated artwork."""
import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from fit_unit_shells import fit


class ShellFitTests(unittest.TestCase):
    def test_portraits_hubs_and_minimaps_unchanged(self):
        baseline = json.loads((ROOT / 'tests/fixtures/pre-audit-art.json').read_text())
        self.assertEqual(len(baseline['assets']), 126)
        for name, expected in baseline['assets'].items():
            with self.subTest(asset=name):
                self.assertEqual(hashlib.sha256((ROOT / name).read_bytes()).hexdigest(), expected)

    def test_all_42_shells_reproduce_with_source_proportions(self):
        reports = json.loads((ROOT / 'artwork/unit-frames/sculpted/fit-report.json').read_text())
        self.assertEqual(len(reports), 42)
        for report in reports:
            with self.subTest(artwork=report['id']):
                image, measured = fit(ROOT / report['source'])
                expected = np.asarray(Image.open(ROOT / report['file']).convert('RGBA'))
                self.assertTrue(np.array_equal(np.asarray(image), expected))
                self.assertEqual(measured, report['measured'])
                self.assertLess(abs(measured['scale'][0]-measured['scale'][1]), .001)
                reg = measured['registration']
                original_gap = measured['power'][1]-measured['health'][3]
                self.assertAlmostEqual(reg['divider'], original_gap*measured['scale'][1])
                for region in ('health', 'power'):
                    x1,y1,x2,y2=reg[region]
                    for fraction in (.25,.75):
                        self.assertEqual(image.getpixel((round(x1+(x2-x1)*fraction), round((y1+y2)/2)))[3], 0)

    def test_approved_priest_and_draenei_keep_thick_separator(self):
        for name in ('class_priest', 'race_draenei'):
            _, measured=fit(ROOT/'artwork/unit-frames/sculpted/references'/f'{name}.png')
            h=measured['registration']['health']
            gap=20*measured['registration']['divider']/(h[3]-h[1])
            self.assertGreater(gap, 6, name)
            self.assertLess(gap, 9, name)

    def test_curved_shoulder_and_outer_tip_are_not_cropped(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'shoulder.png'
            image=Image.new('RGB',(512,256),(0,255,0)); draw=ImageDraw.Draw(image)
            draw.rectangle((50,90,450,195),fill=(130,90,50))
            draw.rectangle((65,105,435,143),fill=(0,255,0))
            draw.rectangle((65,164,435,180),fill=(0,255,0))
            draw.polygon([(380,90),(420,40),(450,90)],fill=(210,80,30))
            draw.rectangle((487,1,496,30),fill=(210,80,30))
            image.save(path)
            output, measured=fit(path); sx,sy=measured['scale'];ox,oy=measured['offset']
            for x,y in ((420,65),(491,12),(250,154)):
                self.assertGreater(output.getpixel((round(ox+x*sx),round(oy+y*sy)))[3], 240)
            self.assertGreater(measured['registration']['divider'], 18)

    def test_invalid_openings_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'invalid.png'
            Image.new('RGB', (512, 256), 'green').save(path)
            with self.assertRaises(AssertionError):
                fit(path)


if __name__ == '__main__':
    unittest.main()
