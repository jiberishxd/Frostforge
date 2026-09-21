# JiberishUI

Border skins for Blizzard's unit frames and action bars, with experimental ElvUI and Ellesmere integrations. The library has **52 trim choices across 15 material families**, plus **15 original class and holiday crests**. Human remains the default unit-border material. Every trim style can be selected globally or per frame group; portraits have independent controls.

**Version 0.1.0-alpha.8 is an implementation for testing, not a compatibility-certified release.** It adds crest X/Y controls and a 10–300% size range, plus a sculpted bottom console with customizable artwork, dimensions, position, action-bar rows, micro menu, and bags. The 65 mocked behavioral groups and 4 recovery-parser tests pass. Alpha.7 options applied in game but the user reported poor fit; alpha.8's new docking, rendering, combat behavior, and provider compatibility still require in-game validation. See [controls and test steps](docs/FANTASY.md).

New highlights include Dwarf / Ironforge, Night Elf Moonwell / Ancient Grove / Sentinel, Mage Arcane Crystal, Warlock Fel Covenant, and standard Black Stone, Slate, Obsidian, Silver Steel, Aged Bronze, Ivory Gold, Forest Wood, and Frost Stone. There are presets for all 13 classes, 26 race identities, and Alliance/Horde. Related presets deliberately share artwork and use different palettes; the library contains 15 material families, not 52 independently painted sets. See `docs/SKIN-LIBRARY.md` for the full mapping.

## Install and use

1. Choose the matching archive in `dist`: Retail (interface **120100**, audited build **12.1.0.69875**) or Forever (interface **16001**, audited build **1.60.1.69913**).
2. Extract its single `JiberishUI` folder into that client's `Interface/AddOns` directory. Avoid an extra nested folder.
3. Start the client or reload its UI, enable JiberishUI, and open **Settings → AddOns → JiberishUI**, `/jui`, or `/jiberishui`.
4. Choose Global or a frame group on the left. **Borders** changes unit/bar trim; **Colors** enables health/power gradients; **Portrait** selects independent trim, artwork, size, and X/Y offsets. **Action setup → Class fantasy hub** opens Console, Position, Controls, and Artwork sections. Previously saved action modes remain selected until changed. Use **Use global settings** on Borders to clear that group's overrides.
5. In hub mode, **Position → Dock Blizzard bars** positions bars 1–3, micro menu, and bags using the Controls sliders. Turn docking off to use the native positions. Edit Mode pauses docking and still owns each bar's button rows/spacing. ElvUI/Ellesmere retain their own layout controls. Unit-frame movement and dimensions remain with the owning UI. Blizzard portrait frames retain their curved outline; JiberishUI changes its material, tint, opacity, and separate crest artwork.

During combat, settings are saved and the synthetic preview updates; live changes apply afterward. Disabling a module requires **Reload UI**, which reconstructs the native frame state. Re-enable before reloading to cancel that disable request. To remove every customization, disable the addon and reload. Disabling Global can be overridden by explicitly enabled groups; use the addon checkbox to turn everything off.

The Profiles page supports named copies, per-character selection, reset, export, and import. `/jui export` and `/jui import` open the transfer dialogs directly. Imports replace the active profile; copy it first if you want a backup. Exports are bounded, plain data in the `JUI1` format and never execute Lua. Retail and Forever have separate saved-variable stores. **Forever build 69913 can reset settings even on `/reload`: the user reproduced this while changed settings were still present on disk.** Keep an export before reload/logout and import it if needed. This is a recovery workflow, not a repair to the client loader. See [persistence evidence and recovery](docs/PERSISTENCE.md).

## Coverage

Implemented discovery includes player, target, focus, pet, boss, target-of-target, focus-target, portrait party/pets, compact party/pets, raids, main/additional action bars, pet/stance/possess/override buttons, extra/zone buttons, flyouts, and Forever multicast/totem buttons. New profiles default to the class fantasy hub with native buttons. Its optional docking moves/scales the three named Blizzard bottom bars, menu container, and bag bar outside combat; other bars stay in their existing positions. Simple surround, individual borders, both, and native modes remain available. No click attributes, bindings, parents, or native button visibility are changed.

