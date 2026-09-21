"""Offline contour registration for the two native Blizzard portrait shapes.

Only pixels of the addon artwork are resampled. No native UI geometry changes.
Source outputs stay untouched; the same fit is used for every identity.
"""
import numpy as np
from PIL import Image

def conform(image, shape):
    """Register the painted inner contour, keeping distant side ornament in place."""
    assert shape in ('player', 'round')
    opening = 60 if shape == 'player' else 58
    # Measure the first substantial ornament edge from the portrait center.
    a=np.asarray(image.getchannel('A'))
    angles=np.linspace(-np.pi,np.pi,720,endpoint=False)
    radii=np.arange(24,174)
    xs=np.rint(154+np.cos(angles[:,None])*radii).astype(int)
    ys=np.rint(148+np.sin(angles[:,None])*radii).astype(int)
    valid=(xs>=0)&(xs<256)&(ys>=0)&(ys<256)
    samples=a[np.clip(ys,0,255),np.clip(xs,0,255)]
    solid=(samples>96)&valid
    substantial=solid[:,:-2]&solid[:,1:-1]&solid[:,2:]
    present=substantial.any(axis=1)
    edge=np.where(present,np.argmax(substantial,axis=1)+24,64).astype(float)
    # Median rejects isolated jewels and one-pixel ragged paint edges.
    edge=np.median(np.stack([np.roll(edge,k) for k in range(-5,6)]),axis=0)
    kernel=np.exp(-np.arange(-48,49)**2/(2*16**2));kernel/=kernel.sum()
    edge=np.convolve(np.pad(edge,(48,48),mode='wrap'),kernel,mode='valid')
    yy,xx=np.mgrid[:256,:256];dx=xx-154;dy=yy-148
    theta=np.arctan2(dy,dx);radius=np.hypot(dx,dy)
    index=np.floor((theta+np.pi)*720/(2*np.pi)).astype(int)%720
    old=edge[index]
    cosine=np.cos(theta);sine=np.sin(theta)
    desired=np.full((256,256),float(opening))
    if shape=='player':
        quadrant=(dx>0)&(dy>0)
        desired[quadrant]=60/np.maximum(cosine[quadrant],sine[quadrant])
    outer=np.maximum(old,desired)+60
    mapped=np.where(radius<desired,old*radius/desired,
                    old+(radius-desired)*(outer-old)/(outer-desired))
    mapped=np.where(radius>=outer,radius,mapped)
    sx=154+cosine*mapped;sy=148+sine*mapped
    # Bilinear sampling in premultiplied alpha prevents dark transparency seams.
    data=np.asarray(image,dtype=float)/255
    data[:,:,:3]*=data[:,:,3:4]
    x0=np.floor(sx).astype(int);y0=np.floor(sy).astype(int)
    fx=sx-x0;fy=sy-y0;out=np.zeros((256,256,4))
    for ox,oy,w in [(0,0,(1-fx)*(1-fy)),(1,0,fx*(1-fy)),(0,1,(1-fx)*fy),(1,1,fx*fy)]:
        x=x0+ox;y=y0+oy;inside=(x>=0)&(x<256)&(y>=0)&(y<256)
        out+=data[np.clip(y,0,255),np.clip(x,0,255)]*(w*inside)[:,:,None]
    out[:,:,:3]/=np.maximum(out[:,:,3:4],1/255)
    clear=radius<=opening
    if shape=='player':clear|=(dx>=0)&(dy>=0)&(dx<=60)&(dy<=60)
    clear|=(xx>=214)|(xx<8)|(yy<8)|(yy>=244)
    out[clear]=0
    return Image.fromarray(np.uint8(np.clip(out*255,0,255)))
