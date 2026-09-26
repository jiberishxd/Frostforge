# Build 0.8.6 stock bar textures and class gradients

265 Lua behavior tests and 17 Python artwork tests pass. New regressions cover texture selection without reading live stock UVs, correct atlas restoration, visible level-zero power after reload, retained opaque no-power openings, all 13 requested class hues and gradient endpoints, stable gradient readback without repeating writes, native color redraws, NPC fallback, texture/color switching and neutral-resource tint restoration. Existing ElvUI/Ellesmere and Retail/Forever coverage remains green.

Source/media/provenance checks and exact Retail/Forever 0.8.6 package checks pass. The settings snapshot was regenerated. All runtime and reference artwork images are unchanged. No WoW interaction or live-client validation was performed. The user's exact Forever reload behavior still requires in-game confirmation; the new regression fixtures cover the identified code failure cases, not WoW's secure rendering engine.

---

# Build 0.8.5 full frames and Blizzard styling

260 Lua behavior tests and 17 Python artwork tests pass. New ElvUI fixtures model opposite-edge health anchors, backdrop-relative power anchors and the provider's public frame structure. Both client paths cover independent Player/Target/Focus shells, retained provider fills, preserved stack size, source selection and backups. Additional checks cover all 42 themes, parent resizing, profile redraws, rounded size readback, unsupported power modes, forbidden regions, hidden providers, combat deferral, media restoration and replaced bars. Existing Blizzard, Ellesmere and cast/text cases pass. New checks cover all 42 themes with hidden/missing/transparent power, complete footer seams and opaque openings, prepared combat transitions, native effect-mask reuse/restoration, independent stock class/dark colors, party/raid pooling, restricted identity/color handling, StatusBar texture application, separate texture selections and profile-backed dialog controls.

Source/provenance and exact Retail/Forever 0.8.5 package validation pass. All runtime and reference artwork images are unchanged. The new settings dialog was also visually inspected in its offline browser preview. No WoW interaction or live-client testing was performed. ElvUI source references and hashes are recorded in addon-sources.json; this does not certify every upstream version or custom layout.

---

# Build 0.8.4 Blizzard cast layers and text controls

234 Lua behavior tests and 17 Python artwork tests pass. Blizzard Player/Target/Focus fixtures cover native cast bars below their owning frame, higher stock/JUI chrome, hidden-to-visible casts in combat, explicit strata and levels, overwritten owned-frame layers, and unreadable optional child layers. Existing Ellesmere and ElvUI cast cases still pass.

Text tests cover all six groups on both client paths, rounded coordinate readback, repeated X/Y adjustments without drift or repeated writes, reordered/partially updated native anchors, native-region aliases, hidden labels, independent reset, backup round trips and combat-deferred restoration. Native content, values and visibility remain untouched.

The exported settings preview was inspected on the Blizzard Name and Cast time sections and the revised Cast bar page. Source/media checks and exact Retail/Forever 0.8.4 package validation pass. All artwork images remain unchanged. No WoW interaction or live-client testing was performed; the user's in-game layout and secure-runtime behavior still need manual confirmation.

---

# Build 0.8.3 original shell overlap

225 Lua behavior tests and 17 Python artwork tests pass. All 42 shells are checked on Player, Target and Focus for exact source coverage with no duplicate or missing texture regions. The actual shell sits above its bar even with old Background / level-zero settings, and its original side edges overlap the fill. Legacy inset depths 0, 3 and 6 produce the same single-shell result.

Fitting checks cover inward edge movement, independent X/Y offsets, joined health/power halves at different native scales, unchanged native bar dimensions during artwork adjustment, backup round trips, combat deferral, region reuse, visibility and restoration. The Night Elf footer retains its proportions when native bars widen. Existing Blizzard and Ellesmere client fixtures pass.

The browser preview was inspected with Paladin at default and narrower widths with offsets, and mirrored Night Elf at full health. The exported settings page exposes width, height and position with no inset control. All runtime and reference artwork images are unchanged. The new settings dialog was also visually inspected in its offline browser preview. Source and Retail/Forever package checks pass. These are offline checks only; no WoW interaction or live-client testing was performed.

