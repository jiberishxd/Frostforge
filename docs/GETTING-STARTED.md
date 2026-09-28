# Getting started with Jiberish's Frostforge

Frostforge decorates your existing interface. Start with one component, choose its provider and artwork, then adjust the fit before moving on to the rest of your layout.

## Install or update

Use the package for your game client: **Retail** or **Forever**. GitHub currently has no published release ZIPs; [build the current source](DEVELOPMENT.md#build-installable-zips) to test it. The repository's **Code → Download ZIP** archive contains the whole development project and is not an installable addon package.

1. Close WoW.
2. Extract the package. Place the entire `JiberishUI` folder inside your client's `Interface/AddOns/` directory. The final path should be `Interface/AddOns/JiberishUI/JiberishUI.toc`, without an extra nested folder.
3. For an update, replace only the old `JiberishUI` addon folder. Keep `WTF` and your saved settings. Replacing the folder avoids leaving retired artwork files behind.
4. Fully restart the client, enable **Jiberish's Frostforge** in the AddOns list, and follow the short setup wizard after logging in for the first time.

Keep the complete package together: Lua code, theme data and all five active media folders—Portraits, Hubs, Minimaps, UnitFrames and CastBars—are needed. An integration also requires its original UI addon and the relevant frame/portrait/cast-bar module to be enabled.

## Quick setup and opening settings

The first-launch wizard has three steps: choose automatic Class/Race/Faction art, choose the decorations to enable, then choose an optional minimap icon and round ElvUI map. Nothing changes until **Finish & open settings**. Skip or Escape dismisses it; rerun it from **Guide → Run quick setup**. Existing installations keep their current setup without an automatic wizard.

Open settings from the **AddOn Compartment**, the **Frostforge** section of ElvUI settings, or `/frostforge`. Enable **Show minimap settings icon** in Guide if you want a clickable penguin beside the map; drag it around the map to reposition it. These access preferences apply across characters. Protected changes and opening the window wait until combat ends.

## Keep a separate setup for each character

Open **Profiles** on the left. Each character gets its own initial setup and remembers its assigned profile. Enter a name such as **Paladin raids** and choose **Rename active profile**, or use **Save as new profile** to make an independent copy. New alts start with automatic class artwork. Selecting an existing profile deliberately shares that profile's future edits across characters. [Profile setup and migration](PROFILES.md).

## Choose a look

Select **Player**, **Target** or **Focus** on the left, then open **Artwork**.

| Control | What it changes |
| --- | --- |
| Portrait art | The decoration around this unit's portrait. Starts on. |
| Unit-frame art | The sculpted shell around health and power. Starts off. |
| Automatic class / race / faction | Follows this unit's identity. |
| Browse | Chooses a fixed theme for this unit. |
| Portrait provider | Which addon's separate portrait receives the surround. |
| Unit-frame provider | Which addon's bars receive the shell. |

Portrait and shell toggles are independent; their theme follows the unit's artwork choice. Player, Target and Focus keep separate settings. Automatic target/focus artwork can change as you select different units. Recognized city NPC affiliations reuse existing race art. Fixed artwork takes priority; unrecognized or unavailable identity information can fall back to Neutral.

For **EllesmereUI**, use a separate portrait and horizontal health with power attached and aligned below it for full shells. For **ElvUI**, full unit-frame shells also support horizontal health with attached full-width power below it; inset, mini/spaced, offset and detached power layouts are not fitted. Choose an explicit provider if Automatic finds a different frame than you intended. [Full compatibility guide](ADDON-COMPATIBILITY.md).

## Fit the artwork

- **Placement:** one portrait size slider changes width and height together. **Advanced sizing** exposes separate dimensions. Existing custom proportions stay intact until you change the size. X/Y, scale, opacity and anchoring remain separate.
- **Unit frame:** shell width/height from 75–150%, plus horizontal/vertical offsets. Reduce width to bring the original edges over the fill. Reset fitting returns to the default overlap without changing portrait settings.
- **Blizzard:** hide the stock portrait image, customize the native name's X/Y, font size, alignment and outline, and toggle stone on all stock health/power bars. The rim and level badge remain native. Name and portrait changes apply outside combat and restore when disabled.
- **Cast bar:** enable its independent Bold border, then set width/height from 50–150%, weight and spacing. Match unit artwork follows the chosen portrait/shell theme; Browse sets a separate cast theme. The provider's own cast bar must be enabled.
- **Minimap / Action hub:** choose automatic player class/race/faction or fixed artwork, then fit its size and position. The minimap art sits above the map and expects a circular opening. **Use a round minimap (ElvUI)** switches an enabled ElvUI map to round while art is applied, then restores the previous shape when either switch is turned off. Other minimap addons keep their own shape controls. Action hubs follow the main action bar. Set your actual button layout in its original addon.

**Advanced** has independent strata for portrait art and unit-frame art. **Cast bar** has cast-border strata and level. Automatic shell/cast strata follow the supported default/provider; an explicit choice affects only that artwork.

Settings save immediately. Changes that need to wait for combat apply when combat ends. To reposition a functional frame, use Blizzard Edit Mode or that UI addon's settings.

## Match health and power textures

Open your provider's status-bar texture menu and choose **Frostforge Stone**. EllesmereUI and ElvUI supply the shared-media library used to make this available; other addons with compatible LibSharedMedia menus can use it too.

In `/jui → Player/Target/Focus → Advanced`, **Automatic (respect UI addon)** keeps ElvUI/Ellesmere's selected textures and uses Frostforge fills on Blizzard frames. The separate **Blizzard → Stone on Blizzard health/power** toggle is on by default and takes precedence for stock bars, including party, raid, pet, boss and target-of-target/focus-target. Turn it off as well if you want entirely stock fills. **Keep provider textures** leaves the fills with the provider. **Use Frostforge fills** explicitly applies Frostforge materials while the shell is enabled. Native class, health and resource tinting stays with the frame provider. [Texture setup details](SETTINGS.md#choose-frostforge-stone-in-your-other-ui-addon).

## Back up and troubleshoot

Open **Guide** to copy a settings backup or restore one. Restore replaces the Frostforge settings for all five components; **Reset component** restores only the selected component. `/jui status` prints attachment and settings diagnostics. `/jf export` and `/jf import` remain available for command-based backups.

| What you see | Check first |
| --- | --- |
| Portrait shows, but the health/power shell does not | Enable Unit-frame art separately; select Blizzard or a compatible ElvUI/Ellesmere layout. |
| No portrait artwork on an addon frame | Enable a separate portrait in that addon; check Portrait provider. Inside-health portraits have no separate surround. |
| No cast border | Enable Cast-bar border and the provider's cast bar. Its border follows cast visibility. |
| A border is too wide, too tall or offset | Use that component's fitting controls and reset fitting if needed. |
| The health texture keeps changing | Select Frostforge Stone in the provider and use Automatic or Keep provider textures in Frostforge. |
| New artwork files are missing after updating | Check the installed folder path and fully restart the client. |
| Forever settings do not survive restart | Export a backup and check the reported [SavedVariables loading issue](PERSISTENCE.md). |

For a report, include your client/build, Frostforge and provider versions, the affected component, `/jui status`, and a screenshot showing the problem. [Open an issue](https://github.com/jiberishxd/JiberishUI-WoW/issues/new/choose).

For stock Blizzard colors and textures, open **Player/Target/Focus → Blizzard → Colors & textures**. Choose class-colored names/health or dark stone health, and pick health/power textures separately. The dialog also includes shared party/raid color controls. These choices work independently of decorative shells.

## Upgrading to Frostforge

The display name changed in 0.9.0. Keep the `JiberishUI` folder and existing saved settings: profiles and backups remain compatible. `/frostforge`, `/jui`, `/jf` and `/jiberishui` open the same window. The old **JiberishUI Stone** texture name remains an alias for **Frostforge Stone** so existing provider selections still load.

Choose **The Igloo** in the sidebar to select `https://theigloo.io`. Copy with Ctrl+C (Command+C on Mac) and paste into your browser.
