"""Fit generated seasonal sets without changing existing runtime artwork.

Generated originals and alpha are retained. Shared registration helpers fit the
portrait openings, bar slots, five-piece hubs and circular minimap apertures.
"""
import argparse
import json
from pathlib import Path
import re

from PIL import Image, ImageDraw, ImageFont
import numpy as np
from build_creature_art import ROOT, save, sha, relative, fit_shell
from build_portraits import normalize_footprint, remove_fragments
from fit_portraits import conform as portrait_fit
from fit_minimaps import conform as minimap_fit
from build_hubs import register as hub_fit, REGISTRATION
from fit_event_art import fit_hub as event_hub_fit, fit_minimap as event_minimap_fit
from fit_event_art import fit_portrait as event_portrait_fit
from fit_event_art import clean_alpha

SETS = {
    'harvest_hollow': ('Harvest Hollow', 'Halloween', 'CLASS_WARRIOR'),
    'witching_hour': ('Witching Hour', 'Halloween', 'CLASS_WARLOCK'),
    'hallows_end': ("Hallow's End", 'Halloween', 'CLASS_DEMONHUNTER'),
    'holly_hearth': ('Holly Hearth', 'Christmas', 'RACE_BLOODELF'),
    'winter_starlight': ('Winter Starlight', 'Christmas', 'CLASS_MAGE'),
    # Preserve the first preview's saved identity for the corrected dwarf set.
    'winter_veil': ('Winter Veil: Alliance', 'Christmas', 'RACE_DWARF'),
    'winter_veil_horde': ('Winter Veil: Horde', 'Christmas', 'RACE_ORC'),
}
EVENT_SETS = ('hallows_end', 'winter_veil', 'winter_veil_horde')
MARKER = '-- Seasonal artwork:'


def alpha_source(path):
    image = Image.open(path).convert('RGBA')
    data = np.array(image)
    assert data[:, :, 3].min() == 0, f'Generated alpha required: {path}'
    data[data[:, :, 3] < 16] = 0
    return Image.fromarray(data)


