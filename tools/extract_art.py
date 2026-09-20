"""Extract only selected classic WC3 artwork into .reference/wc3 (read-only source)."""
from pathlib import Path
import argparse, subprocess
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('storage', help='Warcraft III installation directory')
args=parser.parse_args()
out=root/'.reference/wc3'; out.mkdir(parents=True,exist_ok=True)
for race in ['human','orc','nightelf','undead']:
    for kind,source in [
        ('border',f'ui\\widgets\\escmenu\\{race}\\{race}-options-menu-border.dds'),
        ('ornament',f'ui\\console\\{race}\\{race}uitile-timeindicatorframe.dds'),
        ('console',f'ui\\console\\{race}\\{race}uitile01.dds')]:
        subprocess.run([str(root/'.tools/casc_extract'),args.storage,'war3.w3mod:'+source,str(out/f'{race}-{kind}.dds')],check=True)
