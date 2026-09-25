# Artwork credits and provenance

Class, race, Alliance and Horde crest images: Blizzard Entertainment. World of Warcraft and Warcraft are trademarks or registered trademarks of Blizzard Entertainment. JiberishUI is an independent addon and is not endorsed by Blizzard.

The requested website emblems are visual references for the generated portrait ornaments and action hubs. Their central symbols are integrated into layered artwork; the website's circular icon holders are not pasted onto it. Exact source pages, asset URLs and original hashes are recorded in ARTWORK-SOURCES.json. Original downloads are retained under artwork/official-crests/originals in the development workspace; only prepared decorative textures are installed.

Surrounds, rails and the neutral compass use JiberishUI compositions generated through the built-in image tool, then locally processed under the user's instruction. Prompt sets and originals are retained in artwork/portraits and artwork/hubs. The official emblems and the underlying Warcraft designs are not claimed as JiberishUI original artwork.

No separate written permission from Blizzard has been obtained or is implied by this credit. This record documents provenance, not a license or legal opinion.

## Minimap collection and Warrior revision

The 42 matching minimaps were created with the built-in image generation tool from the existing hub/portrait references. `artwork/minimaps/generation-prompts.json`, `generation-results.json` and `manifest.json` retain prompts, workspace sources and hashes. Alpha cleanup and shared circular fitting use the user's authorized local Python processing. `artwork/warrior-neutral-review/prompt.txt` records the edit removing faction marks from all three Warrior components. These changes do not represent a new license grant for the underlying referenced Blizzard motifs.

## Plain stone health material

Build 0.7.3 uses a new original stone material generated with the built-in image tool, then cropped, reduced to grayscale and fitted locally for 256 × 32 health fills. The source is `artwork/unit-frames/references/plain-stone.png`; its exact prompt and generation record are in `plain-stone-generation.json` beside it. No reference-addon assets, code or branding were used. All 42 health exports use this unmarked material and retain native tinting. Existing ornamental shells, power materials, portraits, hubs and minimaps are unchanged.

The 0.7.4–0.7.5 Shaman unit-frame revisions use the recorded official Shaman crest as a visual reference for an integrated elemental mask and a carved totem counterpart. The built-in image tool produced the edit; user-authorized local processing removes its painted checkerboard. Sources, prompt and extraction hashes are in `artwork/unit-frames/sculpted/shaman-elemental-correction.json`, `shaman-neutral-correction.json` and `shaman-alpha-report.json`. The final revision balances the endcap and replaces red cloth/tusks with faction-neutral wood, stone and rope. Other Shaman families retain their existing integrated elemental motifs.

## Cast borders and Mage emblem accuracy (0.8.0)

The 42 cast borders are separate built-in image-tool generations inspired by the matching unit-frame rails. Complete tips, leaves and bindings are retained outside the bar opening. Prompts and originals are in `artwork/cast-bars/generation-prompts.json` and `references/`; prepared alpha PNGs and their TGA provenance are in `assets/` and `manifest.json`. User-authorized local processing removes generated neutral backgrounds and registers a shared clear opening.

The supplied Mage class emblem guides localized corrections on the portrait, unit shell and cast border: a horizontal arcane lens with a pale diamond center, stacked gemstones, fluted lower rays and cyan book runes. Exact built-in editing prompts, before/generated images and the localized application record are in `artwork/mage-emblem-correction/`. Unchanged hub/minimap designs retain their historical portrait reference snapshots so their source hashes stay accurate.

The Mage cast-border ends were subsequently simplified with the built-in image tool into compact bronze brackets, violet crystals and cyan rune accents. The exact edit prompt is in `artwork/cast-bars/mage-simplification/generation.json`; its `before.png` retains the earlier book/eye cast border. Portrait and unit-shell emblems were not changed by this cast-only simplification.