---

# Build 0.8.2 sculpted hubs and native frame presentation

224 Lua behavior tests and 17 Python artwork tests pass. New coverage removes synthetic black inset strips, samples the painted bevel away from the opening outline, keeps the center footer ornament proportional when native bars widen, resolves cast borders above native child chrome, and persists an independent cast-border level. Both client fixtures exercise full stock portrait removal and restoration, independent name controls, shared-border visibility and combat deferral.

All 42 hubs were restyled against their matching approved unit-frame references and reviewed on dark and light backgrounds. Tests check exact PNG/TGA pixels, clear button space, transparent margins, preserved registration and retained provenance. The approved-art lock confirms all 211 unit-frame/portrait runtime and reference files are unchanged. Historical minimap references now point to retained hub snapshots; minimap pixels are unchanged.

The browser previews use the exported settings layout and actual runtime artwork. Checks cover the Blizzard controls, Night Elf fitting and assembled hub seams. Source/media checks and separate Retail/Forever package validation pass. These are offline checks: no WoW interaction, gameplay, or live-client testing was performed. Confirm portrait restoration, cast layering, native name placement and custom Ellesmere/Blizzard layouts in game before release.

---

# Build 0.8.1 character profiles, native controls and artwork polish

219 Lua 5.1 behavior tests and 15 Python artwork tests pass. New behavior coverage includes character-specific profile assignments on both client paths, migration of the previous setup, independent copies, deliberately shared profiles, relogging, imports, invalid/future formats, combat restrictions, and restoring native presentation after switching profiles. The Profiles, Artwork, Blizzard and Advanced settings pages were visually inspected from the actual Lua UI export.

Ellesmere cast-border cases cover Resource Bars versus Unit Frames discovery, idle preparation, frame chrome layering and independent strata. Blizzard controls cover portrait-image visibility, name positioning/font restoration, and shared stone fills across main, pet, boss, party and raid health/power bars. Native appearance changes defer during combat. Recessed edges are checked across all 42 themes and all three units, with additional Blizzard/Ellesmere coverage for saved Background strata and level zero. The default 3-unit lip and scaled shadow overlap both fills; thin bars cap overlap at 22% per side. These are offline simulations, not certification of the game's secure renderer.

All 42 hubs were visually audited on a solid background; retained masks remove baked checker residue in 24 while preserving artwork RGB and registration. All 42 health fills now use the original minimal painted-stone material. The Druid shell has localized branching antlers; the remaining source pixels, bar openings and rail fitting are unchanged. Of 294 runtime textures, 67 changed (24 hubs, 42 health fills and one Druid shell); the other 227 are unchanged. Artwork tests and provenance checks cover the corrected exports and retained generation references.

Source/media/provenance checks, the exported cast-layout comparison, and exact Retail/Forever 0.8.1 package checks pass. Each archive contains 359 files, including 294 runtime textures. Documentation links resolve locally.

No WoW interaction or in-game testing was performed. Character logout/login persistence, actual Ellesmere cast-border visibility, secure runtime behavior, native text placement and custom layouts remain user-run checks. Retail and Forever keep separate saved files. The previously reported Forever saved-table loading issue remains distinct from profile assignment; see [persistence](PERSISTENCE.md).

---

# Build 0.8.0 matching cast-bar borders and Mage emblem correction

190 Lua 5.1 behavior tests and 12 Python artwork tests pass. Cast cases cover Blizzard, EllesmereUI and ElvUI on both client paths; all 42 themes; complete outer texture coordinates and proportional corners; legacy-style migration to the single Bold design; centered width/height fitting, independent settings, reset and backups; matching/fixed artwork; combat-safe identity changes and queued fitting; idle attachment, fading/hiding, effective scale, provider replacement, unavailable/restricted geometry and Forever gamepad casts.

The artwork checks verify clear cast interiors, transparent outer margins, continuous upper/lower rails and pixel-identical PNG/TGA exports. Mage portrait/unit-shell corrections are confined to the existing emblem regions; the cast border has simplified bronze-and-crystal ends. Only the Mage portrait and unit shell changed among the previous 252 textures; the other 250 remain unchanged. The 42 new cast textures bring the package to 294. The preview is exported from the same Lua fitting code, including width/height examples.

