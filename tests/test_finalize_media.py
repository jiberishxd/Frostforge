"""Source rebuilds must keep the approved PNG bytes and their pixel provenance."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from finalize_media import finalize


class FinalizeMediaTests(unittest.TestCase):
    def fixture(self, root):
        media = root / 'Frostforge/Media'; media.mkdir(parents=True)
        (root / 'docs').mkdir()
        image = Image.new('RGBA', (8, 8), (7, 17, 27, 127))
        tga = media / 'sample.tga'; image.save(tga, compression=None)
        asset = {'file': 'Frostforge/Media/sample.tga', 'sha256': hashlib.sha256(tga.read_bytes()).hexdigest()}
        (root / 'docs/phase1-assets.json').write_text(json.dumps({'assets': [asset]}))
        (root / 'Frostforge/Test.lua').write_text('return "Interface\\\\AddOns\\\\Frostforge\\\\Media\\\\sample.tga"\n')
        return image, tga

    def test_matching_png_is_preserved_and_runtime_paths_are_updated(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); image, tga = self.fixture(root)
            png = tga.with_suffix('.png'); image.save(png, compress_level=0)
            before = png.read_bytes()
            self.assertEqual(finalize(root), 1)
            self.assertEqual(png.read_bytes(), before)
            self.assertFalse(tga.exists())
            self.assertIn('sample.png', (root / 'Frostforge/Test.lua').read_text())
            self.assertEqual(finalize(root), 0)

    def test_changed_pixels_replace_stale_png_without_resizing(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); image, tga = self.fixture(root)
            png = tga.with_suffix('.png'); Image.new('RGBA', (4, 4)).save(png)
            finalize(root)
            with Image.open(png) as actual:
                self.assertEqual(actual.size, image.size)
                self.assertEqual(actual.tobytes(), image.tobytes())

    def test_incorrect_source_hash_stops_before_changing_files(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); _, tga = self.fixture(root)
            tga.write_bytes(tga.read_bytes() + b'changed')
            with self.assertRaises(AssertionError):
                finalize(root)
            self.assertTrue(tga.exists())
            self.assertFalse(tga.with_suffix('.png').exists())