Native health/power colors remain the default. Custom modes use a white fill with the native mask. Health supports fixed and class/reaction colors; power supports fixed, class/reaction, and power-type palettes. Both offer gradients with direction and depth controls. Disconnected, dead, tapped, unavailable, and restricted states fall back to native presentation. Compact frames configured for threat-based health coloring keep native health colors.

Casts, auras, class resources, predictions, absorbs, cooldowns, threat/selection/proc indicators, keybindings, and click behavior remain under Blizzard's control. Their independent reskinning, nameplates, minimap, chat, bag inventory windows, tooltips, and other windows are outside this release. Custom endcaps/ornaments and borders still require the visual checks in `docs/VALIDATION.md`, especially with dense layouts.

ElvUI and Ellesmere support is selected automatically per frame group. The adapters were checked against installed ElvUI **15.26** and Ellesmere modules **9.1.8**; live validation is pending. Mixed ownership, such as ElvUI unit frames with Ellesmere action bars, is supported by discovery. If both providers own the same group, it is skipped with an explanation. External button states, cooldowns, and secure behavior stay with their provider. See [compatibility and testing](docs/COMPATIBILITY.md).

Shadowed Unit Frames, PitBull, Bartender, Dominos, and Masque's Blizzard integration still trigger conservative skips for their affected groups. A provider change after attachment requires reload to finish restoration. Loose texture overrides in the WoW installation are not removed.

## Project and verification

- `JiberishUI/` — addon source and 228 packaged TGA assets, including 15 fantasy crests, the console, and the bar-interior exclusion mask.
- `artwork/hub-console.png` / `artwork/hub-prompts.json` — original console master and exact built-in image_gen prompt; `tools/build_hub.py` encodes its runtime TGA.
- `docs/FANTASY.md` / `docs/fantasy-library.png` — new controls, implementation limits, live test steps, and the crest artwork sheet.
- `artwork/fantasy/` / `artwork/fantasy-prompts.json` — 15 original transparent masters and exact built-in image_gen prompts.
- `docs/border-showcase.png` — selected new borders at representative UI sizes.
- `docs/skin-library-*.png` — full Race, Class, Faction, and Standard preview sheets.
- `docs/skin-catalog.json` / `JiberishUI/SkinCatalog.lua` — generated catalog with permanent profile IDs.
- `artwork/masters/` / `artwork/prompts.json` — 11 original masters and exact built-in image_gen prompts.
- `docs/skin-reference.png` — four-race synthetic fit reference, not game screenshots.
- `docs/assets.json` — dimensions, alpha bounds, crop provenance, and hashes.
- `docs/source-load-order.json` — manifest and recursive XML/script order at the two pinned revisions.
- `docs/ARCHITECTURE.md` — implementation contract and source mapping.
- `docs/COMPATIBILITY.md` / `docs/integration-sources.json` — external provider coverage and installed-source evidence.
- `docs/VALIDATION.md` — exact outstanding game tests and release gates.
- `tools/` — reproducible source tracing, artwork extraction/conversion, checking, and packaging.

Run from the repository root with Python 3 and Lua 5.1:

```sh
lua tests/run.lua
python3 tests/test_recovery.py
python3 tools/check.py
python3 tools/package.py
python3 tools/check.py --packages
```

The local development session used `.tools/lua-5.1.5/src/lua`; the tools and reference caches are ignored by Git and excluded from packages. Pillow is needed only to rebuild artwork/previews. Run `python3 tools/build_library.py` with Pillow to rebuild the expanded library from the included masters; the original four game-extracted families remain intact. See `docs/ARTWORK.md` for extraction details. `/jui diagnostics` reports geometry, adapter/build, frame provider, attached/applied/failed counts, and sanitized error locations without dumping unit identities or health/power quantities. Error summaries also reach BugSack/BugGrabber when installed. Reload after updating; restart the client if it has not picked up the new addon file list.
