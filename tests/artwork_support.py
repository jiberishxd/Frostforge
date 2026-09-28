"""Compare retained TGA-era source records with the lossless PNG runtime art."""
import io
from pathlib import Path
from PIL import Image


def runtime_path(path):
    path = Path(path)
    if not path.exists() and path.suffix == ".tga" and "Frostforge/Media/" in path.as_posix():
        return path.with_suffix(".png")
    return path


def open_asset(path):
    return Image.open(runtime_path(path))


def legacy_bytes(path):
    path = Path(path)
    actual = runtime_path(path)
    if actual == path:
        return path.read_bytes()
    # The recorded TGA bytes were written with Pillow, uncompressed. Rebuild
    # those bytes only in memory so old provenance checks retain their meaning.
    with Image.open(actual) as image, io.BytesIO() as buffer:
        image.save(buffer, format="TGA", compression=None)
        return buffer.getvalue()
