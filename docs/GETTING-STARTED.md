# Getting started with Jiberish's Frostforge

Frostforge decorates your existing interface. Start with one component, choose its provider and artwork, then adjust the fit before moving on to the rest of your layout.

## Install or update

Use the package for your game client: **Retail** or **Forever**, or [build one from source](maintainer/README.md#build-installable-zips). If using GitHub's **Code → Download ZIP**, open `Frostforge-main` and copy only the inner **`Frostforge`** folder into your AddOns directory. That folder contains `Frostforge.toc` and supports both clients; the surrounding artwork, docs, tests and tools are development files.

1. Close WoW. If upgrading from an installation named `JiberishUI`, complete the [one-time settings transfer below](#upgrading-to-frostforge) first.
2. Extract the package. Place the entire `Frostforge` folder inside your client's `Interface/AddOns/` directory. The final path should be `Interface/AddOns/Frostforge/Frostforge.toc`, without an extra nested folder.
3. For subsequent updates, replace only the old `Frostforge` addon folder. Keep `WTF` and your saved settings. Replacing the folder avoids leaving retired artwork files behind.
4. Fully restart the client, enable **Jiberish's Frostforge** in the AddOns list, and follow the short setup wizard after logging in for the first time.

Keep the complete Frostforge folder together: Lua code, theme data and every Media subfolder—including branding, settings and setup images—are needed. An integration also requires its original UI addon and the relevant frame/portrait/cast-bar module to be enabled.

## Quick setup and opening settings

The first-launch tour has four screens: an in-game artwork example, illustrated tips for **Blizzard UI / ElvUI / EllesmereUI**, starting themes and decorations, then easy ways to open settings. Click the interface tabs to read the tips; this does not change your provider. Nothing changes until **Finish & open settings**. **Skip setup** completes the tour without changes. Escape postpones an unfinished first-run tour until next login; loading screens preserve it. Rerun it anytime from **Guide → Run quick setup**. Existing installations keep their setup without an automatic tour.

Open settings from the **AddOn Compartment**, the **Frostforge** section of ElvUI settings, or `/frostforge`. Enable **Show minimap settings icon** in Guide if you want a clickable penguin beside the map; drag it around the map to reposition it. These access preferences apply across characters. Protected changes and opening the window wait until combat ends.

## Keep a separate setup for each character

Open **Profiles** on the left. Each character gets its own initial setup and remembers its assigned profile. Enter a name such as **Paladin raids** and choose **Rename active profile**, or use **Save as new profile** to make an independent copy. New alts start with automatic class artwork. Selecting an existing profile deliberately shares that profile's future edits across characters.

**Use selected for this character** assigns an existing profile; **New profile from defaults** creates a clean one. Profile creation and switching wait until outside combat. Profiles include all Frostforge components, providers, fitting and appearance settings; other addons keep their own profiles.

When upgrading from a single-setup build, the first character receives **Imported setup** and later characters start separately. A Guide backup contains the active profile's artwork settings, not the entire library or character assignments. Restoring into a shared profile changes it for every character using it; make a separate copy first when needed.

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

**Browse portrait art** and **Browse frame art** show all 42 designs, with class/race/faction categories, search and pages. Choosing a design changes the shared theme for this unit without enabling either toggle. Portrait and shell toggles are independent; their theme follows the unit's artwork choice. Player, Target and Focus keep separate settings. Automatic target/focus artwork can change as you select different units. Recognized city NPC affiliations reuse existing race art. Fixed artwork takes priority; unrecognized or unavailable identity information can fall back to Neutral.

For **EllesmereUI**, use a separate portrait and horizontal health with power attached and aligned below it for full shells. For **ElvUI**, full unit-frame shells also support horizontal health with attached full-width power below it; inset, mini/spaced, offset and detached power layouts are not fitted. Choose an explicit provider if Automatic finds a different frame than you intended. [Full compatibility guide](ADDON-COMPATIBILITY.md).

## Fit the artwork

- **Placement:** one portrait size slider changes width and height together. **Advanced sizing** exposes separate dimensions. Existing custom proportions stay intact until you change the size. X/Y, scale, opacity and anchoring remain separate.
- **Unit frame:** shell width/height from 75–150%, plus horizontal/vertical offsets. Reduce width to bring the original edges over the fill. Reset fitting returns to the default overlap without changing portrait settings.
- **Blizzard:** hide the stock portrait image, customize the native name's X/Y, font size, alignment and outline, and toggle stone on all stock health/power bars. Native portrait and text controls apply outside combat and restore when disabled; see [Blizzard frame controls](#blizzard-frame-controls).
- **Cast bar:** enable its independent Bold border, then set width/height from 50–150%, weight and spacing. Match unit artwork follows the chosen portrait/shell theme; Browse sets a separate cast theme. The provider's own cast bar must be enabled.
- **Minimap / Action hub:** choose automatic player class/race/faction or fixed artwork, then fit its size and position. The minimap art sits above the map and expects a circular opening. **Use a round minimap (ElvUI)** switches an enabled ElvUI map to round while art is applied, then restores the previous shape when either switch is turned off. Other minimap addons keep their own shape controls. Action hubs follow the main action bar. Set your actual button layout in its original addon.

**Advanced** has independent strata for portrait art and unit-frame art. **Cast bar** has cast-border strata and level. Automatic shell/cast strata follow the supported default/provider; an explicit choice affects only that artwork.

Settings save immediately. Changes that need to wait for combat apply when combat ends. To reposition a functional frame, use Blizzard Edit Mode or that UI addon's settings.

## Match health and power textures

Open your provider's status-bar texture menu and choose **Frostforge Stone**. EllesmereUI and ElvUI supply the shared-media library used to make this available; other addons with compatible LibSharedMedia menus can use it too.

In `/jui → Player/Target/Focus → Advanced`, **Automatic (respect UI addon)** keeps ElvUI/Ellesmere's selected textures and uses Frostforge fills on Blizzard frames. The separate **Blizzard → Stone on Blizzard health/power** toggle is on by default and takes precedence for stock bars, including party, raid, pet, boss and target-of-target/focus-target. Turn it off as well if you want entirely stock fills. **Keep provider textures** leaves the fills with the provider. **Use Frostforge fills** explicitly applies Frostforge materials while the shell is enabled. Native class, health and resource tinting stays with the frame provider.

## Blizzard frame controls

Open **Player / Target / Focus → Blizzard**. Hide the stock portrait image or its full surround independently. Choose **Name**, **Health**, **Power**, **Level**, **Cast name** or **Cast time** to customize that label's position, size, alignment and outline. Each group has its own reset; **Restore stock portrait & all text** restores the selected unit.

**Colors & textures** controls name color (Blizzard or Class), health color (Blizzard, Class gradient or Dark stone), and separate stock health/power textures (Automatic, Frostforge Stone, Smooth or Blizzard). **Power colors** offers native resource, player class or custom hex color, plus Solid or Gradient shading. **Choose color** opens the picker; Cancel restores the previous choice. Shared **Party & raid** choices are separate from Player/Target/Focus settings. These controls do not require decorative shells and affect Blizzard frames only; configure ElvUI/Ellesmere colors in those addons.

The shared **Stone for Automatic texture** switch covers existing stock player, target, focus, party, raid, pet, boss and secondary-target health/power bars. It adds no ornamental shells to party or raid frames. Explicit texture choices take precedence. For entirely stock fills, turn off the stone switch, select Blizzard textures and use **Keep provider textures** for any enabled shells. Dark stone or custom coloring can still require a neutral fill.

For Target and Focus, **Buffs & debuffs...** and **Cast-bar position...** each offer **Customize position** and X/Y offsets. Positive values move right/up. Buffs and debuffs move together; moving them can also move a cast bar anchored beneath them. Reset or disable restores native placement. Position changes wait until combat ends; the status beside the controls explains pending changes.

## Cast-bar borders

Open **Player / Target / Focus → Cast bar** and enable **Cast-bar border**. It starts off; the selected provider must also have its own cast bar enabled. **Match unit artwork** follows the portrait/frame theme, while **Browse** chooses a separate cast design. Each unit has independent settings.

All 42 designs use the Bold border. **Border width/height** range from 50–150%, **Border weight** from 0.5–2 and **Space around the bar** from 0–8. **Reset border fitting** restores 100% width/height, weight 1 and spacing 1 without changing the theme or toggle. These controls fit the art without resizing the functional bar.

**Cast-border strata** and **Level above nearby artwork** control the border independently of portrait/frame art. Automatic layering follows the native bar and nearby decorations. Blizzard's stock rim/textbox trim is hidden while its Frostforge border is attached and restored when disabled; spell labels, progress, sparks and shields remain native. Fitting and provider changes wait until combat ends. Bars created or resized during combat may wait until then to attach or refit. See [cast-bar compatibility](ADDON-COMPATIBILITY.md#cast-bar-borders).

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
| Forever settings do not survive restart | Keep a backup and read the saved-settings note below. |

For a report, include your client/build, Frostforge and provider versions, the affected component, `/jui status`, and a screenshot showing the problem. [Open an issue](https://github.com/jiberishxd/Frostforge/issues/new/choose).

An earlier Forever report found saved settings missing at startup even though valid saved data existed on disk. Profile selection and the folder-name migration do not establish a fix for that client-loading issue. `/jf status` reports whether settings were received or created. Keep a Guide backup and your original WTF files; do not delete WTF as a troubleshooting step. Offline persistence tests cannot confirm actual logout/login behavior on your client. Unknown or future settings formats are preserved without writes.

## Upgrading to Frostforge

Version 0.9.5 changes the install folder from `JiberishUI` to `Frostforge`. WoW loads saved files by addon folder name, so retaining the same database variables alone does not move the old files. This one-time transfer preserves the complete profile library, character assignments, setup progress and access preferences:

1. Fully close WoW and make a backup copy of your client's `WTF` folder.
2. Under `WTF/Account/<account>/SavedVariables/`, copy `JiberishUI.lua` to `Frostforge.lua` in the same directory.
3. For each character you use, repeat that copy under `WTF/Account/<account>/<realm>/<character>/SavedVariables/`. Repeat for each account and client installation you use. Keep the original files, and do not change anything inside them. If `Frostforge.lua` already exists, keep both versions backed up and choose the settings you want to retain before replacing it.
4. Remove the old `Interface/AddOns/JiberishUI` addon folder and install the new package's `Frostforge` folder. Do not run both copies together. Fully restart WoW.

For just the active profile's artwork settings, an alternative is **Guide → Copy settings backup** in the old installation, followed by importing that backup into the new installation. This alternative does not transfer the entire profile library or other characters' assignments.

Fresh installs need no transfer; later `Frostforge` updates use the same saved files. Database variable names stay `JiberishUIDB` and `JiberishUICharacterDB` for compatibility. `/frostforge`, `/jui`, `/jf` and `/jiberishui` open the same window. The old **JiberishUI Stone** texture name remains an alias for **Frostforge Stone** so existing provider selections still load.

Choose **The Igloo** in the sidebar to select `https://theigloo.io`. Copy with Ctrl+C (Command+C on Mac) and paste into your browser.

## ElvUI portraits and frame artwork

For Frostforge’s circular portrait art, we recommend **Blinkii’s Portraits** or **mMediaTag & Tools** and their circular portrait customization. Use **ElvUI’s own unit frames** for Frostforge’s full unit-frame artwork: horizontal health with full-width power attached below. In Frostforge, choose your portrait addon under **Portrait provider** and **ElvUI** under **Unit-frame provider**, or keep Automatic when it detects the intended frames. These choices are independent. The setup tour includes the same guidance.
