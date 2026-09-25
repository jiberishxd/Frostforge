"""Apply reviewed background-only masks to retained hub generations.

Masks are source-sized, explicitly reviewed selections, not a global gray key:
neutral metal, antlers and painted checker cloth must remain opaque. Only alpha
changes. Source and mask hashes fail closed if either input is replaced.
"""
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / 'artwork/hubs/alpha-cleanup/manifest.json'


def clean(image, identity):
    record = json.loads(REPORT.read_text())['corrections'].get(identity)
    if not record:
        return image
    pixels = np.array(image.convert('RGBA'))
    assert hashlib.sha256(pixels.tobytes()).hexdigest() == record['input_pixels_sha256'], identity
    path = ROOT / record['mask']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == record['mask_sha256'], identity
    mask_image = Image.open(path)
    assert mask_image.mode == 'L' and mask_image.size == image.size, identity
    mask = np.asarray(mask_image)
    assert set(np.unique(mask)) == {0, 255}, identity
    selected = mask > 0
    assert int(selected.sum()) == record['cleared_pixels'], identity
    pixels[selected, 3] = 0
    return Image.fromarray(pixels)
