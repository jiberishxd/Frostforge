"""Register original full unit-shell sprites to two native status-bar openings.

Only own/generated sources are used; the Warcraft identity references are
recorded separately in generation-prompts.json. No third-party addon assets.
"""
from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image, ImageFilter, ImageOps, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'artwork/unit-frames/sculpted';OUT=ART/'assets';OUT.mkdir(exist_ok=True)

def runs(values):
    padded=np.r_[False,values,False];d=np.diff(padded.astype(int));return list(zip(np.where(d==1)[0],np.where(d==-1)[0]))
def fit(source):
    im=Image.open(source).convert('RGBA');a=np.asarray(im).astype(float);h,w=a.shape[:2]
    key=(a[:,:,1]>170)&(a[:,:,0]<70)&(a[:,:,2]<70)&((a[:,:,1]-np.maximum(a[:,:,0],a[:,:,2]))>110)
    mid=key[:,int(w*.35):int(w*.60)].mean(axis=1)>.8
    candidates=[r for r in runs(mid) if h*.27<r[0]<h*.8 and r[1]-r[0]>h*.018]
    assert len(candidates)>=2,(source,candidates)
    hs,he=candidates[0];ps,pe=candidates[1]
    row=(hs+he)//2
    xr=[r for r in runs(key[row]) if r[0]<w/2<r[1]];assert len(xr)==1,(source,xr)
    left,right=xr[0];assert right-left>w*.4,(source,left,right)
    # Green extraction plus despill only at the immediate green boundary.
    alpha=np.where(key,0,a[:,:,3])
    adjacent=np.asarray(Image.fromarray(np.uint8(key*255)).filter(ImageFilter.MaxFilter(5)))>0
    fringe=adjacent&~key
    a[:,:,1]=np.where(fringe,np.minimum(a[:,:,1],np.maximum(a[:,:,0],a[:,:,2])*1.08),a[:,:,1])
    a[:,:,3]=alpha
    # Premultiplied resampling prevents dark or green outlines at alpha edges.
    a[:,:,:3]*=a[:,:,3:4]/255
    xs=np.interp(np.arange(512)+.5,[0,96,396,512],[0,left,right,w])-.5
    ys=np.interp(np.arange(256)+.5,[0,84,132,136,160,256],[0,hs,he,ps,pe,h])-.5
    x0=np.clip(np.floor(xs).astype(int),0,w-1);x1=np.minimum(x0+1,w-1);fx=(xs-x0)[None,:,None]
    y0=np.clip(np.floor(ys).astype(int),0,h-1);y1=np.minimum(y0+1,h-1);fy=(ys-y0)[:,None,None]
    dst=(a[y0[:,None],x0[None,:]]*(1-fx)+a[y0[:,None],x1[None,:]]*fx)*(1-fy)+(a[y1[:,None],x0[None,:]]*(1-fx)+a[y1[:,None],x1[None,:]]*fx)*fy
    dst[:,:,:3]=np.where(dst[:,:,3:4]>0,dst[:,:,:3]*255/np.maximum(dst[:,:,3:4],1),0)
    dst=np.clip(dst,0,255).astype('uint8')
    # Exact native clear regions, and an outer anti-clipping margin.
    dst[84:132,96:396,3]=0;dst[136:160,96:396,3]=0
    dst[:70,96:396,3]=0
    dst[:4,:,3]=0;dst[-4:,:,3]=0;dst[:,:4,3]=0;dst[:,-4:,3]=0
    return Image.fromarray(dst),dict(health=list(map(int,[left,hs,right,he])),power=list(map(int,[left,ps,right,pe])))

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
reports=[]
for j in json.loads((ART/'generation-prompts.json').read_text()):
    source=ART/'references'/(j['id']+'.png')
    if not source.exists():continue
    target=OUT/(j['id']+'.png')
    try:
        out,measured=fit(source);out.save(target)
        reports.append(dict(id=j['id'],source=str(source.relative_to(ROOT)),source_sha256=sha(source),file=str(target.relative_to(ROOT)),sha256=sha(target),measured=measured))
    except Exception as e:print('FIT FAILED',j['id'],e)
(ART/'fit-report.json').write_text(json.dumps(reports,indent=2)+'\n')
# Small contact sheet shows every finished composition on a solid background.
sheet=Image.new('RGB',(1536,((len(reports)+3)//4)*212),(35,39,42));draw=ImageDraw.Draw(sheet)
for i,r in enumerate(reports):
    im=Image.open(ROOT/r['file']).resize((384,192),Image.Resampling.LANCZOS);x=(i%4)*384;y=(i//4)*212;sheet.paste(im,(x,y),im);draw.text((x+12,y+194),r['id'],fill=(235,220,182))
if reports:sheet.save(ART/'review.jpg')
print('Fitted',len(reports),'sculpted shells with identical openings.')
