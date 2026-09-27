"""Compose documentation artwork from existing textures; not game screenshots."""
from pathlib import Path
import argparse
import json
from PIL import Image, ImageDraw, ImageFont, ImageChops

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/images'
GOLD = '#a6ddf5'
INK = '#e1edf4'
MUTED = '#a3b4c0'
BACK = '#111b25'


def font(size, serif=False):
    candidates = (
        ['/System/Library/Fonts/Supplemental/Georgia.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf']
        if serif else ['/System/Library/Fonts/Supplemental/Arial.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']
    )
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size=size)


def place(canvas, image, box):
    image = image.convert('RGBA')
    image.thumbnail((box[2], box[3]), Image.Resampling.LANCZOS)
    xy = (round(box[0] + (box[2]-image.width)/2), round(box[1] + (box[3]-image.height)/2))
    canvas.paste(image, xy, image)


def shell(identity, color):
    """Illustrate the actual fitted shell openings with the shipped stone fill."""
    image = Image.new('RGBA', (512, 256))
    layout = json.loads((ROOT/'artwork/unit-frames/assets/layouts.json').read_text())[identity]
    for kind, tint, value in [('health', color, .78), ('power', '#428ccc', .62)]:
        box = tuple(round(v) for v in layout[kind])
        ImageDraw.Draw(image).rectangle(box, fill='#12191b')
        texture = Image.open(ROOT/f'artwork/unit-frames/assets/{identity}-{kind}.png').convert('RGB')
        size = (box[2]-box[0], box[3]-box[1])
        texture = texture.resize(size, Image.Resampling.LANCZOS)
        texture = ImageChops.multiply(texture, Image.new('RGB', size, tint))
        texture = texture.crop((0, 0, round(size[0]*value), size[1]))
        image.paste(texture, box[:2])
    image.alpha_composite(Image.open(ROOT/f'artwork/unit-frames/assets/{identity}.png').convert('RGBA'))
    return image


def hub(identity, width=860, height=200):
    data=(ROOT/'artwork/hubs/runtime-layout.js').read_text().split('const runtimeHub = ',1)[1].strip().removesuffix(';')
    config=json.loads(data)
    source=Image.open(ROOT/f'artwork/hubs/game/{identity}.png').convert('RGBA')
    canvas=Image.new('RGBA',(width,height))
    scale=min(height/config['designHeight'],width/config['minimumWidth'])
    top=height-config['designHeight']*scale
    for p in sorted(config['pieces'].values(),key=lambda p:p['order']):
        left=round(width*p['leftAnchor']+p['leftOffset']*scale)
        right=round(width*p['rightAnchor']+p['rightOffset']*scale)
        piece=source.crop((round(p['u1']*source.width),0,round(p['u2']*source.width),source.height))
        piece=piece.resize((right-left,round(p['height']*scale)),Image.Resampling.LANCZOS)
        canvas.alpha_composite(piece,(left,round(top+p['y']*scale)))
    return canvas


def stone_preview():
    canvas=Image.new('RGB',(1200,620),BACK);draw=ImageDraw.Draw(canvas)
    draw.text((35,20),'Painted stone · subtle texture, clear class colors',font=font(26,True),fill=GOLD)
    for i,(identity,color,label) in enumerate([
        ('class_paladin','#f58cba','Paladin'),('class_shaman','#379ee0','Shaman')
    ]):
        image=shell(identity,color).resize((570,285),Image.Resampling.LANCZOS)
        canvas.paste(image,(i*600+15,80),image)
        draw.text((i*600+35,369),label,font=font(20),fill=INK)
    texture=Image.open(ROOT/'artwork/unit-frames/assets/class_paladin-health.png').convert('RGB')
    for i,tint in enumerate(['#f58cba','#379ee0','#65b35b']):
        fill=ImageChops.multiply(texture,Image.new('RGB',texture.size,tint))
        canvas.paste(fill,(100+i*350,470))
    draw.text((100,522),'Actual 256 × 32 fills · original texture · native frame colors',font=font(19),fill=MUTED)
    canvas.save(OUT/'minimal-stone.jpg',quality=94)


