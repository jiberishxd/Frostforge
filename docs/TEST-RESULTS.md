# Validation record

Build: **0.4.0-art.1**. Date: **2026-09-21**.

**67 Lua 5.1 tests passed**, with zero writes to mocked native frames.

The offline host checks five owned decorative roots, mouse transparency, separate Retail/Forever adapters, forbidden/restricted native reads, effective scale, anchors, repeated refresh reuse, combat deferral, profile/import validation and the movable classic options window.

Portrait tests cover 42 distinct assets, Player/Target/Focus independence, class changes during combat without geometry writes, restricted/missing/NPC identity fallback, race/faction/fixed modes, protected texture deferral, native portrait visibility, and conversion from old full-frame shells. Portrait fit version 4 uses a shared [8,8,210,244] registration envelope and primary portrait/teardrop/bar clearance. Natural hanging detail is retained; there is no secondary level-badge cutout or horizontal bottom crop. The class symbols are part of the artwork rather than pasted circular badges.

Hub tests cover 42 selections with identical geometry, player-only automatic identity, guarded fallback, combat deferral, atomic module-scoped export/import and a paginated gallery that assigns textures only to visible thumbnails. Width changes preserve endcaps and center ornament. A regression check at multiple width/height limits verifies that all five slices retain full vertical artwork, so hanging details cannot be cropped by their texture coordinates.

Source/media/package checks verify 18 active Lua sources, the data-only registries, absence of native mutation APIs, 85 RGBA textures, power-of-two sizes, source/file hashes, and every pixel of the reserved portrait and hub opening regions. Packages contain 42 portraits, 42 hubs and the existing minimap; historical experiments and downloaded source PNGs are excluded.

The release preparation rebuilt the media from repository-relative retained originals using the pinned Pillow/NumPy versions. All runtime texture and preview image hashes were unchanged. Generation records no longer depend on a local image-service cache. The PR workflow runs the Lua host, source/media checks and exact Retail/Forever archive verification.

The local galleries use actual game-resolution pixels. All 42 portraits and all 42 sculpted hub compositions were visually reviewed, including alpha against dark backgrounds. Browser fitting checks covered the Player at 1440p, mirrored Mage Target at 4K, and Hunter Focus at 1080p/small scale. Hub previews were checked at widths 600 and 900, 1080p/1440p/4K, with unbroken seams, retained hanging ornament and a clear central guide. These are synthetic native-frame guides and estimated target pixel sizes, not live-client certification.

**Live validation remains pending.** Check fit, target/focus switching, combat, Edit Mode changes and reload/logout persistence in both clients. Forever build 69913's previously reported missing saved table is not fixed by this change. Arbitrary native bar layouts and replacement-UI integration are not claimed.
