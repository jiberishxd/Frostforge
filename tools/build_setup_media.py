"""Prepare two small tour captures; never rewrite the existing artwork assets."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

def build():
    manifest_path = ROOT / 'docs/phase1-assets.json'
    manifest = json.loads(manifest_path.read_text())
    assets = [a for a in manifest['assets'] if a.get('kind') != 'setup-screenshot']
    for name, source_path, crop, size, canvas in (
        ('setup-ingame', 'docs/images/setup-ingame.png', None, (910,512), (1024,512)),
        ('setup-settings', 'artwork/settings/setup-settings-capture.png', (10,10,826,632), (512,390), (512,512)),
    ):
        source = Image.open(ROOT / source_path).convert('RGBA')
        image = source.crop(crop) if crop else source
        if image.size != size:
            image = image.resize(size, Image.Resampling.LANCZOS)
        atlas = Image.new('RGBA',canvas)
        atlas.paste(image,(0,0))
        output = f'Frostforge/Media/Setup/{name}.tga'
        (ROOT / output).parent.mkdir(parents=True,exist_ok=True)
        atlas.save(ROOT / output,compression=None)
        atlas.save(ROOT / f'artwork/settings/{name}.png')
        assets.append(dict(id=name,label='Frostforge onboarding screenshot',kind='setup-screenshot',
            file=output,source=source_path,source_size=list(source.size),source_crop=crop,
            source_sha256=hashlib.sha256((ROOT / source_path).read_bytes()).hexdigest(),
            sha256=hashlib.sha256((ROOT / output).read_bytes()).hexdigest(),size=list(canvas),
            alphaBounds=list(atlas.getchannel('A').getbbox()),
            transform='Screenshot fitted without stretching, with transparent padding. Existing artwork files unchanged.'))
    manifest['assets']=assets
    manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')

if __name__=='__main__':
    build()
