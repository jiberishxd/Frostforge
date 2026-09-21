"""Offline Phase 1 source/media/package invariants. No game data is read."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import zipfile

from package import ROOT, CLIENTS, VERSION, active_sources, payload

REQUIRED = {
    "Build.lua", "Core/Core.lua", "Core/ThemeManager.lua", "Core/ProfileManager.lua", "Core/Media.lua",
    "Compatibility/Retail.lua", "Compatibility/Forever.lua",
    "Modules/Minimap.lua", "Modules/PlayerFrame.lua", "Modules/TargetFrame.lua", "Modules/ActionHub.lua",
    "Themes/Paladin/Retribution.lua",
}


def source_checks():
    sources = active_sources()
    assert len(sources) == len(set(sources)) and set(sources) == REQUIRED
    actual = {p.relative_to(ROOT / "JiberishUI").as_posix() for p in (ROOT / "JiberishUI").rglob("*.lua")}
    assert actual == REQUIRED, "Inactive legacy Lua must not remain in the addon folder"
    toc = (ROOT / "JiberishUI/JiberishUI.toc").read_text()
    assert "## SavedVariables: JiberishUIDB" in toc
    assert VERSION in (ROOT / "JiberishUI/Core/Core.lua").read_text()
    forbidden = r"\b(loadstring|loadfile|dofile|UnitHealth|UnitPower|UnitClass|SetAttribute|SetParent|SetStatusBarTexture|SetStatusBarColor|SetAtlas|RegisterForClicks|SetBinding)\s*\("
    for name in sources:
        code = (ROOT / "JiberishUI" / name).read_text()
        code = re.sub(r"--[^\n]*", "", code)
        assert not re.search(forbidden, code), name
        assert not re.search(r"\b(PlayerFrame|TargetFrame|MainActionBar|Minimap|UIParent)\s*[:.]\s*Set\w*\s*\(", code), name
        if name.startswith("Modules/"):
            assert 'CreateFrame("Frame"' in code and ",UIParent)" in code
            assert "EnableMouse(false)" in code and code.count(":CreateTexture(") == 2
        if name.startswith("Themes/"):
            assert not re.search(r"\b(function|CreateFrame|hooksecurefunc|SetScript)\b", code)
            assert code.count('J.ThemeManager:Register("paladin_ret"') == 1
        if name.startswith("Compatibility/"):
            assert "IsUsableFrame(frame)" in code
    core = (ROOT / "JiberishUI/Core/Core.lua").read_text()
    assert "pcall(frame.IsForbidden, frame)" in core and "PLAYER_REGEN_ENABLED" in core
    assert "IsProtected()" in core and 'EnableMouse(false)' in core
    assert 'SLASH_JIBERISHFANTASY1 = "/jf"' in core
    print("PASS Phase 1 manifest, four owned modules, one data-only theme, and prohibited API checks")


def asset_checks():
    manifest = json.loads((ROOT / "docs/phase1-assets.json").read_text())
    assets = manifest["assets"]
    assert len(assets) == 3
    media = (ROOT / "JiberishUI/Core/Media.lua").read_text()
    references = re.findall(r'"Interface\\\\AddOns\\\\JiberishUI\\\\([^"]+)"', media)
    expected = {"JiberishUI/" + path.replace("\\\\", "/") for path in references}
    assert expected == {a["file"] for a in assets}
    for asset in assets:
        path = ROOT / asset["file"]
        data = path.read_bytes()
        assert hashlib.sha256(data).hexdigest() == asset["sha256"]
        assert hashlib.sha256((ROOT / asset["source"]).read_bytes()).hexdigest() == asset["source_sha256"]
        _, palette, kind, _, _, _, _, _, w, h, bits, descriptor = struct.unpack("<BBBHHBHHHHBB", data[:18])
        assert palette == 0 and kind == 2 and bits == 32 and descriptor & 15 == 8
        assert [w, h] == asset["size"]
        assert all(n > 0 and n & (n-1) == 0 for n in (w, h))
        offset = 18 + data[0]
        pixels = data[offset:offset+w*h*4]
        assert len(pixels) == w*h*4
        visible = []
        for i in range(w*h):
            if pixels[i*4+3]:
                x, y = i % w, i // w
                if not descriptor & 32:
                    y = h - 1 - y
                visible.append((x, y))
        assert visible
        bounds = [min(x for x,y in visible), min(y for x,y in visible),
                  max(x for x,y in visible)+1, max(y for x,y in visible)+1]
        assert bounds == asset["alphaBounds"]
        assert min(pixels[3::4]) == 0, "Artwork must have transparency"
    print("PASS three packaged RGBA assets: source/file hashes, dimensions, alpha bounds, media references")


def reference_checks():
    refs = json.loads((ROOT / "docs/phase1-sources.json").read_text())
    for client, (_, _, revision) in CLIENTS.items():
        entry = refs[client.lower()]
        assert entry["revision"] == revision and len(entry["files"]) == 4
        for name, metadata in entry["files"].items():
            assert revision in metadata["url"] and metadata["url"].endswith(name)
            cached = ROOT / ".reference" / client.lower() / name
            if "Minimap" in name:
                cached = ROOT / ".tools" / f"phase1-{client.lower()}-minimap.xml"
            if cached.exists():
                assert hashlib.sha256(cached.read_bytes()).hexdigest() == metadata["sha256"]
    print("PASS separate client metadata and pinned native-root references")


def archive_checks(directory):
    reports = json.loads((directory / "packages.json").read_text())
    assert len(reports) == 2
    for report in reports:
        path = directory / report["file"]
        assert report["version"] == VERSION and not report["in_game_validated"]
        assert hashlib.sha256(path.read_bytes()).hexdigest() == report["sha256"]
        expected = payload(report["client"])
        with zipfile.ZipFile(path) as archive:
            assert len(archive.namelist()) == len(set(archive.namelist())) == report["files"]
            assert set(archive.namelist()) == set(expected)
            for name, content in expected.items():
                assert archive.read(name) == content, name
        assert len([p for p in expected if p.endswith(".tga")]) == 3
    print("PASS both exact client archives; no legacy code/themes or unrelated textures packaged")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--packages", action="store_true")
    parser.add_argument("--dist", type=Path, default=ROOT / "dist")
    args = parser.parse_args()
    source_checks()
    asset_checks()
    reference_checks()
    if args.packages:
        archive_checks(args.dist)