def build(source_dir, events_dir):
    assets, fits = [], []
    sources = {name: events_dir if name in EVENT_SETS else source_dir for name in SETS}
    landmarks_path = events_dir / 'fitting-landmarks.json'
    landmarks = json.loads(landmarks_path.read_text()) if landmarks_path.exists() else {}
    catalogs = {}
    for name in ('Portraits', 'Hubs', 'Minimaps', 'UnitSkins'):
        path = ROOT / 'Frostforge/Themes' / (name + '.lua')
        existing = '\n'.join(line for line in path.read_text().splitlines()
                             if not line.startswith(MARKER) and '.entries.SEASONAL_' not in line)
        catalogs[name] = [existing.rstrip(),
                          '\n' + MARKER + f' {len(SETS)} complete holiday collections.']
    for name, (label, holiday, base) in SETS.items():
        source_dir = sources[name]
        stem, identity = 'seasonal_' + name, 'SEASONAL_' + name.upper()
        references = [{'file': relative(source_dir / 'generation-prompts.json'),
                       'sha256': sha(source_dir / 'generation-prompts.json')}]
        original = source_dir / (name + '-portrait.png')
        source = alpha_source(original)
        half = source.crop((0, 0, source.width // 2, source.height))
        proportion = None
        if name in EVENT_SETS:
            atlas, proportion = event_portrait_fit(half)
            bounds = proportion['source_bounds']
        else:
            registered, bounds = normalize_footprint(half)
            atlas = Image.new('RGBA', (512, 256))
            for index, shape in enumerate(('player', 'round')):
                atlas.paste(remove_fragments(portrait_fit(registered, shape)), (index * 256, 0))
        record = save(atlas, 'Portraits', stem, source_dir, original)
        record.update(id=stem, label=label, group='SEASONAL', holiday=holiday,
                      fit_version=5, registration_box=[8, 8, 214, 244],
                      registration_source_bounds=list(bounds), portrait_center=[154, 148],
                      portrait_radius=60, round_portrait_radius=58,
                      clear_points=[[154/512,148/256],[410/512,148/256],[.45,.5],[.95,.5]],
                      transform='Generated alpha retained; shared player/round contour registration')
        if proportion:
            record.update(proportion_fit=proportion, transform=proportion['method'])
        assets.append(record)
        original = source_dir / (name + '-frame.png')
        shell, measured = fit_shell(original)
        alpha_floor = landmarks.get(name, {}).get('frame_alpha_floor')
        if alpha_floor:
            # Thin slots can acquire faint resampling fringe after downscaling.
            shell = clean_alpha(shell, alpha_floor)
            measured['encoded_alpha_floor'] = alpha_floor
        record = save(shell, 'UnitFrames', stem, source_dir, original)
        record.update(kind='unit-shell', registration=measured['registration'], references=references)
        assets.append(record)
        fits.append(dict(id=stem, fit_version=3, source=relative(original), source_sha256=sha(original),
                         file=record['source'], sha256=record['source_sha256'], measured=measured))
        line = next(line for line in catalogs['UnitSkins'][0].splitlines()
                    if line.strip().startswith(base + ' ='))
        fields = dict(re.findall(r'(cast|health|power)="([^"]+)"', line))
        reg = measured['registration']
        opening = ','.join(kind+'={'+','.join(f'{v:.8f}' for v in reg[kind])+'}'
                           for kind in ('health', 'power'))
        texture = 'Interface\\\\AddOns\\\\Frostforge\\\\Media\\\\UnitFrames\\\\'+stem+'.png'
        fields_lua = ','.join(key+'="'+fields[key]+'"' for key in ('cast','health','power'))
        catalogs['UnitSkins'].append('J.UnitSkinCatalog.entries.'+identity+' = {shell="'+texture+'",'+
                                    fields_lua+',castTheme="'+base+'",opening={'+opening+'}}')
        original = source_dir / (name + '-hub.png')
        hub_source = alpha_source(original)
        if name in EVENT_SETS:
            hub, mapping = event_hub_fit(hub_source, landmarks.get(name, {}).get('hub_rail'))
        else:
            hub, mapping = hub_fit(hub_source)
        encoded = hub.convert('RGBa').resize((1024, 512), Image.Resampling.LANCZOS).convert('RGBA')
        if name in EVENT_SETS:
            # Downsampling can spread alpha 1–3 back into the clear corridor.
            pixels = np.array(encoded)
            pixels[pixels[:, :, 3] < 8] = 0
            encoded = Image.fromarray(pixels)
        record = save(encoded, 'Hubs', stem, source_dir, original)
        record.update(id=stem, label=label, group='SEASONAL', holiday=holiday,
                      registration=REGISTRATION, vertical_registration=mapping,
                      clear_points=[[.5,.25],[.4,.5],[.6,.5]],
                      transform='Generated alpha retained; continuous five-piece hub registration')
        if name in EVENT_SETS:
            record.pop('vertical_registration')
            record.update(proportion_fit=mapping, transform=mapping['method'])
        assets.append(record)
        original = source_dir / (name + '-minimap.png')
        proportion = None
        if name in EVENT_SETS:
            minimap, proportion = event_minimap_fit(alpha_source(original))
            circle = proportion['source_circle']
        else:
            minimap, circle = minimap_fit(alpha_source(original))
        record = save(minimap, 'Minimaps', stem, source_dir, original)
        record.update(id=stem, label=label, group='SEASONAL', holiday=holiday,
                      registration={'canvas':[512,512],'center':[256,256],'radius':149,'margin':8},
                      source_circle=circle, references=references,
                      clear_points=[[.5,.5],[.5,.3],[.3,.5]],
                      transform='Generated alpha retained; shared circular aperture registration')
        if proportion:
            record.update(proportion_fit=proportion, transform=proportion['method'])
        assets.append(record)
        for name, catalog in (('Portraits','PortraitCatalog'), ('Hubs','HubCatalog'), ('Minimaps','MinimapCatalog')):
            texture = 'Interface\\AddOns\\Frostforge\\Media\\'+name+'\\'+stem+'.png'
            catalogs[name].append('J.'+catalog+'.entries.'+identity+' = {label='+json.dumps(label)+
                                  ',group="SEASONAL",holiday='+json.dumps(holiday)+',texture='+json.dumps(texture)+'}')
    # Commit metadata only after every generated set fits successfully.
    for name, lines in catalogs.items():
        (ROOT / 'Frostforge/Themes' / (name + '.lua')).write_text('\n'.join(lines)+'\n')
    path = ROOT / 'docs/phase1-assets.json'
    manifest = json.loads(path.read_text())
    manifest['assets'] = [a for a in manifest['assets'] if not Path(a['file']).stem.startswith('seasonal_')] + assets
    path.write_text(json.dumps(manifest, indent=2)+'\n')
    path = ROOT / 'docs/artwork/unit-frame-fit-report.json'
    existing = [r for r in json.loads(path.read_text()) if not r['id'].startswith('seasonal_')]
    path.write_text(json.dumps(existing+fits, indent=2)+'\n')
    for directory in set(sources.values()):
        reports = [fit for fit in fits if Path(fit['source']).parent == directory.relative_to(ROOT)]
        (directory / 'fit-report.json').write_text(json.dumps(reports, indent=2)+'\n')
    gallery(events_dir / 'seasonal-collection.png')
    gallery(events_dir / 'warcraft-events.png', EVENT_SETS)
    print(f'Fitted {len(SETS)} seasonal sets: portraits, unit frames, hubs and minimaps.')


def gallery(destination, names=None):
    selected = {name: SETS[name] for name in (names or SETS)}
    def font(size):
        for family in ('/System/Library/Fonts/Supplemental/Arial.ttf', 'DejaVuSans.ttf'):
            try: return ImageFont.truetype(family, size)
            except OSError: pass
        return ImageFont.load_default()
    sheet = Image.new('RGB', (1800, 156 + len(selected) * 316), '#101720')
    draw = ImageDraw.Draw(sheet)
    draw.text((40, 26), 'FROSTFORGE / SEASONAL COLLECTION', font=font(32), fill='#e6edf3')
    subtitle = "Hallow's End + Winter Veil: Alliance / Horde" if names else 'Three Halloween sets + four Christmas sets'
    draw.text((40, 72), subtitle + ' | Fitted runtime artwork', font=font(19), fill='#9aafc2')
    for index, (name, (label, holiday, _)) in enumerate(selected.items()):
        y = 120 + index * 316
        draw.rounded_rectangle((24,y,1776,y+298), radius=16, fill='#1a2530')
        draw.text((48,y+14), label.upper(), font=font(25), fill='#f3f1ec')
        draw.text((48,y+48), holiday, font=font(17), fill='#a9bdcf')
        for kind, box in (('Portraits',(46,y+75,206,206)), ('UnitFrames',(280,y+70,420,210)),
                          ('Hubs',(740,y+65,650,217)), ('Minimaps',(1470,y+66,222,222))):
            im = Image.open(ROOT/'Frostforge/Media'/kind/('seasonal_'+name+'.png')).convert('RGBA')
            if kind == 'Portraits': im = im.crop((256,0,512,256))
            im = im.convert('RGBa').resize(box[2:],Image.Resampling.LANCZOS).convert('RGBA')
            sheet.paste(im, box[:2], im)
    sheet.save(destination)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-dir', type=Path, default=ROOT/'artwork/seasonal/v1')
    parser.add_argument('--events-dir', type=Path, default=ROOT/'artwork/seasonal/warcraft-events-v5')
    args = parser.parse_args()
    build(args.source_dir.absolute(), args.events_dir.absolute())
