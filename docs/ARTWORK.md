# Portrait artwork and fitting

The active unit artwork is a portrait background only. There is no health/power border, rail, full-frame shell or bar endpoint. Player, Target and Focus each render one independent texture; Target and Focus mirror the artwork. The minimap retains its Paladin texture; the hub has 42 variants on the existing five-piece geometry.

The library includes 42 compositions from retained generated ornaments and the requested official emblems: 13 classes, 26 playable races, and three faction choices. `artwork/portraits/catalog.json` records the motifs and official roster sources. `generation-prompts.json` stores every complete built-in imagegen prompt. Original outputs are retained separately from processed assets. No generated character portraits are used: native Blizzard portraits stay visible.

The visual brief is classic Warcraft III/original WoW: coarse hand-painted shading, weathered surfaces, broad silhouettes, restrained palettes and detail readable at 128 UI units. Final game textures are 512 × 256 RGBA TGA atlases, with independent 256-square Player and Target/Focus fits. The source and output hashes, dimensions, alpha bounds and processing method are recorded in phase1-assets.json and the artwork manifest. High-resolution originals are not installed in game.

## Shared fit template

Each portrait first uses the common silhouette envelope, then its painted inner contour is measured and smoothly registered to a native opening centered at (154,148). The Player opening has radius 60 and a squared lower-right corner at (214,208). The round Target/Focus opening has radius 58. The lower wrap follows those edges; the outer side drapes retain their individual silhouettes. Both fits keep the right bar corridor x>=214 clear. There is no horizontal lower-band crop, separate level-circle cutout or pasted icon holder.

Fit version 5 stores Player in the left half of each 512 × 256 atlas (U=0..0.5), and Target/Focus in the right half (U=0.5..1). Target/Focus mirror their half in the renderer. Identity changes replace texture bytes without changing those coordinates, frame dimensions or offsets. The opening is normalized independently of the differing wings, crests and cloth around it.

At the default 128 × 128 UI-unit size, Player uses LEFT-to-LEFT offset (−23,11) on the native 232 × 100 root. Target and Focus use RIGHT-to-RIGHT (22,12). These align the openings with the audited 60 × 60 player portrait and 58 × 58 target/focus portrait, while leaving the bars and their endpoint native. Effective scale follows each root. The offline checks inspect every pixel in the protected functional regions; manual resizing can change those relationships.

`tools/build_portraits.py` retains generated alpha where present, uses the user's authorized neutral-background cleanup only when needed, downsamples, and applies the common clearance mask. Small disconnected fragments left by those cutouts are removed. Originals with real alpha retain it. Revised outputs with baked gray checker mattes use the user's authorized local cleanup, preserving dark outlines and enclosed painted details. Processing is reproducible, and original generations remain untouched. A PNG fit gallery shows all candidates against synthetic Blizzard geometry at selectable scale/resolution before installation. This preview is not a substitute for in-game screenshots.

| Asset | Encoded size | Default artwork size |
|---|---|---|
| Media/Portraits/*.tga (42 files) | 512 × 256 (two fits) | 128 × 128 |
| Media/PaladinRet/minimap.tga | 1024 × 1024 | 340 × 340 |
| Media/Hubs/*.tga (42 files) | 1024 × 512 | 1480 × 240 |

The superseded unit-shell files and design experiments remain in research/history only and are excluded from packages. Native decorations never disappear when an asset fails to load.

The retained Paladin revision 2 first spread the armored wing upward and outward and removed its hanging cloth banner. The portrait opening, default dimensions and mirrored Target/Focus layout are unchanged. The previous artwork and generation record are retained under `artwork/portraits/revisions/`; `paladin-flared-edit.json` records the edit prompt and reference roles.

Portrait.3 replaces the Mage crescent with a violet arcane eye and the Hunter paw badge with an antlered skull trophy, following the supplied references. `mage-hunter-emblem-edits.json` records both built-in imagegen edits. The previous assets are retained in `revisions/before-uniform-fit/`; that historical revision is shown in `uniform-fit-review.png` and is superseded by the current collection review.

## Art.1 source and hub update

`artwork/official-crests/sources.json` records 41 downloaded crest sources (13 classes, 26 races, Alliance and Horde), hashes and Blizzard credit. Neutral remains custom. `tools/fetch_official_crests.py` reads the published page crest references; no account data is accessed. Source availability and user direction are not represented as a separate license grant. See ARTWORK-CREDITS.md.

All 13 class portraits and the Undead portrait have newly integrated motif artwork; the other 28 retain their original continuous ornaments with the pasted badge removed. `integrated-generation-prompts.json` records the new portrait briefs. Full side silhouettes are registered before the shared portrait clearance is applied. That revision introduced fit version 4; version 5 now additionally conforms the painted inner contour to each native shape.

All 42 action hubs are complete sculpted compositions generated with `sculpted-generation-prompts.json`. One identifying motif is integrated into the left endcap. Its materials continue across the rail into a complementary right endcap; neither side is a repeated downloaded icon. Originals and result paths are retained separately from prepared atlases. Nine hubs with luminous effects or neutral stone use a recorded solid-color background edit before alpha extraction, to avoid retaining checker patterns or erasing gray sculpture. `alpha-background-revisions.json` records those edits.

Hub atlases share a 2172 × 724 design canvas, encoded as 1024 × 512. Continuous vertical registration aligns the painted rail body to y=530..620. Shared seams are x=620,980,1210,1552. Every slice retains the full vertical image, so cloth and hanging ornament survive resizing. The renderer preserves endcap and center-detail size and stretches only connecting rails. The middle region x=620..1552, y<440 is transparent in every source atlas. Center ornament stays below that region. Only the five existing addon textures change. The preview uses PNGs exported from the exact game-resolution pixels.

The prior portrait.3 lower-band crop was rejected in live feedback and is superseded. Current full collection sheets are `artwork/portraits/collection-review.png` and `artwork/hubs/collection-review.png`. Old revision sheets are retained for history only.

## Art.2 portrait fit correction

Live screenshots showed a floating lower wrap and varying opening sizes when switching artwork. Normalizing only the outer image bounds did not align the inner rim. `tools/fit_portraits.py` now measures the first substantial painted edge along radial samples, smooths that contour, and resamples toward the native Player or round Target/Focus outline. The mapping returns to the original outer artwork beyond the fitting band, and premultiplied-alpha sampling avoids dark edge seams. Every identity uses the same algorithm and anchors.

The two synthetic native-fit sheets are `artwork/portraits/player-fit-review.png` and `round-fit-review.png`. Their gold portrait and level-badge guides are preview overlays, never part of the distributed artwork. Pixel checks verify clear native interiors in both atlas halves and that existing lower wraps sit within four texture pixels of the native edge. The new fitting still needs live confirmation at user-customized sizes and offsets.
