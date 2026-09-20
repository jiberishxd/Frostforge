"""Convert original generated masters into the existing runtime texture contract.
This production conversion crops, resizes, builds repeat-safe tiles, and encodes TGA.
It never generates painting or fabricates source provenance. Master art stays intact.
Requires Pillow. Does not require a game installation or the raw classic source cache.
"""
from pathlib import Path
import hashlib
import json
import math
from PIL import Image,ImageDraw,ImageFont
from art_common import compose
from skin_catalog import SKINS,CATEGORIES,write as write_catalog

ROOT=Path(__file__).resolve().parents[1]
CLASSIC={'human','orc','nightelf','undead'}
MATERIALS=sorted({s['material'] for s in SKINS}-CLASSIC)
PIECES=('tl','tr','bl','br','top','bottom','left','right')
# Wider corner crops preserve generated corner flourishes; edges keep the same band depth.
CUTS={'dwarven_forge':0.16,'moonstone':0.13,'arcane_crystal':0.19,'fel_obsidian':0.21,
      'black_basalt':0.11,'clockwork':0.16,'shadow_steel':0.18,'jade_bamboo':0.18,
      'dragon_scale':0.17,'tribal_totem':0.16,'sacred_gold':0.18}

def font(size,bold=False):
    candidates=['/System/Library/Fonts/Supplemental/Arial Bold.ttf' if bold else '/System/Library/Fonts/Supplemental/Arial.ttf',
                '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' if bold else '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']
    for path in candidates:
        if Path(path).exists():return ImageFont.truetype(path,size)
    return ImageFont.load_default()

def tint(im,rgb):
    channels=list(im.convert('RGBA').split())
    for i,mult in enumerate(rgb):channels[i]=channels[i].point(lambda v,m=mult:round(v*m))
    return Image.merge('RGBA',channels)

