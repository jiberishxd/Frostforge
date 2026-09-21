"""Build reproducible, separate client archives. Does not install into a game client."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CLIENTS = {
    'Retail': (120100, '12.1.0.69875', '78282522143e25c3540583734fd192c3d69be910'),
    'Forever': (16001, '1.60.1.69913', '70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e'),
}
VERSION = '0.1.0-alpha.7'

def package(destination):
    destination.mkdir(parents=True, exist_ok=True)
    reports = []
    for client, (interface, baseline, revision) in CLIENTS.items():
        path = destination / f'JiberishUI-{client}-{VERSION}.zip'
        files = {}
        for source in sorted((ROOT / 'JiberishUI').rglob('*')):
            if not source.is_file() or source.name.startswith('.'): continue
            name = source.relative_to(ROOT).as_posix()
            content = source.read_bytes()
            if source.name == 'JiberishUI.toc':
                content = content.decode().replace('120100, 16001', str(interface)).encode()
            if source.name == 'Build.lua':
                content = ("local _,J=...\nJ.Build={flavor='%s',interface=%d,baseline='%s',revision='%s'}\n" % (client.lower(), interface, baseline, revision)).encode()
            files[name] = content
        for name in ('README.md', 'docs/ARTWORK.md', 'docs/ARCHITECTURE.md', 'docs/COMPATIBILITY.md', 'docs/PERSISTENCE.md', 'docs/FANTASY.md', 'docs/integration-sources.json', 'docs/VALIDATION.md', 'docs/TEST-RESULTS.md', 'docs/assets.json', 'docs/source-load-order.json', 'docs/skin-catalog.json', 'docs/SKIN-LIBRARY.md'):
            files['JiberishUI/' + name] = (ROOT / name).read_bytes()
        with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for name, content in sorted(files.items()):
                entry = zipfile.ZipInfo(name, date_time=(2026, 9, 20, 0, 0, 0))
                entry.compress_type = zipfile.ZIP_DEFLATED; entry.external_attr = 0o644 << 16
                archive.writestr(entry, content)
        reports.append({'client': client, 'interface': interface, 'baseline': baseline, 'source_revision': revision,
                        'file': path.name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                        'files': len(files), 'in_game_validated': False})
    (destination / 'packages.json').write_text(json.dumps(reports, indent=2) + '\n')
    print(json.dumps(reports, indent=2))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('--output', type=Path, default=ROOT/'dist')
    package(parser.parse_args().output)