Source/media/provenance and exact Retail/Forever 0.8.0 packages pass. No WoW interaction or in-game testing was performed. Runtime appearance, native shields/stage pips, text placement, secure behavior and provider-specific custom layouts remain user-run checks documented in CAST-BARS.md.

---

# Build 0.7.5 inset fitting and neutral Shaman totems

170 Lua 5.1 behavior tests and six Python artwork regressions pass. Five new Lua cases cover all 42 inset themes on Player/Target/Focus, mirrored edge crops, joined shell resizing without native-bar/portrait changes, fitting backups/range validation, combat deferral, stable frame reuse and protected rim retirement.

Browser inspection covered the new Unit frame settings page exported from the actual Lua objects, with native Blizzard textures/fonts approximated for this development preview. The balanced Shaman totem shell was inspected as Player at estimated 1440p size; it retains a 5.6 UI-unit painted divider at 20-unit health height. Priest Target was checked with 98% artwork width and 105% height, including inset edge/shadow placement. Final PNGs and packaged TGAs share the same pixels. Only the Shaman shell and matching power texture changed: the other 250 runtime textures, including all 126 portrait/hub/minimap assets, are unchanged from merged 0.7.4.

Source/media/provenance and exact Retail/Forever 0.7.5 package checks pass. No third-party addon code or textures are bundled. No WoW interaction or in-game testing was performed. Actual renderer clipping, labels, provider redraw timing and secure runtime behavior still require the user's manual checks. See SETTINGS.md and VALIDATION.md.

---

# Build 0.7.4 settings workshop, shared stone and Shaman shell

165 Lua 5.1 behavior tests and six Python artwork regressions pass. Thirteen new Lua cases cover the reorganized settings pages, screen-fit scaling and dragged position, literal collection searches/pagination and selection scope, backup round-trips/invalid input, scoped reset, read-only profiles, optional/late SharedMedia registration, provider-controlled fills, selecting shared Stone without stale restoration, and combat-queued texture ownership. Existing material override tests explicitly select JIBERISH mode; new AUTO checks verify no Ellesmere texture hooks or fill writes are installed.

Browser inspection covered the settings Artwork, Advanced, Guide and collection layouts exported from the actual Lua objects. Native Blizzard textures/fonts are approximated in this development preview. Shaman was inspected as Player and mirrored Target with an independently enabled portrait, at estimated 1440p size; the transparent shell retains a 6.3 UI-unit divider at 20-unit health height. The final PNGs and packaged TGAs share the same pixels. Only the Shaman shell and matching power texture changed: the other 250 runtime textures, including all 126 portrait/hub/minimap assets, are unchanged from main.

Source/media/provenance and exact Retail/Forever 0.7.4 package checks pass. SharedMedia integration uses the consumers' existing library; no third-party addon code or textures are bundled. Shared Stone reuses an already distributed health texture.

No WoW interaction or in-game testing was performed. Provider menu registration was verified from the supplied EllesmereUI source and pinned ElvUI source, with behavior exercised in the offline host. Actual menus, rendering, clipping and secure runtime behavior still require the user's manual checks. See SETTINGS.md and VALIDATION.md.

---

# Build 0.7.3 plain stone health and city NPCs

152 Lua 5.1 tests and six Python artwork regressions pass. Ten added Lua checks cover twelve city affiliations on both Retail and Forever, shared portrait/shell selection, independent toggles, player/focus behavior, automatic versus fixed modes, modern/legacy localization, controlled units, unknown affiliations, bounded cache invalidation, secret/missing metadata, combat deferral and the five known guard IDs when tooltips are absent.

The added material regression checks every health export for an opaque, color-neutral 256 × 32 stone fill, matching preview pixels, bounded tonal variation and provenance that excludes shell ornaments. All 42 health TGAs changed; the other 210 runtime artwork files are byte-identical to merged main `c42af81`. Six artwork tests also preserve all prior shell-fitting checks and the 126 pre-audit portrait/hub/minimap hashes.

