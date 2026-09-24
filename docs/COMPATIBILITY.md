# Phase 1 compatibility boundaries

| Client | Package interface | Research baseline | Runtime path |
|---|---:|---|---|
| Retail | 120100 | 12.1.0.69875 | Compatibility/Retail.lua; accepts the 12.x interface family and reports baseline differences |
| WoW Forever | 16001 | 1.60.1.69913 | Compatibility/Forever.lua; accepts only the verified interface identifier |

**Neither client is certified by the offline tests.** The old alpha builds' live attachment counts do not validate this new renderer.

Both paths explicitly resolve Minimap, PlayerFrame, TargetFrame, FocusFrame and MainActionBar. Each adapter separately validates native portrait container/region visibility; both check IsForbidden before access. Forever loads Camelot overrides. Bars, level decorations and native layout remain untouched. Missing roots or portraits remain native.

The five roots are verified against pinned Blizzard source snapshots. Exact URLs and hashes are in [phase1-sources.json](phase1-sources.json). Retail revision: `78282522143e25c3540583734fd192c3d69be910`. Forever revision: `70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e`. The earlier complete unit-frame load-order research remains in source-load-order.json.

Blinkii's Portraits, ElvUI and EllesmereUI now have read-only portrait adapters for Player, Target and Focus on either supported client. Automatic selection prioritizes Blinkii's active registry, then visible ElvUI and EllesmereUI roots, then Blizzard. Explicit per-unit choices wait for that provider instead of silently falling back. Portrait-disabled/health-overlay configurations produce no surround. Source switches retain combat deferral and reuse addon-owned frames. See [setup and fit limits](ADDON-COMPATIBILITY.md); inspected upstream revisions and mask measurements are pinned in [addon-sources.json](addon-sources.json). This is implementation support, with in-game validation still pending.

No party, raid, boss, pet, extra ability, flyout, micro-menu, bag, tracking-bar, chat or tooltip module is loaded. Nameplates and functional indicators are not inspected. Identity-based artwork uses guarded class/race/faction tokens only; unavailable data uses Neutral.

The hub follows MainActionBar's visibility and effective scale. It defaults to screen-bottom positioning; FRAME mode follows the native bar's position instead. It can also follow ElvUI_Bar1 or EABBar_MainBar, selected automatically or with hubSource. It does not create a vehicle/override replacement. The shared Minimap frame remains the map anchor under both UI suites; circular map shapes fit the existing circular artwork. Blizzard retains action paging, bindings, secure click behavior and vehicle transitions. Those transitions still need live testing.
