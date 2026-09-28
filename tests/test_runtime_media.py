"""The compressed runtime library must preserve every approved original pixel."""
import hashlib
import io
import json
from pathlib import Path
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


class RuntimeMediaTests(unittest.TestCase):
    def test_all_compressed_textures_preserve_original_tga_pixels(self):
        assets = json.loads((ROOT / "docs/phase1-assets.json").read_text())["assets"]
        self.assertEqual(len(assets), 298)
        for asset in assets:
            with self.subTest(asset=asset["file"]):
                path = ROOT / asset["file"]
                self.assertEqual(path.suffix, ".png")
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), asset["sha256"])
                with Image.open(path) as image, io.BytesIO() as buffer:
                    self.assertEqual(image.mode, "RGBA")
                    image.save(buffer, format="TGA", compression=None)
                    self.assertEqual(hashlib.sha256(buffer.getvalue()).hexdigest(), asset["legacy_tga_sha256"])
