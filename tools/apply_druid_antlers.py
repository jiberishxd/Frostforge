"""Apply the generated Druid antlers locally, preserving the approved frame."""
from pathlib import Path
import json
import hashlib
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'artwork/unit-frames/sculpted/druid-antler-correction'


def main():
    record=json.loads((FOLDER/'generation.json').read_text())
    before=Image.open(ROOT/record['before'])
    generated=Image.open(ROOT/record['generated']).convert(before.mode)
    assert before.size==generated.size==(1774,887)
    mask=Image.new('L',before.size);draw=ImageDraw.Draw(mask)
    allowed=np.zeros((before.height,before.width),dtype=bool)
    for x1,y1,x2,y2 in record['boxes']:
        draw.rectangle((x1+5,y1+5,x2-5,y2-5),fill=255)
        allowed[y1:y2,x1:x2]=True
    alpha=np.asarray(mask.filter(ImageFilter.GaussianBlur(1.5))).copy()
    alpha[~allowed]=0
    result=Image.composite(generated,before,Image.fromarray(alpha))
    assert np.array_equal(np.asarray(result)[~allowed],np.asarray(before)[~allowed])
    target=ROOT/record['file'];result.save(target)
    (FOLDER/'applied.json').write_text(json.dumps({
        'file':record['file'],'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
        'before_sha256':hashlib.sha256((ROOT/record['before']).read_bytes()).hexdigest(),
        'generated_sha256':hashlib.sha256((ROOT/record['generated']).read_bytes()).hexdigest(),
        'boxes':record['boxes'],
    },indent=2)+'\n')


if __name__=='__main__': main()
