<p align="center">
  <img src="docs/images/logo.png" alt="Jiberish's Frostforge penguin logo" width="200">
</p>

# Jiberish's Frostforge

Class, race and faction artwork for your World of Warcraft interface. Frostforge decorates your existing frames with matching portrait surrounds, sculpted unit-frame shells, cast-bar borders, minimap art and action-bar hubs.

[Getting started](docs/GETTING-STARTED.md) · [Compatibility](docs/ADDON-COMPATIBILITY.md) · [Gallery](docs/GALLERY.md) · [Changelog](docs/CHANGELOG.md) · [The Igloo](https://theigloo.io) · [Discord](https://discord.com/servers/igloo-460933747731070996)

![A selection of Frostforge's matching artwork](docs/images/overview.jpg)

*Artwork showcase using the shipped textures and illustrative bars; not an in-game screenshot.*

## What you can customize

- **42 matching themes:** 13 classes, 26 races and three factions, with automatic identity matching or a fixed design.
- **Independent artwork:** enable and fit portraits, unit frames, cast borders, minimap surrounds and action hubs separately.
- **Your existing UI:** Blizzard frames, compatible ElvUI and EllesmereUI layouts, and Blinkii/mMediaTag portraits.
- **Blizzard appearance:** portrait visibility, labels, colors, stone textures and target/focus aura and cast-bar positioning.
- **Character profiles:** separate layouts, shared profiles when wanted, and copyable settings backups.
- **Quick setup:** an illustrated first-launch tour and settings access through the AddOn Compartment, an optional minimap icon, ElvUI settings or `/frostforge`.

Full unit-frame artwork fits horizontal health with full-width power attached below. See [supported layouts and limits](docs/ADDON-COMPATIBILITY.md) before enabling it with another UI addon.

## Install and get started

**0.9.7 is a development preview.** Live validation across both clients and every provider remains incomplete. There is no published GitHub release download yet.

Use the prepared **Retail** or **Forever** package for your client. Extract it and put its entire `Frostforge` folder in `Interface/AddOns/`, then fully restart WoW. The final path is `Interface/AddOns/Frostforge/Frostforge.toc`.

If using GitHub's **Code → Download ZIP**, open `Frostforge-main` and copy only the inner **Frostforge** folder. The other folders are source artwork, documentation, tests and development tools; they are not installed. Maintainers can [build client-specific packages](docs/maintainer/README.md#build-installable-zips).

On first login, follow the setup tour. Open `/frostforge`, choose a component, select the provider and theme, then enable and fit its artwork. **Player / Target / Focus → Artwork** includes separate portrait and full-frame previews with browsers for all designs.

For ElvUI circular portraits, use **Blinkii's Portraits** or **mMediaTag & Tools** with their circle options. Use **ElvUI's own unit frames** for the full-frame shells. The portrait and unit-frame providers are independent.

Updates replace the addon folder, not your `WTF` folder. Upgrading from the old `JiberishUI` folder requires a [one-time saved-settings transfer](docs/GETTING-STARTED.md#upgrading-to-frostforge). The [setup guide](docs/GETTING-STARTED.md) covers fitting, profiles, backups and troubleshooting.

## Help and credits

[Report a problem](https://github.com/jiberishxd/Frostforge/issues/new/choose) with your client/build, addon/provider versions and a screenshot. See [support](SUPPORT.md) for useful diagnostics, [advanced commands](docs/COMMANDS.md) or [contributing](CONTRIBUTING.md) for development work.

Blizzard artwork, icons, emblems and other Blizzard game assets depicted or referenced are © Blizzard Entertainment, Inc. World of Warcraft and Warcraft are trademarks or registered trademarks of Blizzard Entertainment, Inc. Jiberish's Frostforge is an independent fan-made addon and is not affiliated with, sponsored by or endorsed by Blizzard Entertainment.

[Artwork credits and provenance](Frostforge/CREDITS.md) describe the AI-assisted artwork process, retained source records and reuse limitations.
