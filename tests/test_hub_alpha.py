"""Background removal must preserve painted RGB, fitting and shipped alpha."""
import hashlib
import json
import sys
import unittest
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from clean_hub_alpha import clean
from build_hubs import register
from build_portraits import extract_alpha

class HubAlphaTests(unittest.TestCase):
    def test_reviewed_masks_preserve_art_and_registration(self):
        audit=json.loads((ROOT/'artwork/hubs/alpha-cleanup/manifest.json').read_text())
        manifest={a['id']:a for a in json.loads((ROOT/'artwork/hubs/manifest.json').read_text())['assets']}
        self.assertEqual(set(audit['reviewed_hubs']),set(manifest))
        self.assertEqual(len(audit['reviewed_hubs']),42)
        for identity,r in audit['corrections'].items():
            with self.subTest(identity=identity):
                raw,_=extract_alpha(Image.open(ROOT/manifest[identity]['original']))
                corrected=clean(raw,identity);before=np.array(raw);after=np.array(corrected)
                mask=np.array(Image.open(ROOT/r['mask']))>0
                self.assertTrue(np.array_equal(before[:,:,:3],after[:,:,:3]))
                self.assertTrue(np.array_equal(before[~mask],after[~mask]))
                self.assertFalse(after[mask,3].any())
                original_fit,old_map=register(raw);fitted,new_map=register(corrected)
                self.assertEqual(old_map,new_map)
                self.assertEqual(fitted.size,(2172,724))
                self.assertIsNone(fitted.crop((620,0,1552,440)).getchannel('A').getbbox())
                self.assertEqual(fitted.tobytes(),Image.open(ROOT/manifest[identity]['source']).tobytes())
                encoded=fitted.resize((1024,512),Image.Resampling.LANCZOS)
                self.assertEqual(encoded.tobytes(),Image.open(ROOT/manifest[identity]['file']).tobytes())
                self.assertEqual(encoded.tobytes(),Image.open(ROOT/'artwork/hubs/game'/f'{identity}.png').tobytes())

    def test_reported_checker_holes_are_clear_and_silver_trim_survives(self):
        samples={'race_human':[(1827,267)],'race_highmountaintauren':[(123,220),(2070,257)],
                 'class_monk':[(44,199)],'race_voidelf':[(2070,150)]}
        for identity,points in samples.items():
            raw,_=extract_alpha(Image.open(ROOT/'artwork/hubs/sculpted-originals'/f'{identity}.png'))
            image=clean(raw,identity)
            for point in points:
                with self.subTest(identity=identity,point=point):self.assertEqual(image.getpixel(point)[3],0)
            if identity=='race_voidelf':
                for point in [(367,420),(1975,202),(2010,292)]:
                    self.assertEqual(image.getpixel(point),raw.getpixel(point))
                    self.assertGreater(image.getpixel(point)[3],240)
