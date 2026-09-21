"""Prepare compact, alpha-safe portrait backgrounds for the native Blizzard layout.

Uses the user's authorized local image processing. Retain original generations;
remove only baked neutral backgrounds when needed, then enforce shared openings.
"""
import argparse
import hashlib
import json
import shutil
from collections import deque
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageChops, ImageOps

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'artwork/portraits'
SIZE = 256


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def retain_source(record, destination):
    """Resolve repository-relative generation records, including retained originals."""
    source = ROOT / record['path']
    if source.resolve() != destination.resolve():
        shutil.copyfile(source, destination)


def clearances():
    mask = Image.new('L', (SIZE, SIZE), 255)
    d = ImageDraw.Draw(mask)
    # Shared primary portrait opening. Preserve the full side silhouette and
    # lower sweep: a separate circular level-badge cutout would turn the side
    # ornament into a second ring. Native badges stay above our BACKGROUND art.
    d.ellipse((90, 84, 218, 212), fill=0)
    d.rectangle((154, 148, 218, 212), fill=0)
    d.rectangle((214, 0, 255, 255), fill=0)
    return mask


def normalize_footprint(source):
    # Normalize the complete silhouette, including hanging cloth and feathers.
    # All variants use the same canvas/registration box and opening; natural
    # endpoints are not flattened to force identical visible alpha bounds.
    source=source.resize((SIZE,SIZE),Image.Resampling.LANCZOS)
    bounds=source.getchannel('A').point(lambda a: 255 if a>=16 else 0).getbbox()
    assert bounds, 'Portrait has no ornament'
    aligned=source.crop(bounds).resize((202,236),Image.Resampling.LANCZOS)
    result=Image.new('RGBA',(SIZE,SIZE),(0,0,0,0))
    result.paste(aligned,(8,8))
    return result,bounds


def extract_alpha(image):
    if image.mode == 'RGBA' and image.getchannel('A').getextrema()[0] == 0:
        return image, 'Generated RGBA retained'
    rgb = np.asarray(image.convert('RGB'))
    chroma = rgb.max(axis=2).astype(int)-rgb.min(axis=2).astype(int)
    # The baked checker matte is gray, while dark neutral pixels belong to the
    # ornament's outline/shadow. Do not flood through those into metal details.
    matte = (chroma <= 12) & (rgb.mean(axis=2) >= 90)
    neutral = Image.fromarray(np.where(matte,255,0).astype('uint8')).copy()
    w,h = image.size
    for seed in ((0,0),(w-1,0),(0,h-1),(w-1,h-1),(int(w*.6),int(h*.58))):
        if neutral.getpixel(seed) == 255:
            ImageDraw.floodfill(neutral,seed,128)
    alpha=np.where(np.asarray(neutral)==128,0,255).astype('uint8')
    return Image.fromarray(np.dstack((rgb,alpha))), 'Neutral checker flood above luminance 90; dark outlines and enclosed painted details retained'


def remove_fragments(image):
    alpha=np.array(image.getchannel('A'))
    seen=np.zeros_like(alpha,dtype=bool)
    parts=[]
    for y,x in zip(*np.where(alpha>0)):
        if seen[y,x]: continue
        seen[y,x]=True; queue=deque([(int(y),int(x))]); pixels=[]
        while queue:
            py,px=queue.popleft(); pixels.append((py,px))
            for dy,dx in ((-1,0),(1,0),(0,-1),(0,1)):
                ny,nx=py+dy,px+dx
                if 0<=ny<SIZE and 0<=nx<SIZE and alpha[ny,nx]>0 and not seen[ny,nx]:
                    seen[ny,nx]=True;queue.append((ny,nx))
        parts.append(pixels)
    largest=max(map(len,parts))
    # Clearance cutouts can detach tiny bits of the old lower arc. Keep broad
    # intentional ornaments, not floating fragments beside the level badge.
    for part in parts:
        if len(part)<largest*.1:
            for y,x in part: alpha[y,x]=0
    image.putalpha(Image.fromarray(alpha))
    return image


