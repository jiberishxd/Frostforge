"""Encode the original generated console; nine-slice UVs are applied at runtime."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'artwork/hub-console.png'
target=ROOT/'JiberishUI/Media/hub/console.tga'
original=Image.open(source)
assert original.mode=='RGBA' and original.getchannel('A').getextrema()==(0,255)
target.parent.mkdir(parents=True,exist_ok=True)
texture=original.resize((2048,1024),Image.Resampling.LANCZOS)
texture.save(target,compression=None)
manifest=json.loads((ROOT/'docs/assets.json').read_text())
manifest['sources']=[s for s in manifest['sources'] if s['path']!='artwork/hub-console.png']
manifest['assets']=[a for a in manifest['assets'] if '/Media/hub/' not in a['file']]
manifest['sources'].append(dict(path=source.relative_to(ROOT).as_posix(),size=list(original.size),
    alphaBounds=original.getchannel('A').getbbox(),sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
    origin='original built-in image_gen artwork; artwork/hub-prompts.json#console'))
manifest['assets'].append(dict(file=target.relative_to(ROOT).as_posix(),source=source.relative_to(ROOT).as_posix(),
    crop=None,transform='resample to 2048x1024; preserve alpha; runtime nine-slice x=[0,.12,.88,1], y=[0,.43,.72,1]',
    size=list(texture.size),alphaBounds=texture.getchannel('A').getbbox(),sha256=hashlib.sha256(target.read_bytes()).hexdigest()))
manifest['assets'].sort(key=lambda a:a['file'])
(ROOT/'docs/assets.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Encoded transparent nine-slice console.')
