# Retribution Paladin artwork review

This directory is historical research. Current portrait and action-hub galleries are in `../portraits/` and `../hubs/`; only the minimap source here remains active. Superseded encoded textures are retained under `legacy-game/` and never enter the addon packages.

**0.2.0-phase1.5 unit fitting preview.** The revised unit shell uses three continuous full-height columns and a shaped portrait opening. The game update requires a full restart for the changed unit texture. Existing settings are retained. Hub and minimap are unchanged. Visual fit remains unqualified in game. See `docs/phase1-assets.json` for exact runtime assets and source hashes.

Open `index.html` to inspect each component separately. Player and target are independent shells. Their relative placement is owned by Blizzard Edit Mode; there is no connecting artwork.

## Requested removal

`design-edits/player-no-weapons.png` preserves the supplied design while removing the lower-left hammer and lion medallion. `design-edits/target-no-weapons.png` removes the sword and hammer from the target counterpart. Both are RGB design references: their checkerboard is baked in. They must never be shipped as transparent textures.

The `assets/` directory contains separate generated RGBA candidates with real alpha. These are different drafts, not pixel-identical transparent extractions of the design references. `action-hub-v2.png` supersedes the earlier weapon-bearing hub concept.

## Fit status

- Player/target: **revised for testing**. Three columns (portrait, paired rails and endcap) share a continuous vertical mapping. Adjacent UVs and edges coincide; horizontal resizing stretches only the center column. In-game seams, native indicators and target classifications still need checking.
- Minimap: unchanged. User screenshots show clipping at the native minimap's screen-edge position. Compact versus full-surround preference is pending.
- Action hub: height reduced from 493 to 240 UI units at the same width. Wing and crest proportions stay stable when width changes; rails absorb the extra span. In-game fit remains to be checked.
- Cast bar: deferred.

The preview uses a 1440p size estimate (UI units × effective scale × 1440/768), inferred from the screenshot and diagnostic scales. It is not runtime calibration or proof of game compatibility. The user can switch resolution, scale, background, bounds, and functional-region guides. At 1:1, one CSS pixel represents one target screenshot pixel at 100% browser zoom; OS display scaling can differ.

`runtime-layout.js` is generated from the registered Lua theme by `tools/export_fit_preview.lua`, so piece definitions are shared with the preview. It also imports `reported-fit-profile.txt`, transcribed from the user's screenshot, and exports resolved settings. That profile keeps player dimensions at defaults, uses Background/128/Artwork layering, and hides the hub with scale 1.5 and Y −24. The preview does not change the game profile. The Previous fitting toggle reproduces the earlier phase1.2 whole-image layout.

Unit v2 was edited with built-in image generation; the generated draft had a baked checkerboard. After explicit user authorization, `tools/extract_unit_alpha.py` removed neutral background connected to the outside and aperture seeds. Retained art RGB is unchanged. `unit-fit-correction.json` records prompts and `unit-alpha-report.json` records the processing, dimensions and hashes. The RGB draft remains a design reference only and is excluded from game packages.

Unit root size is 232 × 100. Guide rectangles come from the pinned player XML and the ordinary target classification refresh, with native dimensions unchanged. Synthetic guides do not reproduce masks, portrait artwork, text, or restricted game state.

Source revisions:

- Retail: `78282522143e25c3540583734fd192c3d69be910`
- Forever: `70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e`

Generation used the built-in image tool. `prompts.json` records prompts; `asset-manifest.json` records modes, alpha bounds, checksums, and qualification. A baked checkerboard must not be mistaken for alpha transparency.

## Preview verification

Checked the player, target, minimap, and action hub views in the local browser. Confirmed component switching, solid/checkerboard backgrounds, guide visibility, fit-window scaling, and 1440p/4K readouts. No browser errors were reported. Alpha statistics were read from the PNG files; no pixels were altered by the inspection script. These checks do not qualify the artwork for game use.
