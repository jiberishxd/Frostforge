"""Compose black-background gallery cards from final shipped seasonal textures.

This only reads addon media. It never repaints or changes runtime artwork.
Pass a Cinzel Decorative Black font with --font (see docs/images/README.md).
"""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / 'Frostforge/Media'
SETS = (
    ('harvest_hollow', 'Harvest Hollow', 'Halloween'),
    ('witching_hour', 'Witching Hour', 'Halloween'),
    ('hallows_end', "Hallow's End", 'Halloween'),
    ('holly_hearth', 'Holly Hearth', 'Christmas'),
    ('winter_starlight', 'Winter Starlight', 'Christmas'),
    ('winter_veil', 'Winter Veil: Alliance', 'Christmas'),
    ('winter_veil_horde', 'Winter Veil: Horde', 'Christmas'),
)
KINDS = ('Portraits', 'UnitFrames', 'Minimaps', 'Hubs')
FONT_SHA256 = 'a6c1eb3e228f639a98aafd8a8e8a035582dd50ad5f8a84e9dcbc8664e7457114'


def font(path, size):
    return ImageFont.truetype(str(path), size)


def text(canvas, label, center, top, path, size, maximum=None):
    label = label.upper()
    draw = ImageDraw.Draw(canvas)
    face = font(path, size)
    while maximum and draw.textlength(label, font=face) > maximum:
        size -= 1
        face = font(path, size)
    bounds = draw.textbbox((0, 0), label, font=face)
    x = round(center - (bounds[2] - bounds[0]) / 2 - bounds[0])
    draw.text((x, top - bounds[1]), label, font=face, fill='white')


def artwork(name, kind):
    image = Image.open(MEDIA / kind / f'seasonal_{name}.png').convert('RGBA')
    if kind == 'Portraits':
        # Show one round target/focus portrait, not both packed atlas halves.
        image = image.crop((256, 0, 512, 256))
    elif kind == 'Hubs':
        # The PNG is a storage atlas. Restore its declared physical 3:1 canvas
        # before any uniform fitting so characters keep their intended shape.
        image = image.convert('RGBa').resize((2172, 724), Image.Resampling.LANCZOS).convert('RGBA')
    bounds = image.getchannel('A').getbbox()
    return image.crop(bounds)


def place(canvas, image, box):
    x, y, width, height = box
    scale = min(width / image.width, height / image.height)
    size = (round(image.width * scale), round(image.height * scale))
    fitted = image.convert('RGBa').resize(size, Image.Resampling.LANCZOS).convert('RGBA')
    canvas.paste(fitted, (round(x + (width-size[0])/2), round(y + (height-size[1])/2)), fitted)


def card(name, label, holiday, title_font, label_font):
    image = Image.new('RGB', (1600, 1200), 'black')
    text(image, "Jiberish's", 800, 30, label_font, 18)
    text(image, 'Frostforge', 800, 61, title_font, 65)
    text(image, label, 800, 160, title_font, 45, 1460)
    text(image, f'{holiday} collection', 800, 221, label_font, 18)
    for kind, heading, center, box in (
        ('Portraits', 'Portrait', 250, (105, 307, 290, 298)),
        ('UnitFrames', 'Unit frame', 800, (440, 314, 720, 278)),
        ('Minimaps', 'Minimap', 1350, (1195, 300, 310, 310)),
    ):
        text(image, heading, center, 271, label_font, 19)
        place(image, artwork(name, kind), box)
    text(image, 'Action hub', 800, 676, label_font, 21)
    place(image, artwork(name, 'Hubs'), (90, 726, 1420, 406))
    text(image, 'Addon artwork preview', 800, 1169, label_font, 14)
    return image


def overview(title_font, label_font):
    image = Image.new('RGB', (1800, 2500), 'black')
    text(image, 'Frostforge', 900, 30, title_font, 70)
    text(image, 'Seasonal collections', 900, 121, title_font, 33)
    text(image, 'Seven complete holiday sets', 900, 178, label_font, 19)
    for index, (name, label, holiday) in enumerate(SETS):
        y = 235 + index * 310
        text(image, label, 900, y, title_font, 29)
        for kind, heading, center, box in (
            ('Portraits', 'Portrait', 170, (70, y+72, 200, 190)),
            ('UnitFrames', 'Unit frame', 570, (315, y+89, 510, 160)),
            ('Hubs', 'Action hub', 1180, (870, y+81, 620, 180)),
            ('Minimaps', 'Minimap', 1645, (1545, y+72, 200, 190)),
        ):
            text(image, heading, center, y+48, label_font, 14)
            place(image, artwork(name, kind), box)
    text(image, 'Portraits / Unit frames / Action hubs / Minimaps', 900, 2433, label_font, 18)
    text(image, 'Addon artwork preview', 900, 2470, label_font, 14)
    return image


def build(args):
    assert hashlib.sha256(args.font.read_bytes()).hexdigest() == FONT_SHA256, 'Use the documented Cinzel Decorative Black font.'
    args.output.mkdir(parents=True, exist_ok=True)
    args.masters.mkdir(parents=True, exist_ok=True)
    rendered = [('seasonal-collection', overview(args.font, args.label_font))]
    rendered += [(f'seasonal-{name.replace("_", "-")}', card(name, label, holiday, args.font, args.label_font))
                 for name, label, holiday in SETS]
    report = []
    for stem, image in rendered:
        assert image.getpixel((0, 0)) == (0, 0, 0)
        image.save(args.output / f'{stem}.jpg', quality=94, subsampling=0, optimize=True)
        image.save(args.masters / f'{stem}.png', optimize=True)
        report.append({'image': f'{stem}.jpg', 'dimensions': list(image.size),
                       'bytes': (args.output / f'{stem}.jpg').stat().st_size})
    bundle = args.masters.parent / 'Frostforge-Seasonal-Gallery-PNGs.zip'
    with zipfile.ZipFile(bundle, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for stem, _ in rendered:
            archive.write(args.masters / f'{stem}.png', f'{stem}.png')
    (args.masters.parent / 'gallery-export.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps({'images': report, 'github_bytes': sum(r['bytes'] for r in report),
                      'png_bundle': str(bundle), 'bundle_bytes': bundle.stat().st_size}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--font', type=Path, required=True)
    parser.add_argument('--label-font', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'docs/images/seasonal')
    parser.add_argument('--masters', type=Path, default=ROOT / 'output/seasonal-gallery/png')
    build(parser.parse_args())
