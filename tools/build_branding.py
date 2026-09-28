"""Export the approved transparent logo and subtle stone settings material."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = "docs/images/logo.png"
OUTPUT = "Frostforge/Media/Branding/frostforge-logo.tga"


def build():
    source = Image.open(ROOT / SOURCE)
    assert source.mode == "RGBA" and source.getchannel("A").getextrema() == (0, 255)
    # Pillow resamples RGBA with premultiplied alpha to avoid dark edge halos.
    logo = source.resize((512, 512), Image.Resampling.LANCZOS)
    (ROOT / OUTPUT).parent.mkdir(parents=True, exist_ok=True)
    logo.save(ROOT / OUTPUT, compression=None)
    record = {
        "id": "frostforge-logo", "label": "Jiberish's Frostforge", "kind": "brand-logo",
        "file": OUTPUT, "source": SOURCE, "source_size": list(source.size),
        "source_sha256": hashlib.sha256((ROOT / SOURCE).read_bytes()).hexdigest(),
        "sha256": hashlib.sha256((ROOT / OUTPUT).read_bytes()).hexdigest(),
        "size": list(logo.size), "alphaBounds": list(logo.getchannel("A").getbbox()),
        "clear_points": [[0, 0], [0.99, 0], [0, 0.99], [0.99, 0.99]],
        "transform": "Approved transparent PNG resampled to 512x512 with Lanczos; uncompressed 32-bit RGBA TGA.",
        "provenance": "docs/images/LOGO-SOURCE.md",
    }
    # A square center crop keeps the stone grain natural; borders and button
    # bevels use Blizzard's native assets, tinted in Lua rather than stretched art.
    stone_source = "artwork/settings/sources/frostforge-frame.png"
    master = Image.open(ROOT / stone_source).convert("RGBA")
    crop = [round(master.width*.25),round(master.height*.25),round(master.width*.75),round(master.height*.75)]
    stone = master.crop(crop).resize((256, 256), Image.Resampling.LANCZOS)
    stone_output = "Frostforge/Media/Branding/frostforge-stone.tga"
    stone.save(ROOT / stone_output, compression=None)
    stone.save(ROOT / "artwork/settings/frostforge-stone.png")
    material = {
        "id": "frostforge-stone", "label": "Frostforge settings stone", "kind": "settings-background",
        "file": stone_output, "source": stone_source, "source_size": list(master.size),
        "source_sha256": hashlib.sha256((ROOT / stone_source).read_bytes()).hexdigest(),
        "sha256": hashlib.sha256((ROOT / stone_output).read_bytes()).hexdigest(),
        "size": list(stone.size), "alphaBounds": list(stone.getchannel("A").getbbox()),
        "source_crop": crop,
        "transform": "Center half of the retained generated rough-stone frame, resampled to 256x256 with Lanczos; tinted in Lua.",
    }
    path = ROOT / "docs/phase1-assets.json"
    manifest = json.loads(path.read_text())
    manifest["assets"] = [a for a in manifest["assets"] if a.get("kind") not in
                          ("brand-logo", "settings-background")] + [record, material]
    path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Exported {OUTPUT} with transparent corners and antialiased edges")


if __name__ == "__main__":
    build()
