"""Encode our sculpted shells and painted status-bar materials.

Run fit_unit_shells.py first. --preview prepares finished identities while the
remaining originals are being painted. A release requires all 42 identities.
"""
from pathlib import Path
import argparse, hashlib, json
import numpy as np
from PIL import Image, ImageOps
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'artwork/unit-frames/assets';OUT.mkdir(parents=True,exist_ok=True)
ART=ROOT/'artwork/unit-frames/sculpted'
MEDIA=ROOT/'JiberishUI/Media/UnitFrames';MEDIA.mkdir(parents=True,exist_ok=True)
parser=argparse.ArgumentParser();parser.add_argument('--preview',action='store_true');args=parser.parse_args()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(name,im,refs,kind):
    p=OUT/(name+'.png');im.save(p)
    t=MEDIA/(name+'.tga')
    if not args.preview:im.save(t,compression=None)
    item=dict(file=str(t.relative_to(ROOT)),source=str(p.relative_to(ROOT)),size=list(im.size),
              source_sha256=sha(p),alphaBounds=list(im.getbbox()),kind=kind,
              references=[dict(file=str(r.relative_to(ROOT)),sha256=sha(r)) for r in refs])
    if not args.preview:item['sha256']=sha(t)
    if kind=='unit-shell':item['registration']={'canvas':[512,256],'health':[96,84,396,132],'power':[96,136,396,160],'name':[96,0,396,70],'margin':4}
    return item
jobs=json.loads((ART/'generation-prompts.json').read_text())
reports={r['id']:r for r in json.loads((ART/'fit-report.json').read_text())}
if not args.preview:assert len(reports)==len(jobs)==42,'Complete every original and its fitting before packaging.'
source=ROOT/'artwork/unit-frames/references/painted-metal.png'
base=np.asarray(ImageOps.grayscale(Image.open(source)).resize((256,32),Image.Resampling.LANCZOS)).astype(float)/255
assets=[];entries=[]
for job in jobs:
    name=job['id']
    if name not in reports:continue
    fitted=ROOT/reports[name]['file'];original=ROOT/reports[name]['source']
    shell=Image.open(fitted).convert('RGBA');a=np.asarray(shell).astype(float)/255
    assets.append(save(name,shell,[original,fitted,ART/'generation-prompts.json'],'unit-shell'))
    # Use original painted brushwork and this shell's actual lower-rail material.
    # These full-bleed materials retain Blizzard's health/resource color tint.
    band=a[160:192,100:392];opaque=band[:,:,3]>.8
    color=np.median(band[:,:,:3][opaque],axis=0) if opaque.any() else np.array([.7,.7,.7])
    tint=.86+.14*color/max(color.max(),.01)
    material=Image.fromarray(np.uint8((band[:,:,:3]*band[:,:,3:4]+.45*(1-band[:,:,3:4]))*255)).convert('L').resize((256,32),Image.Resampling.LANCZOS)
    grain=np.asarray(material).astype(float)/255;grain-=grain.mean()
    y=np.linspace(0,1,32)[:,None]
    shade=.63+.18*np.exp(-((y-.22)/.24)**2)-.22*y + (base-.5)*.65+grain*.25
    shade[0]*=.55;shade[-2:]*=.60;shade[2]+= .12
    for kind,factor in [('health',1),('power',1.06)]:
        rgb=np.clip(shade[:,:,None]*tint[None,None,:]*factor,.12,.98)
        fill=Image.fromarray(np.uint8(rgb*255),'RGB').convert('RGBA')
        assets.append(save(name+'-'+kind,fill,[source,fitted],'statusbar-fill'))
    entries.append((name.upper(),name))
(OUT/'available.json').write_text(json.dumps([stem for _,stem in entries])+'\n')
if not args.preview:
    lines=['local _, J = ...','-- Original artwork; data only. Every identity shares the same native-bar registration.','J.UnitSkinCatalog = { entries = {']
    for ident,stem in entries:
        prefix='Interface\\\\AddOns\\\\JiberishUI\\\\Media\\\\UnitFrames\\\\'
        lines.append('    %s = {shell="%s%s.tga",health="%s%s-health.tga",power="%s%s-power.tga"},'%(ident,prefix,stem,prefix,stem,prefix,stem))
    lines+=['} }'];(ROOT/'JiberishUI/Themes/UnitSkins.lua').write_text('\n'.join(lines)+'\n')
    manifest=ROOT/'docs/phase1-assets.json';data=json.loads(manifest.read_text())
    data['assets']=[a for a in data['assets'] if '/UnitFrames/' not in a['file']]+assets
    manifest.write_text(json.dumps(data,indent=2)+'\n')
    (ROOT/'artwork/unit-frames/manifest.json').write_text(json.dumps(assets,indent=2)+'\n')
    # Obsolete development-only common fills are not part of this release.
    for stem in ['health-fill','power-fill']:
        for folder,ext in [(MEDIA,'.tga'),(OUT,'.png')]:
            p=folder/(stem+ext)
            if p.exists():p.unlink()
print('Prepared',len(entries),'sculpted shells with matching health and power materials'+(' for preview.' if args.preview else ' for packaging.'))
