"""Remove only the connected neutral backdrop returned by the Paladin edit.

User-authorized local alpha processing. Enclosed painted silver, cloth and wings
are retained. The source generation and exact edit prompt are stored separately.
"""
from collections import deque
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'artwork/unit-frames/sculpted'


def extract(image):
    a = np.array(image.convert('RGBA'))
    rgb = a[:, :, :3].astype(int)
    allowed = (rgb.max(2)-rgb.min(2) < 25) & (rgb.min(2) > 95)
    h, w = allowed.shape
    mask = np.zeros((h, w), bool)
    queue = deque()
    seeds = ([(0, x) for x in range(w)] + [(h-1, x) for x in range(w)] +
             [(y, 0) for y in range(h)] + [(y, w-1) for y in range(h)] +
             [(410, w//2), (550, w//2)])
    for y, x in seeds:
        if allowed[y, x] and not mask[y, x]:
            mask[y, x] = True
            queue.append((y, x))
    while queue:
        y, x = queue.popleft()
        for yy, xx in ((y-1,x), (y+1,x), (y,x-1), (y,x+1)):
            if 0 <= yy < h and 0 <= xx < w and allowed[yy, xx] and not mask[yy, xx]:
                mask[yy, xx] = True
                queue.append((yy, xx))
    a[mask] = 0
    return Image.fromarray(a)


if __name__ == '__main__':
    record = ART/'paladin-crest-correction.json'
    data = json.loads(record.read_text())
    source, target = ROOT/data['source'], ROOT/data['output']
    extract(Image.open(source)).save(target)
    data['source_sha256'] = hashlib.sha256(source.read_bytes()).hexdigest()
    data['output_sha256'] = hashlib.sha256(target.read_bytes()).hexdigest()
    data['alpha_script'] = 'tools/extract_paladin_crest.py'
    record.write_text(json.dumps(data, indent=2)+'\n')
    print('Extracted Paladin crest edit to transparent RGBA.')
