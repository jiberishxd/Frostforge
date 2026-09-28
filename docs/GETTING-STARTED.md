# Quick start

1. With WoW closed, install the complete **Frostforge** folder in `Interface/AddOns/`. The final path is `Interface/AddOns/Frostforge/Frostforge.toc`. Use the package for your client; from GitHub's Download ZIP, copy only the inner `Frostforge` folder.
2. Restart WoW, enable **Jiberish's Frostforge** and follow the first-login setup tour.
3. Open `/frostforge`, choose a component, select its artwork and provider, then enable and fit it. Portrait art and full unit-frame art have separate switches and browsers.

Settings also open from the AddOn Compartment, ElvUI's Frostforge section or the optional minimap icon. Rerun the tour from **Guide → Run quick setup**. Changes involving protected frames wait until combat ends.

## UI addons

- **Blizzard:** supports Player, Target and Focus portraits, full frames and cast borders.
- **ElvUI:** use its own unit frames for full-frame art. For circular portraits, use **Blinkii's Portraits** or **mMediaTag & Tools** and their circle options; choose portrait and frame providers independently.
- **EllesmereUI:** use a detached portrait and horizontal health with power attached below.

Full shells need full-width power aligned below health; inset, detached, offset and vertical power layouts are not fitted. Each UI addon must support your client. The inspected mMediaTag 4.x plugin requires Retail ElvUI. Enable the provider's own portrait/cast module before adding Frostforge artwork. Select a circular minimap; ElvUI users can enable Frostforge's **Use a round minimap** option.

## Profiles and updates

**Profiles** manages character setups; **Save as new profile** makes an independent copy. Characters using the same profile share edits. **Guide → Copy settings backup** backs up the active profile's artwork settings, not the entire profile library.

Replace the addon folder when updating; keep `WTF` and all saved settings. An earlier Forever saved-data loading issue still needs live verification, so retain backups. For help or missing settings, [ask in The Igloo Discord](https://discord.com/servers/igloo-460933747731070996); include your version, client, UI addons and `/jf status`.

## Upgrading to Frostforge

For installations still named `JiberishUI`, transfer settings once before removing the old addon:

1. Fully close WoW and back up `WTF`.
2. In `WTF/Account/<account>/SavedVariables/`, copy `JiberishUI.lua` to `Frostforge.lua`.
3. Repeat in each `WTF/Account/<account>/<realm>/<character>/SavedVariables/` directory you use. Keep the original files and do not edit their contents. If `Frostforge.lua` already exists, back up both and choose which settings to retain before replacing it.
4. Remove the old `Interface/AddOns/JiberishUI` folder, install `Frostforge` and restart WoW. Do not run both copies.

Fresh installs and later Frostforge updates need no transfer. The old slash commands and saved-variable names remain compatible.
