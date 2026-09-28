# Night Elf emblem refinement

Edited with the built-in imagegen tool, using the user's Blizzard Night Elf emblem reference. The right unit-frame end and left hub end now use swept silver glaive shoulders, a pointed violet helm, a dark disc and silver crescent, and a curved lower blade. The minimap moon is an upright silver crescent; the old curled hook is removed.

## Final transparent artwork

- [Unit-frame shell](../unit-frames/assets/race_nightelf.png) — 512 × 256; unchanged health/power registration.
- [Minimap surround](../minimaps/assets/race_nightelf.png) — 512 × 512; unchanged circular aperture.
- [Action hub](../hubs/assets/race_nightelf.png) — 2172 × 724; unchanged center, right endpoint and shared seams.

Runtime TGA exports are in `Frostforge/Media/UnitFrames`, `Minimaps` and `Hubs`. Only these three Night Elf textures differ from the retained 296-texture baseline.

## Exact editing prompts and provenance

1. [Initial reference-guided edits](generation.json).
2. [Production matte and unit-frame tip correction](production-edits.json).
3. [Moon silhouette revisions](moon-revisions.json).
4. [Removal of the old curled hook](moon-cleanup.json).
5. [Applied regions, source paths and hashes](applied.json).

Generated drafts and input images are retained here. `tools/apply_nightelf_emblem.py` integrates only the reviewed polygons into the original sources. Existing builders extract the production matte, preserve registration and encode the game textures. Tests lock every pixel outside those edit polygons and all other runtime artwork. In-game visual validation is still pending.

Emblem reference credit: Blizzard Entertainment.
