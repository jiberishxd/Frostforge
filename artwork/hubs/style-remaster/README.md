# Sculpted hub style update

All 42 class, race and faction hubs retain their recognizable endcaps, connecting rail and center ornament, with the substantial bevels, stronger volumes and material colors of the approved unit-frame and portrait artwork. Shaman uses carved totems and rope in place of the previous red drapes and teeth.

Each file in `records/` retains the exact image-generation prompt, previous hub target and matching unit-frame style reference. Generated production-matte originals are in `originals/`. The unit-frame references were read-only: `reference-lock.json` protects 211 approved reference and runtime files. No unit-frame or portrait image was edited for this update.

`tools/build_hubs.py` removes the green/magenta production matte, decontaminates edge pixels, applies the established registration and exports matching RGBA PNG/TGA pixels. The 2172 × 724 design canvas, 1024 × 512 runtime atlas, five full-height pieces, button opening and fitting controls are unchanged. `before/` retains the prior transparent artwork and manifest for comparisons, historical transparency tests and existing minimap provenance; minimap artwork was not regenerated.

The [hub gallery](../index.html) offers a previous-art comparison and checker, dark and light backgrounds. `tools/review_hub_restyle.py` refreshes seven contact sheets and the 42-item progress record. Originals, comparisons and records are development assets, excluded from the installable addon.

Validation covers exact PNG/TGA pixels, transparent margins and button openings, registration, source hashes, matte remnants and the approved-art lock. All 42 designs were visually reviewed. The gallery uses runtime atlas slices, but it does not establish live-client validation; no WoW interaction was performed.
