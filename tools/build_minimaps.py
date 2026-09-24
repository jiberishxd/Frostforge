"""Prepare class/race/faction minimap surrounds with a shared native aperture."""
import argparse
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from build_portraits import extract_alpha, digest
from build_hubs import extract_chroma
from fit_minimaps import conform, SIZE, CENTER, RADIUS

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'artwork/minimaps'


def main(partial=False):
    jobs = json.loads((ART/'generation-prompts.json').read_text())
    records = {a['id']:a for a in json.loads((ART/'generation-results.json').read_text())}
    for path in sorted((ART/'generation-records').glob('*.json')):
        record = json.loads(path.read_text()); records[record['id']] = record
    revisions = {r['id']:r for r in json.loads((ART/'alpha-background-revisions.json').read_text())}
    if not partial:
        assert set(records) == {j['id'] for j in jobs}, 'All 42 matching minimaps are required'
    (ART/'assets').mkdir(exist_ok=True)
    output = ROOT/'JiberishUI/Media/Minimaps'; output.mkdir(parents=True, exist_ok=True)
    reports = []
    for job in jobs:
        if job['id'] not in records:
            continue
        original = ROOT/records[job['id']]['path']
        revision = revisions.get(job['id'])
        if revision:
            original = ROOT/revision['path']
            raw, method = extract_chroma(Image.open(original), 'green')
        else:
            raw, method = extract_alpha(Image.open(original))
        result, fitted = conform(raw)
        alpha = np.asarray(result.getchannel('A'))
        assert .10 < (alpha > 0).mean() < .65, job['id']
        png = ART/'assets'/(job['id']+'.png'); result.save(png)
        tga = output/(job['id']+'.tga'); result.save(tga, format='TGA', compression=None)
        assert Image.open(tga).tobytes() == result.tobytes()
        reports.append({'id':job['id'], 'label':job['label'], 'group':job['group'],
            'file':str(tga.relative_to(ROOT)), 'source':str(png.relative_to(ROOT)),
            'source_sha256':digest(png), 'source_size':[SIZE,SIZE],
            'original':str(original.relative_to(ROOT)), 'original_sha256':digest(original),
            'background_revision':revision,
            'size':[SIZE,SIZE], 'sha256':digest(tga), 'alphaBounds':list(result.getchannel('A').getbbox()),
            'transform':method+'; radial contour registration to shared circular opening; outer silhouette retained; detached matte specks under 200 pixels removed',
            'source_circle':fitted, 'registration':{'canvas':[512,512],'center':[256,256],'radius':149,'margin':8},
            'clear_points':[[.5,.5],[.5,.3],[.3,.5]], 'default_display_size':[340,340],
            'references':[{'file':p,'sha256':digest(ROOT/p)} for p in job['references']],
            'in_game_qualified':False})
    (ART/'manifest.json').write_text(json.dumps({'assets':reports,'complete':len(reports)==42,'in_game_qualified':False},indent=2)+'\n')
    (ART/'gallery-data.js').write_text('const minimapAssets = '+json.dumps(reports)+';\n')
    sheet = Image.new('RGB',(7*240, ((len(reports)+6)//7)*260),'#26322d')
    for i, entry in enumerate(reports):
        im = Image.open(ROOT/entry['source']).resize((232,232),Image.Resampling.LANCZOS)
        sheet.paste(im,((i%7)*240+4,(i//7)*260+20),im)
        ImageDraw.Draw(sheet).text(((i%7)*240+8,(i//7)*260+4),entry['label'],fill='white')
    sheet.save(ART/'collection-review.png')
    if not partial:
        (ART/'generation-results.json').write_text(json.dumps([records[j['id']] for j in jobs],indent=2)+'\n')
        lines=['local _, J = ...','-- Data only; every identity shares one circular aperture.','J.MinimapCatalog = { entries = {} }']
        for entry in reports:
            path='Interface\\AddOns\\JiberishUI\\Media\\Minimaps\\'+entry['id']+'.tga'
            lines.append('J.MinimapCatalog.entries.'+entry['id'].upper()+' = {label='+json.dumps(entry['label'])+',group='+json.dumps(entry['group'].upper())+',texture='+json.dumps(path)+'}')
        (ROOT/'JiberishUI/Themes/Minimaps.lua').write_text('\n'.join(lines)+'\n')
        p=ROOT/'docs/phase1-assets.json'; data=json.loads(p.read_text())
        data['assets']=[a for a in data['assets'] if '/Minimaps/' not in a['file'] and not a['file'].endswith('PaladinRet/minimap.tga')]+reports
        data['minimap_prompts']='artwork/minimaps/generation-prompts.json'
        p.write_text(json.dumps(data,indent=2)+'\n')
    print('Prepared',len(reports),'minimap surrounds at 512 pixels with a shared transparent circular opening.')


if __name__ == '__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('--partial',action='store_true')
    main(parser.parse_args().partial)
