<p align="center"><img src="docs/images/emblem.png" width="112" alt="JiberishUI gold compass emblem"></p>

# JiberishUI

**Bring the grit, craft, and character of Warcraft into your interface.**

JiberishUI adds sculpted artwork around your portraits, health and power bars, cast bars, action bars, and minimap. Build a matching look for your class, race, or faction—from Paladin wings and Priest stonework to Druid roots and Shaman totems.

[Artwork gallery](docs/GALLERY.md) · [Getting started](docs/GETTING-STARTED.md) · [Compatibility](#works-with-your-ui) · [Report an issue](https://github.com/jiberishxd/JiberishUI-WoW/issues/new/choose)

![A selection of JiberishUI portrait, unit-frame, cast-bar, action-hub and minimap artwork](docs/images/overview.jpg)

*Artwork showcase using the addon's actual textures. See the gallery for labeled previews and an early in-game capture.*

**Current source: 0.8.3 · Development preview.** Retail and Forever packages are built separately. Automated checks cover behavior, artwork fitting and packaging; live-client compatibility and custom layouts still need player testing. There are no packaged [GitHub releases](https://github.com/jiberishxd/JiberishUI-WoW/releases) published yet. To test from source, [build an installable ZIP](docs/DEVELOPMENT.md#build-installable-zips).

## Make it your own

- **42 matching themes:** 13 classes, 26 races, and Alliance, Horde and Neutral. Each has portrait, unit-frame, action-hub, minimap and cast-bar artwork.
- **Independent artwork toggles:** use portrait surrounds, full unit-frame shells and cast-bar borders separately on Player, Target and Focus.
- **Automatic identity:** follow a unit's class, race or faction, or choose a fixed design. Recognized city NPCs use the matching existing race artwork; for example, Undercity → Undead and Stormwind → Human.
- **Fit your layout:** adjust size, offsets, scale and layers. Portrait art, unit-frame art and cast borders each have their own strata. Unit-frame shells have separate width, height and position controls. Bold cast borders have their own width, height, weight and spacing.
- **Stock Blizzard controls:** hide the portrait image or its full stock surround, adjust each name label, and use plain stone on health and power—including party and raid bars.
- **A shared stone material:** choose **JiberishUI Stone** in compatible EllesmereUI, ElvUI and other LibSharedMedia status-bar texture menus.
- **A Warcraft-style settings workshop:** searchable artwork collections, per-component controls, reset options and copy/paste settings backups.
- **Character profiles:** save named setups and assign them per character. New alts start separately; copy a layout or deliberately share one. [Profile guide](docs/PROFILES.md).

Your frame provider continues to handle health and power values, casts, names, portraits, auras and clicks. JiberishUI's decorations are click-through. Full unit-frame styling can apply fill textures and fit power-bar spacing to the artwork; disabling it restores the provider's layout and any fills it managed. The separate stock-wide stone toggle can keep Blizzard bars textured even without shells.

## Works with your UI

These are the integrations implemented in the current build. Support depends on the provider's enabled modules and layout; this table is not a claim that every combination has been validated in game.

| UI / addon | Portrait art | Full unit-frame shells | Cast-bar borders | Action hub |
| --- | --- | --- | --- | --- |
| **Blizzard UI** | Yes | Yes | Yes | Yes |
| **EllesmereUI** | Yes, with a separate portrait | Yes, for compatible bar layouts¹ | Yes | Yes |
| **ElvUI** | Yes, with a separate portrait | Not implemented | Yes | Yes |
| **Blinkii's Portraits** | Yes | Uses another provider | Uses another provider | Uses another provider |
| **mMediaTag & Tools** | Yes, through ElvUI | Not implemented | Uses ElvUI | Uses ElvUI |

¹ Ellesmere full shells require horizontal health with power attached and aligned below it. Detached, hidden, above-health or vertical power layouts do not receive a full shell. Separate/circular portraits give the closest portrait fit; portraits drawn inside health bars have no separate surround to decorate.

The **minimap surround** follows the shared minimap and is designed for a circular map. Action hubs decorate the main bar; keep your preferred addon in charge of its buttons and layout. **JiberishUI Stone** can also be used on other frames through your provider's texture settings, including ElvUI frames without JiberishUI shells.

Third-party addons must support your game client themselves. JiberishUI does not make a Retail-only addon work on Forever. [Detailed provider setup and limitations](docs/ADDON-COMPATIBILITY.md).

## Get started

1. Install the matching **Retail** or **Forever** ZIP. Put its `JiberishUI` folder directly inside your client's `Interface/AddOns/` directory, then fully restart WoW.
2. Enable JiberishUI and your preferred UI addon. Open **`/jui`**.
3. Choose **Player**, **Target** or **Focus**. In **Artwork**, select automatic class/race/faction matching or browse for a fixed design.
4. Enable **Portrait art** and **Unit-frame art** independently. Portraits start on; full shells start off. Choose the correct providers when using multiple UI addons.
5. Open **Cast bar** to enable its separate border; the provider's cast bar must also be enabled. Then choose matching **Minimap** and **Action hub** artwork if you want a coordinated set.

Settings save as you go. Fitting changes that need to wait for combat apply afterward. Use **Placement** for portraits, **Unit frame** for shell fitting, and **Cast bar** for cast-border fitting. Use **Blizzard** for stock portrait/name controls and the stock-wide stone toggle (on by default); **Cast bar** exposes cast-border strata; **Advanced** has portrait/shell strata and a separate cast-border level. Your provider's settings still control where its functional frames sit.

![The JiberishUI settings workshop with separate portrait and unit-frame controls](docs/images/settings.jpg)

*Offline settings preview exported from the addon's settings code; fonts and native panel textures are browser approximations.*

For a clean update, close WoW and replace only the existing `Interface/AddOns/JiberishUI` folder. Keep your `WTF` folder and saved settings. [Full setup and troubleshooting](docs/GETTING-STARTED.md).

## Help, feedback and development

- **Missing art or a fitting problem?** Check the toggle and provider for that component, then include `/jui status`, your client/addon versions, and a screenshot in a [bug report](https://github.com/jiberishxd/JiberishUI-WoW/issues/new/choose).
- **Want to share a layout or request an improvement?** Open an [issue](https://github.com/jiberishxd/JiberishUI-WoW/issues/new/choose). [Support guide](SUPPORT.md).
- **Want to contribute?** Read the [contributor guide](CONTRIBUTING.md), [local build instructions](docs/DEVELOPMENT.md), and [validation checklist](docs/VALIDATION.md).

This build decorates Player, Target, Focus, the main action hub and minimap. The plain stone material also covers stock party, raid, pet, boss, target-of-target and focus-target health/power bars; ornamental shells remain limited to Player/Target/Focus. Nameplates are outside this feature. A reported Forever saved-settings loading issue is documented in the [persistence notes](docs/PERSISTENCE.md); keep a settings backup while testing.

JiberishUI is an independent community project. [Artwork credits and source references](docs/ARTWORK-CREDITS.md) · [Test results](docs/TEST-RESULTS.md) · [Advanced commands](docs/COMMANDS.md).
