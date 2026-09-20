# Artwork provenance and rebuilding

The original four race families are adapted from Blizzard's installed classic Warcraft III UI data, build **3.0.0.24268**. Those four families contain Blizzard artwork; no ownership of that source artwork is claimed. The expanded library also includes **11 original generated material families**, described below. JiberishUI is not an official Blizzard product.

The source CASC storage was read from `/Applications/Warcraft III`. The game installation was not modified. Classic `war3.w3mod` files were selected explicitly; `_hd.w3mod` and `_de.w3mod` overrides were not used.

For each of `human`, `orc`, `nightelf`, and `undead`:

| Source pattern inside CASC | Dimensions | Use |
|---|---|---|
| `war3.w3mod:ui\widgets\escmenu\RACE\RACE-options-menu-border.dds` | 512 × 64 | Eight-cell source strip for normalized corners and repeatable edges |
| `war3.w3mod:ui\console\RACE\RACEuitile-timeindicatorframe.dds` | 256 × 128 | Portrait/bar ornaments and endcaps |
| `war3.w3mod:ui\console\RACE\RACEuitile01.dds` | 512 × 512 | Inspected as console context, not resized into frame textures |

The first four strip cells are vertically stored edge sections. Top/bottom sections are cropped and rotated 90 degrees clockwise. Corners are cropped from their 64 × 64 cells to 32 × 32 usable regions. Separate 32 × 64 / 64 × 32 edge files ensure repetition never samples another atlas cell. Native WoW portraits/masks remain intact; the portrait surround is decorative.

Each theme includes eight normalized pieces, a composed 128 × 128 portrait surround, four 64 × 64 button states, and a 256 × 128 ornament. A shared opaque white 8 × 8 fill permits accurate tinting. The runtime uses the separate pieces to fit portraits, bars, and compact frames; the composed portrait is also supplied as an asset reference. Button pressed/highlight/checked states use distinct brightness levels while preserving Blizzard's state visibility and blending.

The classic families contribute 57 textures including the shared white fill. With the expanded library, `assets.json` records all **211** output dimensions, nonzero-alpha bounds, exact source path/crop, transformation, and SHA-256. Outputs are uncompressed 32-bit RGBA TGA with power-of-two dimensions and lowercase paths. `skin-reference.png` retains the four original themes; `border-showcase.png` and `skin-library-*.png` show the expanded catalog. These are offline qualifications; seamless appearance at every runtime UI scale remains an in-game gate.

## Original material library

Eleven material masters were made with the **built-in image_gen tool**: Dwarven Forge, Moonstone, Arcane Crystal, Fel Obsidian, Black Basalt, Clockwork, Shadow Steel, Jade Bamboo, Dragon Scale, Tribal Totem, and Sacred Gold. This is original Warcraft-inspired fantasy artwork, not extracted official race/class emblems.

The original transparent PNGs are preserved in `artwork/masters/`; exact generation prompts are in `artwork/prompts.json`. Each master is a square perimeter frame with a transparent center. The masters are source assets in the repository, not large runtime textures in the addon ZIPs. No generated file is referenced from an external cache.

`tools/build_library.py` performs deterministic production conversion: measured corner crops; perpendicular alpha-bound normalization for rails; 32 × 32 corners; 64 × 32 / 32 × 64 edge tiles with mirrored periods; composed portrait and button states; and a central rail ornament. Mirrored periods have identical endpoint pixels to avoid discontinuities where a tile repeats. Masks and alpha are retained, and the original masters are unchanged. Small-frame visual suitability is still subject to in-game checks.

The 52 catalog presets share 15 material families (the original four plus these eleven). Race/class/faction variants use runtime tint and appearance defaults; they do not duplicate or claim unique artwork for each identity. Standard styles default to no ornaments. Selecting a preset preserves explicit global/group overrides and does not automatically change health/power color modes.

To rebuild the expanded library from the included source files:

```sh
python3 tools/build_library.py
python3 tools/check.py
```

This requires Pillow but no game installation. `tools/skin_catalog.py` is the canonical catalog; it writes the Lua catalog and JSON reference. Rebuilding the original four families with `tools/build_art.py` preserves expanded-family manifest entries, and rebuilding the expanded library preserves the original game-derived entries.

Rebuilding requires a local Warcraft III installation, a C++ compiler, CascLib, and Python with Pillow. The development tools used [CascLib revision `2a280f5`](https://github.com/ladislav-zezula/CascLib/tree/2a280f5a231966dc5d1b534978dd9f9f04a374cd), which stays outside the addon package.

```sh
python3 tools/build_casc.py
python3 tools/extract_art.py '/Applications/Warcraft III'
python3 tools/build_art.py
python3 tools/check.py
```

The extraction helper is a read/list/export utility. CascLib's local storage reader requests read/write file handles internally, which required sandbox escalation on this workstation even though extraction did not write into the game. The raw DDS and build tools remain in ignored local caches and are not shipped.
