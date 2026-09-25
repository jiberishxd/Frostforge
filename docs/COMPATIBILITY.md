# Phase 1 compatibility boundaries

| Client | Package interface | Research baseline | Runtime path |
|---|---:|---|---|
| Retail | 120100 | 12.1.0.69875 | Compatibility/Retail.lua; accepts the 12.x interface family and reports baseline differences |
| WoW Forever | 16001 | 1.60.1.69913 | Compatibility/Forever.lua; accepts only the verified interface identifier |

**Neither client is certified by the offline tests.** The old alpha builds' live attachment counts do not validate this new renderer.

Both paths explicitly resolve Minimap, PlayerFrame, TargetFrame, FocusFrame and MainActionBar. Each adapter separately validates native portrait container/region visibility; both check IsForbidden before access. Forever loads Camelot overrides. Level decorations and Blizzard health-bar geometry remain untouched. Unit-frame artwork changes fill textures and fits the existing power bar below the thick painted separator, restoring its original points and size when disabled. The independent stock-wide stone toggle textures health and power even without shells. Missing roots or portraits remain native.

The five roots are verified against pinned Blizzard source snapshots. Exact URLs and hashes are in [phase1-sources.json](phase1-sources.json). Retail revision: `78282522143e25c3540583734fd192c3d69be910`. Forever revision: `70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e`. The earlier complete unit-frame load-order research remains in source-load-order.json.

Blinkii's Portraits, mMediaTag & Tools, ElvUI and EllesmereUI have read-only portrait adapters for Player, Target and Focus. Automatic selection prioritizes Blinkii’s active visible portrait, then mMediaTag, visible ElvUI and EllesmereUI portraits, then Blizzard. A hidden or transparent portrait does not block later visible providers; an active replacement with its portrait disabled does not decorate leftover Blizzard frames. Explicit per-unit choices wait for that provider instead of silently falling back. Portrait-disabled/health-overlay configurations produce no surround. Source switches retain combat deferral and reuse addon-owned frames. See [setup and fit limits](ADDON-COMPATIBILITY.md); inspected upstream revisions and mask measurements are pinned in [addon-sources.json](addon-sources.json). This is implementation support, with in-game validation still pending.

mMediaTag 4.x is Retail-only and requires ElvUI. The adapter also recognizes the legacy 3.x portrait registry, with a mocked Forever-path check; this does not establish upstream mMediaTag support for Forever. Every external addon must itself run on the selected client. The mMediaTag adapter covers portraits; action bars continue through the ElvUI anchor and the minimap through the shared native root.

Party, raid, boss, pet and secondary-target support is limited to plain stone on existing health/power textures. No ornamental shells are added to those frames. No extra ability, flyout, micro-menu, bag, tracking-bar, chat or tooltip module is loaded. Nameplates and functional indicators are not inspected. Identity-based artwork uses guarded class/race/faction tokens only; unavailable data uses Neutral.

The hub follows MainActionBar's visibility and effective scale. It defaults to screen-bottom positioning; FRAME mode follows the native bar's position instead. It can also follow ElvUI_Bar1 or EABBar_MainBar, selected automatically or with hubSource. It does not create a vehicle/override replacement. The shared Minimap frame remains the map anchor under both UI suites; circular map shapes fit the existing circular artwork. Blizzard retains action paging, bindings, secure click behavior and vehicle transitions. Those transitions still need live testing.

Full skins use verified Mainline health/mana child paths on Retail. Forever first follows its initialized healthbar/manabar bindings, with verified child paths as a fallback. Inspected frames pass IsForbidden before access. See [unit skin details](UNIT-SKINS.md). Portrait providers and visibility do not disable bar styling. `unitFrameSource` independently selects Blizzard or EllesmereUI (AUTO prefers active Ellesmere frames). The supplied Ellesmere 9.2.9 public Health/Power objects are fitted within their original stack height; its clip container and all provider settings stay unchanged. Full shells require attached horizontal power below/aligned with health. Other layouts receive fill textures only. Both Ellesmere bar layouts restore on disable. Hidden provider bars hide the shell. ElvUI full-bar reskinning is not implemented.

## City affiliations and health materials (0.7.3)

All 42 skins share original plain stone health with the provider’s color; power materials and shell geometry are unchanged. City selection uses public NPC metadata, client-localized reputation names and a small known-guard fallback on both client paths. It is shared by all supported portrait/bar providers. Missing APIs or restricted identity retain the selected mode’s normal fallback. In-game validation is pending; see NPC-CITIES.md.

## Stock portrait/name and stone controls (0.8.2)

See [stock controls](BLIZZARD-CONTROLS.md). Native portrait-image alpha and name presentation changes are opt-in, reversible, per unit and applied outside combat. Stock-wide stone is enabled by default, independent of shells. It preserves native colors, values, masks and bar geometry. Exact stock-root and party/raid registry sources are pinned in [stock-frame-sources.json](stock-frame-sources.json).
