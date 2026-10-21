# Quick start

1. Download the **Retail** or **Forever** ZIP from the [latest release](https://github.com/jiberishxd/Frostforge/releases/latest). With WoW closed, install its complete **Frostforge** folder in `Interface/AddOns/`. The final path is `Interface/AddOns/Frostforge/Frostforge.toc`. Version 1.0.2 targets Retail **12.1.0** and Forever **1.60.1**; use the package for your client.
2. Restart WoW, enable **Jiberish's Frostforge** and follow the first-login setup tour.
3. Open `/frostforge`, choose a component, select its artwork and provider, then enable and fit it. Portrait art and full unit-frame art have separate switches and browsers.

Settings also open from the blue **Frostforge** row after **AddOns** in the Escape menu, the AddOn Compartment, ElvUI's Frostforge section or the optional minimap icon. Rerun the tour from **Guide → Run quick setup**. Changes involving protected frames wait until combat ends.

## UI addons

- **Blizzard:** supports Player, Target and Focus portraits, full frames and cast borders.
- **ElvUI:** use its own unit frames for full-frame art. For circular portraits, use **Blinkii's Portraits** or **mMediaTag & Tools** and their circle options; choose portrait and frame providers independently.
- **EllesmereUI:** use a detached portrait and horizontal health with power attached below.

Full shells need full-width power aligned below health; inset, detached, offset and vertical power layouts are not fitted. Each UI addon must support your client. The inspected mMediaTag 4.x plugin requires Retail ElvUI. Enable the provider's own portrait/cast module before adding Frostforge artwork. Select a circular minimap; ElvUI users can enable Frostforge's **Use a round minimap** option.

## Profiles and updates

**Profiles** manages character setups; **Save as new profile** makes an independent copy. Characters using the same profile share edits. **Guide → Copy settings backup** backs up the active profile's artwork settings, not the entire profile library.

Replace the addon folder when updating; keep `WTF` and all saved settings. An earlier Forever saved-data loading issue still needs live verification, so retain backups. For help or missing settings, [ask in The Igloo Discord](https://discord.com/servers/igloo-460933747731070996); include your version, client, UI addons and `/jf status`.

**Party / Target of Target:** enable **Compact frame border** to use the smaller castbar designs around the bars. **Frame border** adjusts fit and weight; **Advanced** has separate portrait and compact-border strata/level controls. Portrait art is independent; enable separate portraits in your UI addon first. Automatic themes match each member individually. Blizzard compact party frames have no portraits; Ellesmere party support uses its Raid Frames module.

### NPC creature artwork

In **Target / Focus → Artwork**, leave an automatic theme selected and enable **Match NPC creature types** (on by default). Supported NPC types select a matching portrait and unit-frame shell. Enable **Unit-frame art** separately to show the shell. City affiliations keep their existing race artwork.

Open either artwork browser and choose **Creatures** to select one of the ten designs manually. This switches the shared portrait/frame theme to a fixed design. Turning creature matching off restores the previous NPC selection behavior. Unknown, unavailable or restricted creature types fall back safely. Players keep their class/race/faction selection.

### Seasonal artwork

Choose **Seasonal** in the portrait, unit-frame, action hub or minimap artwork browser. Harvest Hollow, Witching Hour and Hallow’s End are Halloween sets; Holly Hearth, Winter Starlight, Winter Veil: Alliance and Winter Veil: Horde are Christmas options. The two Winter Veil versions feature the faction’s dwarf or orc Greatfather Winter; select the version you want by name. Search by name or holiday. Pick the same collection in each component for a matching interface, or mix them independently.

Choosing a portrait or full frame sets that unit's shared portrait/frame theme; enable each artwork component separately. Seasonal choices stay selected until you change them and do not switch with the calendar. Cast bars and compact frame borders use existing matching trims.
