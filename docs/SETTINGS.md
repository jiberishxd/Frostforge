# Settings workshop and shared stone

Open `/jui`. Choose Player, Target, Focus, Minimap or Action hub on the left. Settings save immediately; changes that need protected frames wait until combat ends.

- **Artwork:** Independent portrait and unit-frame toggles, automatic class/race/faction choices, providers and attachment status. Browse opens a searchable collection; picking a design makes it fixed for that component.
- **Placement:** Size, offsets, scale, opacity and anchor. For units, these fit portrait art; full shells follow the actual bars. Move the native frames in their owning UI's settings.
- **Unit frame** (Player/Target/Focus): Artwork width/height from 75–150% of the automatic fit, plus inset edge depth from 0–3. A dedicated reset restores 100%/100%/1.5 without changing portraits. Both shell halves scale around the same bar-stack center. These controls resize decorations, not native bars.
- **Advanced:** Health/power texture ownership, layers, fitting bounds and support details printed to chat.
- **Cast bar (Player/Target/Focus):** Independent enable toggle, one Bold artwork style, automatic or explicit Blizzard/EllesmereUI/ElvUI provider, Match unit artwork or a separate collection choice, border width, height, weight and spacing. Off by default; the provider must have its own cast bar enabled. [Cast-bar details](CAST-BARS.md).
- **Guide:** Setup help and troubleshooting, plus copy/paste backup and restore. Restore replaces JiberishUI settings for all five components; invalid backups leave current settings intact. Reset component asks before restoring just that component's defaults.

The window uses native Blizzard textured panels, red buttons, checks and sliders, with existing portrait art in its header. It scales to fit shorter screens, remembers dragged position, and supports Escape to close. Search matches plain label text within the selected class/race/faction category; long collections have pages.

## Choose JiberishUI Stone in your other UI addon

1. Install this build with JiberishUI enabled, then restart the game.
2. In EllesmereUI, open Unit Frames and find **Bar Texture**. Select **JiberishUI Stone**. Its per-unit texture setting also supplies power/cast/absorb texture choices in the inspected 9.2.9 release; use its sync option or repeat for other units. Raid frames, resource bars and other modules with shared texture menus can select the same material separately.
3. In ElvUI, select **JiberishUI Stone** in its status-bar texture settings. Use its general/global or per-frame settings as appropriate for your layout. Other installed addons with LibSharedMedia status-bar menus can use it too.
4. In `/jui` → Player/Target/Focus → **Advanced**, leave **Health & power textures** on **Automatic (respect UI addon)**, or choose **Keep provider textures**. This prevents JiberishUI from replacing your Ellesmere selection.

Automatic keeps Ellesmere's selected textures and uses JiberishUI fills on Blizzard frames. **Use JiberishUI fills** explicitly overrides the selected unit's fills while unit-frame art is enabled. Native colors, values, labels and clicks remain controlled by the provider. Shared Stone works independently of all JiberishUI artwork toggles, and the selected provider tint supplies health/class/resource color.

The material is registered through the LibSharedMedia-3.0 already supplied by EllesmereUI or ElvUI; you do not need a duplicate texture pack. If the menu was already open during loading, reopen it. The name is exactly **JiberishUI Stone**. This does not add ElvUI full-shell support; JiberishUI full shells currently support Blizzard and compatible Ellesmere bar layouts.

## Preview and verification

`artwork/settings/` renders snapshots exported from the real Lua settings objects with `tools/export_settings_preview.lua`. Its Blizzard fonts and panel textures are browser approximations, and controls shown inside the pictured window are snapshots. Use the preview's top selectors to review layouts. It is not a game screenshot. No WoW automation or gameplay testing was performed.

## Stock frames and separate layers (0.8.1)

Player, Target and Focus have a **Blizzard** page for their stock portrait image and name label, plus a shared **Stone textures on all Blizzard health/power bars** switch. The switch starts on and remains active independently of full-shell and fill-mode choices. **Advanced** separates portrait, unit-frame and cast-border strata. [Full behavior and restoration](BLIZZARD-CONTROLS.md).
