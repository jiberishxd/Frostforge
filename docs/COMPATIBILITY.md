# Phase 1 compatibility boundaries

| Client | Package interface | Research baseline | Runtime path |
|---|---:|---|---|
| Retail | 120100 | 12.1.0.69875 | Compatibility/Retail.lua; accepts the 12.x interface family and reports baseline differences |
| WoW Forever | 16001 | 1.60.1.69913 | Compatibility/Forever.lua; accepts only the verified interface identifier |

**Neither client is certified by the offline tests.** The old alpha builds' live attachment counts do not validate this new renderer.

Both paths explicitly resolve Minimap, PlayerFrame, TargetFrame and MainActionBar. Their separate files intentionally do not share unit-frame child paths. Forever's manifest adds Camelot overrides; the prototype does not inspect their portraits, bars, level decorations or internal structure. Missing roots remain native.

The four roots are verified against pinned Blizzard source snapshots. Exact URLs and hashes are in [phase1-sources.json](phase1-sources.json). Retail revision: `78282522143e25c3540583734fd192c3d69be910`. Forever revision: `70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e`. The earlier complete unit-frame load-order research remains in source-load-order.json.

ElvUI/Ellesmere-specific rendering is outside Phase 1. Their objects are never discovered, styled or moved by this prototype. Artwork follows the visibility/alpha of the native Blizzard roots, so it normally disappears when a replacement hides them. A replacement that leaves a native root visible may also leave its surrounding artwork visible; hide that JiberishUI component for testing. Compatibility with replacements is not claimed.

No party, raid, focus, boss, pet, extra ability, flyout, micro-menu, bag, tracking-bar, chat or tooltip module is loaded. Nameplates and functional indicators are not inspected.

The hub follows the native MainActionBar anchor and its visibility. It does not create a vehicle/override replacement or follow an external action-bar provider. Blizzard retains action paging, bindings, secure click behavior and vehicle transitions. Those transitions still need live testing.
