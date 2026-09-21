# Gradients, portraits, and the shared action-bar surround

Implemented in **0.1.0-alpha.7**. Offline tests pass; live visual fit and combat safety remain unverified on Retail and Forever. The Forever 69913 SavedVariables loading failure is unchanged. Keep an external `/jui export` while testing.

## Colors

Select Global or a unit group, then **Colors**. Turning on **Health gradient** selects class/reaction colors if the mode was still native. Turning on **Power gradient** selects power-type colors if the mode was native. Both can also use fixed colors; power additionally supports class/reaction colors. Direction and depth are adjustable. The class preview uses synthetic amounts and does not inspect unit quantities.

Gradients interpolate from a darker shade of the base color to a lighter shade across the existing status-bar fill texture. They do not change as health drops: Blizzard owns the fill amount, masks, absorbs, predictions, and overlays. The 13 class identities use the client's class palette. Power-type overrides remain configurable. Dead, disconnected, tapped, unavailable, and restricted states yield to native colors; threat-health coloring takes priority on affected health bars. Turning the gradient off returns a flat fill; choosing native color mode restores the captured native texture/color.

## Portrait

The **Portrait** tab has a separate border material picker, tint, outline toggle, class/holiday artwork browser, artwork size, and opacity. These choices do not change health/power border material. All 52 existing race/class/faction/standard materials are available for portrait trim. Blizzard's existing curved geometry remains authoritative; the crest sits above the portrait instead of repainting its face or bar backdrop.

The new artwork library contains **15 independently generated transparent crests**: Warrior, Paladin, Hunter, Rogue, Priest, Death Knight, Shaman, Mage, Monk, Druid, Demon Hunter, Warlock, Evoker, Halloween, and Christmas. Automatic class artwork follows accessible player-unit class identity. It does not guess an NPC's class; select a fixed style to decorate NPC portraits. Crests are off by default and can be mixed with any trim material. External inside/overlay portraits remain with their provider; separate portrait backdrops receive the new controls.

## Action setup

**Action setup** selects the Action bars group. The default is **One surround / native buttons**. Other modes are individual borders, both, and native artwork. A class or holiday crest decorates a shared outer surround; the native buttons retain their functional states. Micro-menu and bag-button areas can be included independently. Bag inventory windows are outside this feature.

**Main cluster** starts with the lowest central action button and includes adjacent rows. Distant side bars stay native. **All visible action bars** expands the surround to include every discovered main/additional action button. The selected micro menu and bags extend the same outer rectangle, even if placed far apart. Use the owning UI's layout editor to arrange these components together for a compact console. The addon does not reposition them. Padding, border thickness, artwork scale, surround opacity, and backdrop opacity are adjustable. The header crest sits above the surround to preserve key labels and cooldowns.

The surround follows runtime rectangles/effective scales outside combat and freezes geometry in combat. It can hide when the underlying controls are hidden. It is mouse-transparent. Native Blizzard bar art is suppressed only after a surround successfully renders. Missing artwork, unavailable geometry, and ownership conflicts retain native art. ElvUI/Ellesmere action-button registries are reused; their native state textures are retained. Visible `ElvUI_MicroBar` / `ElvUIBagBar` containers are preferred when present, otherwise Blizzard's `MicroMenu` / `BagsBar` are used (also the Ellesmere containers).

## Art and source evidence

- Original generated PNGs: `artwork/fantasy/`.
- Exact prompts and generation mode: `artwork/fantasy-prompts.json` (**built-in image_gen**).
- Runtime transparent TGAs: `JiberishUI/Media/fantasy/`.
- Conversion: `tools/build_fantasy.py`, which preserves alpha and encodes power-of-two TGA files.
- Hashes, dimensions, alpha bounds, and source links: `docs/assets.json`.
- Contact sheet: `docs/fantasy-library.png` (artwork reference, not an in-game screenshot).

The gradient API uses `TextureBase:SetGradient(orientation, minColor, maxColor)` from Blizzard's generated SimpleTextureBase API documentation. Existing pinned MainActionBar sources reference `MicroMenu` and Forever `BagsBar`; discovery only reads their public geometry. Installed ElvUI MicroBar/BagBar and Ellesmere extra-bar definitions were inspected; additional hashes are recorded in `integration-sources.json`. No vendor code is bundled.

## Required live checks

1. Test both gradient directions/depth limits on players of different classes, NPCs, and each changing power type. Confirm dead/tapped/disconnected/threat colors and absorbs/predictions remain correct. Return to flat/native modes.
2. Combine a different portrait trim, class crest, and unit-bar material. Test hidden/vehicle portraits, tiny party pets, target mirroring, maximum scale, name/level/indicator overlap, and all 15 crests.
3. Test one surround, individual, both, and native modes. Include/exclude micro menu and bags. Move bars in Edit Mode, save/cancel, hide/reveal bars, page actions, enter vehicles, and use controller navigation. Verify buttons remain clickable throughout.
4. Repeat with ElvUI and Ellesmere separately. Check their fade behavior, shaped buttons, profile/layout changes, and disabled modules. Enter combat, queue several settings, and confirm only the latest appearance applies afterward with no blocked actions or secret-value errors.

Restart the client after installing if it has cached the previous TOC file list. New files and assets are included in both client packages; interfaces remain 120100 and 16001.
