"""Night Elf corrections must not alter other artwork or functional openings."""
import hashlib
import json
import sys
import unittest
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'artwork/nightelf-emblem-update'
sys.path.insert(0,str(ROOT/'tools'))
from apply_nightelf_emblem import apply_overlay
from fit_unit_shells import fit

class NightElfEmblemTests(unittest.TestCase):
    def test_only_three_requested_runtime_textures_change(self):
        before=json.loads((ART/'baseline.json').read_text())['assets']
        self.assertEqual(len(before),296)
        changed={p for p,sha in before.items() if hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=sha}
        self.assertEqual(changed,{'JiberishUI/Media/'+k+'/race_nightelf.tga' for k in ('UnitFrames','Hubs','Minimaps')})

    def test_generated_inlays_are_localized_reproducible_and_documented(self):
        records=json.loads((ART/'applied.json').read_text())
        self.assertEqual({r['kind'] for r in records},{'unit','hub','minimap'})
        for r in records:
            with self.subTest(kind=r['kind']):
                for field,hashkey in [('source','source_sha256'),('generated','generated_sha256'),('file','sha256')]:
                    self.assertEqual(hashlib.sha256((ROOT/r[field]).read_bytes()).hexdigest(),r[hashkey])
                before=Image.open(ROOT/r['source']);after=Image.open(ROOT/r['file'])
                mask=Image.new('L',before.size);ImageDraw.Draw(mask).polygon([tuple(p) for p in r['polygon']],fill=255)
                allowed=np.asarray(mask)>0;b,a=np.asarray(before),np.asarray(after)
                self.assertTrue(np.array_equal(a[~allowed],b[~allowed]))
                self.assertFalse(np.array_equal(a[allowed],b[allowed]))
                self.assertEqual(apply_overlay(r['kind']).tobytes(),after.tobytes())

    def test_bar_fitting_hub_seams_and_round_map_aperture_stay_intact(self):
        before,old=fit(ART/'unit-frame-before.png')
        after,new=fit(ROOT/'artwork/unit-frames/sculpted/references/race_nightelf.png')
        self.assertEqual(old,new)
        # Unit rails and both openings are unchanged through the bar region.
        self.assertEqual(before.crop((0,100,405,200)).tobytes(),after.crop((0,100,405,200)).tobytes())
        for kind,folder,size in [('hub','Hubs',(1024,512)),('minimap','Minimaps',(512,512))]:
            a=Image.open(ROOT/'artwork'/('hubs' if kind=='hub' else 'minimaps')/'assets/race_nightelf.png')
            alpha=np.asarray(a)[:,:,3]
            self.assertFalse(alpha[:4].any() or alpha[-4:].any() or alpha[:,:4].any() or alpha[:,-4:].any())
            if kind=='hub':self.assertFalse(alpha[:440,620:1552].any())
            else:
                self.assertFalse(alpha[:8].any() or alpha[-8:].any() or alpha[:,:8].any() or alpha[:,-8:].any())
                y,x=np.indices(alpha.shape)
                self.assertFalse(alpha[(x-256)**2+(y-256)**2<148**2].any())
            game=Image.open(ROOT/'JiberishUI/Media'/folder/'race_nightelf.tga')
            self.assertEqual(a.resize(size,Image.Resampling.LANCZOS).tobytes(),game.tobytes())
