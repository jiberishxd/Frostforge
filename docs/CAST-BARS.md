# Matching cast-bar borders (0.8.1)

Player, Target and Focus each have an optional border for their existing Blizzard, EllesmereUI or ElvUI cast bar. Open `/jui`, select the unit, then **Cast bar**. Enable **Cast-bar border**; it is off by default and independent of portrait and unit-frame toggles. The provider's own cast bar must also be enabled.

All borders use **Bold**, with no style selector. Older Subtle/Classic saved settings and backups automatically use Bold while retaining artwork, enabled state and fitting values. **Border weight** ranges from 0.5–2 and **Space around the bar** from 0–8 UI units; both default to 1. The border follows the actual bar dimensions and scale. Each of the 42 class/race/faction designs has dedicated painted rails with complete outer leaves, bindings and end details. Transparent margins let those details extend freely. The renderer preserves the full outer contour and uses equal X/Y scaling at the corners; only the connecting spans adapt to the bar. There is no center texture or cropped unit-shell rim.

**Border width (%)** and **Border height (%)** independently adjust the centered artwork from 50–150%; 100% follows the native cast bar. The native bar, fill and text are never resized. **Reset border fitting** returns width/height to 100%, weight to 1 and spacing to 1 without changing the enable toggle or selected artwork. Values below 100% deliberately bring artwork inside the native rectangle. All fitting changes wait until combat ends.

**Match unit artwork** follows the same class/race/faction/fixed selection and recognized city-NPC resolver as the unit's portrait and shell. **Browse** overrides only the cast border. Clicking Match unit artwork restores matching. Each unit keeps independent settings, included in JF2 backups. Reset component restores that unit's defaults, including turning the border off.

**Cast-bar provider** offers Automatic, Blizzard, EllesmereUI and ElvUI. Automatic searches the configured unit/portrait provider first, then Ellesmere, ElvUI and Blizzard, choosing a visible cast when available. With all casts idle it prefers an available visible addon root, then the first available candidate, so a hidden bar can be attached before combat. Use an explicit provider when running multiple cast-bar addons; an explicit choice never falls back to another one.

## Verified anchors and scope

- Blizzard Retail: `PlayerCastingBarFrame`, optional `OverlayPlayerCastingBarFrame`, and `TargetFrame.spellbar` / `FocusFrame.spellbar`.
- Blizzard Forever: the same fields plus `GamepadPlayerCastingBarFrame` when that player cast bar is active.
- EllesmereUI 9.2.9: Player first discovers `ERB_CastBarFrame._bar` from Resource Bars, then the Unit Frames mini bar. Target/Focus use `EllesmereUIUnitFrames_Target/Focus.Castbar`. A visible main Player bar wins; a visible mini bar is used when the main is inactive. When both are idle, the main bar is prepared before combat.
- ElvUI v15.26: `ElvUF_Player/Target/Focus.Castbar`, including its independently moved cast-bar holder.

These source paths and hashes are recorded in `cast-bar-sources.json`. Third-party sources were inspected read-only and are not bundled. Unit-frame shell support is still Blizzard/Ellesmere; the new ElvUI support here is specifically for its cast-bar border. Party, raid, pet, boss, nameplate and other third-party standalone cast bars are outside this feature.

Only horizontal bars with public geometry are decorated. Unavailable, forbidden, restricted or vertical bars remain untouched. The owned border uses the provider's strata by default and draws above its cast bar and known Ellesmere cast-art child. **Advanced → Cast-border strata** can override its strata independently of portrait and unit-frame art. The layout-only template allows attachment to Ellesmere Blizzard-style aura-layout bars where supported. It draws outside the progress rectangle at the default 100% fitting and never captures mouse or keyboard input. Native borders are retained. Very close icons, text outside the bar, sparks, shields or custom masks may need a smaller weight/spacing in the provider's layout.

JiberishUI does not read cast/channel/empower data, alter progress or timing, recolor the bar, replace its texture, move it, or modify native callbacks. Casts, channels, empowered stages, interrupt cues, latency, text and icons stay native. Attachment, fitting and option changes wait until combat ends. Existing unprotected border textures may follow automatic identity changes in combat; protected updates wait. Visibility and effective alpha are sampled every 0.05 seconds; geometry/provider discovery runs on the existing 0.2-second scan. Owned frames/textures are reused. A cast first created or resized during combat may have to wait until combat ends for its border to attach/refit.

## Manual validation

The Lua mock exercises all three providers on Retail and Forever paths. The browser comparison uses the exact exported runtime border pieces, not a separate fitted painting. These checks do not establish live-client validation. Without automating gameplay, the user should:

1. Enable one unit's border and confirm the other two units and all portrait/shell toggles stay independent. Try Reset border fitting and a JF2 export/import.
2. Start and finish a cast/channel, interrupt it, and test an empowered cast where available. Confirm native progress, labels, icons, shields and stage indicators remain intact, with no lingering border after the bar fades/hides.
3. Try width, height, weight and spacing, a fixed border theme and Match unit artwork. Target players/NPCs with different artwork selections.
4. Move/resize the provider cast bar, change profiles, reload and switch provider. Confirm the border follows, old borders disappear and backups restore the settings.
5. Change settings in combat; confirm changes apply after combat without errors. Toggle the feature off and verify the provider retains all of its own appearance and behavior.

Use `/jui status` for a per-unit cast-border provider/status line. No WoW interaction was performed during development.

The settings status distinguishes **Ellesmere Resource Bars** from **Ellesmere Unit Frames**, and reports whether the border is attached waiting for a cast or following a visible cast. If attachment fails, `/jui status` includes the frame-operation error.
