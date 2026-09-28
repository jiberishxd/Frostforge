# Artwork source history

Maintainer reference for artwork generation, fitting and revisions. Player-facing attribution is in [CREDITS](../../Frostforge/CREDITS.md). Source images, prompts, hashes and processing records remain in the repository; none of these development notes is installed with the addon. Older entries describe their stated version, not the current runtime.

## Generation and ownership records

Blizzard artwork, icons, emblems and other Blizzard game assets depicted or referenced are © Blizzard Entertainment, Inc. World of Warcraft and Warcraft are trademarks or registered trademarks of Blizzard Entertainment, Inc. Jiberish's Frostforge is an independent fan-made addon and is not affiliated with, sponsored by or endorsed by Blizzard Entertainment.

The requested website emblems are visual references for the generated portrait ornaments and action hubs. Their central symbols are integrated into layered artwork; the website's circular icon holders are not pasted onto it. Exact source pages, asset URLs and original hashes are recorded in ARTWORK-SOURCES.json. Original downloads are retained under artwork/official-crests/originals in the development workspace; only prepared decorative textures are installed.

Surrounds, rails and the neutral compass use Frostforge compositions generated through the built-in image tool, then locally processed under the user's instruction. Prompt sets and originals are retained in artwork/portraits and artwork/hubs. The official emblems and the underlying Warcraft designs are not claimed as Frostforge original artwork.

No separate written permission from Blizzard has been obtained or is implied by this credit. This record documents provenance, not a license or legal opinion.

### Minimap collection and Warrior revision

The 42 matching minimaps were created with the built-in image generation tool from the existing hub/portrait references. `artwork/minimaps/generation-prompts.json`, `generation-results.json` and `manifest.json` retain prompts, workspace sources and hashes. Alpha cleanup and shared circular fitting use the user's authorized local Python processing. `artwork/warrior-neutral-review/prompt.txt` records the edit removing faction marks from all three Warrior components. These changes do not represent a new license grant for the underlying referenced Blizzard motifs.

### Painted stone and hub transparency revision (0.8.1)

The shared stone material now uses a new original hand-painted fantasy surface with broad, restrained shading and quiet wear. It was generated with the built-in image tool; the exact prompt is retained in `artwork/unit-frames/references/plain-stone-generation.json`, beside the original `plain-stone.png`. Earlier material versions are retained under `references/revisions/`. Authorized local processing crops, converts to grayscale and encodes the 256 × 32 fill. All 42 health exports and the existing **Frostforge Stone** SharedMedia entry use this source. No reference-addon artwork, code or branding is bundled.

