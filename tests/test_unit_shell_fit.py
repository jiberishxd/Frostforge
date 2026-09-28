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
    def test_druid_antlers_preserve_rails_openings_and_other_source_pixels(self):
        root=ROOT/'artwork/unit-frames/sculpted/druid-antler-correction'
        record=json.loads((root/'generation.json').read_text())
        before=np.asarray(Image.open(ROOT/record['before']))
        after=np.asarray(Image.open(ROOT/record['file']))
        allowed=np.zeros(before.shape[:2],dtype=bool)
        for x1,y1,x2,y2 in record['boxes']: allowed[y1:y2,x1:x2]=True
        self.assertTrue(np.array_equal(before[~allowed],after[~allowed]))
        self.assertFalse(np.array_equal(before[allowed],after[allowed]))
        old,old_fit=fit(ROOT/record['before']);new,new_fit=fit(ROOT/record['file'])
        self.assertEqual(old_fit,new_fit)
        self.assertTrue(np.array_equal(np.asarray(old)[100:],np.asarray(new)[100:]))

    def test_complete_cast_silhouettes_have_clear_centers_and_uncropped_details(self):
        source = (ROOT / 'artwork/cast-bars/runtime-borders.js').read_text()
        data = json.loads(source.split('window.castBorders=', 1)[1].rstrip(';\n'))
        self.assertEqual(len(data['themes']), 42)
        for identity, theme in data['themes'].items():
            image = Image.open(ROOT / 'artwork/cast-bars/assets' / (theme['file'] + '.png')).convert('RGBA')
            alpha = np.asarray(image)[:,:,3]
            with self.subTest(identity=identity):
                self.assertEqual(set(theme['styles']), {'CAPPED'})
                self.assertEqual(image.size, (512,128))
                self.assertFalse(alpha[48:80,48:464].any())
                self.assertFalse(alpha[:4].any() or alpha[-4:].any() or alpha[:,:4].any() or alpha[:,-4:].any())
                self.assertTrue((alpha[:48,48:464]>32).any(axis=0).all())
                self.assertTrue((alpha[80:,48:464]>32).any(axis=0).all())
                game = Image.open(ROOT / 'JiberishUI/Media/CastBars' / (theme['file']+'.tga')).convert('RGBA')
                self.assertEqual(image.tobytes(), game.tobytes())
                for style, pieces in theme['styles'].items():
                    self.assertEqual(len(pieces), 8)
                    for name, p in pieces.items():
                        x,y,w,h = (p[k] for k in ('x','y','w','h'))
                        self.assertTrue(x+w<=0 or x>=180 or y+h<=0 or y>=16)
                        if name in ('11','13','31','33'):
                            sx=w/((p['u2']-p['u1'])*512)
                            sy=h/((p['v2']-p['v1'])*128)
                            self.assertAlmostEqual(sx,sy,places=6)
                    self.assertEqual(min(p['u1'] for p in pieces.values()),0)
                    self.assertEqual(max(p['u2'] for p in pieces.values()),1)
                    self.assertEqual(min(p['v1'] for p in pieces.values()),0)
                    self.assertEqual(max(p['v2'] for p in pieces.values()),1)

    def test_mage_emblem_changes_are_localized_and_keep_frame_openings(self):
        root=ROOT/'artwork/mage-emblem-correction'
        for record in json.loads((root/'applied.json').read_text()):
            with self.subTest(kind=record['kind']):
                before=np.asarray(Image.open(ROOT/record['source']))
                after=np.asarray(Image.open(ROOT/record['file']))
                allowed=np.zeros(before.shape[:2],dtype=bool)
                for x1,y1,x2,y2 in record['boxes']: allowed[y1:y2+1,x1:x2+1]=True
                self.assertTrue(np.array_equal(before[~allowed],after[~allowed]))
                self.assertFalse(np.array_equal(before[allowed],after[allowed]))
        before=np.asarray(Image.open(root/'unit-frame-fitted-before.png'))
        after=np.asarray(Image.open(ROOT/'artwork/unit-frames/assets/class_mage.png'))
        self.assertTrue(np.array_equal(before[:,:,3],after[:,:,3]))

    def test_health_is_plain_color_neutral_stone_for_every_identity(self):
        assets = json.loads((ROOT / 'artwork/unit-frames/manifest.json').read_text())
        health = [a for a in assets if a['file'].endswith('-health.tga')]
        self.assertEqual(len(health), 42)
        pixels = None
        for asset in health:
            with self.subTest(asset=asset['file']):
                image = Image.open(ROOT / asset['file']).convert('RGBA')
                self.assertEqual(image.size, (256, 32))
                actual = np.asarray(image)
                self.assertTrue(np.all(actual[:, :, 3] == 255))
                self.assertTrue(np.array_equal(actual[:, :, 0], actual[:, :, 1]))
                self.assertTrue(np.array_equal(actual[:, :, 1], actual[:, :, 2]))
                self.assertGreater(float(actual[:, :, 0].std()), 5)
                self.assertLess(float(actual[:, :, 0].std()), 40)
                preview = np.asarray(Image.open(ROOT / asset['source']).convert('RGBA'))
                self.assertTrue(np.array_equal(actual, preview))
                if pixels is not None:
                    self.assertTrue(np.array_equal(actual, pixels))
                pixels = actual
                refs = {ref['file'] for ref in asset['references']}
                self.assertEqual(refs, {
                    'artwork/unit-frames/references/plain-stone.png',
                    'artwork/unit-frames/references/plain-stone-generation.json',
                })

    def test_other_portraits_hubs_and_minimaps_unchanged(self):
        baseline = json.loads((ROOT / 'tests/fixtures/pre-audit-art.json').read_text())
        self.assertEqual(len(baseline['assets']), 126)
        hub_corrections=json.loads((ROOT/'artwork/hubs/alpha-cleanup/manifest.json').read_text())['corrections']
        import io
        retained_hubs={Path(a['file']).stem:a for a in json.loads((ROOT/'artwork/hubs/style-remaster/before/manifest.json').read_text())['assets']}
        for name, expected in baseline['assets'].items():
            if name.endswith('Portraits/class_mage.tga'): continue
            if name=='JiberishUI/Media/Minimaps/race_nightelf.tga':
                buffer=io.BytesIO()
                Image.open(ROOT/'artwork/nightelf-emblem-update/minimap-before.png').save(buffer,format='TGA',compression=None)
                self.assertEqual(hashlib.sha256(buffer.getvalue()).hexdigest(),expected)
                continue  # Only the top moon changes; covered in test_nightelf_emblem.py.
            if '/Hubs/' in name and Path(name).stem in hub_corrections:
                self.assertEqual(expected,hub_corrections[Path(name).stem]['before_tga_sha256'])
                continue  # Alpha-only changes are checked in test_hub_alpha.py.
            if '/Hubs/' in name:
                retained=retained_hubs[Path(name).stem]
                buffer=io.BytesIO()
                Image.open(ROOT/retained['file']).save(buffer,format='TGA',compression=None)
                self.assertEqual(expected,hashlib.sha256(buffer.getvalue()).hexdigest())
                continue  # All current hubs are checked in test_hub_restyle.py.
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
