# Gradients, portraits, and the customizable action hub

Current build: **0.1.0-alpha.8**. The user confirmed alpha.7 options apply, but requested fit adjustments after screenshots showed a floating crest and a long thin action surround. Alpha.8 adds independent crest placement and a new console/docking system. Its live fit and combat safety remain unverified on Retail and Forever. The Forever 69913 SavedVariables loading failure is unchanged. Keep an external `/jui export` while testing.

## Colors

Select Global or a unit group, then **Colors**. Turning on **Health gradient** selects class/reaction colors if the mode was still native. Turning on **Power gradient** selects power-type colors if the mode was native. Both can also use fixed colors; power additionally supports class/reaction colors. Direction and depth are adjustable. The class preview uses synthetic amounts and does not inspect unit quantities.

Gradients interpolate from a darker shade of the base color to a lighter shade across the existing status-bar fill texture. They do not change as health drops: Blizzard owns the fill amount, masks, absorbs, predictions, and overlays. The 13 class identities use the client's class palette. Power-type overrides remain configurable. Dead, disconnected, tapped, unavailable, and restricted states yield to native colors; threat-health coloring takes priority on affected health bars. Turning the gradient off returns a flat fill; choosing native color mode restores the captured native texture/color.

## Portrait

The **Portrait** tab has a separate border material picker, tint, outline toggle, class/holiday artwork browser, artwork size (10–300%), opacity, and X/Y sliders (−250 to +250 local UI units). Positive X moves right; positive Y moves up. Zero offsets anchor the crest just above the portrait; negative Y lowers it toward the outline. Reset artwork position restores zero offsets and 80% size. These choices do not move the portrait or change health/power border material. All 52 existing materials are available for trim. Blizzard's existing curved geometry remains authoritative.

The new artwork library contains **15 independently generated transparent crests**: Warrior, Paladin, Hunter, Rogue, Priest, Death Knight, Shaman, Mage, Monk, Druid, Demon Hunter, Warlock, Evoker, Halloween, and Christmas. Automatic class artwork follows accessible player-unit class identity. It does not guess an NPC's class; select a fixed style to decorate NPC portraits. Crests are off by default and can be mixed with any trim material. External inside/overlay portraits remain with their provider; separate portrait backdrops receive the new controls.

## Action setup

**Action setup** selects the Action bars group. Choose **Class fantasy hub** at the top. New profiles default to it; an explicit previously saved mode is preserved. The new console uses one original graphite/pewter master with fixed sculpted corners and flexible center/rails, class tint/material, separate action/menu/bag bays, and one of the 15 class/holiday crests. Classes share the console structure; their crests and trim/palettes differ. Native buttons retain their functional states. This skins the control area, not the bag inventory windows.

| Section | Controls |
|---|---|
| Console | Width 500–2000, height 120–600 UI units, console/backdrop opacity; padding for legacy simple surround |
| Position | Overall X/Y, Blizzard docking toggle, main/all selection for decoration bounds, reset hub layout |
| Controls → Action bars 1–3 | Shared X/Y, size multiplier 40–160%, gap between bars |
| Controls → Bar 2 / Bar 3 | Extra X/Y offsets and independent size multipliers relative to the shared bar settings |
| Controls → Micro menu / Bag buttons | Independent X/Y, size 40–160%, inclusion toggle |
| Artwork | Class/holiday choice, crest size 10–300%, X/Y, reset crest position |

The console position is clamped to the screen. Control coordinates are UIParent units relative to its center/bottom; they are independent of its width/height, allowing custom arrangements. The default is three stacked bottom bars with menu/bags along the lower shelf. Adjust controls to fit the console after changing sizes. No automatic overlap solver is applied, and extreme crest/offset settings can overlap other UI.

**Dock Blizzard bars** moves/scales only `MainActionBar`, `MultiBarBottomLeft`, `MultiBarBottomRight`, `MicroMenuContainer` (or `MicroMenu` fallback), and `BagsBar`. It runs outside combat, leaves internal buttons/rows/spacing and bindings intact, and does not reparent any frame. Hidden bars stay hidden. Edit Mode pauses docking and restores captured native anchors/scale; after Edit Mode closes the hub applies again. Turning docking off or choosing another mode restores the latest native layout captured by post-hooks. For other action bars, use Edit Mode. For ElvUI/Ellesmere, docking is skipped: position their controls inside the console using their own layout editor. These are deliberate limits of the current hub.

**Simple surround** retains alpha.7's geometry-following outer rectangle without moving controls. Main cluster starts from the lowest central action button and includes nearby rows; all-bars mode includes every visible registered main/additional action button. Distant micro/menu areas can extend that old rectangle. Individual, both, and native modes also remain available. In the new hub, distant controls never stretch the console across empty space.

The hub/legacy surround use addon-owned mouse-transparent frames. Geometry freezes in combat, with changes queued until combat ends. The hub can hide when its action controls disappear. Native Blizzard main-bar art is suppressed only after successful rendering; missing artwork, unavailable geometry, or ownership conflicts retain native art and release docking outside combat. Visible `ElvUI_MicroBar` / `ElvUIBagBar` containers are preferred for decorative bounds when present, otherwise Blizzard's `MicroMenu` / `BagsBar` are used (also Ellesmere's containers). Functional warnings, key labels, cooldowns, paging, and clicks remain native; live validation is required.

## Art and source evidence

- Original generated PNGs: `artwork/fantasy/`.
- Exact prompts and generation mode: `artwork/fantasy-prompts.json` (**built-in image_gen**).
- Runtime transparent TGAs: `JiberishUI/Media/fantasy/`.
- Conversion: `tools/build_fantasy.py`, which preserves alpha and encodes power-of-two TGA files.
- Hashes, dimensions, alpha bounds, and source links: `docs/assets.json`.
- Contact sheet: `docs/fantasy-library.png` (artwork reference, not an in-game screenshot).
- Console master: `artwork/hub-console.png`; prompt: `artwork/hub-prompts.json` (**built-in image_gen**); runtime: `JiberishUI/Media/hub/console.tga`; converter: `tools/build_hub.py`.

The gradient API uses `TextureBase:SetGradient(orientation, minColor, maxColor)` from Blizzard's generated SimpleTextureBase API documentation. Existing pinned MainActionBar sources reference `MicroMenu` and Forever `BagsBar`; discovery only reads their public geometry. Installed ElvUI MicroBar/BagBar and Ellesmere extra-bar definitions were inspected; additional hashes are recorded in `integration-sources.json`. No vendor code is bundled.

## Required live checks

1. Test both gradient directions/depth limits on players of different classes, NPCs, and each changing power type. Confirm dead/tapped/disconnected/threat colors and absorbs/predictions remain correct. Return to flat/native modes.
2. Combine a different portrait trim, class crest, and unit-bar material. Test hidden/vehicle portraits, tiny party pets, target mirroring, maximum scale, name/level/indicator overlap, and all 15 crests.
3. Test hub, simple surround, individual, both, and native modes. Adjust every X/Y/size limit, reset positions, and include/exclude micro menu/bags. Toggle docking off to verify native restoration. Edit Mode save/cancel must pause then resume docking without losing native positions. Hide/reveal bars, page actions, enter vehicles, and use controller navigation. Verify all buttons remain clickable and layered above console art.
4. Repeat with ElvUI and Ellesmere separately. Check their fade behavior, shaped buttons, profile/layout changes, and disabled modules. Enter combat, queue several settings, and confirm only the latest appearance applies afterward with no blocked actions or secret-value errors.

Restart the client after installing if it has cached the previous TOC file list. New files and assets are included in both client packages; interfaces remain 120100 and 16001.
