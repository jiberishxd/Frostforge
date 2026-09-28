"""Prepare complete sculpted hubs on one shared, five-piece fitting atlas.

Only alpha cleanup and registration are procedural. Each theme's endcaps, drape,
rail and integrated left emblem are painted together, never repeated icon stamps.
"""
import argparse
import json
import numpy as np
from PIL import Image, ImageFilter
from build_portraits import ROOT, extract_alpha, digest, retain_source
from clean_hub_alpha import clean
from apply_nightelf_emblem import apply_overlay

ART = ROOT / 'artwork/hubs'
WIDTH, HEIGHT = 2172, 724
REGISTRATION = {'canvas':[2172,724], 'seams':[620,980,1210,1552],
                'rail_band':[530,620], 'clear_region':[620,0,1552,440]}


def extract_chroma(image,matte):
    rgb=np.array(image.convert('RGB'),dtype=float)
    backdrop=np.median(np.concatenate((rgb[0],rgb[-1])),axis=0)
    if matte=='magenta':
        assert backdrop[0]>200 and backdrop[1]<30 and backdrop[2]>200
        key=np.minimum(rgb[:,:,0],rgb[:,:,2])-rgb[:,:,1]
        maximum=min(backdrop[0],backdrop[2])-backdrop[1]
    else:
        assert matte=='green' and backdrop[1]>200 and max(backdrop[0],backdrop[2])<30
        key=rgb[:,:,1]-np.maximum(rgb[:,:,0],rgb[:,:,2])
        maximum=backdrop[1]-max(backdrop[0],backdrop[2])
    # Restrict soft keying to the matte and its immediate edge. Violet cloth
    # and embedded gems must not become translucent just for sharing a hue.
    # Magenta also survives in small shaded gaps where the generated matte
    # never reaches its full background intensity. Include those cores and
    # their blended fringe; ordinary violet material stays below this key.
    core_limit=maximum-(75 if matte=='magenta' else 25)
    fade_end=maximum-(55 if matte=='magenta' else 0)
    core=Image.fromarray(np.where(key>core_limit,255,0).astype('uint8'))
    edge=np.asarray(core.filter(ImageFilter.MaxFilter(9 if matte=='magenta' else 5)))>0
    alpha=np.where(edge,1-np.clip((key-55)/(fade_end-55),0,1),1)
    # Remove the chroma backdrop from partially covered edge pixels as well.
    color=(rgb-(1-alpha[:,:,None])*backdrop)/np.maximum(alpha[:,:,None],.001)
    if matte=='green':
        # These four blue/ivory designs have no green paint. Suppress green
        # spill inside the generated glow, where an edge key alone misses it.
        color[:,:,1]=np.minimum(color[:,:,1],np.maximum(color[:,:,0],color[:,:,2]))
    output=np.dstack((np.clip(color,0,255),np.round(alpha*255))).astype('uint8')
    return Image.fromarray(output), matte.title()+' backdrop keyed and edge color decontaminated; neutral sculpture retained'


def register(source):
    source=source.resize((WIDTH,HEIGHT),Image.Resampling.LANCZOS)
    alpha=np.array(source.getchannel('A'))
    # Ignore isolated antialias pixels while measuring the painted rail body.
    tops=[];bottoms=[]
    for x in list(range(680,840,8))+list(range(1340,1490,8)):
        ys=np.where(alpha[400:700,x]>128)[0]+400
        if len(ys):tops.append(int(ys[0]));bottoms.append(int(ys[-1])+1)
    assert tops and bottoms, 'Missing connecting rail'
    top=int(np.median(tops));bottom=int(np.median(bottoms))
    assert 440<=top<bottom<=710, (top,bottom)
    # A handful of disconnected checker-matte specks must not become the
    # registration landmark and squash the entire painted endcap. The actual
    # composition is empty in this early middle region. Fail rather than erase
    # a substantial ornament if a generation violates that constraint.
    early=alpha[:350,620:1552]
    assert (early>32).sum()<64, 'Substantial art above the shared opening'
    alpha[:350,620:1552]=0
    source.putalpha(Image.fromarray(alpha))
    meaningful=(alpha[:,620:1552]>32).sum(axis=1)
    first=int(np.where(meaningful>4)[0][0])
    assert first>=350, 'Unsafe registration landmark'
    pairs=[(0,8)]
    if 50<first<top-20: pairs.append((first-2,444))
    pairs.extend([(top,530),(bottom,620),(HEIGHT,716)])
    mesh=[]
    for (sy,dy),(ey,fy) in zip(pairs,pairs[1:]):
        mesh.append(((0,dy,WIDTH,fy),(0,sy,0,ey,WIDTH,ey,WIDTH,sy)))
    result=source.transform((WIDTH,HEIGHT),Image.Transform.MESH,mesh,Image.Resampling.BICUBIC)
    a=np.array(result.getchannel('A'));a[a<8]=0
    # The continuous warp positions the whole composition, including endcaps.
    # This only clears resampling fringe in the native button safety region.
    assert (a[:440,620:1552]>32).sum()<50, 'Art violates shared button opening'
    a[:440,620:1552]=0
    a[:4]=0;a[-4:]=0;a[:,:4]=0;a[:,-4:]=0
    result.putalpha(Image.fromarray(a))
    return result, pairs


