# Settings workshop and shared stone

Open the AddOn Compartment entry, ElvUI’s Frostforge section, the optional minimap icon, or `/frostforge`. Choose Player, Target, Focus, Minimap or Action hub on the left. Settings save immediately; changes that need protected frames wait until combat ends.

- **Artwork:** Independent portrait and unit-frame toggles, automatic class/race/faction choices, providers and attachment status. Browse opens a searchable collection; picking a design makes it fixed for that component.
- **Placement:** Size, offsets, scale, opacity and anchor. For units, one size slider adjusts width and height together; Advanced sizing reveals separate dimensions. These fit portrait art; full shells follow the actual bars. Move the native frames in their owning UI's settings.
- **Unit frame** (Player/Target/Focus): Artwork width/height from 75–150%, plus independent horizontal/vertical offsets. The original shell sits above the bars, with a small side overlap at 100%. Reduce width to move its sides inward. Reset restores 100%/100% and zero offsets without changing portraits. The former inset strips and depth control have been removed; saved depth values are ignored.
- **Advanced:** Health/power texture ownership, layers, fitting bounds and support details printed to chat.
- **Cast bar (Player/Target/Focus):** Independent enable toggle, one Bold artwork style, automatic or explicit Blizzard/EllesmereUI/ElvUI provider, Match unit artwork or a separate collection choice, border width, height, weight and spacing, plus strata and level. Off by default; the provider must have its own cast bar enabled. [Cast-bar details](CAST-BARS.md).
- **The Igloo:** Select and copy [theigloo.io](https://theigloo.io) into your browser to visit Jiberish's website.
- **Guide:** Rerun the four-screen illustrated setup tour, toggle the optional minimap icon, read setup help, or copy/paste a settings backup. Restore replaces Frostforge settings for all five components; invalid backups leave current settings intact. Reset component asks before restoring just that component's defaults.

The window uses native Blizzard borders, quiet solid dark panels, muted frost-blue Blizzard buttons and white button labels, alongside native Blizzard checks and sliders. Hover brightens a fitted icy outline; selected tabs, enabled toggles and chosen options keep their blue border after the pointer leaves. The official transparent penguin logo stays in the header across every component. It scales to fit shorter screens, remembers dragged position, and supports Escape to close. Search matches plain label text within the selected class/race/faction category; long collections have pages.

When you change targets in combat, the portrait surround and full unit-frame artwork update to the new readable identity when the game permits. The shell remaps the new design into its existing fitted sections, including the footer for units without power. Bar positions, dimensions and native fill textures wait until combat ends, when the design's exact proportions are refitted. Briefly unreadable frames hide their decorations safely and recover on the same attachment when readable again; attaching to a different frame still waits until combat ends.

## Minimap shape and layering

Minimap artwork automatically clears the native map, backdrop and immediate parent layer, including old saved Background settings. Its transparent center leaves map clicks intact. The optional settings icon remains above the artwork.

**Minimap → Artwork → Use a round minimap (ElvUI)** uses ElvUI’s native circle option outside combat, provided its minimap module is enabled and initialized. The original shape is journaled per ElvUI profile across reloads and restored when art or round shape is turned off. Profile changes restore the previous profile before adopting the new one. Other addons retain their own shape controls.

## Choose Frostforge Stone in your other UI addon

1. Install this build with Frostforge enabled, then restart the game.
2. In EllesmereUI, open Unit Frames and find **Bar Texture**. Select **Frostforge Stone**. Its per-unit texture setting also supplies power/cast/absorb texture choices in the inspected 9.2.9 release; use its sync option or repeat for other units. Raid frames, resource bars and other modules with shared texture menus can select the same material separately.
3. In ElvUI, select **Frostforge Stone** in its status-bar texture settings. Use its general/global or per-frame settings as appropriate for your layout. Other installed addons with LibSharedMedia status-bar menus can use it too.
4. In `/frostforge` → Player/Target/Focus → **Advanced**, leave **Health & power textures** on **Automatic (respect UI addon)**, or choose **Keep provider textures**. This prevents Frostforge from replacing your Ellesmere selection.

Automatic keeps ElvUI/Ellesmere's selected textures and uses Frostforge fills on Blizzard frames. **Use Frostforge fills** explicitly overrides the selected unit's fills while unit-frame art is enabled. Native colors, values, labels and clicks remain controlled by the provider. Shared Stone works independently of all Frostforge artwork toggles, and the selected provider tint supplies health/class/resource color.

The material is registered through the LibSharedMedia-3.0 already supplied by EllesmereUI or ElvUI; you do not need a duplicate texture pack. If the menu was already open during loading, reopen it. The name is exactly **Frostforge Stone**. Full shells support Blizzard and compatible attached ElvUI/Ellesmere bar layouts. In **Artwork**, enable **Unit-frame art** and choose **Unit-frame provider → ElvUI** or Automatic. When visible, ElvUI power must be full-width, attached and aligned below health; inset, mini/spaced, offset, detached or vertical arrangements retain their provider layout.

## Preview and verification

`artwork/settings/` renders snapshots exported from the real Lua settings objects with `tools/export_settings_preview.lua`. Its Blizzard fonts and panel textures are browser approximations, and controls shown inside the pictured window are snapshots. Use the preview's top selectors to review layouts. It is not a game screenshot. No WoW automation or gameplay testing was performed.

## Stock frames and separate layers (0.8.4)

Player, Target and Focus have a **Blizzard** page for hiding their stock portrait image or full surround. Select **Name**, **Health**, **Power**, **Level**, **Cast name** or **Cast time**, then enable customization to adjust that label's X/Y, size, alignment and outline. Health/power controls move the corresponding center/left/right labels together. Offsets are relative to Blizzard's original anchors, without accumulating on redraws. Each group has its own reset; **Restore stock portrait & all text** restores the selected unit.

The shared **Stone on Blizzard health/power** switch starts on and remains active independently of full-shell and fill-mode choices. **Advanced** separates portrait and unit-frame strata. **Cast bar** keeps cast-border strata and **Level above nearby artwork** together. Automatic cast layering also clears Blizzard's owning frame and enabled Frostforge portrait/shell layers. [Full behavior and restoration](BLIZZARD-CONTROLS.md).

### Blizzard colors and textures

Open **Blizzard → Colors & textures**. The selected Player, Target or Focus has independent **Name color** (Blizzard/Class) and **Health color** (Blizzard/Class gradient/Dark stone). Shared **Party & raid** controls offer the same choices. Class gradients apply subtle vertical shading to player health using the 13-class palette; names use the solid base color. NPCs retain their native colors. Dark stone is a charcoal health fill; native resource colors remain unchanged.

**Stock health texture** and **Stock power texture** are separate, shared choices: Automatic, Frostforge Stone, Smooth or Blizzard texture. Automatic follows the existing **Stone for Automatic texture** switch; explicit choices take precedence over shell fills. Dark stone always selects stone for the affected health bars. Class gradient uses the chosen neutral Stone or Smooth texture; with Blizzard texture selected, it uses a neutral Blizzard fill instead of multiplying the class hue into a green atlas. Everything saves with your character’s Frostforge profile. These options affect stock Blizzard frames only.

## Power colors and Blizzard placement (0.8.7)

- Open **Player / Target / Focus → Blizzard → Colors & textures → Power colors**. Choose **Native resource color**, **Class color (players)** or **Custom color**, then **Solid** or **Gradient**. Gradient shades from darker below to the base color above. Use **Choose color**, or enter six hex digits and press Enter. Cancel in the color picker restores the previous choice. The **Party & raid** tab controls their power bars separately.
- Color and shading work with the selected stock power texture, independently of shell artwork. Precolored Blizzard fills use a neutral material when recolored or shaded. Native-resource mode preserves resource changes and native grey/disconnect tints. ElvUI/Ellesmere color settings remain with those addons.
- Open **Target / Focus → Blizzard → Buffs & debuffs...** and enable **Customize position**. X/Y move Blizzard's combined aura group; positive values move right/up. Aura order, spell tooltips and visibility remain Blizzard-controlled.
- Open **Target / Focus → Blizzard → Cast-bar position...** for equivalent cast-bar offsets. The Frostforge border follows the native bar. Enable **Cast-bar border** and select the provider on **Cast bar**; its strata and level settings remain there. Moving the aura group may also move the stock cast bar when Blizzard anchors it below those auras.
- Placement is applied outside combat, reuses native anchors without accumulating offsets, and restores on disable/reset/profile change. If Blizzard reanchors a protected region during combat, Frostforge reapplies its saved placement after combat.

## Aura position fix (0.8.8)

Target/Focus buff/debuff offsets now reapply after Blizzard's aura-anchor callback, so a native layout refresh cannot erase an out-of-combat X/Y edit before it appears. **Customize position** shows applied offsets or a waiting/error status, also available through `/jui status`. Native updates during combat retain a fresh baseline for reconciliation after combat.

## Browse unit-frame art

Player, Target and Focus → **Artwork** now show separate portrait and full-frame previews. **Browse frame art** opens all 42 unit-frame designs in Classes, Races and Factions, with search and pagination. The previews use the actual full-shell artwork and mirror for Target/Focus.

Portrait and unit-frame artwork share the selected theme for that unit. Choosing a frame design changes that shared theme to **Chosen artwork**; it does not enable either artwork toggle or change another unit. Enable **Unit-frame art** separately. Return **Shared artwork theme** to an automatic mode to follow unit identity again. The gallery is created only when opened and clears thumbnails when closed.