The browser preview was inspected with rose Paladin health and green Undead Target health, including the matching portrait toggle. It renders the actual packaged health pixels with the original shells and thick dividers. Source/media/provenance and exact Retail/Forever 0.7.3 package checks pass. No reference-addon assets, code or branding are included.

No WoW interaction or in-game testing was performed. City matching requires a public matching affiliation or known guard ID, rather than the player's zone; unrecognized NPCs keep their previous automatic-mode fallback. Actual city tooltips, provider rendering and combat behavior still need the user's in-game checks in VALIDATION.md.

---

# Build 0.7.2 EllesmereUI integration

142 Lua 5.1 tests and five Python artwork regressions pass. Fourteen new Lua checks cover the supplied EllesmereUI 9.2.9 object structure on both client paths: independent portrait/shell toggles for all three units, explicit and automatic provider selection, inactive/transparent providers, coexistence with Blinkii, delayed/replaced frames, original stack bounds, all 42 theme fits without cumulative shrinkage, combat queuing, restoration after provider redraws, hidden/forbidden/secret geometry, supported versus texture-only layouts, stock portrait masks and side changes, default/explicit layers, diagnostics, scale changes and partial provider redraws.

The offline fixture describes public object shape only; no Ellesmere code is copied or executed. Read-only inspection hashes for the supplied release are in addon-sources.json. The mock rejects functional native writes and all presentation writes in combat. It permits only the documented fill texture/UV and bar layout edits. Stable ticks do not repeat layout or fill writes. Root size, clipping and parent relationships are untouched.

All 252 runtime artwork files are unchanged from merged 0.7.1. Source, transparency, provenance and exact Retail/Forever 0.7.2 package checks pass. No third-party addon code or textures are included.

No WoW interaction or in-game testing was performed. The reported Ellesmere failure exposed the missing bar adapter; active-provider selection, portrait masks and opaque-panel layering are also corrected offline. User confirmation is still required for renderer clipping, labels/prediction overlays, profile redraw timing and secure behavior. Full Ellesmere shells currently require horizontal attached power below/aligned with health; other layouts receive available textures only. See VALIDATION.md for the user-run checks and use `/jui status` to report any remaining issue.

## Previous build 0.7.1 independent unit-frame artwork

128 Lua tests pass. Coverage includes four portrait/shell toggle combinations on Retail and Forever; legacy migration/import/export; initialized Forever bar bindings; unavailable or restricted fill metadata; external portrait providers; and source-proportional power-bar fitting. Geometry tests cover restoration, combat deferral, later native layouts and stable ticks without repeated writes. The mock permits only the intended out-of-combat power geometry and fill appearance writes, and rejects functional native mutations.

Five artwork tests verify the 126 unchanged portrait/hub/minimap TGAs against pre-audit commit `72c5c69`, reproduce all 42 source-faithful shells, check transparent interiors and source-proportional dividers, retain shoulder/tip regression markers, and reject invalid geometry. Priest and Draenei separators remain more than six UI units at a 20-unit health height. Source/media/provenance and exact package checks cover all 252 runtime assets.

All 42 shell exports were inspected on a dark contact sheet. Browser checks cover Priest Player and Paladin Target at 1440p, plus Draenei Focus at 1080p, with the original artwork beside the native fitting preview and independent toggles. These are offline estimates, not live screenshots.

No WoW interaction or in-game testing was performed. The reported Forever failure has not been reproduced in a live client; coupled toggles and the all-or-nothing shell/fill path are corrected and tested offline. User validation is still required, especially native layer ordering, names, resources, vehicles, prediction overlays and secure behavior. Use the per-unit `/jui status` lines if an issue remains.

## Historical 0.7.0-art.2 audit (reverted in 0.7.1)

The 42 identities were inspected in both Player and mirrored Target/Focus portrait-and-shell compositions, plus the portrait-only, hub and minimap collection sheets. The same name-clearance crop removed upper-corner pixels in all 42 shells; the outer padding cut a few tip pixels in 27. Shell fit version 2 preserves those details outside the unchanged clear regions. New fitting records require zero visible pixels discarded by either mask.

