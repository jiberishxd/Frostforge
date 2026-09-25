"""Register original full unit-shell sprites to two native status-bar openings.

Only own/generated sources are used; the Warcraft identity references are
recorded separately in generation-prompts.json. No third-party addon assets.
"""
from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image, ImageFilter, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'artwork/unit-frames/sculpted';OUT=ART/'assets'

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
    # Fit into the outer margin instead of erasing tips after resampling.
    # Register the actual top of the rail too: a thicker source rail must not
    # get mistaken for an upper emblem crossing the entire name corridor.
    center_ink=np.where((alpha[:hs,int(w*.4):int(w*.6)]>0).any(axis=1))[0]
    assert center_ink.size,(source,"Missing upper rail")
    rail_top=int(center_ink[0])
    ys=np.interp(np.arange(256)+.5,[4,12,70,84,132,136,160,244,252],
        [0,hs*12/84,rail_top,hs,he,ps,pe,pe+(h-pe)*84/96,h])-.5
    canvas_x=[4,12,96,396,500,508]
    source_x=[0,left*12/96,left,right,right+(w-right)*104/116,w]
    # Some upper ornaments reach farther inward than the health opening.
    # Register those complete silhouettes outside the name corridor. The old
    # rectangular alpha cut amputated curls, feathers, gears and crown points.
    bounds=[]
    for sy in ys[:70]:
        lo=max(0,int(np.floor(sy)));hi=min(rail_top,int(np.ceil(sy))+2)
        upper=alpha[lo:hi]>0
        lx=np.where(upper[:,:w//2])[1];rx=np.where(upper[:,w//2:])[1]+w//2
        bounds.append((max(left,int(lx.max())+4) if lx.size else left,
                       min(right,int(rx.min())-4) if rx.size else right))
    bounds=np.array(bounds)
    assert (bounds[:,0]<bounds[:,1]).all(),(source,"Upper ornaments cross the name corridor")
    # Limit deformation to the inner shoulders; crowns and outer silhouettes
    # retain their existing width. A bounded-slope envelope avoids a jagged warp
    # without ever cutting across a protruding source pixel.
    canonical=np.interp(bounds,source_x,canvas_x)
    displacement=np.maximum(0,np.c_[canonical[:,0]-96,396-canonical[:,1]])
    distance=np.abs(np.arange(70)[:,None]-np.arange(70)[None,:])
    displacement=np.maximum(0,(displacement[None,:,:]-2*distance[:,:,None]).max(axis=1))
    # Ease back to the original bar registration below the name line. All
    # lower drapery, both openings and the shared runtime anchor stay intact.
    blend=np.clip((np.arange(256)+.5-70)/14,0,1)
    blend=blend*blend*(3-2*blend)
    xs=[]
    for y,b in enumerate(blend):
        dl,dr=displacement[min(y,69)]*(1-b)
        canonical_x=np.interp(np.arange(512)+.5,[4,48,96,396,456,508],
            [4,48,96+dl,396-dr,456,508])
        xs.append(np.interp(canonical_x,canvas_x,source_x)-.5)
    xs=np.array(xs)
    x0=np.clip(np.floor(xs).astype(int),0,w-1);x1=np.minimum(x0+1,w-1);fx=(xs-x0)[:,:,None]
    y0=np.clip(np.floor(ys).astype(int),0,h-1);y1=np.minimum(y0+1,h-1);fy=(ys-y0)[:,None,None]
    dst=(a[y0[:,None],x0]*(1-fx)+a[y0[:,None],x1]*fx)*(1-fy)+(a[y1[:,None],x0]*(1-fx)+a[y1[:,None],x1]*fx)*fy
    dst[:,:,:3]=np.where(dst[:,:,3:4]>0,dst[:,:,:3]*255/np.maximum(dst[:,:,3:4],1),0)
    dst=np.clip(dst,0,255).astype('uint8')
    # These must already be clear through fitting, not destructive clipping.
    name_discarded=int(np.count_nonzero(dst[:70,96:396,3]))
    edge_discarded=int(np.count_nonzero(np.r_[dst[:4,:,3].ravel(),dst[-4:,:,3].ravel(),dst[:,:4,3].ravel(),dst[:,-4:,3].ravel()]))
    assert name_discarded==edge_discarded==0,(source,name_discarded,edge_discarded)
    # Exact native functional openings still take priority over painted bevels.
    dst[84:132,96:396,3]=0;dst[136:160,96:396,3]=0
    dst[:70,96:396,3]=0
    dst[:4,:,3]=0;dst[-4:,:,3]=0;dst[:,:4,3]=0;dst[:,-4:,3]=0
    return Image.fromarray(dst),dict(health=list(map(int,[left,hs,right,he])),power=list(map(int,[left,ps,right,pe])),
        upper_source_bounds=[int(bounds[:,0].max()),int(bounds[:,1].min())],rail_top=rail_top,
        name_pixels_discarded=name_discarded,edge_pixels_discarded=edge_discarded)

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    OUT.mkdir(exist_ok=True)
    reports=[]
    for j in json.loads((ART/'generation-prompts.json').read_text()):
        source=ART/'references'/(j['id']+'.png')
        target=OUT/(j['id']+'.png')
        # A failed fit must stop the build, not leave a partial report paired
        # with stale exports from a previous run.
        out,measured=fit(source);out.save(target)
        reports.append(dict(id=j['id'],fit_version=2,source=str(source.relative_to(ROOT)),source_sha256=sha(source),file=str(target.relative_to(ROOT)),sha256=sha(target),measured=measured))
    (ART/'fit-report.json').write_text(json.dumps(reports,indent=2)+'\n')
    sheet=Image.new('RGB',(1536,((len(reports)+3)//4)*212),(35,39,42));draw=ImageDraw.Draw(sheet)
    for i,r in enumerate(reports):
        im=Image.open(ROOT/r['file']).resize((384,192),Image.Resampling.LANCZOS);x=(i%4)*384;y=(i//4)*212;sheet.paste(im,(x,y),im);draw.text((x+12,y+194),r['id'],fill=(235,220,182))
    if reports:sheet.save(ART/'review.jpg')
    print('Fitted',len(reports),'sculpted shells with identical openings.')

if __name__=='__main__':
    main()
