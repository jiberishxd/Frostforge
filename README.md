# JiberishUI

**0.4.0-art.2** adds 42 class/race/faction action hubs and fits each portrait’s inner contour to the native frame, closing the floating lower-wrap gap. Class symbols are integrated into the layered portrait ornament and sculpted hubs, using the requested Blizzard emblems as references, including the Undead mask, Mage eye and Hunter stag skull. There are no pasted circular icon holders. All choices use shared fitting templates; the native UI remains functional underneath.

Blizzard owns every portrait, health/power bar, name, level badge, aura, position, secure click and action button. JiberishUI creates mouse-transparent decorations under UIParent; it does not replace, reparent or reskin native controls.

## Portrait library

- 13 class backgrounds.
- 26 playable-race backgrounds, including allied races, Earthen and Haranir.
- Alliance, Horde and Neutral backgrounds.

All 42 portraits use transparent 512 × 256 textures containing two 256-square fits, displayed at the same 128 × 128 UI units. Player uses the teardrop fit; Target and Focus use the round fit. Their painted inner contours follow the native openings, with a shared center and clear bar regions. Cloth, feathers and stone sweep down the side naturally; there is no separate level-badge cutout or forced horizontal crop. Natural alpha bounds vary within the shared envelope. Source artwork and the fitting gallery are in `artwork/portraits/`.

## Action hub library

The hub includes the same 13 classes, 26 races and three faction choices. `/jui` → Action hub exposes automatic player class/race/faction selection and a paginated artwork gallery. Selecting an individual hub sets Chosen artwork. It never follows the target's identity. All 42 choices retain the same anchor, five-piece geometry, baseline and reserved button space. Endcaps preserve their proportions while the rails stretch independently. Paladin keeps its flared wing endcaps; other variants carry their identity through layered armor, stone, wood, feathers and draped cloth, with one integrated motif on the left. Neutral uses an original compass. Hub textures are 1024 × 512 RGBA; only visible gallery thumbnails are assigned textures. A standalone fit gallery is in `artwork/hubs/`.

**Automatic class is the default.** Targeting a player changes that frame's background to their class; Focus selects its own class independently. Race and faction modes, or a fixed artwork choice, are available separately for each frame. NPCs and unavailable/restricted class information use Neutral. Automatic race/faction modes also use Neutral when their information is unavailable. No health/power quantities are read.

## Testing in game

Install the matching Retail or Forever package and **fully restart WoW** for the new files and textures. Open `/jui`. Select Player, Target or Focus, then use Portrait selection or Browse artwork. The options window uses textured borders, red/gold buttons, classic checkbox art, slider tracks and a selected-portrait crest. Move it by its title bar; all in-game decorations remain click-through.

Target a Paladin, then a Rogue or another class. Set a different-class player as Focus. Check the native name, level badge and bars remain visible, and test entering/exiting combat. Automatic texture changes can run in combat only on already-attached, unprotected addon frames. Protected changes and all positioning/configuration changes wait until combat ends.

The baseline fits are verified offline against the pinned native geometry. **This build still needs in-game visual and secure-runtime validation on both clients.** See [validation](docs/VALIDATION.md) and [test results](docs/TEST-RESULTS.md).

## Controls

`/jui`, `/jiberishui` and `/jf` open the movable options window. Existing commands remain available:

| Command | Effect |
|---|---|
| `/jf debug [on\|off]` | Show decorative bounds and geometry/texture information |
| `/jf status` | Print client, settings and component diagnostics |
| `/jf reloadtheme` | Reapply current in-memory settings |
| `/jf set <component> <property> <value>` | Adjust one decorative component |
| `/jf show <component>` / `/jf hide <component>` | Show or hide artwork |
| `/jf reset [component]` | Reset one component, or all when omitted |
| `/jf export` / `/jf import <backup>` | Export/import validated appearance data |

Components: `playerFrame`, `targetFrame`, `focusFrame`, `minimap`, `actionHub`.

Properties: width/height (16–2048), X/Y (−2048–2048), scale (0.25–3), opacity, shown, anchor (FRAME/SCREEN), anchor points, strata, frame level (0–128), and texture layer. Action hub additionally exposes `hubMode` (CLASS/RACE/FACTION/FIXED) and a catalog `hub` ID. Portrait components additionally expose `portraitMode` (CLASS/RACE/FACTION/FIXED) and a catalog `portrait` ID.

```text
/jf set targetFrame portraitMode CLASS
/jf set focusFrame portraitMode RACE
/jf set playerFrame portrait CLASS_PALADIN
/jf set playerFrame portraitMode FIXED
/jf set actionHub hubMode RACE
/jf set actionHub hub RACE_SCOURGE
/jf set actionHub hubMode FIXED
```

Background strata and level 0 keep native controls above the art. Custom dimensions/offsets/strata can change the fit. Use Reset this component to return to the fitted defaults.

## Persistence and scope

Settings remain under `JiberishUIDB.phase1`, now version 2. Version-1 shell sizing converts once to portrait sizing; offsets retain their adjustment relative to the previous defaults. Layering, visibility, hub/minimap settings and options position are retained. JF2 backups preserve new portrait settings; old JF1 backups are accepted and converted. Unknown/future database formats are preserved read-only.

Forever build 69913 previously failed to supply saved settings at startup in live diagnostics. This update does not fix that client loading failure. Export before closing: [persistence notes](docs/PERSISTENCE.md).

No party/raid, pet, boss, cast-bar or replacement-UI modules are added. ElvUI/Ellesmere integration is not claimed. No native minimap or action-bar positioning changes are made; existing minimap edge clipping and arbitrary action-hub layouts remain separate fitting concerns.

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
python3 tools/encode_paladin_ret.py
python3 tools/build_portraits.py
python3 tools/build_hubs.py
python3 tools/render_portrait_review.py
lua5.1 tools/export_fit_preview.lua
python3 tools/check.py
```

Serve the repository with `python3 -m http.server 8757 --bind 127.0.0.1`, then open `/artwork/portraits/` or `/artwork/hubs/` on that server. The source PNGs, generation briefs and revision history are retained for editing; only active textures and Lua files enter the game packages. Downloaded website HTML is a local cache and is not committed. Source references and Blizzard credits are in [artwork credits](docs/ARTWORK-CREDITS.md). Mock checks cannot certify WoW's secure runtime.
