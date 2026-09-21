"""Offline source, artwork, load-order, and optional release archive checks (stdlib only)."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import zipfile
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]

def check_assets():
    manifest=json.loads((ROOT/'docs/assets.json').read_text())
    catalog=json.loads((ROOT/'docs/skin-catalog.json').read_text())
    materials={s['material'] for s in catalog['skins']}
    generated={s['material'] for s in catalog['skins']}-{'human','orc','nightelf','undead'}
    assert len(manifest['sources'])==12+len(generated)
    actual={p.relative_to(ROOT).as_posix() for p in (ROOT/'JiberishUI/Media').rglob('*.tga')}
    expected={a['file'] for a in manifest['assets']}
    assert actual==expected and len(actual)==len(materials)*14+2
    for material in materials:
        required={'tl','tr','bl','br','top','bottom','left','right','portrait','ornament','button-normal','button-pushed','button-highlight','button-checked'}
        assert {Path(p).stem for p in actual if Path(p).parent.name==material}==required,material
    for source in manifest['sources']:
        if source['path'].startswith('artwork/'):
            assert hashlib.sha256((ROOT/source['path']).read_bytes()).hexdigest()==source['sha256'],source['path']
    for asset in manifest['assets']:
        path=ROOT/asset['file'];data=path.read_bytes()
        assert path.name==path.name.lower()
        assert hashlib.sha256(data).hexdigest()==asset['sha256'], path
        _,palette,image_type,_,_,_,_,_,w,h,bpp,descriptor=struct.unpack('<BBBHHBHHHHBB',data[:18])
        assert palette==0 and image_type==2 and bpp==32 and descriptor&15==8, path
        assert [w,h]==asset['size'] and all(n>0 and n&(n-1)==0 for n in (w,h)),path
        offset=18+data[0];pixels=data[offset:offset+w*h*4];assert len(pixels)==w*h*4
        visible=[]
        for i in range(w*h):
            if pixels[i*4+3]:
                x=i%w;y=i//w
                if not descriptor&32:y=h-1-y
                visible.append((x,y))
        assert visible,path
        bounds=[min(x for x,y in visible),min(y for x,y in visible),max(x for x,y in visible)+1,max(y for x,y in visible)+1]
        assert bounds==asset['alphaBounds'],path
        if path.name=='outside-rect.tga':
            for y in range(8):
                for x in range(8):
                    assert pixels[(y*8+x)*4+3]==(0 if 2<=x<6 and 2<=y<6 else 255)
        if path.parent.name in generated and path.stem in {'top','bottom','left','right'}:
            def pixel(x,y):return pixels[(y*w+x)*4:(y*w+x+1)*4]
            if path.stem in {'top','bottom'}:assert all(pixel(0,y)==pixel(w-1,y) for y in range(h)),path
            else:assert all(pixel(x,0)==pixel(x,h-1) for x in range(w)),path
    print(f'PASS {len(actual)} RGBA TGA assets: hashes, alpha, dimensions, families, and repeat seams')

def check_catalog():
    from skin_catalog import SKINS
    data=json.loads((ROOT/'docs/skin-catalog.json').read_text())
    assert data['skins']==SKINS
    assert len(SKINS)==52 and len({s['id'] for s in SKINS})==52
    assert {s['identity'] for s in SKINS if s['category']=='class'}=={'WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','DEATHKNIGHT','SHAMAN','MAGE','MONK','DRUID','DEMONHUNTER','WARLOCK','EVOKER'}
    assert {s['identity'] for s in SKINS if s['category']=='race'}=={'Human','Orc','Night Elf','Undead','Dwarf','Gnome','Draenei','Worgen','Pandaren','Dracthyr','Tauren','Troll','Blood Elf','Goblin','Void Elf','Lightforged Draenei','Dark Iron Dwarf','Kul Tiran','Mechagnome','Earthen','Haranir','Nightborne','Highmountain Tauren',"Mag'har Orc",'Zandalari Troll','Vulpera'}
    assert {s['identity'] for s in SKINS if s['category']=='faction'}=={'Alliance','Horde'}
    print('PASS 52 catalog entries: 13 classes, 26 race identities, factions, standard finishes')

def check_sources():
    toc=(ROOT/'JiberishUI/JiberishUI.toc').read_text()
    entries=[line.strip().replace('\\','/') for line in toc.splitlines() if line.strip().endswith('.lua')]
    assert len(entries)==len(set(entries))
    assert {p.relative_to(ROOT/'JiberishUI').as_posix() for p in (ROOT/'JiberishUI').rglob('*.lua')}==set(entries)
    assert '## SavedVariables: JiberishUIDB' in toc
    for path in entries:
        text=(ROOT/'JiberishUI'/path).read_text()
        assert not re.search(r'\b(loadstring|loadfile|dofile|UnitHealth|UnitPower|UnitHealthMax|UnitPowerMax)\s*\(',text),path
        assert not re.search(r':(SetAttribute|SetParent|RegisterForClicks|SetFrameLevel|SetFrameStrata)\s*\(',text) or path=='Core/Settings.lua',path
    traces=json.loads((ROOT/'docs/source-load-order.json').read_text())
    for flavor,trace in traces.items():
        assert re.fullmatch('[0-9a-f]{40}',trace['revision'])
        for name,manifest in trace['manifests'].items():
            assert manifest['expandedLoadOrder']
            for path in manifest['expandedLoadOrder']: assert path in trace['files'],path
        for path,metadata in trace['files'].items():
            cached=ROOT/'.reference'/flavor/path
            if cached.exists(): assert hashlib.sha256(cached.read_bytes()).hexdigest()==metadata['sha256'],cached
        order=trace['manifests']['Blizzard_UnitFrame']['expandedLoadOrder']
        if flavor=='forever':
            for name in ('PlayerFrame','TargetFrame'):
                assert order.index(f'Blizzard_UnitFrame/Mainline/{name}.lua')<order.index(f'Blizzard_UnitFrame/Camelot/{name}.lua')
        else: assert not any('/Camelot/' in p for p in order)
    print('PASS addon manifest, API boundaries, pinned traces, and Camelot override order')

def check_paths():
    paths={
        'Blizzard_UnitFrame/Mainline/PlayerFrame.xml': ['PlayerFrameContainer.PlayerPortrait','PlayerFrameContainer.FrameTexture','PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar','PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBarMask','PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.ManaBarMask'],
        'Blizzard_UnitFrame/Mainline/TargetFrame.xml': ['TargetFrameContainer.Portrait','TargetFrameContainer.FrameTexture','TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar','TargetFrameContent.TargetFrameContentMain.ManaBar.ManaBarMask','HealthBar.HealthBarMask','ManaBar.ManaBarMask'],
        'Blizzard_UnitFrame/Mainline/PartyFrameTemplates.xml': ['HealthBarContainer.HealthBar','HealthBarContainer.HealthBarMask','ManaBar.ManaBarMask','Portrait','PetFrame'],
    }
    for flavor in ('retail','forever'):
        for path,required in paths.items():
            file=ROOT/'.reference'/flavor/path
            if not file.exists(): continue
            found=set()
            def visit(element,prefix):
                key=element.get('parentKey');prefix=prefix+[key] if key else prefix
                if key:found.add('.'.join(prefix))
                for child in element:visit(child,prefix)
            visit(ET.parse(file).getroot(),[])
            for key in required: assert key in found,(flavor,path,key)
    print('PASS adapter XML paths against available cached client sources')

def check_packages():
    report=json.loads((ROOT/'dist/packages.json').read_text())
    for item in report:
        path=ROOT/'dist'/item['file'];assert hashlib.sha256(path.read_bytes()).hexdigest()==item['sha256']
        with zipfile.ZipFile(path) as archive:
            names=archive.namelist();assert all(n.startswith('JiberishUI/') for n in names)
            assert len(names)==len(set(names))==item['files']
            assert not any('.reference/' in n or '.tools/' in n for n in names)
            assert f'## Interface: {item["interface"]}\n' in archive.read('JiberishUI/JiberishUI.toc').decode()
            assert f"flavor='{item['client'].lower()}'" in archive.read('JiberishUI/Build.lua').decode()
            assets=json.loads(archive.read('JiberishUI/docs/assets.json'))
            assert len([n for n in names if n.endswith('.tga')])==len(assets['assets'])
            assert len(json.loads(archive.read('JiberishUI/docs/skin-catalog.json'))['skins'])==52
            for name in names:
                local=ROOT/name
                if name.endswith('.tga') or (name.endswith('.lua') and not name.endswith('/Build.lua')):
                    assert archive.read(name)==local.read_bytes(),name
    print('PASS Retail/Forever archive roots, interface metadata, source/assets, and hashes')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--packages',action='store_true');args=parser.parse_args()
    check_assets();check_catalog();check_sources();check_paths()
    if args.packages:check_packages()
