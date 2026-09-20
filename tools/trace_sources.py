"""Pin and trace relevant Blizzard addon manifests, including nested XML scripts/includes.
Network is used only to fetch the exact two audited commits. Dependencies are recorded,
not force-loaded; these traces describe the five frame-owning addons, not the whole UI.
"""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path, PurePosixPath
import hashlib
import json
import posixpath
import re
import subprocess
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
REFS={'retail':'78282522143e25c3540583734fd192c3d69be910','forever':'70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e'}
ADDONS=['Blizzard_UnitFrame','Blizzard_ActionBar','Blizzard_CompactRaidFrames','Blizzard_OverrideActionBar','Blizzard_ZoneAbility']

def trace(flavor,revision):
    cache=ROOT/'.reference'/flavor
    def fetch(path):
        output=cache/path
        if not output.exists():
            output.parent.mkdir(parents=True,exist_ok=True)
            subprocess.run(['curl','--retry','2','--fail','--silent','--show-error','-L',f'https://raw.githubusercontent.com/Gethe/wow-ui-source/{revision}/Interface/AddOns/{path}','-o',str(output)],check=True)
        return output.read_text(encoding='utf-8-sig')
    family='Mainline'; game='Camelot' if flavor=='forever' else 'Mainline'
    active={'mainline',game.lower()}
    def allowed(line):
        for rule,names in re.findall(r'\[(AllowLoadGameType|ExcludeLoadGameType) ([^]]+)\]',line):
            matches=bool(active & {n.strip().lower() for n in names.split(',')})
            if (rule=='AllowLoadGameType' and not matches) or (rule=='ExcludeLoadGameType' and matches): return False
        return True
    def path_for(base,name):
        name=name.replace('[Family]',family).replace('[Game]',game).replace('\\','/')
        return posixpath.normpath(str(PurePosixPath(base).parent/name))
    manifests={}; pending=[]; sources={}; links={}
    for addon in ADDONS:
        suffix='_Mainline' if flavor=='retail' and addon in ('Blizzard_UnitFrame','Blizzard_ActionBar','Blizzard_ZoneAbility') else ''
        path=f'{addon}/{addon}{suffix}.toc';text=fetch(path); sources[path]=text
        files=[];dependencies=[];excluded=[]
        for line in text.splitlines():
            line=line.strip()
            if not line: continue
            if not allowed(line): excluded.append(line);continue
            if line.startswith('##'):
                if re.match(r'## (Dep|Dependencies|RequiredDeps|OptionalDeps):',line): dependencies.append(line)
                continue
            if line.startswith('#'): continue
            token=re.split(r'\s+\[',line)[0].strip()
            entry=path_for(path,token);files.append(entry);pending.append(entry)
        manifests[addon]={'manifest':path,'dependencies':dependencies,'orderedFiles':files,'excluded':excluded}
    with ThreadPoolExecutor(max_workers=12) as pool:
        while pending:
            batch=list(dict.fromkeys(p for p in pending if p not in sources));pending=[]
            for path,text in zip(batch,pool.map(fetch,batch)):
                sources[path]=text;children=[]
                if path.endswith('.xml'):
                    for elem in ET.fromstring(text).iter():
                        if elem.tag.rsplit('}',1)[-1] in ('Include','Script') and elem.get('file'):
                            child=path_for(path,elem.get('file'));children.append(child);pending.append(child)
                links[path]=children
    def flatten(path,stack=()):
        if path in stack: raise ValueError('XML include cycle')
        result=[path]
        for child in links.get(path,[]): result.extend(flatten(child,stack+(path,)))
        return result
    for manifest in manifests.values(): manifest['expandedLoadOrder']=[p for path in manifest['orderedFiles'] for p in flatten(path)]
    return {'revision':revision,'family':family,'game':game,'scope':ADDONS,'manifests':manifests,
            'files':{p:{'sha256':hashlib.sha256((cache/p).read_bytes()).hexdigest(),'includes':links.get(p,[])} for p in sorted(sources)}}

if __name__=='__main__':
    result={flavor:trace(flavor,revision) for flavor,revision in REFS.items()}
    (ROOT/'docs/source-load-order.json').write_text(json.dumps(result,indent=2)+'\n')
    for flavor,data in result.items(): print(flavor,len(data['files']),'pinned source files traced')
