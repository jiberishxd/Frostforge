"""Deterministically slice the user-requested original WC3 assets; no generated artwork.
Run with Python + Pillow after tools/extract_art.py. Output paths and crop provenance
are recorded in docs/assets.json. Source DDS files remain outside release packages.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from art_common import compose
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
RACES = ['human', 'orc', 'nightelf', 'undead']
PIECES = ['left', 'right', 'top', 'bottom', 'tl', 'tr', 'bl', 'br']
manifest = {'sourceBuild': '3.0.0.24268', 'sourceMode': 'classic (no _hd or _de overrides)', 'sources': [], 'assets': []}
# Rebuilding classic art must not erase the separately built original library manifest.
manifest_path=ROOT/'docs/assets.json'
if manifest_path.exists():
    previous=json.loads(manifest_path.read_text())
    manifest['sources']=[s for s in previous['sources'] if not s['path'].startswith('war3.w3mod:')]
    manifest['assets']=[a for a in previous['assets'] if Path(a['file']).parent.name not in RACES and not a['file'].endswith('/neutral.tga')]
    if 'generatedArtwork' in previous:manifest['generatedArtwork']=previous['generatedArtwork']
sheet = Image.new('RGB', (1200, 1060), '#12161c')
draw = ImageDraw.Draw(sheet)
draw.text((28, 18), 'JIBERISHUI / CLASSIC WARCRAFT III / MEASURED ASSET REFERENCE', fill='white')

def save(im, path, source, crop=None, transform=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    im = im.convert('RGBA')
    im.save(path, compression=None)
    manifest['assets'].append({'file': str(path.relative_to(ROOT)), 'source': source,
                              'crop': crop, 'transform': transform, 'size': list(im.size),
                              'alphaBounds': im.getchannel('A').getbbox(),
                              'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})

for row, race in enumerate(RACES):
    for kind, source_path in [('border',f'ui\\widgets\\escmenu\\{race}\\{race}-options-menu-border.dds'),
                              ('ornament',f'ui\\console\\{race}\\{race}uitile-timeindicatorframe.dds'),
                              ('console',f'ui\\console\\{race}\\{race}uitile01.dds')]:
        original=ROOT/'.reference/wc3'/f'{race}-{kind}.dds'
        original_image=Image.open(original).convert('RGBA')
        manifest['sources'].append({'path':'war3.w3mod:'+source_path,'size':list(original_image.size),
                                    'alphaBounds':original_image.getchannel('A').getbbox(),
                                    'sha256':hashlib.sha256(original.read_bytes()).hexdigest()})
    src = ROOT / '.reference/wc3' / f'{race}-border.dds'
    strip = Image.open(src).convert('RGBA')
    assert strip.size == (512,64)
    base = ROOT / 'Frostforge/Media' / race
    source = f'war3.w3mod:ui\\widgets\\escmenu\\{race}\\{race}-options-menu-border.dds'
    pieces = {}
    for i,key in enumerate(PIECES):
        sub = {'left':(0,0,32,64),'right':(32,0,64,64),
               'top':(0,0,32,64),'bottom':(32,0,64,64),
               'tl':(0,0,32,32),'tr':(32,0,64,32),
               'bl':(0,32,32,64),'br':(32,32,64,64)}[key]
        crop = [64*i+sub[0],sub[1],64*i+sub[2],sub[3]]
        im = strip.crop(crop)
        if key in ('top','bottom'):
            im = im.transpose(Image.Transpose.ROTATE_270)
        pieces[key] = im
        save(im, base / f'{key}.tga', source, crop, 'clockwise 90' if key in ('top','bottom') else None)
    for state, tint in [('normal',1),('pushed',0.65),('highlight',1.35),('checked',1.15)]:
        button = compose(pieces,64,64,12)
        if tint != 1:
            channels=list(button.split())
            for c in range(3): channels[c]=channels[c].point(lambda v:min(255,round(v*tint)))
            button=Image.merge('RGBA',channels)
        save(button, base/f'button-{state}.tga', source, transform=f'8-piece button composition; RGB multiplier {tint}')
    # A dedicated portrait surround leaves the original circular portrait/mask intact.
    save(compose(pieces,128,128,16),base/'portrait.tga',source,transform='8-piece portrait composition')
    ornament=Image.open(ROOT/'.reference/wc3'/f'{race}-ornament.dds').convert('RGBA')
    save(ornament,base/'ornament.tga',f'war3.w3mod:ui\\console\\{race}\\{race}uitile-timeindicatorframe.dds')
    y=70+row*245
    draw.text((28,y),race.upper(),fill='white')
    sheet.paste(strip,(28,y+26),strip)
    for x,w,h,e in [(28,232,74,12),(295,126,32,6),(470,84,42,5),(590,45,45,9)]:
        frame=compose(pieces,w,h,e)
        sheet.paste(frame,(x,y+130),frame)
    sheet.paste(ornament,(730,y+60),ornament)
    draw.text((28,y+215),'Unit / bar / compact / button (synthetic fitting references; not in-game screenshots)',fill='#aebccc')
save(Image.new('RGBA',(8,8),'white'), ROOT/'Frostforge/Media/neutral.tga', 'procedural white fill', transform='neutral tintable status-bar fill')
(ROOT/'docs/assets.json').write_text(json.dumps(manifest,indent=2)+'\n')
sheet.save(ROOT/'docs/skin-reference.png')
print(f'Built {len(manifest["assets"])} textures and docs/skin-reference.png')
