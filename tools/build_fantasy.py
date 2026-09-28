"""Encode generated transparent crests as WoW TGA textures; keep original masters.

Only runtime resampling/encoding is performed. No painting or alpha removal.
The 2:1 texture is displayed at the master's 3:1 aspect ratio by the addon.
"""
import hashlib
import json
from pathlib import Path
from PIL import Image,ImageDraw
from build_library import font

ROOT=Path(__file__).resolve().parents[1]

def build():
    prompts=json.loads((ROOT/'artwork/fantasy-prompts.json').read_text())['prompts']
    manifest=json.loads((ROOT/'docs/assets.json').read_text())
    manifest['sources']=[s for s in manifest['sources'] if not s['path'].startswith('artwork/fantasy/')]
    manifest['assets']=[a for a in manifest['assets'] if '/Media/fantasy/' not in a['file']]
    for name in sorted(prompts):
        source=ROOT/'artwork/fantasy'/f'{name}.png'
        original=Image.open(source)
        assert original.mode=='RGBA' and original.getchannel('A').getextrema()==(0,255),name
        manifest['sources'].append(dict(path=source.relative_to(ROOT).as_posix(),size=list(original.size),
            alphaBounds=original.getchannel('A').getbbox(),sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
            origin='original built-in image_gen artwork; artwork/fantasy-prompts.json#'+name))
        target=ROOT/'Frostforge/Media/fantasy'/f'{name}.tga';target.parent.mkdir(parents=True,exist_ok=True)
        texture=original.resize((512,256),Image.Resampling.LANCZOS);texture.save(target,compression=None)
        manifest['assets'].append(dict(file=target.relative_to(ROOT).as_posix(),source=source.relative_to(ROOT).as_posix(),
            crop=None,transform='resample to 512x256; display at original 3:1 aspect; preserve alpha',
            size=list(texture.size),alphaBounds=texture.getchannel('A').getbbox(),sha256=hashlib.sha256(target.read_bytes()).hexdigest()))
    manifest['assets'].sort(key=lambda a:a['file'])
    (ROOT/'docs/assets.json').write_text(json.dumps(manifest,indent=2)+'\n')
    sheet=Image.new('RGB',(1320,940),'#0b111b');draw=ImageDraw.Draw(sheet)
    draw.text((24,20),'JIBERISHUI / CLASS FANTASY + HOLIDAYS',font=font(28,True),fill='#eaf2ff')
    draw.text((24,61),'15 original crests for portraits and action-bar surrounds. Artwork sheet; in-game fit pending.',font=font(16),fill='#9aaabd')
    for i,name in enumerate(sorted(prompts)):
        x=24+(i%3)*432;y=110+(i//3)*162
        draw.rounded_rectangle((x,y,x+408,y+145),radius=8,fill='#141d2a')
        draw.text((x+14,y+10),name.replace('deathknight','death knight').replace('demonhunter','demon hunter').title(),font=font(17,True),fill='#eaf2ff')
        art=Image.open(ROOT/'artwork/fantasy'/f'{name}.png').resize((360,120),Image.Resampling.LANCZOS)
        sheet.paste(art,(x+24,y+28),art)
    sheet.save(ROOT/'docs/fantasy-library.png')
    print(f'Encoded {len(prompts)} transparent class and holiday crests.')

if __name__=='__main__':build()