All 126 portrait/hub/minimap runtime textures and 84 fill textures are byte-identical to art.1. Original generated sources are unchanged. The 42 fitted shell textures were rebuilt. Two synthetic fitting regressions check that an inward shoulder and an outer crown tip survive export while every functional opening stays empty, and that invalid source geometry fails. The existing 117 Lua tests and complete source/media/package checks also pass.

Browser checks cover Priest Player at 1440p, Priest Target at 4K, and Gnome Focus at 1080p, including matching gallery orientation and transparent shell inspection. These are synthetic baseline previews. No new live-client result is claimed; custom offsets, UI scale, native masks and real layer ordering still need Retail/Forever confirmation. See [audit findings](ARTWORK-AUDIT.md).

## Previous validation record (0.7.0-art.1)

**117 Lua 5.1 tests passed.** The default portrait-only mode still performs no native writes. Opt-in full skins change only fill texture/UV appearance; the mock rejects all functional native writes and all native appearance writes during combat.

The skin tests cover both client adapters, shared 42-theme geometry, independent unit settings, exact atlas/file/UV restoration, native redraw and replacement regions, UV-only redraws, missing fills, combat queues, hidden bars, effective scale, forbidden/secret metadata, option toggles, scoped imports and reused frames/hooks. Compatibility tests cover Blinkii, mMediaTag, ElvUI and Ellesmere source discovery, active masks, source priorities, hidden/missing sources and suspending/restoring native skins across source switches. All 119 measured upstream masks were separately checked against pinned hashes and the configured containing openings.

Source/media checks cover 24 active Lua sources and 252 runtime TGAs: 42 portraits, 42 hubs, 42 minimaps, 42 sculpted unit shells and 84 painted fill textures. Surround alpha, native clear regions, uniform fit, provenance and exact Retail/Forever package payloads are checked. The unit skins alone may restore a captured native atlas; all other prohibited functional API checks remain in force.

The new local side-by-side preview uses encoded assets at estimated native game size. Shaman Player at 1440p, mirrored Shaman Target at 4K, and Undead Focus at 1080p were visually inspected for clear names/badges and fitted shell sections. **In-game validation remains pending.** In particular, verify masks, prediction overlays, power-type changes, vehicles, secure clicks and restoration after combat in both clients. The browser and mock host do not emulate WoW's secure renderer.

## Previous validation record (0.6.0-compat.2)

Build: **0.6.0-compat.2**. Date: **2026-09-24**.

**95 Lua 5.1 tests passed**, with zero writes to mocked native frames.

The offline host checks five owned decorative roots, mouse transparency, separate Retail/Forever adapters, forbidden/restricted native reads, effective scale, anchors, repeated refresh reuse, combat deferral, profile/import validation and the movable classic options window.

Portrait tests cover 42 distinct assets, Player/Target/Focus independence, class changes during combat without geometry writes, restricted/missing/NPC identity fallback, race/faction/fixed modes, protected texture deferral, native portrait visibility, and conversion from old full-frame shells. Portrait fit version 5 measures the painted inner contour and conforms it to a shared center with distinct Player (radius 60, squared lower corner) and round Target/Focus (radius 58) openings. All 42 choices use the same 128-unit frames and X/Y offsets. The test host checks the correct atlas half on both clients; pixel checks cover both native interiors and lower-wrap contact. Natural hanging detail is retained; there is no secondary level-badge cutout or horizontal bottom crop. The class symbols are part of the artwork rather than pasted circular badges.

Hub tests cover 42 selections with identical geometry, player-only automatic identity, guarded fallback, combat deferral, atomic module-scoped export/import and a paginated gallery that assigns textures only to visible thumbnails. Width changes preserve endcaps and center ornament. A regression check at multiple width/height limits verifies that all five slices retain full vertical artwork, so hanging details cannot be cropped by their texture coordinates.

Source/media/package checks verify 22 active Lua sources, the data-only registries, absence of native mutation APIs, 126 RGBA textures, power-of-two sizes, source/file hashes, and every pixel of the reserved portrait and hub opening regions. Packages contain 42 portraits, 42 hubs and 42 minimaps; historical experiments and downloaded source PNGs are excluded.