def build():
    write_catalog()
    manifest=json.loads((ROOT/'docs/assets.json').read_text())
    manifest['sources']=[s for s in manifest['sources'] if not s['path'].startswith('artwork/masters/')]
    manifest['assets']=[a for a in manifest['assets'] if Path(a['file']).parent.name not in MATERIALS]
    manifest['generatedArtwork']=[]
    def save(im,material,name,source,crop,transform):
        path=ROOT/'JiberishUI/Media'/material/(name+'.tga');path.parent.mkdir(parents=True,exist_ok=True)
        im=im.convert('RGBA');im.save(path,compression=None)
        manifest['assets'].append(dict(file=path.relative_to(ROOT).as_posix(),source=source,crop=crop,transform=transform,
                                      size=list(im.size),alphaBounds=im.getchannel('A').getbbox(),sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    for material in MATERIALS:
        source=f'artwork/masters/{material}.png';path=ROOT/source;master=Image.open(path).convert('RGBA');w,h=master.size
        assert w==h and master.getpixel((w//2,h//2))[3]==0,(material,'master must have a transparent center')
        manifest['sources'].append(dict(path=source,size=[w,h],alphaBounds=master.getchannel('A').getbbox(),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),origin='original image_gen artwork'))
        c=round(w*CUTS[material]);center=w//2
        start,end=round(w*0.27),round(w*0.45)
        crops={'tl':(0,0,c,c),'tr':(w-c,0,w,c),'bl':(0,h-c,c,h),'br':(w-c,h-c,w,h),
               'top':(start,0,end,c),'bottom':(start,h-c,end,h),
               'left':(0,start,c,end),'right':(w-c,start,w,end)}
        pieces={}
        for key,crop in crops.items():
            horizontal=key in ('top','bottom');vertical=key in ('left','right')
            size=(64,32) if horizontal else (32,64) if vertical else (32,32)
            raw=master.crop(crop)
            if horizontal or vertical:
                bbox=raw.getchannel('A').point(lambda a:255 if a>=64 else 0).getbbox()
                assert bbox,(material,key,'empty rail')
                # Normalize rail thickness independently of the larger corner ornament.
                x,y,r,b=crop
                crop=(x,y+bbox[1],r,y+bbox[3]) if horizontal else (x+bbox[0],y,x+bbox[2],b)
                raw=master.crop(crop)
            im=raw.resize(size,Image.Resampling.LANCZOS)
            # Mirrored periods have identical seam pixels at both ends of a repeat.
            if horizontal:
                half=im.crop((0,0,32,32));im=Image.new('RGBA',(64,32));im.paste(half,(0,0));im.paste(half.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(32,0))
            elif vertical:
                half=im.crop((0,0,32,32));im=Image.new('RGBA',(32,64));im.paste(half,(0,0));im.paste(half.transpose(Image.Transpose.FLIP_TOP_BOTTOM),(0,32))
            pieces[key]=im
            save(im,material,key,source,list(crop),'normalize; mirrored periodic edge' if horizontal or vertical else 'normalize corner')
        for state,mult in [('normal',1),('pushed',0.65),('highlight',1.35),('checked',1.15)]:
            image=compose(pieces,64,64,12)
            if mult!=1:
                channels=list(image.split())
                for i in range(3):channels[i]=channels[i].point(lambda v:min(255,round(v*mult)))
                image=Image.merge('RGBA',channels)
            save(image,material,'button-'+state,source,None,f'eight-piece composition; RGB multiplier {mult}')
        save(compose(pieces,128,128,16),material,'portrait',source,None,'eight-piece portrait composition')
        ornament_crop=(center-c,0,center+c,c)
        save(master.crop(ornament_crop).resize((256,128),Image.Resampling.LANCZOS),material,'ornament',source,list(ornament_crop),'center rail ornament; preserve alpha')
        manifest['generatedArtwork'].append(dict(material=material,master=source,prompt='artwork/prompts.json#'+material,cornerFraction=CUTS[material]))
    manifest['assets'].sort(key=lambda a:a['file'])
    (ROOT/'docs/assets.json').write_text(json.dumps(manifest,indent=2)+'\n')
    build_previews()
    print(f'Built {len(MATERIALS)} original material families; {len(manifest["assets"])} total runtime textures; {len(SKINS)} selectable skins')

def build_previews():
    materials={}
    for name in sorted({s['material'] for s in SKINS}):
        materials[name]={key:Image.open(ROOT/'JiberishUI/Media'/name/(key+'.tga')).convert('RGBA') for key in PIECES}
    def panel(skin):
        card=Image.new('RGBA',(450,180),'#141b24');d=ImageDraw.Draw(card)
        d.text((16,12),skin['label'],font=font(19,True),fill='#ecf2ff')
        d.text((16,39),skin['material'].replace('_',' ').upper(),font=font(11),fill='#8999ae')
        border=tint(compose(materials[skin['material']],326,72,10),skin['tint'])
        d.rectangle((28,73,300,91),fill='#293d35');d.rectangle((28,73,244,91),fill='#648d6e')
        d.rectangle((28,99,300,109),fill='#293949');d.rectangle((28,99,201,109),fill='#49789b')
        card.alpha_composite(border,(16,61))
        card.alpha_composite(tint(compose(materials[skin['material']],60,60,10),skin['tint']),(366,65))
        d.text((16,151),'Unit / compact border + action button • synthetic fit',font=font(11),fill='#8999ae')
        return card
    def sheet(title,items,path,subtitle):
        cols=3;rows=math.ceil(len(items)/cols);im=Image.new('RGB',(1430,130+rows*198),'#0a1017');d=ImageDraw.Draw(im)
        d.text((24,22),title,font=font(30,True),fill='#eaf2ff');d.text((24,69),subtitle,font=font(16),fill='#99aabc')
        for i,item in enumerate(items):
            card=panel(item);im.paste(card,(24+(i%cols)*468,110+(i//cols)*198),card)
        im.save(ROOT/path)
    for category,label in CATEGORIES:
        items=[s for s in SKINS if s['category']==category]
        sheet('JIBERISHUI / '+label.upper(),items,'docs/skin-library-'+category+'.png',f'{len(items)} choices • original materials + Warcraft III artwork • in-game fit validation pending')
    picks=['dwarf','nightelf_moonwell','mage','warlock','blackstone','monk','evoker','tauren','gnome']
    sheet('JIBERISHUI / EXPANDED BORDER LIBRARY',[next(s for s in SKINS if s['id']==id) for id in picks],
          'docs/border-showcase.png','52 styles / 15 material families • races, classes, factions & standard finishes')
    lines=['# Border library','',f'{len(SKINS)} selectable presets across {len(materials)} material families. Families share texture files; palettes and default ornament/thickness settings distinguish variants.','',
           'The original four Warcraft III IDs remain valid. Other choices are original generated materials or explicitly named palette variants of shared materials. These are cosmetic choices on either client, independent of which races/classes that client offers.','',
           'Roster checked against Blizzard’s [playable races](https://worldofwarcraft.blizzard.com/en-gb/game/races) and [classes](https://worldofwarcraft.blizzard.com/en-gb/game/classes).','']
    for category,label in CATEGORIES:
        lines.extend(['## '+label,'','| Style | Material family | Identity |','|---|---|---|'])
        for s in SKINS:
            if s['category']==category:lines.append(f'| {s["label"]} | {s["material"]} | {s["identity"] or "Neutral"} |')
        lines.append('')
    lines.extend(['## Artwork','', 'Original masters: `artwork/masters/`. Exact built-in image_gen prompts: `artwork/prompts.json`. Runtime crops, alpha bounds, hashes, and transforms: `docs/assets.json`. Preview sheets are synthetic fit examples, not game screenshots.',''])
    (ROOT/'docs/SKIN-LIBRARY.md').write_text('\n'.join(lines))

if __name__=='__main__':build()
