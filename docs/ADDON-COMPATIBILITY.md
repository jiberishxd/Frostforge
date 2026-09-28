# UI integrations and compatibility

Frostforge decorates existing frames. Keep the original UI addon and its portrait, unit-frame or cast-bar module enabled. This is a development preview: source inspection and offline tests cover the adapters, but live fitting and secure behavior still need testing on each client/provider combination.

| Provider | Portrait surrounds | Full unit-frame art | Cast borders | Action hub |
| --- | --- | --- | --- | --- |
| Blizzard | Player, Target, Focus | Player, Target, Focus | Player, Target, Focus | Main action bar |
| ElvUI | Separate portraits | Compatible horizontal layouts | Horizontal casts | Main bar |
| EllesmereUI | Detached portraits | Compatible horizontal layouts | Resource Bars / Unit Frames | Main bar |
| Blinkii's Portraits | Separate portraits | Use Blizzard/ElvUI/Ellesmere bars | Use a supported cast provider | Use a supported bar provider |
| mMediaTag & Tools | Separate portraits | Use ElvUI bars | Use a supported cast provider | Use ElvUI's main bar |

Every external addon must itself support your game client. The inspected mMediaTag 4.x engine is a Retail ElvUI plugin; recognizing its legacy 3.x portraits does not make the current plugin compatible with Forever. Adapter references are pinned in [addon-sources.json](addon-sources.json).

## Portraits

Select Player, Target or Focus → **Artwork → Portrait provider**. Automatic looks for a visible Blinkii portrait first, then mMediaTag, ElvUI, EllesmereUI and Blizzard. Choose a specific provider when several are installed; an explicit choice waits for that provider instead of silently switching.

Enable a separate portrait in the provider. **Blinkii's Portraits** and **mMediaTag & Tools** offer circular portrait customization that fits Frostforge well alongside ElvUI. EllesmereUI's detached Circle mode also fits. Health-bar overlay/inside portraits have no separate surround; unusual masks and extra decorations may need manual fitting. Unmasked rectangular or 3D portraits fit inside a containing circle.

Frostforge follows the portrait's center, size, scale and visibility. New attachments, provider switches and fitting changes wait until combat ends. Existing artwork can follow readable unit identity changes in combat; restricted identity or geometry may temporarily defer an update.

## Full unit-frame artwork

Enable **Unit-frame art** separately from portrait art and select **Unit-frame provider**. Automatic prefers visible ElvUI, then EllesmereUI, then Blizzard. For ElvUI users, use **ElvUI's own unit frames** for the full shells and a separate portrait provider for circular surrounds.

ElvUI and EllesmereUI full shells require horizontal health with full-width power attached below and aligned with its edges. ElvUI inset, mini/spaced, offset or detached power, and vertical/above-health layouts are not fitted. Unsupported layouts retain their provider geometry; explicitly requested fill textures can still apply. Hidden/absent power uses the full shell with a dark empty power opening. A hidden unit frame hides its artwork.

Frostforge fits within the original bar stack and restores native geometry and textures when disabled. Shell size/offset controls do not move the underlying functional frame; use the provider's layout controls to move it. `/jf status` reports requested/resolved providers and fitting limits.

Full shells are for Player, Target and Focus only. Party, raid, pet, boss and secondary-target support is limited to Blizzard color/texture controls; those frames receive no ornamental shell. Nameplates and their indicators are outside this feature.

## Cast-bar borders

Enable both the provider's cast bar and Frostforge's independent **Cast-bar border**. Supported providers are Blizzard, ElvUI and EllesmereUI horizontal Player/Target/Focus casts.

Ellesmere Player discovery prefers its visible **Resource Bars** main cast bar, then the **Unit Frames** mini cast bar; when both are idle, the main bar is prepared first. Target/Focus use Unit Frames casts. The settings status identifies the chosen source. ElvUI uses its unit-frame cast bars, including their moved holders. An explicit provider never falls back to a different one.

Vertical, restricted, forbidden and unrelated standalone third-party cast bars are not decorated. Progress, timing, colors, text, icons and gameplay remain provider-controlled. Bars first created/resized in combat can wait until combat ends for attachment/refitting. [Fitting and layer controls](GETTING-STARTED.md#cast-bar-borders) are in the setup guide; inspected anchors and hashes are in [cast-bar-sources.json](cast-bar-sources.json).

## Minimap, action hub and textures

The circular minimap artwork follows the shared Minimap frame. **Use a round minimap (ElvUI)** changes an enabled ElvUI map to its native circle option outside combat, remembers the original shape per profile and restores it when disabled. For other minimap addons, select a circular shape in their own settings. Frostforge's map art sits above the map and keeps its center clear for clicks.

**Action hub → Action bar provider** selects Blizzard, ElvUI or EllesmereUI. FRAME follows the main bar's position; SCREEN uses your screen anchor while following visibility and scale. Set rows, paging and functional button layouts in the original UI addon. Vehicle/override transitions need live testing.

Choose **Frostforge Stone** through ElvUI/Ellesmere's existing shared-media texture menus, then use **Automatic (respect UI addon)** or **Keep provider textures** in Frostforge. Stock Blizzard texture/color controls are separate. See [texture setup](GETTING-STARTED.md#match-health-and-power-textures).

No third-party addon code or textures are bundled. Source records and offline coverage are available in the [maintainer documentation](maintainer/README.md).
