"""Apply the generated emblem corrections only inside the approved emblem areas."""
from pathlib import Path
import json
import hashlib
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'artwork/mage-emblem-correction'
JOBS={
    'portrait': ('artwork/portraits/integrated-originals/class_mage.png',[(423,106,894,400)]),
    'unit-frame': ('artwork/unit-frames/sculpted/references/class_mage.png',[(1456,121,1749,342)]),
    # Retain the earlier correction as the input to the later simplified ends.
    'cast-bar': ('artwork/cast-bars/mage-simplification/before.png',[(32,450,192,578),(1344,450,1504,578)]),
}

def main():
    records=[]
    for kind,(destination,boxes) in JOBS.items():
        before=Image.open(ART/(kind+'-before.png'))
        edited=Image.open(ART/(kind+'-generated.png')).convert(before.mode)
        assert before.size==edited.size,(kind,before.size,edited.size)
        mask=Image.new('L',before.size)
        draw=ImageDraw.Draw(mask)
        for x1,y1,x2,y2 in boxes: draw.rectangle((x1+5,y1+5,x2-5,y2-5),fill=255)
        mask=mask.filter(ImageFilter.GaussianBlur(1.5))
        if kind=='unit-frame':
            allowed=np.asarray(mask).copy()
            for im in (before,edited):
                a=np.asarray(im).astype(int)
                green=(a[:,:,1]>170)&(a[:,:,0]<70)&(a[:,:,2]<70)&(a[:,:,1]-np.maximum(a[:,:,0],a[:,:,2])>110)
                allowed[green]=0
            mask=Image.fromarray(allowed)
        result=Image.composite(edited,before,mask)
        outside=np.asarray(mask)==0
        assert np.array_equal(np.asarray(result)[outside],np.asarray(before)[outside])
        result.save(ROOT/destination)
        records.append(dict(kind=kind,file=destination,boxes=boxes,
            sha256=hashlib.sha256((ROOT/destination).read_bytes()).hexdigest(),
            source=str((ART/(kind+'-before.png')).relative_to(ROOT)),
            generated=str((ART/(kind+'-generated.png')).relative_to(ROOT)),
            note='Only the generated emblem region is composited; all other source pixels are unchanged.'))
    (ART/'applied.json').write_text(json.dumps(records,indent=2)+'\n')

if __name__=='__main__': main()
