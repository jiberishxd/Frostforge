# JiberishUI

Standalone border skins for Blizzard's unit frames and action bars. The library has **52 choices across 15 material families**: race, class, faction, and standard styles. Human remains the default. Every style can be selected globally or per frame group.

**Version 0.1.0-alpha.2 is an implementation for testing, not a compatibility-certified release.** Artwork has been prepared and measured, both source baselines have been traced, and offline tests pass. In-game combat safety, visual fit, and persistence on both clients remain release gates. No game installation or saved settings were changed during development.

New highlights include Dwarf / Ironforge, Night Elf Moonwell / Ancient Grove / Sentinel, Mage Arcane Crystal, Warlock Fel Covenant, and standard Black Stone, Slate, Obsidian, Silver Steel, Aged Bronze, Ivory Gold, Forest Wood, and Frost Stone. There are presets for all 13 classes, 26 race identities, and Alliance/Horde. Related presets deliberately share artwork and use different palettes; the library contains 15 material families, not 52 independently painted sets. See `docs/SKIN-LIBRARY.md` for the full mapping.

## Install and use

1. Choose the matching archive in `dist`: Retail (interface **120100**, audited build **12.1.0.69875**) or Forever (interface **16001**, audited build **1.60.1.69913**).
2. Extract its single `JiberishUI` folder into that client's `Interface/AddOns` directory. Avoid an extra nested folder.
3. Start the client or reload its UI, enable JiberishUI, and open **Settings → AddOns → JiberishUI**, `/jui`, or `/jiberishui`.
4. Choose Global or a frame group on the left, then **Browse styles**. Filter by category or search, page through the previews, and click a style to apply it. Color-mode buttons still cycle choices. Use **Use global settings** to clear that group's overrides.
5. Use Blizzard Edit Mode for movement, dimensions, and spacing. JiberishUI controls decorative thickness, inset, opacity, tint, and ornament size. Narrow variants clamp the requested thickness.

During combat, settings are saved and the synthetic preview updates; live changes apply afterward. Disabling a module requires **Reload UI**, which reconstructs the native frame state. Re-enable before reloading to cancel that disable request. To remove every customization, disable the addon and reload. Disabling Global can be overridden by explicitly enabled groups; use the addon checkbox to turn everything off.

The Profiles page supports named copies, per-character selection, reset, export, and import. Imports replace the active profile; copy it first if you want a backup. Exports are bounded, plain data in the `JUI1` format and never execute Lua. Retail and Forever have separate saved-variable stores. Forever build 69913 has a reported restart-persistence problem, not reproduced here; retain an export until local restart testing succeeds.

## Coverage

Implemented discovery includes player, target, focus, pet, boss, target-of-target, focus-target, portrait party/pets, compact party/pets, raids, main/additional action bars, pet/stance/possess/override buttons, extra/zone buttons, flyouts, and Forever multicast/totem buttons. Main-bar border art and both endcaps are decorated independently; Forever endcaps retain their own Edit Mode containers.

Native health/power colors remain the default. Custom modes use a white fill with the native mask. Health supports fixed and class/reaction colors; power supports fixed and power-type palettes. Disconnected, dead, tapped, unavailable, and restricted states fall back to native presentation. Compact frames configured for threat-based health coloring keep native health colors.

Casts, auras, class resources, predictions, absorbs, cooldowns, threat/selection/proc indicators, keybindings, and click behavior remain under Blizzard's control. Their independent reskinning, nameplates, minimap, chat, bags, tooltips, and other windows are outside this release. Custom endcaps/ornaments and borders still require the visual checks in `docs/VALIDATION.md`, especially with dense layouts.

Known overlapping replacements are skipped: ElvUI; relevant EllesmereUI unit/raid/action modules; Shadowed Unit Frames; PitBull; Bartender; Dominos; and Masque's Blizzard integration. This conservative check is based on loaded addons, not individual settings inside those addons. If a conflict loads after attachment, JiberishUI stops further updates and requests a reload. Loose texture overrides in the WoW installation are not removed.

## Project and verification

- `JiberishUI/` — addon source and 211 packaged TGA assets.
- `docs/border-showcase.png` — selected new borders at representative UI sizes.
- `docs/skin-library-*.png` — full Race, Class, Faction, and Standard preview sheets.
- `docs/skin-catalog.json` / `JiberishUI/SkinCatalog.lua` — generated catalog with permanent profile IDs.
- `artwork/masters/` / `artwork/prompts.json` — 11 original masters and exact built-in image_gen prompts.
- `docs/skin-reference.png` — four-race synthetic fit reference, not game screenshots.
- `docs/assets.json` — dimensions, alpha bounds, crop provenance, and hashes.
- `docs/source-load-order.json` — manifest and recursive XML/script order at the two pinned revisions.
- `docs/ARCHITECTURE.md` — implementation contract and source mapping.
- `docs/VALIDATION.md` — exact outstanding game tests and release gates.
- `tools/` — reproducible source tracing, artwork extraction/conversion, checking, and packaging.

Run from the repository root with Python 3 and Lua 5.1:

```sh
lua tests/run.lua
python3 tools/check.py
python3 tools/package.py
python3 tools/check.py --packages
```

The local development session used `.tools/lua-5.1.5/src/lua`; the tools and reference caches are ignored by Git and excluded from packages. Pillow is needed only to rebuild artwork/previews. Run `python3 tools/build_library.py` with Pillow to rebuild the expanded library from the included masters; the original four game-extracted families remain intact. See `docs/ARTWORK.md` for extraction details. `/jui diagnostics` reports geometry, adapter/build, module coverage, and failures without dumping unit identities or health/power quantities.