def main(partial=False):
    jobs=json.loads((ART/'generation-prompts.json').read_text())
    records={}
    for name in ('first-generation-results.json','remaining-generation-results.json'):
        if (ART/name).exists():
            records.update({r['id']:r for r in json.loads((ART/name).read_text())})
    if not partial:
        assert set(records)=={j['id'] for j in jobs}, 'All requested artwork must be present'
    integrated_path=ART/'integrated-generation-results.json'
    integrated={r['id']:r for r in json.loads(integrated_path.read_text())} if integrated_path.exists() else {}
    for folder in ('originals','integrated-originals','assets'):
        (ART/folder).mkdir(exist_ok=True)
    output=ROOT/'JiberishUI/Media/Portraits'; output.mkdir(parents=True,exist_ok=True)
    official={a['id']:a for a in json.loads((ROOT/'artwork/official-crests/sources.json').read_text())}
    reports=[]
    for job in jobs:
        if job['id'] not in records: continue
        original=ART/'originals'/f"{job['id']}.png"
        retain_source(records[job['id']],original)
        if job['id'] in integrated:
            original=ART/'integrated-originals'/f"{job['id']}.png"
            retain_source(integrated[job['id']],original)
        source,method=extract_alpha(Image.open(original))
        result,registration_bounds=normalize_footprint(source)
        result.putalpha(ImageChops.darker(result.getchannel('A'),clearances()))
        result=remove_fragments(result)
        a=np.asarray(result.getchannel('A'))
        assert .025 < (a>0).mean() < .65, job['id']
        assert not a[:,214:].any()
        assert result.getpixel((154,148))[3]==0
        png=ART/'assets'/f"{job['id']}.png"; result.save(png)
        tga=output/f"{job['id']}.tga"; result.save(tga,format='TGA',compression=None)
        assert Image.open(tga).tobytes()==result.tobytes()
        reports.append({
            'id':job['id'],'label':job['label'],'group':job['group'],
            'file':str(tga.relative_to(ROOT)),'source':str(png.relative_to(ROOT)),
            'source_sha256':digest(png),'source_size':[SIZE,SIZE],
            'original':str(original.relative_to(ROOT)),'original_sha256':digest(original),
            'transform':method+'; register complete layered ornament in [8,8,210,244]; retain natural side details and lower sweep; shared primary portrait/bar clearance; no pasted badge, icon ring or level-badge cutout',
            'fit_version':4,'registration_source_bounds':list(registration_bounds),
            'registration_box':[8,8,210,244],'portrait_center':[154,148],'portrait_radius':64,
            'emblem_reference':official.get(job['id']) if job['id'] in integrated else None,
            'emblem_treatment':'motif integrated into generated sculpted ornament; no downloaded circular badge' if job['id'] in integrated else 'original continuous themed ornament; pasted badge removed',
            'size':[SIZE,SIZE],'default_display_size':[128,128],
            'alphaBounds':list(result.getchannel('A').getbbox()),'clear_points':[[154/256,148/256],[.9,.5]],
            'sha256':digest(tga),'in_game_qualified':False,
        })
    (ART/'manifest.json').write_text(json.dumps({'assets':reports,'in_game_qualified':False},indent=2)+'\n')
    (ART/'gallery-data.js').write_text('const portraitAssets = '+json.dumps(reports)+';\n')
    if not partial:
        manifest=json.loads((ROOT/'docs/phase1-assets.json').read_text())
        manifest['assets']=[a for a in manifest['assets'] if '/Portraits/' not in a['file'] and 'unit-shell' not in a['file']]+reports
        manifest['portrait_prompts']='artwork/portraits/generation-prompts.json'
        (ROOT/'docs/phase1-assets.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(f'Prepared {len(reports)} portrait backgrounds at 256 pixels with verified native openings.')


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--partial',action='store_true')
    main(parser.parse_args().partial)
