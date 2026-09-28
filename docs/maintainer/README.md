# Maintainer documentation

Frostforge is a Lua addon with retained artwork sources and offline previews. The game installs only the packaged `Frostforge` directory. The repository itself also includes editing references, tooling and tests.

Player instructions live in [Getting started](../GETTING-STARTED.md) and [Compatibility](../ADDON-COMPATIBILITY.md). The installable addon is entirely inside `Frostforge/`.

| Reference | Purpose |
| --- | --- |
| [Architecture](ARCHITECTURE.md) | Frame ownership, providers and combat behavior |
| [Validation](VALIDATION.md) | Manual client/provider checks |
| [Test results](TEST-RESULTS.md) | Versioned offline results and remaining live checks |
| [Performance](PERFORMANCE.md) | Measurements, methodology and raw samples |
| [Artwork source history](ARTWORK.md) | Generation, source attribution and fitting history |
| [Release preparation](RELEASE.md) | Player packages and listing copy |

`artwork/` retains editable originals, prompts, previews, historical references and regression fixtures. `docs/*sources.json` and `docs/phase1-assets.json` record provenance and the active media inventory. Keep those with the source repository; they are not runtime dependencies or player downloads. Superseded border-library/fantasy guides and their five obsolete generators were removed; their history remains in Git. Active media builders and all art assets are retained.

## Build installable ZIPs

Requires Python 3. From the repository root, run:

```sh
python3 tools/package.py
```

This writes `Jiberishs-Frostforge-Retail-<version>.zip` and `Jiberishs-Frostforge-Forever-<version>.zip` into `dist/`. Use the archive matching your client; each contains a single top-level `Frostforge` folder and a matching `Frostforge.toc`. Each ZIP contains the 30 active Lua files, one TOC, all 298 runtime textures, and only two documents: `README.md` and `CREDITS.md`. No development guides, benchmarks, source manifests or documentation screenshots are copied into the package. Keep the complete folder together.

The repository source and packaged addon both use `Frostforge/Frostforge.toc`. GitHub's **Code → Download ZIP** therefore contains `Frostforge-main/Frostforge`; copy only that inner addon folder into `Interface/AddOns/`. The source manifest supports both clients, while packaging selects a single client and replaces `Build.lua` with its pinned build metadata. No runtime path rewriting is needed. Saved-variable names and compatibility aliases remain unchanged. Validation checks source-folder naming, unchanged packaged Lua, every installed media path and startup under the `Frostforge` addon name with supplied saved tables.

## Local checks

```sh
lua5.1 tests/run.lua
python3 -m unittest discover -s tests -p 'test_packaging.py'
python3 tools/check.py
python3 tools/package.py
python3 tools/check.py --packages
```

Install Lua 5.1 and Python 3 to run these checks; a local Lua 5.1 executable can be used instead of `lua5.1`. The same checks run on pull requests.

The repository includes the final textures and all artwork inputs. To rebuild media without a generation-service cache or network access, install the pinned image-processing dependencies and run:

```sh
python3 -m pip install -r tools/requirements-artwork.txt
python3 tools/build_portraits.py
python3 tools/apply_nightelf_emblem.py
python3 tools/build_hubs.py
python3 tools/build_minimaps.py
python3 tools/extract_paladin_crest.py
python3 tools/apply_druid_antlers.py
python3 tools/fit_unit_shells.py
python3 tools/build_unit_frame_art.py
python3 tools/fit_cast_borders.py
python3 tools/build_branding.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/render_portrait_review.py
lua5.1 tools/export_fit_preview.lua
lua5.1 tools/export_cast_preview.lua
lua5.1 tools/export_settings_preview.lua
python3 tools/check.py
```

Documentation compositions can be refreshed with `python3 tools/render_readme_media.py --hub-review`. This also renders every hub over solid teal for transparency review. Hub cleanup uses retained, hashed masks; it never repaints the source or changes its registration. See [hub transparency](ARTWORK.md#hub-transparency-cleanup).

Serve the repository with `python3 -m http.server 8757 --bind 127.0.0.1`, then open `/artwork/portraits/` `/artwork/hubs/` `/artwork/minimaps/` `/artwork/unit-frames/`, `/artwork/cast-bars/` or `/artwork/settings/` on that server. The source PNGs, generation briefs and revision history are retained for editing; only active runtime files, the install readme and credits enter the game packages. Downloaded website HTML is a local cache and is not committed. Source references and Blizzard credits are in [artwork credits](../../Frostforge/CREDITS.md). Mock checks cannot certify WoW's secure runtime.
