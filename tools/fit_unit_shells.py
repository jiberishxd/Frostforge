"""Extract original unit shells without warping rails or cropping ornaments.

The native-bar adapter consumes measured openings instead of forcing every
painting into a four-pixel divider. All sources retain their aspect ratio.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'artwork/unit-frames/sculpted'
OUT = ART / 'assets'


def runs(values):
    edges = np.diff(np.r_[False, values, False].astype(int))
    return list(zip(np.where(edges == 1)[0], np.where(edges == -1)[0]))


def extract(source):
    image = Image.open(source).convert('RGBA')
    a = np.array(image)
    rgb = a[:, :, :3].astype(float)
    green = (rgb[:, :, 1] > 170) & (rgb[:, :, 0] < 70) & (rgb[:, :, 2] < 70)
    green &= rgb[:, :, 1] - np.maximum(rgb[:, :, 0], rgb[:, :, 2]) > 110
    background = green | (a[:, :, 3] == 0)
    a[background] = 0
    # Despill only at the keyed green boundary; retain all painted shapes.
    adjacent = np.asarray(Image.fromarray(np.uint8(green * 255)).filter(ImageFilter.MaxFilter(5))) > 0
    fringe = adjacent & ~background
    a[:, :, 1] = np.where(fringe, np.minimum(a[:, :, 1], np.maximum(a[:, :, 0], a[:, :, 2]) * 1.08), a[:, :, 1])
    h, w = background.shape
    middle = background[:, int(w * .35):int(w * .60)].mean(axis=1) > .8
    slots = [r for r in runs(middle) if h * .27 < r[0] < h * .8 and r[1] - r[0] > h * .018]
    assert len(slots) >= 2, (source, 'Missing health/power openings', slots)
    hs, he = slots[0]
    ps, pe = slots[1]
    horizontal = [r for r in runs(background[(hs + he) // 2]) if r[0] < w / 2 < r[1]]
    assert len(horizontal) == 1 and horizontal[0][1] - horizontal[0][0] > w * .4
    left, right = horizontal[0]
    assert ps > he, (source, 'Missing painted divider')
    return Image.fromarray(a), dict(health=[int(left), int(hs), int(right), int(he)],
                                   power=[int(left), int(ps), int(right), int(pe)])


def fit(source):
    image, measured = extract(source)
    w, h = image.size
    factor = min(504 / w, 248 / h)
    size = (round(w * factor), round(h * factor))
    # Pillow's RGBa mode resamples premultiplied alpha, preventing green halos.
    fitted = image.convert('RGBa').resize(size, Image.Resampling.LANCZOS).convert('RGBA')
    offset = ((512 - size[0]) // 2, (256 - size[1]) // 2)
    result = Image.new('RGBA', (512, 256))
    result.paste(fitted, offset)
    registration = {'canvas': [512, 256], 'margin': 4}
    for kind in ('health', 'power'):
        x1, y1, x2, y2 = measured[kind]
        registration[kind] = [offset[0] + x1 * size[0] / w, offset[1] + y1 * size[1] / h,
                              offset[0] + x2 * size[0] / w, offset[1] + y2 * size[1] / h]
    registration['divider'] = registration['power'][1] - registration['health'][3]
    measured.update(scale=[size[0] / w, size[1] / h], offset=list(offset), registration=registration)
    return result, measured


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    reports = []
    for job in json.loads((ART / 'generation-prompts.json').read_text()):
        source = ART / 'references' / (job['id'] + '.png')
        target = OUT / (job['id'] + '.png')
        image, measured = fit(source)
        image.save(target)
        reports.append(dict(id=job['id'], fit_version=3, source=str(source.relative_to(ROOT)),
                            source_sha256=sha(source), file=str(target.relative_to(ROOT)), sha256=sha(target), measured=measured))
    (ART / 'fit-report.json').write_text(json.dumps(reports, indent=2) + '\n')
    sheet = Image.new('RGB', (1536, ((len(reports) + 3) // 4) * 212), (35, 39, 42))
    draw = ImageDraw.Draw(sheet)
    for i, report in enumerate(reports):
        image = Image.open(ROOT / report['file']).resize((384, 192), Image.Resampling.LANCZOS)
        x, y = (i % 4) * 384, (i // 4) * 212
        sheet.paste(image, (x, y), image)
        draw.text((x + 12, y + 194), report['id'], fill=(235, 220, 182))
    sheet.save(ART / 'review.jpg')
    print('Preserved', len(reports), 'original shell silhouettes with measured openings and thick dividers.')


if __name__ == '__main__':
    main()
