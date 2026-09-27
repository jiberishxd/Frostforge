# Development and local previews

Frostforge is a Lua addon with retained artwork sources and offline previews. The game installs only the packaged `JiberishUI` directory. The repository itself also includes editing references, tooling and tests.

## Build installable ZIPs

Requires Python 3. From the repository root, run:

```sh
python3 tools/package.py
```

This writes `Jiberishs-Frostforge-Retail-<version>.zip` and `Jiberishs-Frostforge-Forever-<version>.zip` into `dist/`. Use the archive matching your client; each contains a single top-level `JiberishUI` folder. Keep the complete folder together.

## Local checks

```sh
lua5.1 tests/run.lua
python3 tools/check.py
python3 tools/package.py
python3 tools/check.py --packages
```

Install Lua 5.1 and Python 3 to run these checks; a local Lua 5.1 executable can be used instead of `lua5.1`. The same checks run on pull requests.

The repository includes the final textures and all artwork inputs. To rebuild media without a generation-service cache or network access, install the pinned image-processing dependencies and run:

```sh
python3 -m pip install -r tools/requirements-artwork.txt
python3 tools/build_portraits.py
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

Documentation compositions can be refreshed with `python3 tools/render_readme_media.py --hub-review`. This also renders every hub over solid teal for transparency review. Hub cleanup uses retained, hashed masks; it never repaints the source or changes its registration. See [hub transparency](HUB-TRANSPARENCY.md).

Serve the repository with `python3 -m http.server 8757 --bind 127.0.0.1`, then open `/artwork/portraits/` `/artwork/hubs/` `/artwork/minimaps/` `/artwork/unit-frames/`, `/artwork/cast-bars/` or `/artwork/settings/` on that server. The source PNGs, generation briefs and revision history are retained for editing; only active textures and Lua files enter the game packages. Downloaded website HTML is a local cache and is not committed. Source references and Blizzard credits are in [artwork credits](ARTWORK-CREDITS.md). Mock checks cannot certify WoW's secure runtime.
