"""Production nine-slice composition shared by classic and original material builders."""
from PIL import Image

def compose(pieces, w, h, edge):
    im=Image.new('RGBA',(w,h))
    boxes={'tl':(0,0,edge,edge),'tr':(w-edge,0,w,edge),'bl':(0,h-edge,edge,h),'br':(w-edge,h-edge,w,h),
           'top':(edge,0,w-edge,edge),'bottom':(edge,h-edge,w-edge,h),'left':(0,edge,edge,h-edge),'right':(w-edge,edge,w,h-edge)}
    for key,(x,y,r,b) in boxes.items():
        if key in ('top','bottom','left','right'):
            tw,th=(edge*2,edge) if key in ('top','bottom') else (edge,edge*2)
            tile=pieces[key].resize((tw,th),Image.Resampling.LANCZOS)
            for yy in range(y,b,th):
                for xx in range(x,r,tw):
                    im.alpha_composite(tile.crop((0,0,min(tw,r-xx),min(th,b-yy))),(xx,yy))
        else:im.alpha_composite(pieces[key].resize((r-x,b-y),Image.Resampling.LANCZOS),(x,y))
    return im
