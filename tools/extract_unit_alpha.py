"""User-authorized local alpha extraction for the revised Paladin unit artwork.

The generator painted a neutral checkerboard. Flood only neutral pixels connected
to the outside or the two deliberate openings; enclosed silver details stay opaque.
No global color key is applied to the metal or feathers.
"""
from pathlib import Path
import json
import hashlib
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "artwork/paladin-ret-review/design-edits/unit-continuous-joins-rgb.png"
OUTPUT = ROOT / "artwork/paladin-ret-review/assets/unit-shell-v2.png"


def main():
    source = Image.open(SOURCE).convert("RGB")
    rgb = np.asarray(source)
    chroma = rgb.max(axis=2).astype(int) - rgb.min(axis=2).astype(int)
    neutral = Image.fromarray(np.where(chroma <= 12, 255, 0).astype("uint8")).copy()
    w, h = source.size
    seeds = [(0, 0), (w-1, 0), (0, h-1), (w-1, h-1), (570, 500), (1200, 520)]
    for point in seeds:
        if neutral.getpixel(point) == 255:
            ImageDraw.floodfill(neutral, point, 128)
    foreground = Image.fromarray(np.where(np.asarray(neutral) == 128, 0, 255).astype("uint8")).copy()
    # Retain the connected sculpted shell; reject disconnected checker specks.
    assert foreground.getpixel((570, 300)) == 255
    ImageDraw.floodfill(foreground, (570, 300), 128)
    alpha = np.where(np.asarray(foreground) == 128, 255, 0).astype("uint8")
    rgba = np.dstack((rgb.copy(), alpha))
    rgba[alpha == 0, :3] = 0
    result = Image.fromarray(rgba)
    result.save(OUTPUT)
    report = {
        "source": str(SOURCE.relative_to(ROOT)), "output": str(OUTPUT.relative_to(ROOT)),
        "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        "output_sha256": hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
        "size": list(result.size), "alpha_bounds": list(result.getchannel("A").getbbox()),
        "opaque_fraction": float((alpha > 0).mean()),
        "method": "Neutral-background flood from exterior and opening seeds, retaining the connected shell; RGB of retained art unchanged",
        "authorization": "User explicitly requested local Python processing after built-in alpha extraction failed twice",
        "visually_qualified": False,
    }
    (ROOT / "artwork/paladin-ret-review/unit-alpha-report.json").write_text(json.dumps(report, indent=2) + "\n")
    for point in seeds:
        assert result.getpixel(point)[3] == 0
    assert not alpha[460:585,900:1500].any(), "The bar opening must contain no checkerboard islands"
    assert not alpha[440:625,500:680].any(), "The portrait opening must remain clear"
    assert 0.15 < report["opaque_fraction"] < 0.65
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