The release preparation rebuilt the media from repository-relative retained originals using the pinned Pillow/NumPy versions. Art.1 runtime texture and preview hashes were unchanged by the portability cleanup; Art.2 intentionally changes the portrait pixels and atlas dimensions for the fitting correction. Generation records no longer depend on a local image-service cache. The PR workflow runs the Lua host, source/media checks and exact Retail/Forever archive verification.

The local galleries use actual game-resolution pixels. All 42 portraits and all 42 sculpted hub compositions were visually reviewed, including alpha against dark backgrounds. Browser fitting checks covered the Player at 1440p, mirrored Mage Target at 4K, and Hunter Focus at 1080p/small scale. Hub previews were checked at widths 600 and 900, 1080p/1440p/4K, with unbroken seams, retained hanging ornament and a clear central guide. These are synthetic native-frame guides and estimated target pixel sizes, not live-client certification.

**0.6.0-compat.2 live validation remains pending.** Art.1 screenshots confirmed the artwork appears in game and exposed the lower-wrap gap now corrected in offline fitting previews. Check fit, target/focus switching, combat, Edit Mode changes and reload/logout persistence in both clients. Forever build 69913's previously reported missing saved table is not fixed by this change. Arbitrary bar layouts remain a manual fitting concern. Addon portrait and main-bar adapters are implemented; live compatibility validation remains pending.

## Minimap update validation

Seven added Lua tests cover native diameter/effective scale on Retail and Forever, saved adjustments, hidden/forbidden/missing anchors, 42 interchangeable textures with identical geometry, player-only automatic selection with guarded fallback, protected combat deferral, atomic module-scoped profile import/export, and reusable paginated thumbnails. Pixel checks verify the entire shared circular opening and eight-pixel canvas margin, along with all 42 matching portrait/hub reference hashes. Both archives contain 162 files and 126 runtime TGAs.

The complete minimap collection was inspected on a solid background, and detached matte fragments were removed. A Nightborne background revision removes the remaining attached checker fringe. Warrior's revised portrait, hub and minimap have plain cloth without faction emblems. The minimap gallery previews the exact encoded pixels and native opening at selectable diameter, resolution and effective scale. These remain synthetic checks; live-client fitting, edge clipping and secure behavior need in-game confirmation.

## Addon compatibility validation

Eleven additional Lua tests cover Blinkii priority and explicit per-unit sources on both client adapters; round and mirrored opening registration; scale and size changes; late loading, clickable/display replacement and removal; external alpha, visibility and portrait replacement; disabled/health-overlay portraits; Ellesmere detached mask bounds; forbidden/restricted inputs; combat deferral; ElvUI/Ellesmere main action-bar sources; and scoped profile/export/import/options behavior. The initial compatibility build passed 86 tests with zero native-frame writes.

Source snapshots are pinned in addon-sources.json. All 47 measured mask files (40 Blinkii, seven Ellesmere) were checked against their recorded hashes and every occupied pixel was verified to fit the configured containing circle. Source/media checks and exact Retail/Forever archive verification pass. No third-party Lua or textures are packaged. These offline checks cannot validate the real secure runtime or visual fit in WoW.

## mMediaTag follow-up validation

Nine additional Lua tests bring the suite to 95. They cover 4.x and 3.x registry discovery for Player/Target/Focus; modern Retail and legacy Forever mock paths; automatic priority and explicit selection; mask geometry independent of zoom; mirrored and custom masks; inherited ElvUI alpha/visibility/scale; stable idle polling; late loading, replacement and removal; stale-global/legacy rejection; disabled legacy fallback; forbidden/secret inputs; combat deferral; and scoped options/export/import persistence. No provider frames are written.

The 48 current and 24 legacy mMediaTag mask files were measured from pinned upstream revisions and recorded with SHA-256 hashes. Their nonzero-alpha pixel centers fit the stored containing radii, rounded upward to six decimal places. No upstream Lua or media is shipped. This adapter does not establish mMediaTag's client support; real WoW fitting and secure-runtime checks remain pending.
