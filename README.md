# JiberishUI — Phase 1 fantasy artwork prototype

**0.2.0-phase1.1** implements one theme, `paladin_ret`, with exactly four non-interactive artwork components:

- Minimap surround
- Player-frame surround
- Target-frame surround
- Action-bar hub/background

Blizzard owns the UI, including its borders, colors, buttons, clicks, visibility rules, and Edit Mode layout. JiberishUI adds its own frames and textures, parented to UIParent and anchored to four native roots. It does not move, reparent, recolor, hide, or replace native UI.

This is an architectural prototype. Existing gold trim, a Paladin crest, and a console texture are layout fixtures, not a finished fitted skin. **Offline checks pass; this refactor has not yet been validated in-game.** Additional themes, gradients, party/raid/focus components, replacement-addon adapters, and bar docking are outside Phase 1.

## Install and test

Use the matching archive for Retail or Forever. Each contains a single `JiberishUI` folder. Replace the previous addon folder; do not merge old source files into the package. Keep your WTF/SavedVariables files.

**Restart WoW once after installing this refactor**, because its file list changed. The previous runtime's hooks cannot be unloaded by `reloadtheme`.

Run:

```text
/jf theme paladin_ret
/jf debug
/jf status
```

Select a target to see its artwork. Debug also outlines an attached target component while no target is visible; its artwork stays hidden in that case. If an anchor is absent or forbidden, status explains why no frame was attached.

Use Edit Mode to move or scale Blizzard UI. Use the commands below to adjust only the decorative artwork. Start with default Blizzard UI to validate Phase 1. Follow [the four-component test checklist](docs/VALIDATION.md) before expanding scope.

## Controls

`/jf` displays help. `/jui` and `/jiberishui` are aliases.

| Command | Result |
|---|---|
| `/jf theme paladin_ret` | Select and reapply the test theme, retaining your per-component overrides |
| `/jf reloadtheme` | Reapply loaded theme data, asset references, and current overrides |
| `/jf debug [on\|off]` | Toggle each component's bounds and geometry/texture labels |
| `/jf status` | Print attachment status, debug details, client baseline, and errors |
| `/jf set <component> <property> <value>` | Change one artwork property |
| `/jf show <component>` / `/jf hide <component>` | Toggle that component immediately outside combat |
| `/jf reset [component]` | Clear one component's overrides, or all four when omitted |
| `/jf export` / `/jf import <JF1 backup>` | Print/restore a validated text backup of Phase 1 appearance settings |

Component names are `minimap`, `playerFrame`, `targetFrame`, and `actionHub`.

| Property | Values |
|---|---|
| `width`, `height` | 16–2048 artwork UI units |
| `x`, `y` | −2048–2048 native-anchor UI units; positive X is right, positive Y is up |
| `scale` | 0.25–3, multiplied by the native anchor's effective scale |
| `strata` | BACKGROUND, LOW, MEDIUM, HIGH, DIALOG, FULLSCREEN, FULLSCREEN_DIALOG, TOOLTIP |
| `layer` | BACKGROUND, BORDER, ARTWORK, OVERLAY |
| `point`, `relativePoint` | CENTER, TOP, BOTTOM, LEFT, RIGHT, TOPLEFT, TOPRIGHT, BOTTOMLEFT, BOTTOMRIGHT |
| `opacity` | 0–1 |
| `shown` | on / off |

Examples:

```text
/jf set playerFrame width 290
/jf set playerFrame height 145
/jf set playerFrame x -6
/jf set playerFrame y 8
/jf set playerFrame scale 1.1
/jf set targetFrame strata BACKGROUND
/jf set minimap layer BORDER
/jf set actionHub width 850
/jf set actionHub height 165
/jf set actionHub y -10
```

The hub is one artwork background anchored to MainActionBar. It does not arrange bars, bags, or the micro menu, and does not automatically encompass every custom bar layout. Width/height adjust its footprint. Default BACKGROUND strata keeps the artwork behind native controls; higher strata can visually cover them, though the artwork remains mouse-transparent.

Changes requested in combat apply after combat ends. Existing unprotected artwork can safely follow native visibility during combat; if the client protects it, visibility changes are deferred too.

`reloadtheme` reuses the existing objects. It cannot execute newly edited Lua from disk. After changing Lua files, use `/reload`; after installing a new file list, restart the client. WoW may cache changed texture bytes and require a restart.

## Settings and scope

Phase 1 settings live under `JiberishUIDB.phase1`. Earlier profiles remain in the saved table, untouched and inactive; their docking and native styling settings are not migrated into this renderer. Retail and Forever keep separate SavedVariables.

Forever build 69913 previously failed to supply saved settings at startup in the user's live diagnostics. This refactor does not claim to fix that client-side loading behavior. See [persistence notes](docs/PERSISTENCE.md).

The old skin library and research assets remain in repository history/research files. Release packages include only the Phase 1 source and three referenced textures. [Architecture](docs/ARCHITECTURE.md), [compatibility](docs/COMPATIBILITY.md), and [test results](docs/TEST-RESULTS.md) describe the limits.

## Local checks

```sh
lua5.1 tests/run.lua
python3 tools/check.py
python3 tools/package.py
python3 tools/check.py --packages
```

Use a Lua 5.1 interpreter; locally the bundled build is `.tools/lua-5.1.5/src/lua`. Mock tests cannot certify WoW's secure runtime or visual fit.