All 42 hubs were reviewed for enclosed matte/checkerboard residue. Twenty-four received alpha-only corrections using retained source-space masks; their original painted RGB and fitting geometry are preserved. Mask hashes, source hashes and review sheets are in `artwork/hubs/alpha-cleanup/`; [hub transparency notes](ARTWORK.md#hub-transparency-cleanup) explain the verification. Original generated hub sources remain unchanged.

The Druid unit-frame antlers were corrected with the built-in image tool using the official Druid crest as a shape reference. Original/generated images and the exact prompt are retained in `artwork/unit-frames/sculpted/druid-antler-correction/`. Authorized local compositing confines the edit to the two upper endcaps; all other source pixels and the measured bar geometry are unchanged. The cast border retains a snapshot of the older unit-frame input used for its generation.

### Previous plain stone health material

Build 0.7.3 uses a new original stone material generated with the built-in image tool, then cropped, reduced to grayscale and fitted locally for 256 × 32 health fills. The source is `artwork/unit-frames/references/plain-stone.png`; its exact prompt and generation record are in `plain-stone-generation.json` beside it. No reference-addon assets, code or branding were used. All 42 health exports use this unmarked material and retain native tinting. Existing ornamental shells, power materials, portraits, hubs and minimaps are unchanged.

The 0.7.4–0.7.5 Shaman unit-frame revisions use the recorded official Shaman crest as a visual reference for an integrated elemental mask and a carved totem counterpart. The built-in image tool produced the edit; user-authorized local processing removes its painted checkerboard. Sources, prompt and extraction hashes are in `artwork/unit-frames/sculpted/shaman-elemental-correction.json`, `shaman-neutral-correction.json` and `shaman-alpha-report.json`. The final revision balances the endcap and replaces red cloth/tusks with faction-neutral wood, stone and rope. Other Shaman families retain their existing integrated elemental motifs.

### Cast borders and Mage emblem accuracy (0.8.0)

The 42 cast borders are separate built-in image-tool generations inspired by the matching unit-frame rails. Complete tips, leaves and bindings are retained outside the bar opening. Prompts and originals are in `artwork/cast-bars/generation-prompts.json` and `references/`; prepared alpha PNGs and their TGA provenance are in `assets/` and `manifest.json`. User-authorized local processing removes generated neutral backgrounds and registers a shared clear opening.

The supplied Mage class emblem guides localized corrections on the portrait, unit shell and cast border: a horizontal arcane lens with a pale diamond center, stacked gemstones, fluted lower rays and cyan book runes. Exact built-in editing prompts, before/generated images and the localized application record are in `artwork/mage-emblem-correction/`. Unchanged hub/minimap designs retain their historical portrait reference snapshots so their source hashes stay accurate.

The Mage cast-border ends were subsequently simplified with the built-in image tool into compact bronze brackets, violet crystals and cyan rune accents. The exact edit prompt is in `artwork/cast-bars/mage-simplification/generation.json`; its `before.png` retains the earlier book/eye cast border. Portrait and unit-shell emblems were not changed by this cast-only simplification.

### Frostforge identity and settings material (0.9.0)

The owner-approved transparent penguin logo is retained in `docs/images/logo.png`, with its generation and alpha-processing record in [LOGO-SOURCE.md](../images/LOGO-SOURCE.md). A 512 × 512 RGBA TGA supplies the in-game icon and header. The subtle settings background is a square center crop from an original built-in image-tool generation; its full source and exact prompt are retained in `artwork/settings/sources/`. Native Blizzard borders and desaturated, blue-tinted button textures supply the controls. The generated border is not used at runtime.

Build 0.9.3 refines only the Night Elf unit-frame right emblem, hub left emblem and minimap moon using the supplied Blizzard Night Elf emblem. `artwork/nightelf-emblem-update/` retains the reference, exact built-in imagegen editing prompts, generated production mattes, before images and localized application record. Standard local alpha extraction, fitting and TGA encoding preserve the existing bar openings, hub seams and circular map aperture. Historical style references are retained. This adds no license grant for the referenced Blizzard motif.

### Notices and reuse

The notice above is also available in the in-game Guide and the repository README. Use it on the CurseForge project page; [listing text](RELEASE.md) is provided for that purpose. The notice applies to Blizzard assets and underlying designs, not to all Frostforge code or every original composition.

Blizzard's [Legal FAQ](https://www.blizzard.com/en-sg/legal/c1ae32ac-7ff9-4ac3-a03b-fc04b8697010/blizzard-legal-faq) asks fansites to retain appropriate copyright, trademark and other notices. It describes conditional permissions, not an unrestricted license for every bundled asset or modification. Attribution alone does not grant permission; review the terms applicable to each asset before distribution.

### Illustrated setup tour (0.9.7)

The owner supplied the in-game example retained at `docs/images/setup-ingame.png` specifically for the setup wizard. Its resized runtime capture preserves the complete scene and aspect ratio. The other capture is the current settings preview exported from the addon’s Lua UI in the offline host; native Blizzard fonts/borders are approximated by that preview. `tools/build_setup_media.py` reproducibly exports their padded TGA textures and source hashes. None of the 296 existing art assets is changed.

## Portrait artwork and fitting

Portrait-only mode uses a portrait background without a health/power border, rail, full-frame shell or bar endpoint. Optional full-frame skins are described below. Player, Target and Focus each render one independent texture; Target and Focus mirror the artwork. The minimap and action hub each have the same 42 identities, with shared circular and five-piece fitting geometry respectively.

The library includes 42 compositions from retained generated ornaments and the requested official emblems: 13 classes, 26 playable races, and three faction choices. `artwork/portraits/catalog.json` records the motifs and official roster sources. `generation-prompts.json` stores every complete built-in imagegen prompt. Original outputs are retained separately from processed assets. No generated character portraits are used: native Blizzard portraits stay visible.

The visual brief is classic Warcraft III/original WoW: coarse hand-painted shading, weathered surfaces, broad silhouettes, restrained palettes and detail readable at 128 UI units. Final game textures are 512 × 256 RGBA TGA atlases, with independent 256-square Player and Target/Focus fits. The source and output hashes, dimensions, alpha bounds and processing method are recorded in phase1-assets.json and the artwork manifest. High-resolution originals are not installed in game.

### Shared fit template

Each portrait first uses the common silhouette envelope, then its painted inner contour is measured and smoothly registered to a native opening centered at (154,148). The Player opening has radius 60 and a squared lower-right corner at (214,208). The round Target/Focus opening has radius 58. The lower wrap follows those edges; the outer side drapes retain their individual silhouettes. Both fits keep the right bar corridor x>=214 clear. There is no horizontal lower-band crop, separate level-circle cutout or pasted icon holder.

Fit version 5 stores Player in the left half of each 512 × 256 atlas (U=0..0.5), and Target/Focus in the right half (U=0.5..1). Target/Focus mirror their half in the renderer. Identity changes replace texture bytes without changing those coordinates, frame dimensions or offsets. The opening is normalized independently of the differing wings, crests and cloth around it.

At the default 128 × 128 UI-unit size, Player uses LEFT-to-LEFT offset (−23,11) on the native 232 × 100 root. Target and Focus use RIGHT-to-RIGHT (22,12). These align the openings with the audited 60 × 60 player portrait and 58 × 58 target/focus portrait, while leaving the bars and their endpoint native. Effective scale follows each root. The offline checks inspect every pixel in the protected functional regions; manual resizing can change those relationships.

`tools/build_portraits.py` retains generated alpha where present, uses the user's authorized neutral-background cleanup only when needed, downsamples, and applies the common clearance mask. Small disconnected fragments left by those cutouts are removed. Originals with real alpha retain it. Revised outputs with baked gray checker mattes use the user's authorized local cleanup, preserving dark outlines and enclosed painted details. Processing is reproducible, and original generations remain untouched. A PNG fit gallery shows all candidates against synthetic Blizzard geometry at selectable scale/resolution before installation. This preview is not a substitute for in-game screenshots.

| Asset | Encoded size | Default artwork size |
|---|---|---|
| Media/Portraits/*.tga (42 files) | 512 × 256 (two fits) | 128 × 128 |
| Media/Minimaps/*.tga (42 files) | 512 × 512 | 340 × 340 at native diameter 198 |
| Media/Hubs/*.tga (42 files) | 1024 × 512 | 1480 × 240 |
| Media/UnitFrames/*.tga (42 shells) | 512 × 256 | Fitted to the native bars |
| Media/UnitFrames/*-health.tga and *-power.tga (84 fills) | 256 × 32 | Native health/power regions |

These four directories are the complete active media inventory: 252 textures. The retired material families (`arcane_crystal`, `jade_bamboo`, `fel_obsidian`, `black_basalt` and their peers), the old `fantasy` and singular `hub` directories, and the standalone placeholder textures have been removed from the addon folder. They were already excluded from release ZIPs. Artwork sources and historical records outside `Frostforge` remain available for editing; the current build commands are in README.md. Validation rejects any media file outside the active manifest.

The superseded unit-shell files and design experiments remain in research/history only and are excluded from packages. Native decorations never disappear when an asset fails to load.

The retained Paladin revision 2 first spread the armored wing upward and outward and removed its hanging cloth banner. The portrait opening, default dimensions and mirrored Target/Focus layout are unchanged. The previous artwork and generation record are retained under `artwork/portraits/revisions/`; `paladin-flared-edit.json` records the edit prompt and reference roles.

Portrait.3 replaces the Mage crescent with a violet arcane eye and the Hunter paw badge with an antlered skull trophy, following the supplied references. `mage-hunter-emblem-edits.json` records both built-in imagegen edits. The previous assets are retained in `revisions/before-uniform-fit/`; that historical revision is shown in `uniform-fit-review.png` and is superseded by the current collection review.

### Art.1 source and hub update

`artwork/official-crests/sources.json` records 41 downloaded crest sources (13 classes, 26 races, Alliance and Horde), hashes and Blizzard credit. Neutral remains custom. `tools/fetch_official_crests.py` reads the published page crest references; no account data is accessed. Source availability and user direction are not represented as a separate license grant. See the [installed credits](../../Frostforge/CREDITS.md).

All 13 class portraits and the Undead portrait have newly integrated motif artwork; the other 28 retain their original continuous ornaments with the pasted badge removed. `integrated-generation-prompts.json` records the new portrait briefs. Full side silhouettes are registered before the shared portrait clearance is applied. That revision introduced fit version 4; version 5 now additionally conforms the painted inner contour to each native shape.

All 42 action hubs are complete sculpted compositions generated with `sculpted-generation-prompts.json`. One identifying motif is integrated into the left endcap. Its materials continue across the rail into a complementary right endcap; neither side is a repeated downloaded icon. Originals and result paths are retained separately from prepared atlases. Nine hubs with luminous effects or neutral stone use a recorded solid-color background edit before alpha extraction, to avoid retaining checker patterns or erasing gray sculpture. `alpha-background-revisions.json` records those edits.

Hub atlases share a 2172 × 724 design canvas, encoded as 1024 × 512. Continuous vertical registration aligns the painted rail body to y=530..620. Shared seams are x=620,980,1210,1552. Every slice retains the full vertical image, so cloth and hanging ornament survive resizing. The renderer preserves endcap and center-detail size and stretches only connecting rails. The middle region x=620..1552, y<440 is transparent in every source atlas. Center ornament stays below that region. Only the five existing addon textures change. The preview uses PNGs exported from the exact game-resolution pixels.

The prior portrait.3 lower-band crop was rejected in live feedback and is superseded. Current full collection sheets are `artwork/portraits/collection-review.png` and `artwork/hubs/collection-review.png`. Old revision sheets are retained for history only.

### Art.2 portrait fit correction

Live screenshots showed a floating lower wrap and varying opening sizes when switching artwork. Normalizing only the outer image bounds did not align the inner rim. `tools/fit_portraits.py` now measures the first substantial painted edge along radial samples, smooths that contour, and resamples toward the native Player or round Target/Focus outline. The mapping returns to the original outer artwork beyond the fitting band, and premultiplied-alpha sampling avoids dark edge seams. Every identity uses the same algorithm and anchors.

The two synthetic native-fit sheets are `artwork/portraits/player-fit-review.png` and `round-fit-review.png`. Their gold portrait and level-badge guides are preview overlays, never part of the distributed artwork. Pixel checks verify clear native interiors in both atlas halves and that existing lower wraps sit within four texture pixels of the native edge. The new fitting still needs live confirmation at user-customized sizes and offsets.

### 0.5.0 minimap collection and Warrior correction

All 42 minimaps were generated with the built-in image tool using the matching processed portrait and hub as references. Full prompts, originals and per-asset records are retained in `artwork/minimaps/`. User-authorized Python processing removes baked neutral checker mattes when needed, measures each inner rim, and registers it to center (256,256), radius 149 on a 512-square canvas. A premultiplied-alpha radial resample retains the outer ornament within an eight-pixel transparent margin. Nightborne uses a recorded solid-green background revision to remove a noisy painted checker fringe before extraction. The entire circular opening is transparent, with no map image, labels, buttons or backplate baked into the artwork.

The renderer scales the default 340-unit artwork by the native Minimap diameter / 198. Effective native scale is applied once; user width/height and scale adjustments remain available. Switching identities changes only the texture and keeps identical geometry. Native screen-edge placement, labels and buttons remain unchanged; ornate crests can still extend beyond the screen at edge-hugging native positions.

The Warrior portrait, action hub and minimap were edited to remove faction insignia from their red cloth. Weapons, armor and draping remain. The edit prompt, before images and revised outputs are retained under `artwork/warrior-neutral-review/`; their processed textures use the same fit templates as the other identities.

### Optional unit-frame materials (0.7.0-art.1)

The 42 full unit-frame shells are original generated artwork, guided by the approved Shaman composition, the existing portrait for each identity, and the recorded official Warcraft class/race/faction reference. Their raw sources, prompts and measured fitting records are in `artwork/unit-frames/sculpted/`. Warrior remains faction-neutral; Mage uses an arcane eye, Hunter uses hunting/skull motifs, and Paladin has broad wings. No other addon's assets, code or branding are used.

`tools/fit_unit_shells.py` removes the solid green matte, despills adjacent edges and uniformly contains every shell in a 512 × 256 atlas with transparent margins. Version 3 measures each source’s two openings and retains its thick separator, curved joins, full shoulders and hanging detail. No rectangular name crop or nonuniform contour warp is applied. Runtime sections anchor to the existing health bar and fit the native power bar into the corresponding lower opening.

`tools/build_unit_frame_art.py` encodes the 42 shells and 84 matching 256 × 32 opaque health/power materials. Those materials combine our original painted surface with the corresponding shell's lower-rail material; native color tint and masks remain in charge of resource hues and clipping. Portrait, hub and minimap pixels are unchanged. The preview includes a stored-size checkerboard view and gameplay-size Player/Target/Focus comparisons.

### 0.7.0-art.2 artwork audit

The shell fitter now measures the full upper silhouettes and top rail before registration. It keeps the inner shoulders outside the existing name corridor, eases back to the unchanged health opening, and fits extremities inside the outer padding. The name and margin masks must discard zero visible pixels before a fit can export. This replaces the rectangular crop that cut off the Priest corner and similar details in the other shells. Failed fits stop the build rather than publishing an incomplete fitting report.

All 42 original shell sources, all portraits, hubs, minimaps and 84 fill textures remain unchanged. Only the 42 fitted shell exports change. The browser gallery now follows the selected Player/Target/Focus orientation in its thumbnails too. See [the audit findings and comparison](ARTWORK.md#historical-fitting-audit).

### 0.7.1 source fidelity and Paladin correction

The 126 portrait, hub and minimap textures remain byte-identical to pre-audit commit `72c5c69`. All 42 shells now preserve the source paintings’ proportions, and their matching fills are rebuilt from the retained lower-rail material. Paladin alone received a targeted image edit: the official crowned-lion class motif replaces the generic sun on its right winged endcap. The original source, returned edit, exact prompt, input references and reproducible alpha extraction are retained in `artwork/unit-frames/sculpted/paladin-crest-correction.json` and `revisions/`. The browser shows the complete shell separately and offers independent portrait/unit-frame toggles; the audit section above is historical.

## Historical fitting audit

**Historical record — superseded by 0.7.1.** The user requested the original source silhouettes and thicker borders. Version 0.7.1 replaces both the original compressed export and the audit warp with uniform source fitting and measured openings. It also restores Paladin’s crowned-lion class motif. The 126 portrait/hub/minimap assets remain unchanged; the fitting changes and comparison below are historical.

The Priest corner was an export/fitting error. The artwork source was intact; a rectangular name-clearance mask removed its inner carved detail. The same shared mask affected every full shell to varying degrees.

| Finding | Scope | Correction |
| --- | --- | --- |
| Upper corners cut straight through ornament | 42 full shells; Priest lost 1,427 visible atlas pixels in the name corridor | Fit complete upper shoulders outside the corridor, with a smooth transition into the unchanged bar opening. No repainting or new motifs. |
| Canvas padding erasing extreme tips | 27 full shells; 515 visible atlas pixels across the collection | Fit tips inside the four-pixel padding before export. |
| Gallery thumbnails always showing Player | All full-frame gallery choices | Thumbnails now follow the selected Player, Target or Focus layout. |
| Comparison panes hiding the far edge at narrow widths | Browser fitting preview | Stack panels when two complete canvases do not fit side by side, retaining the selected gameplay pixel size. |

The revised fitter records **zero visible pixels removed** by either the name or outer-margin mask in all 42 shells. Health/power openings remain exactly (96,84)-(396,132) and (96,136)-(396,160), on the same 512 × 256 atlas. Frame dimensions, offsets and runtime section coordinates are unchanged.

![Priest Player and Target/Focus before and after fitting correction](../artwork-audit/priest-before-after.jpg)

The green background, labels, empty portrait silhouettes and level badges above are synthetic review guides. They are not baked into the distributed artwork.

### Inspected and retained

All 13 classes, 26 races and three faction identities were reviewed. Each portrait was checked in both the Player shape and mirrored round Target/Focus shape, alone and paired with its full shell. The complete hub and minimap sheets were also inspected for detached pieces, hard clipping and inconsistent openings. No additional defect requiring artwork changes was identified in those collections at the reviewed scale.

All 126 portrait, hub and minimap runtime assets and all 84 health/power fills are byte-identical to art.1. Original generated shell paintings remain intact. The change is confined to the fitted shell exports and preview accuracy. Differences in wings, cloth, crests and outer silhouettes are intentional identity details; they do not change the shared functional opening.

### Verification and limits

The export pipeline asserts that name clearance and padding discard no painted pixels. Two image-fitting regressions preserve recognizable shoulder/tip markers while testing clear openings and rejection of invalid input. Existing Lua and full media/provenance/package checks remain in force.

The live browser checks use Priest Player at 1440p, Priest Target at 4K and Gnome Focus at 1080p. Review sheets cover all 42 Player and Target/Focus pairings at estimated gameplay size. These checks use synthetic native geometry. Real client layering, unusually long names, custom offsets, and native screen-edge placement still need in-game confirmation. No addon was installed into either WoW client during this audit.

## Hub transparency cleanup

All 42 action hubs were inspected over a solid background. Twenty-four contained enclosed checkerboard, pale matte or colored spill that the earlier edge-connected background removal had missed. This includes the reported Human lion and Highmountain Tauren gaps.

The correction clears only reviewed background alpha. Source colors, ornaments, atlas dimensions, five-piece seams and vertical registration remain unchanged. Intentional patterns, including the Goblin checkered cloth, are retained. The other 18 hub textures remain byte-identical to the previous build.

`artwork/hubs/alpha-cleanup/manifest.json` records all 42 reviewed identities and the 24 corrections. Each binary mask has a hash, source-pixel hash, cleared-pixel count and previous runtime texture hash. `tools/clean_hub_alpha.py` validates those inputs before applying a mask. The original generated images remain unchanged.

`tests/test_hub_alpha.py` checks that cleanup changes only approved alpha pixels, preserves the source RGB and registration, removes the reported holes, protects selected colored metal edges, and produces identical PNG/TGA pixels. Three retained review sheets show all 42 complete runtime hub compositions over solid teal. Rebuild them with `python3 tools/render_readme_media.py --hub-review`.

Unchanged minimap generations retain their original hub inputs under `artwork/minimaps/reference-history/hubs-before-alpha-cleanup/`; their provenance does not claim the newer alpha-corrected files were used to generate them.

These are offline source and export checks. The updated hubs have not been validated in a live client.
