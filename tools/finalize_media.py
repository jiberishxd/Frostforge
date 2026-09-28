"""Finalize a source builder's TGA exports as lossless runtime PNGs.

Existing PNG bytes are retained when their pixels already match. No image is
resized or recolored. Run after the selected source-art builder, before checks.
"""
import hashlib
import io
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def finalize(root=ROOT):
    root = Path(root)
    inventory = root / 'docs/phase1-assets.json'
    manifest = json.loads(inventory.read_text())
    planned = []
    replacements = []
    for asset in manifest['assets']:
        source = root / asset['file']
        if source.suffix != '.tga':
            continue
        source.relative_to(root / 'Frostforge/Media')
        data = source.read_bytes()
        assert hashlib.sha256(data).hexdigest() == asset['sha256'], source
        target = source.with_suffix('.png')
        with Image.open(source) as image:
            assert image.mode == 'RGBA', source
            with io.BytesIO() as buffer:
                image.save(buffer, format='TGA', compression=None)
                assert buffer.getvalue() == data, 'Expected canonical builder TGA output'
            encoded = None
            if target.exists():
                with Image.open(target) as existing:
                    if existing.format == 'PNG' and existing.mode == 'RGBA' and existing.size == image.size and existing.tobytes() == image.tobytes():
                        encoded = target.read_bytes()
            if encoded is None:
                with io.BytesIO() as buffer:
                    image.save(buffer, format='PNG', optimize=True)
                    encoded = buffer.getvalue()
            with Image.open(io.BytesIO(encoded)) as verified:
                assert verified.size == image.size and verified.tobytes() == image.tobytes()
        old = asset['file']
        asset['legacy_tga_sha256'] = hashlib.sha256(data).hexdigest()
        asset['file'] = target.relative_to(root).as_posix()
        asset['sha256'] = hashlib.sha256(encoded).hexdigest()
        asset['encoding'] = 'PNG; lossless pixels verified against the original TGA'
        for slash in ('\\', '\\\\'):
            replacements.append((('Interface/AddOns/' + old).replace('/', slash),
                                 ('Interface/AddOns/' + asset['file']).replace('/', slash)))
        planned.append((source, target, encoded))
    # Verify all input bytes before changing outputs or the inventory.
    for source, target, encoded in planned:
        if not target.exists() or target.read_bytes() != encoded:
            target.write_bytes(encoded)
    if planned:
        for path in (root / 'Frostforge').rglob('*'):
            if path.suffix in ('.lua', '.toc'):
                text = path.read_text()
                updated = text
                for before, after in replacements:
                    updated = updated.replace(before, after)
                if updated != text:
                    path.write_text(updated)
        inventory.write_text(json.dumps(manifest, indent=2) + '\n')
        for source, _, _ in planned:
            source.unlink()
    report = root / 'artwork/unit-frames/sculpted/fit-report.json'
    if report.is_file():
        (root / 'docs/artwork/unit-frame-fit-report.json').write_bytes(report.read_bytes())
    return len(planned)


if __name__ == '__main__':
    print(f'Finalized {finalize()} generated textures; existing matching PNG bytes retained.')
