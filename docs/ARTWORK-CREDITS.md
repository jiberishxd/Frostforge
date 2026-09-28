# Artwork credits and provenance

Blizzard artwork, icons, emblems and other Blizzard game assets depicted or referenced are © Blizzard Entertainment, Inc. World of Warcraft and Warcraft are trademarks or registered trademarks of Blizzard Entertainment, Inc. Jiberish's Frostforge is an independent fan-made addon and is not affiliated with, sponsored by or endorsed by Blizzard Entertainment.

The requested website emblems are visual references for the generated portrait ornaments and action hubs. Their central symbols are integrated into layered artwork; the website's circular icon holders are not pasted onto it. Exact source pages, asset URLs and original hashes are recorded in ARTWORK-SOURCES.json. Original downloads are retained under artwork/official-crests/originals in the development workspace; only prepared decorative textures are installed.

Surrounds, rails and the neutral compass use Frostforge compositions generated through the built-in image tool, then locally processed under the user's instruction. Prompt sets and originals are retained in artwork/portraits and artwork/hubs. The official emblems and the underlying Warcraft designs are not claimed as Frostforge original artwork.

No separate written permission from Blizzard has been obtained or is implied by this credit. This record documents provenance, not a license or legal opinion.

## Minimap collection and Warrior revision

The 42 matching minimaps were created with the built-in image generation tool from the existing hub/portrait references. `artwork/minimaps/generation-prompts.json`, `generation-results.json` and `manifest.json` retain prompts, workspace sources and hashes. Alpha cleanup and shared circular fitting use the user's authorized local Python processing. `artwork/warrior-neutral-review/prompt.txt` records the edit removing faction marks from all three Warrior components. These changes do not represent a new license grant for the underlying referenced Blizzard motifs.

## Painted stone and hub transparency revision (0.8.1)

The shared stone material now uses a new original hand-painted fantasy surface with broad, restrained shading and quiet wear. It was generated with the built-in image tool; the exact prompt is retained in `artwork/unit-frames/references/plain-stone-generation.json`, beside the original `plain-stone.png`. Earlier material versions are retained under `references/revisions/`. Authorized local processing crops, converts to grayscale and encodes the 256 × 32 fill. All 42 health exports and the existing **Frostforge Stone** SharedMedia entry use this source. No reference-addon artwork, code or branding is bundled.

All 42 hubs were reviewed for enclosed matte/checkerboard residue. Twenty-four received alpha-only corrections using retained source-space masks; their original painted RGB and fitting geometry are preserved. Mask hashes, source hashes and review sheets are in `artwork/hubs/alpha-cleanup/`; [hub transparency notes](HUB-TRANSPARENCY.md) explain the verification. Original generated hub sources remain unchanged.

The Druid unit-frame antlers were corrected with the built-in image tool using the official Druid crest as a shape reference. Original/generated images and the exact prompt are retained in `artwork/unit-frames/sculpted/druid-antler-correction/`. Authorized local compositing confines the edit to the two upper endcaps; all other source pixels and the measured bar geometry are unchanged. The cast border retains a snapshot of the older unit-frame input used for its generation.

## Previous plain stone health material

Build 0.7.3 uses a new original stone material generated with the built-in image tool, then cropped, reduced to grayscale and fitted locally for 256 × 32 health fills. The source is `artwork/unit-frames/references/plain-stone.png`; its exact prompt and generation record are in `plain-stone-generation.json` beside it. No reference-addon assets, code or branding were used. All 42 health exports use this unmarked material and retain native tinting. Existing ornamental shells, power materials, portraits, hubs and minimaps are unchanged.

The 0.7.4–0.7.5 Shaman unit-frame revisions use the recorded official Shaman crest as a visual reference for an integrated elemental mask and a carved totem counterpart. The built-in image tool produced the edit; user-authorized local processing removes its painted checkerboard. Sources, prompt and extraction hashes are in `artwork/unit-frames/sculpted/shaman-elemental-correction.json`, `shaman-neutral-correction.json` and `shaman-alpha-report.json`. The final revision balances the endcap and replaces red cloth/tusks with faction-neutral wood, stone and rope. Other Shaman families retain their existing integrated elemental motifs.

## Cast borders and Mage emblem accuracy (0.8.0)

The 42 cast borders are separate built-in image-tool generations inspired by the matching unit-frame rails. Complete tips, leaves and bindings are retained outside the bar opening. Prompts and originals are in `artwork/cast-bars/generation-prompts.json` and `references/`; prepared alpha PNGs and their TGA provenance are in `assets/` and `manifest.json`. User-authorized local processing removes generated neutral backgrounds and registers a shared clear opening.

The supplied Mage class emblem guides localized corrections on the portrait, unit shell and cast border: a horizontal arcane lens with a pale diamond center, stacked gemstones, fluted lower rays and cyan book runes. Exact built-in editing prompts, before/generated images and the localized application record are in `artwork/mage-emblem-correction/`. Unchanged hub/minimap designs retain their historical portrait reference snapshots so their source hashes stay accurate.

The Mage cast-border ends were subsequently simplified with the built-in image tool into compact bronze brackets, violet crystals and cyan rune accents. The exact edit prompt is in `artwork/cast-bars/mage-simplification/generation.json`; its `before.png` retains the earlier book/eye cast border. Portrait and unit-shell emblems were not changed by this cast-only simplification.

## Frostforge identity and settings material (0.9.0)

The owner-approved transparent penguin logo is retained in `docs/images/logo.png`, with its generation and alpha-processing record in [LOGO-SOURCE.md](images/LOGO-SOURCE.md). A 512 × 512 RGBA TGA supplies the in-game icon and header. The subtle settings background is a square center crop from an original built-in image-tool generation; its full source and exact prompt are retained in `artwork/settings/sources/`. Native Blizzard borders and desaturated, blue-tinted button textures supply the controls. The generated border is not used at runtime.

Build 0.9.3 refines only the Night Elf unit-frame right emblem, hub left emblem and minimap moon using the supplied Blizzard Night Elf emblem. `artwork/nightelf-emblem-update/` retains the reference, exact built-in imagegen editing prompts, generated production mattes, before images and localized application record. Standard local alpha extraction, fitting and TGA encoding preserve the existing bar openings, hub seams and circular map aperture. Historical style references are retained. This adds no license grant for the referenced Blizzard motif.

## Notices and reuse

The notice above is also available in the in-game Guide and the repository README. Use it on the CurseForge project page; [listing text](CURSEFORGE.md) is provided for that purpose. The notice applies to Blizzard assets and underlying designs, not to all Frostforge code or every original composition.

Blizzard's [Legal FAQ](https://www.blizzard.com/en-sg/legal/c1ae32ac-7ff9-4ac3-a03b-fc04b8697010/blizzard-legal-faq) asks fansites to retain appropriate copyright, trademark and other notices. It describes conditional permissions, not an unrestricted license for every bundled asset or modification. Attribution alone does not grant permission; review the terms applicable to each asset before distribution.

## Illustrated setup tour (0.9.7)

The owner supplied the in-game example retained at `docs/images/setup-ingame.png` specifically for the setup wizard. Its resized runtime capture preserves the complete scene and aspect ratio. The other capture is the current settings preview exported from the addon’s Lua UI in the offline host; native Blizzard fonts/borders are approximated by that preview. `tools/build_setup_media.py` reproducibly exports their padded TGA textures and source hashes. None of the 296 existing art assets is changed.
