# Changelog

## 1.0.0

- First official release, with separate downloads for Retail 12.1.0 and Forever 1.60.1.
- Includes 42 class, race and faction themes for portraits, unit frames, cast bars, minimaps and action hubs, plus compact Party and Target of Target borders.
- Includes the setup tour, saved profiles, supported UI-addon integrations, and the blue Frostforge settings entry inside the Escape menu.
- Preserves existing Frostforge settings when upgrading from 0.9.x. Choose the package for your client and keep your saved settings.

## 0.9.16

- Fix the missing Game Menu row by assigning its blue label before accessing the native button's lazily created font string. Optional provider styling failures now leave the menu entry visible and usable. Regression tests cover fresh buttons and failed provider styling. The row is confirmed visible in-game with EllesmereUI; combat and protected-action checks remain on the validation checklist.

## 0.9.15

- Place the blue Frostforge button inside the Escape menu, directly after AddOns, matching the native row size and font and supporting EllesmereUI/ElvUI styling. The button stays outside Blizzard's shared pool; only row positions and menu height change after native layout. Combat layout changes wait until combat ends.

## 0.9.14

- Fix Frostforge's Game Menu integration tainting native Logout and Exit Game actions. The launcher now sits below the menu, outside Blizzard's shared button pool, with a blue Frostforge label. Reload the UI after installing to clear the old hook and taint; in-game confirmation is still required.

## 0.9.13

- Add `/jf partydebug` (also `/jf status party`) to report each party frame's attachment, unit assignment and visibility/opacity checks. It handles unavailable or restricted reads without requiring a pasted script. This diagnostic update does not change rendering; the remaining EllesmereUI party-border issue is still under investigation.

## 0.9.12

- Fix missing EllesmereUI party-member borders and portraits when native range fading uses protected opacity. Keep provider fading, Frostforge opacity and party sorting intact.

## 0.9.11

- Align all 42 castbar borders to the same painted opening so class, race and faction changes retain a consistent fit, including during combat. Also applies to the shared Party and Target of Target borders. Original artwork and saved fitting settings are preserved.

## 0.9.10

- Start Action Hubs at 900 × 240, screen anchored, with offsets 0 / -14, scale 1 and opacity 1. Saved custom placement is preserved.

## 0.9.9

- Fix Party and Target of Target layering above provider borders and highlights, including combat layer changes. Add an independent compact-border level control under Advanced.
- Add **Frostforge** to the Escape Game Menu, opening the addon settings directly.

## 0.9.8

- Compact castbar-style borders for Target of Target and Party frames, using all 42 existing designs.
- Party portrait surrounds for supported Blizzard, ElvUI and EllesmereUI layouts, with individual member matching and independent fitting controls.
- Existing images and native frame controls are unchanged. Live group/combat validation is still required.

## 0.9.7

- Illustrated first-login tour with Blizzard, ElvUI and Ellesmere guidance.
- Full unit-frame artwork browser alongside portraits; fixed the Neutral flash when clearing targets.
- Reduced repeated layout work and initial settings allocations; existing artwork quality is unchanged.
- Smaller player packages, shorter documentation, Discord support links and removal of unused legacy source artwork.

## 0.9.6–0.9.5

Renamed the source/install folder to **Frostforge**. Older JiberishUI installs need the [one-time settings transfer](GETTING-STARTED.md#upgrading-to-frostforge).

## 0.9.4–0.9.1

Improved combat artwork switching, custom power colors, cast-border layering and selected-button highlights. Added setup/access options, linked portrait sizing, minimap improvements and Night Elf artwork refinements.

## 0.9.0

Renamed the addon **Jiberish's Frostforge**, with the penguin logo and frosted settings style.

Earlier changes remain in [Git history](https://github.com/jiberishxd/Frostforge/commits/main/). For questions or feedback, [join The Igloo Discord](https://discord.com/servers/igloo-460933747731070996).