def main(partial=False):
    for folder in ('sculpted-originals','assets','game'):(ART/folder).mkdir(parents=True,exist_ok=True)
    output=ROOT/'JiberishUI/Media/Hubs';output.mkdir(parents=True,exist_ok=True)
    official={a['id']:a for a in json.loads((ROOT/'artwork/official-crests/sources.json').read_text())}
    entries=json.loads((ROOT/'artwork/portraits/manifest.json').read_text())['assets']
    records={a['id']:a for a in json.loads((ART/'sculpted-generation-results.json').read_text()) if a.get('integrated')}
    remasters={r['id']:r for p in sorted((ART/'style-remaster/records').glob('*.json'))
               for r in [json.loads(p.read_text())]}
    if not partial:assert set(records)=={a['id'] for a in entries}, 'Complete sculpted library required'
    reports=[]
    for entry in entries:
        id=entry['id']
        if id not in records:continue
        restyle=remasters.get(id)
        if restyle:
            original=ROOT/restyle['original']
        else:
            original=ART/'sculpted-originals'/f'{id}.png';retain_source(records[id],original)
        matte=(restyle or records[id]).get('matte')
        raw,method=extract_chroma(Image.open(original),matte) if matte else extract_alpha(Image.open(original))
        # Earlier alpha masks belong to the old painted silhouettes only.
        corrected=raw if restyle else clean(raw,id)
        if corrected is not raw:
            method+='; reviewed enclosed-background alpha mask (artwork/hubs/alpha-cleanup/manifest.json)'
        raw=corrected
        canvas,mapping=register(raw)
        if id=='race_nightelf': canvas=apply_overlay('hub')
        assert canvas.crop((620,0,1552,440)).getchannel('A').getbbox() is None
        png=ART/'assets'/f'{id}.png';canvas.save(png)
        encoded=canvas.resize((1024,512),Image.Resampling.LANCZOS)
        encoded.save(ART/'game'/f'{id}.png')
        tga=output/f'{id}.tga';encoded.save(tga,format='TGA',compression=None)
        assert Image.open(tga).tobytes()==encoded.tobytes()
        reports.append({'id':id,'label':entry['label'],'group':entry['group'],
            'file':str(tga.relative_to(ROOT)),'source':str(png.relative_to(ROOT)),
            'source_sha256':digest(png),'source_size':[WIDTH,HEIGHT],
            'original':str(original.relative_to(ROOT)),'original_sha256':digest(original),
            'size':[1024,512],'sha256':digest(tga),'alphaBounds':list(encoded.getchannel('A').getbbox()),
            'emblem_reference':official.get(id),'emblem_treatment':'one integrated left motif, no repeated crest stamps or badge holder',
            'transform':method+'; continuous vertical registration; all five slices retain full-height alpha',
            'vertical_registration':mapping,'registration':REGISTRATION,
            'clear_points':[[.5,.25],[.4,.5],[.6,.5]],'in_game_qualified':False})
        if restyle:
            reports[-1]['style_remaster']={
                'record':str((ART/'style-remaster/records'/f'{id}.json').relative_to(ROOT)),
                'target':restyle['target'],'target_sha256':digest(ROOT/restyle['target']),
                'style_reference':restyle['style_reference'],
                'style_reference_sha256':digest(ROOT/restyle['style_reference'])}
        if id=='race_nightelf':
            reports[-1]['emblem_correction']='artwork/nightelf-emblem-update/applied.json'
            reports[-1]['transform']+='; localized generated left-emblem inlay on retained registration'
    manifest={'assets':reports,'geometry':'Shared full-height five-piece atlas; 2172 x 724 design; 1024 x 512 texture',
              'credit':'Official emblem references: Blizzard Entertainment. Sculpted compositions: JiberishUI.',
              'complete':len(reports)==42,'in_game_qualified':False}
    (ART/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (ART/'gallery-data.js').write_text('const hubAssets = '+json.dumps(reports)+';\n')
    if not partial:
        lines=['local _, J = ...','-- Data only; all variants use the same five-piece fitting template.','J.HubCatalog = { entries = {} }']
        for entry in reports:
            path='Interface\\AddOns\\JiberishUI\\Media\\Hubs\\'+entry['id']+'.tga'
            lines.append('J.HubCatalog.entries.'+entry['id'].upper()+' = {label='+json.dumps(entry['label'])+',group='+json.dumps(entry['group'].upper())+',texture='+json.dumps(path)+'}')
        (ROOT/'JiberishUI/Themes/Hubs.lua').write_text('\n'.join(lines)+'\n')
        target=ROOT/'docs/phase1-assets.json';data=json.loads(target.read_text())
        replacements={a['file']:a for a in reports}
        data['assets']=[replacements.pop(a['file'],a) for a in data['assets']
                        if not a['file'].endswith('PaladinRet/action-hub.tga')
                        and ('/Hubs/' not in a['file'] or a['file'] in replacements)]
        data['assets'].extend(replacements.values())
        data['official_crest_sources']='artwork/official-crests/sources.json'
        target.write_text(json.dumps(data,indent=2)+'\n')
    print('Prepared',len(reports),'complete sculpted hub atlases with shared seams and clear button regions.')


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--partial',action='store_true')
    main(parser.parse_args().partial)
