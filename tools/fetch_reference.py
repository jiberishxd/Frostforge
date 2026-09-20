"""Cache the version-pinned Blizzard source files used by adapters."""
from pathlib import Path
import argparse, subprocess
ROOT=Path(__file__).resolve().parents[1]
REFS={'retail':'78282522143e25c3540583734fd192c3d69be910','forever':'70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e'}
parser=argparse.ArgumentParser(); parser.add_argument('flavor',choices=REFS); parser.add_argument('paths',nargs='+'); args=parser.parse_args()
for path in args.paths:
    out=ROOT/'.reference'/args.flavor/path; out.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run(['curl','-L','--fail','--silent','--show-error',f'https://raw.githubusercontent.com/Gethe/wow-ui-source/{REFS[args.flavor]}/Interface/AddOns/{path}','-o',str(out)],check=True)
