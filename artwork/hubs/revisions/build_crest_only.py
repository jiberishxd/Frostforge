"""Build a shared five-piece hub atlas using source-tracked Blizzard crests.

Artwork compositing/alpha processing is explicitly authorized by the user.
All themes share the same reserved space, rail seams and registration boxes.
"""
import json
import shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageOps, ImageChops, ImageDraw
from build_portraits import ROOT, extract_alpha, digest

ART = ROOT / 'artwork/hubs'
WIDTH, HEIGHT = 2172, 724


def fit(image, size):
    return ImageOps.contain(image.crop(image.getchannel('A').getbbox()), size, Image.Resampling.LANCZOS)


def stamp(canvas, image, box):
    x,y,w,h = box
    image = fit(image,(w,h))
    canvas.alpha_composite(image,(x+(w-image.width)//2,y+(h-image.height)//2))


def main():
    for folder in ('originals','assets','game'):
        (ART/folder).mkdir(parents=True,exist_ok=True)
    output=ROOT/'JiberishUI/Media/Hubs';output.mkdir(parents=True,exist_ok=True)
    official={a['id']:a for a in json.loads((ROOT/'artwork/official-crests/sources.json').read_text())}
    portraits=json.loads((ROOT/'artwork/portraits/manifest.json').read_text())['assets']
    palettes={}
    for record in json.loads((ART/'generation-results.json').read_text()):
        path=ART/'originals'/f"{record['id']}.png"
        shutil.copyfile(record['path'],path)
        palettes[record['id']]=extract_alpha(Image.open(path))[0]
    paladin=Image.open(ROOT/'artwork/paladin-ret-review/assets/action-hub-v2.png').convert('RGBA')
    palettes['class_paladin']=paladin
    reports=[]
    for entry in portraits:
        id=entry['id']
        family='class_paladin'
        if any(word in id for word in ('mage','warlock','demonhunter','nightborne','voidelf','draenei')):family='class_mage'
        if any(word in id for word in ('hunter','druid','shaman','monk','tauren','troll','pandaren','vulpera','nightelf','haranir')):family='class_hunter'
        if id in ('class_warrior','race_orc','race_magharorc','faction_horde'):family='class_warrior'
        if id=='class_paladin':family=id
        material=palettes[family].resize((WIDTH,HEIGHT),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',(WIDTH,HEIGHT))
        # One continuous rail passes behind the endcaps. The five-piece renderer
        # cuts it at identical seams for every theme, so changing artwork cannot
        # change fit or stretch a crest when the user adjusts the overall width.
        rail=material.crop((660,530,810,620)).resize((1632,106),Image.Resampling.LANCZOS)
        if id not in ('class_paladin','class_warrior','race_orc','race_magharorc'):
            tones=('171c21','a0a5a8')
            if any(k in id for k in ('mage','warlock','voidelf','nightborne','scourge')):tones=('151322','786d9e')
            elif any(k in id for k in ('hunter','druid','shaman','tauren','troll','haranir','pandaren','monk')):tones=('161e13','a8a16d')
            elif any(k in id for k in ('bloodelf','lightforged','zandalari')):tones=('2a2111','bda363')
            elif any(k in id for k in ('human','alliance','earthendwarf')):tones=('172531','94a8ba')
            elif any(k in id for k in ('darkiron','worgen','rogue','deathknight')):tones=('11161b','687683')
            grade=ImageOps.colorize(ImageOps.grayscale(rail),'#'+tones[0],'#'+tones[1]).convert('RGBA')
            grade.putalpha(rail.getchannel('A'));rail=Image.blend(rail,grade,0.8)
        canvas.alpha_composite(rail,(270,524))
        if id=='class_paladin':
            canvas.alpha_composite(paladin.crop((0,0,620,724)),(0,0))
            canvas.alpha_composite(paladin.crop((1552,0,2172,724)),(1552,0))
            # Preserve the reference Paladin rails/endcaps, replace only its sun.
            canvas.alpha_composite(paladin.crop((620,500,980,640)),(620,500))
            canvas.alpha_composite(paladin.crop((1210,500,1552,640)),(1210,500))
        if id in official:
            crest=Image.open(ROOT/official[id]['file']).convert('RGBA')
        else:
            # Neutral has no claimed official faction logo. Use the custom
            # compass crest from the retained neutral source, not another race.
            raw=extract_alpha(Image.open(ROOT/'artwork/portraits/originals/faction_neutral.png'))[0]
            crest=raw.crop((470,135,795,460))
            mask=Image.new('L',crest.size);ImageDraw.Draw(mask).ellipse((2,2,322,322),fill=255)
            crest.putalpha(ImageChops.darker(crest.getchannel('A'),mask))
        if id!='class_paladin':
            stamp(canvas,crest,(12,8,596,670))
            stamp(canvas,crest,(1564,8,596,670))
        stamp(canvas,crest,(986,444,218,226))
        # Explicit empty functional region. Artwork never occupies button space.
        assert canvas.crop((620,0,1552,440)).getchannel('A').getbbox() is None
        png=ART/'assets'/f'{id}.png';canvas.save(png)
        encoded=canvas.resize((1024,512),Image.Resampling.LANCZOS)
        encoded.save(ART/'game'/f'{id}.png')
        tga=output/f'{id}.tga';encoded.save(tga,format='TGA',compression=None)
        assert Image.open(tga).tobytes()==encoded.tobytes()
        reports.append({'id':id,'label':entry['label'],'group':entry['group'],
            'file':str(tga.relative_to(ROOT)),'source':str(png.relative_to(ROOT)),
            'source_sha256':digest(png),'source_size':[WIDTH,HEIGHT],
            'size':[1024,512],'sha256':digest(tga),'alphaBounds':list(encoded.getchannel('A').getbbox()),
            'official_crest':official.get(id),'rail_source':family,
            'registration':{'left':[12,8,596,670],'right':[1564,8,596,670],'center':[986,444,218,226]},
            'clear_points':[[.5,.25],[.4,.5],[.6,.5]],'in_game_qualified':False})
    manifest={'assets':reports,'geometry':'Shared five-piece atlas; 2172 x 724 design; 1024 x 512 texture',
              'credit':'Crests: Blizzard Entertainment. Surround/rail compositions: JiberishUI.',
              'in_game_qualified':False}
    (ART/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (ART/'gallery-data.js').write_text('const hubAssets = '+json.dumps(reports)+';\n')
    lines=['local _, J = ...','-- Data only; all variants use the same five-piece fitting template.','J.HubCatalog = { entries = {} }']
    for entry in reports:
        path='Interface\\AddOns\\JiberishUI\\Media\\Hubs\\'+entry['id']+'.tga'
        lines.append('J.HubCatalog.entries.'+entry['id'].upper()+' = {label='+json.dumps(entry['label'])+',group='+json.dumps(entry['group'].upper())+',texture='+json.dumps(path)+'}')
    (ROOT/'JiberishUI/Themes/Hubs.lua').write_text('\n'.join(lines)+'\n')
    target=ROOT/'docs/phase1-assets.json';data=json.loads(target.read_text())
    data['assets']=[a for a in data['assets'] if '/Hubs/' not in a['file'] and not a['file'].endswith('PaladinRet/action-hub.tga')]+reports
    data['official_crest_sources']='artwork/official-crests/sources.json'
    target.write_text(json.dumps(data,indent=2)+'\n')
    print('Prepared',len(reports),'hub atlases with identical registration and clear button regions.')


if __name__=='__main__':main()
