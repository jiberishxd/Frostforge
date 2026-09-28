"""The hub edition must preserve the approved frames and native button aperture."""
import hashlib
import os
import json
import unittest
from pathlib import Path
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
if os.environ.get("FROSTFORGE_ARTWORK_TESTS") != "1":
    raise unittest.SkipTest("Source-art audit: attach artwork and set FROSTFORGE_ARTWORK_TESTS=1")
if not (ROOT / "artwork").is_dir():
    raise RuntimeError("FROSTFORGE_ARTWORK_TESTS=1 requires the separate artwork library")
from artwork_support import open_asset, legacy_bytes

ART=ROOT/'artwork/hubs'
def digest(path):return hashlib.sha256(legacy_bytes(path)).hexdigest()

class HubRestyleTests(unittest.TestCase):
    def test_approved_unit_frames_and_portraits_are_unchanged(self):
        lock=json.loads((ART/'style-remaster/reference-lock.json').read_text())['files']
        self.assertEqual(len(lock),211)
        for name,sha in lock.items():
            # The later, user-requested Night Elf correction retains these
            # exact source pixels as its baseline; localized edits are checked
            # independently in test_nightelf_emblem.py.
            if name=='artwork/unit-frames/sculpted/references/race_nightelf.png':
                self.assertEqual(digest(ROOT/'artwork/nightelf-emblem-update/unit-frame-before.png'),sha)
                continue
            if name=='Frostforge/Media/UnitFrames/race_nightelf.tga':
                import io
                buffer=io.BytesIO()
                open_asset(ROOT/'artwork/nightelf-emblem-update/unit-frame-fitted-before.png').save(buffer,format='TGA',compression=None)
                self.assertEqual(hashlib.sha256(buffer.getvalue()).hexdigest(),sha)
                continue
            with self.subTest(file=name):self.assertEqual(digest(ROOT/name),sha)

    def test_remastered_library_has_exact_exports_and_clear_openings(self):
        entries=json.loads((ART/'manifest.json').read_text())['assets']
        records={p.stem:json.loads(p.read_text()) for p in (ART/'style-remaster/records').glob('*.json')}
        self.assertEqual(len(entries),42)
        self.assertEqual(set(records),{a['id'] for a in entries})
        old={a['id']:a for a in json.loads((ART/'style-remaster/before/manifest.json').read_text())['assets']}
        for a in entries:
            with self.subTest(identity=a['id']):
                self.assertEqual(a['registration'],old[a['id']]['registration'])
                self.assertNotEqual(a['source_sha256'],old[a['id']]['source_sha256'])
                source=open_asset(ROOT/a['source'])
                self.assertEqual(source.mode,'RGBA')
                self.assertEqual(source.size,(2172,724))
                alpha=np.asarray(source.getchannel('A'))
                self.assertFalse(alpha[:440,620:1552].any())
                self.assertFalse(alpha[:4].any() or alpha[-4:].any() or alpha[:,:4].any() or alpha[:,-4:].any())
                encoded=open_asset(ROOT/a['file'])
                self.assertEqual(encoded.tobytes(),open_asset(ART/'game'/(a['id']+'.png')).tobytes())
                self.assertEqual(digest(ROOT/a['original']),a['original_sha256'])
                r=a['style_remaster']
                self.assertEqual(digest(ROOT/r['target']),r['target_sha256'])
                self.assertEqual(digest(ROOT/r['style_reference']),r['style_reference_sha256'])
                # Strong matte colors cannot remain opaque after extraction.
                rgb=np.asarray(source,dtype=np.int16)
                if records[a['id']]['matte']=='green':key=rgb[:,:,1]-np.maximum(rgb[:,:,0],rgb[:,:,2])
                else:key=np.minimum(rgb[:,:,0],rgb[:,:,2])-rgb[:,:,1]
                self.assertFalse(((key>225)&(rgb[:,:,3]>16)).any())
