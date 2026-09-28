"""Prepare complete, alpha-backed cast rails; never crop them out of a unit shell.

Local background processing is user-authorized. Generated alpha is preserved.
RGB checker/green fallbacks are removed only where connected to the background.
The eight outer regions retain all ornament pixels; corner fitting is isotropic.
"""
from pathlib import Path
import hashlib
import json
import argparse
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'artwork/cast-bars'
OPENING = (48, 48, 464, 80)
CANVAS = (512, 128)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def extract(path):
    source = Image.open(path)
    a = np.array(source.convert('RGBA'))
    method = 'Preserved generated alpha'
    if source.mode != 'RGBA' or a[:, :, 3].min() > 0:
        rgb = a[:, :, :3].astype(int)
        lo, hi = rgb.min(axis=2), rgb.max(axis=2)
        green = (rgb[:, :, 1] > 170) & (rgb[:, :, 0] < 80) & (rgb[:, :, 2] < 80)
        neutral = (hi-lo < 24) & (lo > 60)
        candidates = green if green.mean() > .25 else neutral
        mask = Image.fromarray(np.uint8(candidates)*255).copy()
        h,w = candidates.shape
        for y in (0, h//2, h-1):
            for x in (0,w//2,w-1):
                if mask.getpixel((x,y)) == 255:
                    ImageDraw.floodfill(mask, (x,y), 128)
        a[np.asarray(mask) == 128, 3] = 0
        # Retain painted connected components touching the two long rails;
        # remove detached checker flecks without deleting leaves or feathers.
        visible = Image.fromarray(np.uint8(a[:, :, 3] > 32)*255).copy()
        column = np.asarray(visible)[:, w//2]
        for y in np.flatnonzero(column):
            if visible.getpixel((w//2,int(y))) == 255:
                ImageDraw.floodfill(visible, (w//2,int(y)), 128)
        a[np.asarray(visible) != 128, 3] = 0
        if green.mean() > .25:
            edge = np.asarray(Image.fromarray(np.uint8(green)*255).filter(ImageFilter.MaxFilter(3))) > 0
            a[:, :, 1] = np.where(edge, np.minimum(a[:, :, 1], np.maximum(a[:, :, 0], a[:, :, 2])), a[:, :, 1])
        method = 'Connected backdrop removal and rail component retention'
    a[a[:, :, 3] < 16, 3] = 0
    a[a[:, :, 3] == 0, :3] = 0
    image = Image.fromarray(a)
    assert image.getchannel('A').getbbox(), path
    return image, method


def opening(image):
    """Largest clear rectangle in the enclosed central cast opening."""
    a = np.array(image)[:, :, 3]
    h,w = a.shape
    # The opening lies between the two central rail runs, not the empty canvas.
    coverage = (a[:, int(w*.3):int(w*.7)] > 32).mean(axis=1)
    rows = np.flatnonzero(coverage > .5)
    assert len(rows), 'No continuous rails'
    edges = np.diff(np.r_[False, coverage > .5, False].astype(int))
    runs = list(zip(np.where(edges == 1)[0],np.where(edges == -1)[0]))
    pairs = [(b,c) for (_,b),(c,_) in zip(runs,runs[1:]) if c-b > 12]
    assert pairs, ('No bar opening', runs)
    top,bottom = max(pairs,key=lambda p:p[1]-p[0])
    center = (int(top)+int(bottom))//2
    left = np.flatnonzero(a[center,:w//2] > 32)
    right = np.flatnonzero(a[center,w//2:] > 32)
    assert len(left) and len(right), 'Cast opening must have finished ends'
    lo,hi = int(left[-1]+1),int(right[0]+w//2)
    # Avoid rounded inner corners, then measure the complete leaf/rope contour.
    lo += 8; hi -= 8
    choices=[]
    for inset in range(0, max(1,int((hi-lo)*.12)), 4):
        l,r=lo+inset,hi-inset
        upper = np.where(a[:center,l:r] > 32)
        lower = np.where(a[center:,l:r] > 32)
        t = int(upper[0].max()+1)
        b = int(lower[0].min()+center)
        choices.append(((r-l)*(b-t),(l,t,r,b)))
    _,rect=max(choices)
    lo,top,hi,bottom=rect
    assert hi-lo > w*.5 and bottom-top > 10, rect
    return rect


def fit(path):
    image, method = extract(path)
    l,t,r,b = opening(image)
    bx,by,br,bb = image.getchannel('A').getbbox()
    ol,ot,orr,ob = OPENING
    s = min((orr-ol)/(r-l), (ol-4)/max(1,l-bx), (CANVAS[0]-orr-4)/max(1,br-r),
            (ot-4)/max(1,t-by), (CANVAS[1]-ob-4)/max(1,bb-b))
    # Keep every complete corner at the same X/Y scale. Only the long central
    # spans and plain side joins adapt to the common cast opening.
    xs = [bx,l,r,br]; ys = [by,t,b,bb]
    dx = [ol-round((l-bx)*s),ol,orr,orr+round((br-r)*s)]
    dy = [ot-round((t-by)*s),ot,ob,ob+round((bb-b)*s)]
    out = Image.new('RGBA',CANVAS)
    for row in range(3):
        for col in range(3):
            if row == col == 1:
                continue
            crop = image.crop((xs[col],ys[row],xs[col+1],ys[row+1]))
            size = (dx[col+1]-dx[col],dy[row+1]-dy[row])
            if min(size)>0:
                crop = crop.convert('RGBa').resize(size,Image.Resampling.LANCZOS).convert('RGBA')
                out.paste(crop,(dx[col],dy[row]))
    assert not np.array(out)[ot:ob,ol:orr,3].any()
    return out, dict(method=method,source_opening=[l,t,r,b],opening=list(OPENING),
                     source_bounds=[bx,by,br,bb],scale=s,canvas=list(CANVAS),margin=4)


def build_review(reports):
    sheet=Image.new('RGB',(1536,148*((len(reports)+2)//3)),(32,40,43))
    draw=ImageDraw.Draw(sheet)
    for index,record in enumerate(reports):
        image=Image.open(ROOT/record['source']).convert('RGBA')
        x,y=(index%3)*512,(index//3)*148
        sheet.paste(image,(x,y),image)
        draw.text((x+10,y+132),record['id'],fill=(224,207,163))
    sheet.save(ART/'review.jpg',quality=90)


def main():
    parser=argparse.ArgumentParser();parser.add_argument('ids',nargs='*');args=parser.parse_args()
    (ART/'assets').mkdir(exist_ok=True)
    media=ROOT/'Frostforge/Media/CastBars';media.mkdir(exist_ok=True)
    reports=[]
    for path in sorted((ART/'references').glob('*.png')):
        if args.ids and path.stem not in args.ids: continue
        image,measured=fit(path)
        png=ART/'assets'/path.name;tga=media/(path.stem+'.tga')
        image.save(png);image.save(tga,compression=None)
        record=dict(id=path.stem,kind='cast-border',source=str(png.relative_to(ROOT)),source_sha256=sha(png),
                    original=str(path.relative_to(ROOT)),original_sha256=sha(path),file=str(tga.relative_to(ROOT)),
                    sha256=sha(tga),size=list(CANVAS),measured=measured,
                    alphaBounds=list(image.getchannel('A').getbbox()),clear_points=[[.5,.5],[.2,.5],[.8,.5]],
                    references=[dict(file='artwork/cast-bars/generation-prompts.json',sha256=sha(ART/'generation-prompts.json'))])
        if path.stem == 'class_mage':
            reference=ART/'mage-simplification/generation.json'
            record['references'].append(dict(file=str(reference.relative_to(ROOT)),sha256=sha(reference)))
        reports.append(record)
        print(path.stem,measured['source_opening'],image.getchannel('A').getbbox())
    if not args.ids:
        (ART/'manifest.json').write_text(json.dumps(reports,indent=2)+'\n')
        build_review(reports)
        if len(reports)==42:
            manifest=ROOT/'docs/phase1-assets.json';data=json.loads(manifest.read_text())
            data['assets']=[a for a in data['assets'] if '/CastBars/' not in a['file']]+reports
            manifest.write_text(json.dumps(data,indent=2)+'\n')


if __name__ == '__main__':
    main()
