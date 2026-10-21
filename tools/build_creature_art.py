"""Fit generated creature portraits/shells with the established addon geometry.

Originals and prompts stay in the requested source directory. Local fitting is
user-authorized; generated alpha and the original paintings are preserved.
Only creature assets/catalog entries are replaced. Existing themes stay intact.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re

from PIL import Image, ImageDraw, ImageFont
from build_portraits import normalize_footprint, remove_fragments
from fit_portraits import conform
from fit_unit_shells import runs
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
TYPES = {
    'beast': 'CLASS_HUNTER', 'humanoid': 'CLASS_WARRIOR',
    'undead': 'CLASS_DEATHKNIGHT', 'demon': 'CLASS_DEMONHUNTER',
    'dragonkin': 'CLASS_EVOKER', 'elemental': 'CLASS_SHAMAN',
    'mechanical': 'RACE_MECHAGNOME', 'giant': 'RACE_EARTHENDWARF',
    'critter': 'CLASS_DRUID', 'aberration': 'RACE_VOIDELF',
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path):
    return path.relative_to(ROOT).as_posix()


def save(image, kind, stem, source_dir, original):
    fitted = source_dir / 'fitted' / kind / (stem + '.png')
    fitted.parent.mkdir(parents=True, exist_ok=True)
    fitted_image = image.convert('RGBA')
    fitted_image.save(fitted)
    runtime = ROOT / 'Frostforge/Media' / kind / fitted.name
    runtime.write_bytes(fitted.read_bytes())
    legacy = io.BytesIO()
    fitted_image.save(legacy, format='TGA', compression=None)
    return dict(file=relative(runtime), source=relative(fitted), size=list(image.size),
                sha256=sha(runtime), source_sha256=sha(fitted),
                original=relative(original), original_sha256=sha(original),
                legacy_tga_sha256=hashlib.sha256(legacy.getvalue()).hexdigest(),
                alphaBounds=list(image.getchannel('A').getbbox()), in_game_qualified=False)


def fit_shell(original):
    """Measure generated alpha without chroma-keying green creature details."""
    image=Image.open(original).convert('RGBA')
    a=np.array(image)
    assert a[:,:,3].min()==0, 'Generated alpha required'
    # Tiny alpha noise is invisible but fragments otherwise empty bar slots.
    a[a[:,:,3]<16]=0
    h,w=a.shape[:2]
    middle=(a[:,int(w*.35):int(w*.6),3]<32).mean(axis=1)>.8
    # Exclude the unbounded exterior below short hanging ornaments.
    slots=[r for r in runs(middle) if h*.27<r[0]<r[1]<h*.85 and r[1]-r[0]>h*.018]
    assert len(slots)==2, (original, 'Expected two bar openings', slots)
    measured={}
    for kind,(top,bottom) in zip(('health','power'),slots):
        # Use coverage across the slot, avoiding isolated translucent flecks.
        mid=(top+bottom)//2;thick=max(2,(bottom-top)//6)
        columns=(a[mid-thick:mid+thick,:,3]<64).mean(axis=0)>.7
        columns=np.convolve(columns.astype(float),np.ones(25)/25,mode='same')>.6
        if kind=='power':
            # A small leaf/tusk can cross the thin power slot. Its usable
            # horizontal span follows the aligned health opening above it.
            columns[measured['health'][0]:measured['health'][2]]=True
        spans=[r for r in runs(columns) if r[0]<w/2<r[1]]
        assert len(spans)==1 and spans[0][1]-spans[0][0]>w*.5, (original,kind,spans)
        left,right=spans[0]
        measured[kind]=[int(left),int(top),int(right),int(bottom)]
        a[top+2:bottom-2,left+2:right-2]=0
    image=Image.fromarray(a)
    factor=min(504/w,248/h)
    size=(round(w*factor),round(h*factor))
    offset=((512-size[0])//2,(256-size[1])//2)
    fitted=image.convert('RGBa').resize(size,Image.Resampling.LANCZOS).convert('RGBA')
    result=Image.new('RGBA',(512,256));result.paste(fitted,offset)
    reg={'canvas':[512,256],'margin':4}
    for kind,(left,top,right,bottom) in measured.items():
        reg[kind]=[offset[0]+left*size[0]/w,offset[1]+top*size[1]/h,
                   offset[0]+right*size[0]/w,offset[1]+bottom*size[1]/h]
    reg['divider']=reg['power'][1]-reg['health'][3]
    measured.update(scale=[size[0]/w,size[1]/h],offset=list(offset),registration=reg)
    return result,measured


def build(source_dir):
    assets, reports, entries = [], [], []
    catalog_path = ROOT / 'Frostforge/Themes/UnitSkins.lua'
    catalog = '\n'.join(line for line in catalog_path.read_text().splitlines()
                        if not line.startswith('J.UnitSkinCatalog.entries.CREATURE_')
                        and not line.startswith('-- Creature artwork')).rstrip() + '\n'
    for name, base in TYPES.items():
        stem, identity = 'creature_' + name, 'CREATURE_' + name.upper()
        original = source_dir / (name + '-portrait.png')
        source = Image.open(original).convert('RGBA')
        assert source.getchannel('A').getextrema()[0] == 0, 'Generated alpha required'
        # Each source is a dual portrait atlas. Register the first painting to
        # both established openings, keeping the two variants visually matched.
        source = source.crop((0, 0, source.width // 2, source.height))
        registered, bounds = normalize_footprint(source)
        atlas = Image.new('RGBA', (512, 256))
        for index, shape in enumerate(('player', 'round')):
            atlas.paste(remove_fragments(conform(registered, shape)), (index * 256, 0))
        record = save(atlas, 'Portraits', stem, source_dir, original)
        record.update(id=stem, label=name.title(), group='CREATURE', fit_version=5,
                      registration_box=[8, 8, 214, 244], registration_source_bounds=list(bounds),
                      portrait_center=[154, 148], portrait_radius=60, round_portrait_radius=58,
                      clear_points=[[154/512,148/256],[410/512,148/256],[.45,.5],[.95,.5]],
                      transform='Generated alpha retained; shared player/round contour registration')
        assets.append(record)
        original = source_dir / (name + '-frame.png')
        shell, measured = fit_shell(original)
        record = save(shell, 'UnitFrames', stem, source_dir, original)
        record.update(kind='unit-shell', registration=measured['registration'], references=[
            dict(file=relative(original), sha256=sha(original)),
            dict(file=relative(source_dir/'generation-prompts.json'), sha256=sha(source_dir/'generation-prompts.json'))])
        assets.append(record)
        reports.append(dict(id=stem, fit_version=3, source=relative(original), source_sha256=sha(original),
                            file=record['source'], sha256=record['source_sha256'], measured=measured))
        base_line = next(line for line in catalog.splitlines() if line.strip().startswith(base + ' ='))
        fields = dict(re.findall(r'(cast|health|power)="([^"]+)"', base_line))
        reg = measured['registration']
        opening = ','.join(kind+'={'+','.join(f'{v:.8f}' for v in reg[kind])+'}' for kind in ('health','power'))
        shell_path = 'Interface\\\\AddOns\\\\Frostforge\\\\Media\\\\UnitFrames\\\\'+stem+'.png'
        fields_lua = ','.join(key+'="'+fields[key]+'"' for key in ('cast','health','power'))
        entries.append('J.UnitSkinCatalog.entries.'+identity+' = {shell="'+shell_path+'",'+fields_lua+',castTheme="'+base+'",opening={'+opening+'}}')
    catalog_path.write_text(catalog+'\n-- Creature artwork: dedicated portrait/shell; existing matching fills and cast trim.\n'+'\n'.join(entries)+'\n')
    manifest_path = ROOT/'docs/phase1-assets.json'
    manifest = json.loads(manifest_path.read_text())
    manifest['assets'] = [a for a in manifest['assets'] if not Path(a['file']).stem.startswith('creature_')] + assets
    manifest_path.write_text(json.dumps(manifest, indent=2)+'\n')
    fits_path = ROOT/'docs/artwork/unit-frame-fit-report.json'
    fits = [r for r in json.loads(fits_path.read_text()) if not r['id'].startswith('creature_')]
    fits_path.write_text(json.dumps(fits+reports, indent=2)+'\n')
    (source_dir/'fit-report.json').write_text(json.dumps(reports,indent=2)+'\n')
    gallery(source_dir)
    print('Fitted 10 creature portrait atlases and 10 unit-frame shells; all originals retained.')


def gallery(source_dir):
    # Actual runtime art at 2x display scale. This is a review sheet, not an
    # in-game screenshot; transparent openings stay visible against charcoal.
    sheet = Image.new('RGB', (1560, 1120), '#11171d')
    draw = ImageDraw.Draw(sheet)
    def font_at(size):
        for family in ('/System/Library/Fonts/Supplemental/Arial.ttf', 'DejaVuSans.ttf'):
            try: return ImageFont.truetype(family, size)
            except OSError: pass
        return ImageFont.load_default()
    font,small = font_at(23),font_at(16)
    draw.text((32, 24), 'FROSTFORGE / CREATURE COLLECTION', font=font, fill='#d8eafa')
    draw.text((32, 59), 'New portrait surrounds + matching unit-frame shells | Runtime artwork preview', font=small, fill='#8fa6ba')
    for i,name in enumerate(TYPES):
        x,y = 24+(i%2)*768, 100+(i//2)*200
        draw.rounded_rectangle((x,y,x+744,y+184),radius=12,fill='#1c252e')
        draw.text((x+18,y+12),name.title(),font=font,fill='#e8eef3')
        atlas=Image.open(ROOT/'Frostforge/Media/Portraits'/('creature_'+name+'.png'))
        portrait=atlas.crop((256,0,512,256)).resize((144,144),Image.Resampling.LANCZOS)
        sheet.paste(portrait,(x+12,y+38),portrait)
        shell=Image.open(ROOT/'Frostforge/Media/UnitFrames'/('creature_'+name+'.png'))
        shell=shell.resize((288,144),Image.Resampling.LANCZOS)
        sheet.paste(shell,(x+180,y+36),shell)
        # A second preview at normal display size reveals over-fine details.
        tiny=shell.resize((216,108),Image.Resampling.LANCZOS)
        sheet.paste(tiny,(x+508,y+54),tiny)
    sheet.save(source_dir/'creature-collection.png')


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--source-dir',type=Path,default=ROOT/'artwork/creatures/v1')
    build(parser.parse_args().source_dir.absolute())