def hub_reviews():
    identities=sorted(p.stem for p in (ROOT/'artwork/hubs/game').glob('*.png'))
    for start in range(0,len(identities),14):
        canvas=Image.new('RGB',(1500,1680),(25,55,48));draw=ImageDraw.Draw(canvas)
        for i,identity in enumerate(identities[start:start+14]):
            image=hub(identity,width=720,height=202)
            x,y=i%2*750+15,i//2*240
            canvas.paste(image,(x,y),image)
            draw.text((x,y+204),identity,font=font(17),fill=INK)
        canvas.save(ROOT/f'artwork/hubs/alpha-cleanup/review-{start//14+1}.jpg',quality=92)


def main():
    OUT.mkdir(exist_ok=True)
    canvas=Image.new('RGB',(1400,860),BACK)
    draw=ImageDraw.Draw(canvas)
    place(canvas,Image.open(ROOT/'docs/images/logo.png'),(35,18,104,104))
    draw.text((158,28),"Jiberish's Frostforge",font=font(48,True),fill=GOLD)
    draw.text((160,91),'42 themes. One coordinated Warcraft interface.',font=font(23),fill=INK)
    draw.line((42,136,1358,136),fill='#3c596c',width=2)
    draw.text((44,163),'SCULPTED UNIT FRAMES',font=font(18),fill=GOLD)
    place(canvas,shell('class_paladin','#f58cba'),(40,192,600,300))
    draw.text((720,163),'PORTRAIT SURROUNDS',font=font(18),fill=GOLD)
    for i,(identity,label) in enumerate([('class_paladin','Paladin'),('class_mage','Mage'),('class_shaman','Shaman'),('class_druid','Druid')]):
        place(canvas,Image.open(ROOT/f'artwork/portraits/assets/{identity}.png'),(720+i*155,197,140,140))
        draw.text((735+i*155,345),label,font=font(17),fill=MUTED)
    draw.text((720,393),'MATCHING CAST BORDERS',font=font(18),fill=GOLD)
    place(canvas,Image.open(ROOT/'artwork/cast-bars/assets/class_mage.png'),(717,422,615,110))
    draw.line((42,556,1358,556),fill='#3c596c',width=1)
    draw.text((44,586),'ACTION HUBS',font=font(18),fill=GOLD)
    place(canvas,hub('class_paladin'),(42,619,870,195))
    draw.text((1050,586),'MINIMAP ART',font=font(18),fill=GOLD)
    place(canvas,Image.open(ROOT/'artwork/minimaps/assets/class_shaman.png'),(1035,616,225,205))
    draw.text((44,828),'Actual addon textures • Composited artwork preview',font=font(16),fill=MUTED)
    canvas.save(OUT/'overview.jpg',quality=94,optimize=True)

    grid=Image.new('RGB',(1200,680),BACK);draw=ImageDraw.Draw(grid)
    draw.text((30,22),'Class and race character, carried across your frames',font=font(27,True),fill=GOLD)
    for i,(identity,label,color) in enumerate([
        ('class_paladin','Paladin • gilded wings and plate','#f58cba'),
        ('class_mage','Mage • arcane stone and violet crystal','#69ccf0'),
        ('class_shaman','Shaman • elemental totems and bindings','#379ee0'),
        ('race_nightelf','Night Elf • moonlit boughs and feathers','#7bbb68'),
    ]):
        x,y=(i%2)*600,(i//2)*300+65
        place(grid,shell(identity,color),(x+32,y,536,268))
        draw.text((x+34,y+271),label,font=font(18),fill=INK)
    grid.save(OUT/'unit-frames.jpg',quality=94,optimize=True)

    # A dedicated 2:1 share-card asset, ready for GitHub's social preview field.
    social=Image.new('RGB',(1280,640),BACK);draw=ImageDraw.Draw(social)
    place(social,Image.open(ROOT/'docs/images/logo.png'),(42,35,112,112))
    draw.text((174,42),"Jiberish's Frostforge",font=font(60,True),fill=GOLD)
    draw.text((176,122),'Class, race & faction artwork for your Warcraft UI',font=font(26),fill=INK)
    place(social,shell('class_paladin','#f58cba'),(34,195,620,310))
    place(social,shell('class_shaman','#379ee0'),(654,195,590,310))
    draw.text((52,558),'Portraits · Unit frames · Cast bars · Action hubs · Minimap',font=font(23),fill=GOLD)
    draw.text((52,602),'Artwork preview • Development build',font=font(16),fill=MUTED)
    social.save(OUT/'social-preview.jpg',quality=94,optimize=True)
    stone_preview()


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--hub-review',action='store_true',help='Also render all 42 hubs over solid teal for alpha review.')
    args=parser.parse_args()
    main()
    if args.hub_review:
        hub_reviews()
