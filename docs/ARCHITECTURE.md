# Phase 1 rendering architecture

The active manifest loads one data-only Retribution Paladin theme, four modules, and shared services. No legacy renderer, colors, secure layout/docking code, provider adapters, settings skin, or native decoration hooks are loaded.

## Files and responsibilities

| File | Responsibility |
|---|---|
| Core/Core.lua | Module registry, lifecycle, input validation, safe frame reads, geometry, visibility, debug and commands |
| Core/ThemeManager.lua | Configuration-only theme registry; defaults plus per-component overrides |
| Core/ProfileManager.lua | Versioned Phase 1 namespace, sanitization, reset and bounded data-only backup |
| Core/Media.lua | Three packaged local texture paths |
| Compatibility/Retail.lua | Retail 12.x root discovery with forbidden-frame checks |
| Compatibility/Forever.lua | Separate Forever 16001 root discovery, acknowledging Camelot overrides |
| Modules/Minimap.lua | Own frame and textures for the Minimap anchor |
| Modules/PlayerFrame.lua | Own frame and textures for the PlayerFrame anchor |
| Modules/TargetFrame.lua | Own frame and textures for the TargetFrame anchor |
| Modules/ActionHub.lua | Own frame and textures for the MainActionBar anchor |
| Themes/Paladin/Retribution.lua | paladin_ret data and asset references only |

Each module creates an ordinary Frame directly under UIParent and two Texture objects. Core records ownership, configures those objects, and adds four debug line textures plus a FontString. No secure template, native child, parent write, attribute write, native function replacement, native texture setter, or native script hook is used.

The nonvisual event driver has no rendering regions and disables mouse input. Debug outlines cover the four rendering frames; no separate interactive debug UI is created.

## Coordinates and layering

Width and height are explicit artwork dimensions. An artwork frame's local scale is:

`anchor effective scale / UIParent effective scale * configured scale`

This accounts for native scaling and UIParent scaling exactly once. Its anchor references the live Blizzard root, so native movement follows automatically. X/Y are expressed in native-anchor units; dividing SetPoint offsets by configured scale keeps the requested offset stable when decorative size changes. Dimensions and native scale are polled, but artwork width/height do not automatically expand to wrap a resized, rotated, or rearranged bar group.

The default frame strata and texture layer are BACKGROUND, with frame level zero. Native art and controls remain untouched above the decoration. Users can change strata/layer independently. The crest is constrained within the owned frame rectangle and displayed at its intended 3:1 aspect. The main artwork is stretched to the configured footprint as a prototype fixture.

## Lifecycle and safety

At player login (or a load-on-demand login already in progress), Core initializes the profile, selects a compatible client path, discovers roots, and attaches only outside combat. ADDON_LOADED, PLAYER_ENTERING_WORLD, PLAYER_TARGET_CHANGED, PLAYER_REGEN_ENABLED, scale/display changes, and Edit Mode layout events request refreshes. Optional event-registration failures are reported, not fatal.

A 0.2-second read-only scan of four explicitly named roots catches visibility, effective scale, late loads and root replacement without native hooks or overrides. Stable polling performs no writes. Refreshes reuse frames, textures, labels and points.

Every discovery checks IsForbidden before native geometry/visibility reads, in both client paths. Missing, forbidden, zero-sized, or restricted geometry is skipped without accessing unit data. Unexpected errors are isolated per module, reported in status, and stale artwork is hidden when safe.

Configuration is saved immediately; a single dirty flag defers all geometry, new attachment, texture and debug changes through combat. PLAYER_REGEN_ENABLED applies the latest profile state. Existing artwork visibility/alpha follows the native anchor only if the owned root is unprotected; otherwise even those writes wait. New roots encountered in combat remain native. A replaced root cannot display old artwork at a stale anchor.

There are no native hooks to duplicate. If future redraw requirements justify hooksecurefunc, its callback must gate any received Blizzard frame through IsUsableFrame before access. This prototype requires no redraw hooks because it never modifies native artwork.

## Theme and profile boundaries

Theme registration rejects executable values, duplicate IDs, missing components and invalid exposed properties. The registered table is copied. Theme resolution copies defaults and adds only validated per-component overrides.

JiberishUIDB.phase1 version 1 contains theme, debug and modules. Previous top-level profiles/character assignments are preserved. A future Phase 1 version or an unknown database format is preserved read-only. Malformed property overrides fall back to theme defaults. Backups are length-limited JF1 data; imports validate the complete candidate before any mutation and never execute Lua.

All four components can be hidden immediately outside combat because no native snapshots need restoration. Reloading without the addon simply removes its artwork. A full restart is required for the initial transition from the older addon/file list.
