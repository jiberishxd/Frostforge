# Validation record

Build: **0.6.0-compat.1**. Date: **2026-09-24**.

**86 Lua 5.1 tests passed**, with zero writes to mocked native frames.

The offline host checks five owned decorative roots, mouse transparency, separate Retail/Forever adapters, forbidden/restricted native reads, effective scale, anchors, repeated refresh reuse, combat deferral, profile/import validation and the movable classic options window.

Portrait tests cover 42 distinct assets, Player/Target/Focus independence, class changes during combat without geometry writes, restricted/missing/NPC identity fallback, race/faction/fixed modes, protected texture deferral, native portrait visibility, and conversion from old full-frame shells. Portrait fit version 5 measures the painted inner contour and conforms it to a shared center with distinct Player (radius 60, squared lower corner) and round Target/Focus (radius 58) openings. All 42 choices use the same 128-unit frames and X/Y offsets. The test host checks the correct atlas half on both clients; pixel checks cover both native interiors and lower-wrap contact. Natural hanging detail is retained; there is no secondary level-badge cutout or horizontal bottom crop. The class symbols are part of the artwork rather than pasted circular badges.

Hub tests cover 42 selections with identical geometry, player-only automatic identity, guarded fallback, combat deferral, atomic module-scoped export/import and a paginated gallery that assigns textures only to visible thumbnails. Width changes preserve endcaps and center ornament. A regression check at multiple width/height limits verifies that all five slices retain full vertical artwork, so hanging details cannot be cropped by their texture coordinates.

Source/media/package checks verify 22 active Lua sources, the data-only registries, absence of native mutation APIs, 126 RGBA textures, power-of-two sizes, source/file hashes, and every pixel of the reserved portrait and hub opening regions. Packages contain 42 portraits, 42 hubs and 42 minimaps; historical experiments and downloaded source PNGs are excluded.

The release preparation rebuilt the media from repository-relative retained originals using the pinned Pillow/NumPy versions. Art.1 runtime texture and preview hashes were unchanged by the portability cleanup; Art.2 intentionally changes the portrait pixels and atlas dimensions for the fitting correction. Generation records no longer depend on a local image-service cache. The PR workflow runs the Lua host, source/media checks and exact Retail/Forever archive verification.

The local galleries use actual game-resolution pixels. All 42 portraits and all 42 sculpted hub compositions were visually reviewed, including alpha against dark backgrounds. Browser fitting checks covered the Player at 1440p, mirrored Mage Target at 4K, and Hunter Focus at 1080p/small scale. Hub previews were checked at widths 600 and 900, 1080p/1440p/4K, with unbroken seams, retained hanging ornament and a clear central guide. These are synthetic native-frame guides and estimated target pixel sizes, not live-client certification.

**0.6.0-compat.1 live validation remains pending.** Art.1 screenshots confirmed the artwork appears in game and exposed the lower-wrap gap now corrected in offline fitting previews. Check fit, target/focus switching, combat, Edit Mode changes and reload/logout persistence in both clients. Forever build 69913's previously reported missing saved table is not fixed by this change. Arbitrary bar layouts remain a manual fitting concern. Addon portrait and main-bar adapters are implemented; live compatibility validation remains pending.

## Minimap update validation

Seven added Lua tests cover native diameter/effective scale on Retail and Forever, saved adjustments, hidden/forbidden/missing anchors, 42 interchangeable textures with identical geometry, player-only automatic selection with guarded fallback, protected combat deferral, atomic module-scoped profile import/export, and reusable paginated thumbnails. Pixel checks verify the entire shared circular opening and eight-pixel canvas margin, along with all 42 matching portrait/hub reference hashes. Both archives contain 162 files and 126 runtime TGAs.

The complete minimap collection was inspected on a solid background, and detached matte fragments were removed. A Nightborne background revision removes the remaining attached checker fringe. Warrior's revised portrait, hub and minimap have plain cloth without faction emblems. The minimap gallery previews the exact encoded pixels and native opening at selectable diameter, resolution and effective scale. These remain synthetic checks; live-client fitting, edge clipping and secure behavior need in-game confirmation.

## Addon compatibility validation

Eleven additional Lua tests cover Blinkii priority and explicit per-unit sources on both client adapters; round and mirrored opening registration; scale and size changes; late loading, clickable/display replacement and removal; external alpha, visibility and portrait replacement; disabled/health-overlay portraits; Ellesmere detached mask bounds; forbidden/restricted inputs; combat deferral; ElvUI/Ellesmere main action-bar sources; and scoped profile/export/import/options behavior. The compatibility-only suite passes 86 tests with zero native-frame writes.

Source snapshots are pinned in addon-sources.json. All 47 measured mask files (40 Blinkii, seven Ellesmere) were checked against their recorded hashes and every occupied pixel was verified to fit the configured containing circle. Source/media checks and exact Retail/Forever archive verification pass. No third-party Lua or textures are packaged. These offline checks cannot validate the real secure runtime or visual fit in WoW.
