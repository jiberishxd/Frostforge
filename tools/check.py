"""Offline Phase 1 source/media/package invariants. No game data is read."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import zipfile
import math

from package import ROOT, CLIENTS, VERSION, active_sources, payload

REQUIRED = {
    "Core/SmallFrames.lua", "Compatibility/SmallFrames.lua", "Themes/CastBorders.lua",
    "Build.lua", "Core/Core.lua", "Core/ThemeManager.lua", "Core/ProfileManager.lua", "Core/Media.lua", "Core/Settings.lua", "Core/Portraits.lua", "Themes/Portraits.lua", "Themes/NPCCities.lua", "Core/Hubs.lua", "Themes/Hubs.lua", "Core/Minimaps.lua", "Themes/Minimaps.lua",
    "Compatibility/Retail.lua", "Compatibility/Forever.lua", "Compatibility/AddOns.lua", "Themes/PortraitMaskFits.lua", "Core/NamedProfiles.lua", "Core/Access.lua", "Core/Setup.lua",
    "Modules/Minimap.lua", "Modules/PlayerFrame.lua", "Modules/TargetFrame.lua", "Modules/FocusFrame.lua", "Modules/ActionHub.lua",
    "Themes/Paladin/Retribution.lua", "Core/UnitSkins.lua", "Themes/UnitSkins.lua", "Core/CastBars.lua", "Core/BlizzardUnits.lua",
}


def source_checks():
    sources = active_sources()
    assert len(sources) == len(set(sources)) and set(sources) == REQUIRED
    actual = {p.relative_to(ROOT / "Frostforge").as_posix() for p in (ROOT / "Frostforge").rglob("*.lua")}
    assert actual == REQUIRED, "Inactive legacy Lua must not remain in the addon folder"
    toc = (ROOT / "Frostforge/Frostforge.toc").read_text()
    assert "## SavedVariables: JiberishUIDB" in toc
    assert "## SavedVariablesPerCharacter: JiberishUICharacterDB" in toc
    assert "## Title: Jiberish's Frostforge" in toc
    assert "## X-Website: https://theigloo.io" in toc
    assert "Media\\Branding\\frostforge-logo.tga" in toc
    assert VERSION in (ROOT / "Frostforge/Core/Core.lua").read_text()
    forbidden = r"\b(loadstring|loadfile|dofile|UnitHealth|UnitPower|SetAttribute|SetParent|SetStatusBarTexture|SetStatusBarColor|SetAtlas|RegisterForClicks|SetBinding)\s*\("
    for name in sources:
        code = (ROOT / "Frostforge" / name).read_text()
        code = re.sub(r"--[^\n]*", "", code)
        # Only the opt-in skin renderer may restore an existing fill atlas.
        rules = forbidden.replace("|SetAtlas", "").replace("|SetStatusBarTexture", "") if name == "Core/UnitSkins.lua" else forbidden
        assert not re.search(rules, code), name
        if name == "Core/Access.lua":
            # A post-hook joins the pooled Game Menu list; no unit-frame hooks.
            assert re.findall(r'\bhooksecurefunc\s*\(\s*([^\n]+)', code) == ['menu,"AddButton",function(frame,label)']
        elif name not in {"Core/UnitSkins.lua", "Core/BlizzardUnits.lua"}:
            assert not re.search(r"\bhooksecurefunc\s*\(", code), name
        assert not re.search(r"\b(PlayerFrame|TargetFrame|FocusFrame|MainActionBar|Minimap|UIParent)\s*[:.]\s*Set\w*\s*\(", code), name
        if name == "Core/CastBars.lua":
            assert not re.search(r"\b(UnitCastingInfo|UnitChannelInfo|UnitEmpoweredChannelInfo|GetValue|GetMinMaxValues|SetValue|SetMinMaxValues|HookScript)\s*\(", code), name
        if name.startswith("Modules/"):
            assert 'CreateFrame("Frame"' in code and ",UIParent)" in code
            assert "EnableMouse(false)" in code and code.count(":CreateTexture(") == 1
        if name.startswith("Themes/"):
            assert not re.search(r"\b(function|CreateFrame|hooksecurefunc|SetScript)\b", code)
            if name.endswith("Retribution.lua"):
                assert code.count('J.ThemeManager:Register("paladin_ret"') == 1
        if name.startswith("Compatibility/"):
            assert "IsUsableFrame(frame)" in code
    core = (ROOT / "Frostforge/Core/Core.lua").read_text()
    assert "pcall(frame.IsForbidden, frame)" in core and "PLAYER_REGEN_ENABLED" in core
    assert "IsProtected()" in core and 'EnableMouse(false)' in core
    assert 'SLASH_JIBERISHFANTASY1 = "/jf"' in core
    print("PASS manifest, five owned modules, data-only artwork registry, and prohibited API checks")


def asset_checks():
    manifest = json.loads((ROOT / "docs/phase1-assets.json").read_text())
    assets = manifest["assets"]
    assert len(assets) == 298
    groups = [{Path(a["file"]).stem for a in assets if "/"+kind+"/" in a["file"]} for kind in ("Portraits", "Hubs", "Minimaps")]
    assert all(len(g) == 42 and g == groups[0] for g in groups), "Artwork catalogs must match"
    assert {Path(a["file"]).stem for a in assets if a.get("kind")=="unit-shell"} == groups[0]
    fits=json.loads((ROOT/'artwork/unit-frames/sculpted/fit-report.json').read_text())
    assert len(fits)==42 and {f['id'] for f in fits}==groups[0]
    for fitted in fits:
        for field,hash_field in (('source','source_sha256'),('file','sha256')):
            assert hashlib.sha256((ROOT/fitted[field]).read_bytes()).hexdigest()==fitted[hash_field]
    for kind in ('health','power'):
        assert {Path(a['file']).stem.rsplit('-',1)[0] for a in assets if a['file'].endswith('-'+kind+'.tga')} == groups[0]
    actual_media = {p.relative_to(ROOT).as_posix() for p in (ROOT/"Frostforge/Media").rglob("*") if p.is_file()}
    expected_media = {a["file"] for a in assets}
    assert actual_media == expected_media, (
        "Addon media must contain only active manifest assets; "
        f"unused={sorted(actual_media - expected_media)}, missing={sorted(expected_media - actual_media)}"
    )
    media = (ROOT / "Frostforge/Core/Media.lua").read_text() + (ROOT / "Frostforge/Themes/Portraits.lua").read_text() + (ROOT / "Frostforge/Themes/Hubs.lua").read_text() + (ROOT / "Frostforge/Themes/Minimaps.lua").read_text()
    media += (ROOT / "Frostforge/Themes/UnitSkins.lua").read_text()
    references = re.findall(r'"Interface\\\\AddOns\\\\Frostforge\\\\([^"]+)"', media)
    expected = {"Frostforge/" + path.replace("\\\\", "/") for path in references}
    assert expected == {a["file"] for a in assets}
    for asset in assets:
        path = ROOT / asset["file"]
        data = path.read_bytes()
        assert hashlib.sha256(data).hexdigest() == asset["sha256"]
        assert hashlib.sha256((ROOT / asset["source"]).read_bytes()).hexdigest() == asset["source_sha256"]
        if asset.get("original"):
            assert hashlib.sha256((ROOT / asset["original"]).read_bytes()).hexdigest() == asset["original_sha256"]
        if asset.get("alpha_processing"):
            processing = json.loads((ROOT / asset["alpha_processing"]).read_text())
            assert processing["output_sha256"] == asset["source_sha256"]
            assert hashlib.sha256((ROOT / processing["source"]).read_bytes()).hexdigest() == processing["source_sha256"]
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
        if asset.get("kind") not in ("statusbar-fill", "settings-background"):
            assert min(pixels[3::4]) == 0, "Surround artwork must have transparency"
        for fx, fy in asset.get("clear_points", []):
            x, y = int(fx*w), int(fy*h)
            if not descriptor & 32:
                y = h - 1 - y
            assert pixels[(y*w+x)*4+3] == 0, "Functional opening must remain transparent"
        if "/CastBars/" in asset["file"]:
            assert asset['kind']=='cast-border' and [w,h]==[512,128]
            assert bounds[0]>=4 and bounds[1]>=4 and bounds[2]<=508 and bounds[3]<=124
            for y in range(48,80):
                row=y if descriptor & 32 else h-1-y
                assert all(pixels[(row*w+x)*4+3]==0 for x in range(48,464))
            for ref in asset['references']:
                assert hashlib.sha256((ROOT/ref['file']).read_bytes()).hexdigest()==ref['sha256']
        if "/UnitFrames/" in asset["file"]:
            assert asset["kind"] in ("unit-shell", "statusbar-fill")
            assert [w,h] == ([512,256] if asset["kind"] == "unit-shell" else [256,32])
            for ref in asset["references"]:
                assert hashlib.sha256((ROOT/ref["file"]).read_bytes()).hexdigest()==ref["sha256"]
            if asset["kind"]=="unit-shell":
                assert bounds[0]>=4 and bounds[1]>=4 and bounds[2]<=508 and bounds[3]<=252
                report=next(f for f in fits if f['id']==path.stem)
                registration=report['measured']['registration']
                assert report['fit_version']==3 and asset['registration']==registration
                assert registration['canvas']==[512,256] and registration['margin']==4
                health,power=registration['health'],registration['power']
                assert registration['divider']==power[1]-health[3]>0
                for region in ('health','power'):
                    x1,y1,x2,y2=registration[region]
                    # Test the bar interiors, allowing the original bevels and
                    # ornaments at their edges instead of cutting them away.
                    for fraction in (.25,.75):
                        x,y=round(x1+(x2-x1)*fraction),round((y1+y2)/2)
                        row=y if descriptor & 32 else h-1-y
                        assert pixels[(row*w+x)*4+3]==0, (asset['file'],region)

            else:
                # The sampled fill band is opaque; native masks own clipping.
                for y in range(h):
                    row=y if descriptor & 32 else h-1-y
                    assert all(pixels[(row*w+x)*4+3]==255 for x in range(w))
        if "/Portraits/" in asset["file"]:
            assert [w,h] == [512,256]
            assert asset['fit_version']==5 and asset['registration_box']==[8,8,214,244]
            assert asset['portrait_center']==[154,148] and asset['portrait_radius']==60 and asset['round_portrait_radius']==58
            assert bounds[0]>=8 and bounds[1]>=8 and bounds[2]<=470 and bounds[3]<=244
            assert any(y>=190 for x,y in visible), 'Natural side flare must not be chopped off'
            if asset.get('official_crest') or asset.get('emblem_reference'):
                crest=asset.get('official_crest') or asset['emblem_reference'];assert hashlib.sha256((ROOT/crest['file']).read_bytes()).hexdigest()==crest['sha256']
            for y in range(h):
                for x in range(w):
                    # Separate Player and round Target/Focus atlas halves, with
                    # the bar corridor clear in both before runtime mirroring.
                    local_x=x%256
                    radius=60 if x<256 else 58
                    clear = ((local_x-154)**2+(y-148)**2 <= radius**2 or
                             (x<256 and 154 <= local_x <= 214 and 148 <= y <= 208) or
                             local_x >= 214)
                    row = y if descriptor & 32 else h-1-y
                    if clear:
                        assert pixels[(row*w+x)*4+3] == 0, asset["file"]
            # A painted lower wrap must hug the native edge, rather than only
            # passing the empty-center test while floating below it.
            for start,radius in ((0,60),(256,58)):
                for degrees in (90,100,110):
                    angle=math.radians(degrees)
                    hits=[]
                    for distance in range(radius+1,100):
                        x=start+round(154+math.cos(angle)*distance)
                        y=round(148+math.sin(angle)*distance)
                        if y>=h:continue
                        row=y if descriptor & 32 else h-1-y
                        if pixels[(row*w+x)*4+3]>96:hits.append(distance-radius)
                    if hits:
                        assert min(hits)<=4, (asset['file'],start,degrees,'Lower wrap floats away',min(hits))
        if "/Minimaps/" in asset["file"]:
            assert [w,h] == [512,512]
            assert asset['registration'] == {'canvas':[512,512],'center':[256,256],'radius':149,'margin':8}
            assert bounds[0]>=8 and bounds[1]>=8 and bounds[2]<=504 and bounds[3]<=504
            for y in range(h):
                row=y if descriptor & 32 else h-1-y
                for x in range(w):
                    if (x-256)**2+(y-256)**2<=149**2:
                        assert pixels[(row*w+x)*4+3]==0, asset['file']
            for ref in asset['references']:
                assert hashlib.sha256((ROOT/ref['file']).read_bytes()).hexdigest()==ref['sha256']
        if "/Hubs/" in asset["file"]:
            assert [w,h]==[1024,512]
            assert asset['registration']=={'canvas':[2172,724],'seams':[620,980,1210,1552],
                                            'rail_band':[530,620],'clear_region':[620,0,1552,440]}
            # Stay inside UV margins to account for resampling at the seams.
            for y in range(2,int(h*435/724)):
                for x in range(int(w*625/2172),int(w*1547/2172)):
                    row=y if descriptor & 32 else h-1-y
                    assert pixels[(row*w+x)*4+3]==0, 'Hub art covers reserved button region'
            if asset.get('official_crest') or asset.get('emblem_reference'):
                crest=asset.get('official_crest') or asset['emblem_reference'];assert hashlib.sha256((ROOT/crest['file']).read_bytes()).hexdigest()==crest['sha256']
    print("PASS 42 portrait openings, 42 shared hub atlases, 42 circular minimaps, 298 RGBA assets (including the official transparent logo and stone interface, 42 complete cast borders, 42 sculpted shells and 84 painted fills) and provenance hashes")


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
            assert {name.split("/")[0] for name in archive.namelist()} == {"Frostforge"}, "Wrong install folder"
            assert "Frostforge/Frostforge.toc" in archive.namelist(), "Manifest must match the install folder"
            assert report["addon_folder"] == "Frostforge"
            assert len(archive.namelist()) == len(set(archive.namelist())) == report["files"]
            assert set(archive.namelist()) == set(expected)
            for name, content in expected.items():
                assert archive.read(name) == content, name
            # Check paths against actual ZIP members, independently of payload's
            # rewrite. Artwork can otherwise pass source checks but fail in game.
            for name in archive.namelist():
                if not name.endswith((".lua", ".toc")):
                    continue
                code = archive.read(name).decode().replace("\\\\", "/").replace("\\", "/")
                for asset in re.findall(r'Interface/AddOns/([^"\s]+)', code):
                    assert asset.startswith("Frostforge/") and asset in archive.namelist(), (name, asset)
        assert len([p for p in expected if p.endswith(".tga")]) == 298
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
