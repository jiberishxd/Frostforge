"""Package only the active manifest and its qualified media references."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CLIENTS = {
    "Retail": (120100, "12.1.0.69875", "78282522143e25c3540583734fd192c3d69be910"),
    "Forever": (16001, "1.60.1.69913", "70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e"),
}
TOC = ROOT / "JiberishUI/JiberishUI.toc"
VERSION = re.search(r"^## Version: (.+)$", TOC.read_text(), re.M).group(1)
DOCS = ("README.md", "docs/ARCHITECTURE.md", "docs/ARTWORK.md", "docs/COMPATIBILITY.md",
        "docs/PERSISTENCE.md", "docs/VALIDATION.md", "docs/TEST-RESULTS.md",
        "docs/phase1-assets.json", "docs/phase1-sources.json", "docs/ARTWORK-CREDITS.md", "docs/ARTWORK-SOURCES.json")


def active_sources():
    return [line.strip().replace("\\", "/") for line in TOC.read_text().splitlines()
            if line.strip().endswith(".lua")]


def payload(client):
    interface, baseline, revision = CLIENTS[client]
    files = {"JiberishUI/JiberishUI.toc": TOC.read_bytes().replace(b"120100, 16001", str(interface).encode())}
    for name in active_sources():
        files["JiberishUI/" + name] = (ROOT / "JiberishUI" / name).read_bytes()
    files["JiberishUI/Build.lua"] = (
        "local _,J=...\nJ.Build={flavor='%s',interface=%d,baseline='%s',revision='%s'}\n"
        % (client.lower(), interface, baseline, revision)).encode()
    for asset in json.loads((ROOT / "docs/phase1-assets.json").read_text())["assets"]:
        files[asset["file"]] = (ROOT / asset["file"]).read_bytes()
    for name in DOCS:
        files["JiberishUI/" + name] = (ROOT / name).read_bytes()
    return files


def package(destination):
    destination.mkdir(parents=True, exist_ok=True)
    reports = []
    for client, (interface, baseline, revision) in CLIENTS.items():
        files = payload(client)
        path = destination / f"JiberishUI-{client}-{VERSION}.zip"
        with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for name, content in sorted(files.items()):
                entry = zipfile.ZipInfo(name, date_time=(2026, 9, 21, 0, 0, 0))
                entry.compress_type = zipfile.ZIP_DEFLATED
                entry.external_attr = 0o644 << 16
                archive.writestr(entry, content)
        reports.append({"client": client, "interface": interface, "baseline": baseline,
                        "source_revision": revision, "version": VERSION, "file": path.name,
                        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                        "files": len(files), "themes": ["paladin_ret"],
                        "modules": ["minimap", "playerFrame", "targetFrame", "focusFrame", "actionHub"],
                        "in_game_validated": False})
    (destination / "packages.json").write_text(json.dumps(reports, indent=2) + "\n")
    print(json.dumps(reports, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=ROOT / "dist")
    package(parser.parse_args().output)
