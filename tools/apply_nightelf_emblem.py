"""Integrate generated Night Elf inlays; retain every pixel outside each edit.

The image tool paints the artwork. This step keys its production matte and
composites the reviewed regions into the retained, already registered textures.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'artwork/nightelf-emblem-update'
POLYGONS = {
    'unit': [(1336,0),(1774,0),(1774,887),(1460,887),(1460,320),(1336,278)],
    'hub': [(0,0),(592,0),(592,724),(0,724)],
    'minimap': [(221,4),(308,4),(308,96),(221,96)],
}
BEFORE = {'unit':'unit-frame-before.png','hub':'hub-before.png','minimap':'minimap-before.png'}
GENERATED = {'unit':'unit-final.png','hub':'hub-final.png','minimap':'minimap-cleanup.png'}
TARGET = {'unit':'artwork/unit-frames/sculpted/references/race_nightelf.png',
          'hub':'artwork/hubs/assets/race_nightelf.png',
          'minimap':'artwork/minimaps/assets/race_nightelf.png'}

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def keyed(image):
    rgb = np.asarray(image.convert('RGB'),dtype=float)
    key = rgb[:,:,1]-np.maximum(rgb[:,:,0],rgb[:,:,2])
    core = Image.fromarray(np.uint8((key>205)*255))
    edge = np.asarray(core.filter(ImageFilter.MaxFilter(5)))>0
    alpha = np.where(edge,1-np.clip((key-55)/145,0,1),1)
    # Suppress green at the keyed boundary without amplifying the generated
    # matte's RGB noise into bright magenta fringes. Painted gems stay intact.
    color = rgb.copy()
    color[:,:,1] = np.where(edge,np.minimum(color[:,:,1],np.maximum(color[:,:,0],color[:,:,2])),color[:,:,1])
    return Image.fromarray(np.uint8(np.dstack((np.clip(color,0,255),np.round(alpha*255)))))

def mask_for(kind,size):
    mask=Image.new('L',size)
    ImageDraw.Draw(mask).polygon(POLYGONS[kind],fill=255)
    # Feather inward so the declared edit boundary stays an exact pixel lock.
    mask=mask.filter(ImageFilter.MinFilter(7)).filter(ImageFilter.GaussianBlur(1))
    hard=Image.new('L',size);ImageDraw.Draw(hard).polygon(POLYGONS[kind],fill=255)
    return Image.fromarray(np.minimum(np.asarray(mask),np.asarray(hard)))

def apply_overlay(kind):
    before=Image.open(ART/BEFORE[kind])
    generated=Image.open(ART/GENERATED[kind])
    if kind=='unit':
        assert generated.size==before.size
        edited=generated.convert(before.mode)
    else:
        edited=keyed(generated).convert('RGBa').resize(before.size,Image.Resampling.LANCZOS).convert('RGBA')
    result=Image.composite(edited,before,mask_for(kind,before.size))
    if kind=='minimap':
        # Keep the atlas's established eight-pixel guard band; only Lanczos
        # fringe reaches this area above the complete painted crescent tip.
        alpha=np.array(result.getchannel('A'))
        alpha[:8]=0;alpha[-8:]=0;alpha[:,:8]=0;alpha[:,-8:]=0
        result.putalpha(Image.fromarray(alpha))
    return result

def record():
    records=[]
    for kind in BEFORE:
        path=ROOT/TARGET[kind]
        records.append(dict(kind=kind,file=TARGET[kind],sha256=digest(path),
            source=str((ART/BEFORE[kind]).relative_to(ROOT)),
            source_sha256=digest(ART/BEFORE[kind]),
            generated=str((ART/GENERATED[kind]).relative_to(ROOT)),
            generated_sha256=digest(ART/GENERATED[kind]),
            polygon=POLYGONS[kind],
            note='Generated inlay only; pixels outside the polygon, registration and functional apertures retained.'))
    (ART/'applied.json').write_text(json.dumps(records,indent=2)+'\n')

if __name__=='__main__':
    apply_overlay('unit').save(ROOT/TARGET['unit'])
    # Hub and minimap builders apply their inlay after the normal registration.
    for kind in ('hub','minimap'): apply_overlay(kind).save(ROOT/TARGET[kind])
    record()
