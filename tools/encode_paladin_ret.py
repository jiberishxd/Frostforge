"""Encode reviewed RGBA PNG candidates as WoW TGA textures, without repainting them."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "artwork/paladin-ret-review/assets"
OUTPUT = ROOT / "JiberishUI/Media/PaladinRet"
SPECS = (
    ("minimap-v1.png", "minimap.tga", (1024, 1024), (340, 340), ((.5, .51),)),
)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    assets = []
    for name, target, size, display, clear_points in SPECS:
        source, destination = SOURCE / name, OUTPUT / target
        original = Image.open(source)
        assert original.mode == "RGBA", "Reject opaque/checkerboard design references"
        assert original.getchannel("A").getextrema() == (0, 255)
        # File encoding/resampling only. Runtime dimensions restore the artwork's
        # aspect ratio within each configured piece; target mirroring is local.
        encoded = original.resize(size, Image.Resampling.LANCZOS)
        alpha = encoded.getchannel("A")
        for x, y in clear_points:
            assert alpha.getpixel((int(x*size[0]), int(y*size[1]))) == 0, "Functional opening must be clear"
        encoded.save(destination, format="TGA", compression=None)
        reopened = Image.open(destination)
        assert reopened.mode == "RGBA" and reopened.tobytes() == encoded.tobytes()
        assets.append({
            "file": destination.relative_to(ROOT).as_posix(),
            "source": source.relative_to(ROOT).as_posix(),
            "source_sha256": digest(source), "source_size": list(original.size),
            "crop": None, "transform": "RGBA Lanczos resample for power-of-two TGA encoding; no art edits",
            "size": list(size), "default_display_size": list(display),
            "alphaBounds": list(alpha.getbbox()), "clear_points": list(clear_points),
            "sha256": digest(destination),
            "phase1_usage": "User-authorized in-game artwork test; visual fit not qualified",
        })
    (ROOT / "docs/phase1-assets.json").write_text(json.dumps({
        "assets": assets, "in_game_qualified": False,
        "review": "artwork/paladin-ret-review/index.html",
        "prompts": "artwork/paladin-ret-review/prompts.json",
    }, indent=2) + "\n")
    print("Encoded minimap; run build_portraits.py and build_hubs.py to complete the media manifest.")


if __name__ == "__main__":
    main()
