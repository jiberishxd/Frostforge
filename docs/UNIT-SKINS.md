# Independent portrait and Blizzard unit-frame artwork

Build 0.7.1 exports all 42 source shells without squeezing their dividers or cutting their upper shoulders. Paladin restores the official class-inspired crowned lion inside its flared-wing endcap. The 126 portrait, hub and minimap textures remain unchanged. In `/jui`, select Player, Target or Focus. **Portrait art** controls only the decorative portrait surround. **Unit-frame artwork** controls the separate sculpted shell and painted health/power fills. Both settings are independent per unit; either, both, or neither may be enabled. The native portrait itself stays under Blizzard's control. Existing `unitStyle=FULL` settings migrate to `unitFrameShown=true` without changing portrait visibility. The default is portrait art on and unit-frame artwork off.

The full skin combines a substantial sculpted shell with painted health/power materials. All 42 class/race/faction identities have original shells inspired by their existing portraits and the Warcraft identity references recorded in the artwork provenance. Each has its own full-bleed health and power material. Blizzard's health/reaction and mana/rage/energy hues remain native. There are no new portrait or level-badge circles.

Every source is uniformly contained in a transparent 512 × 256 atlas. The fitter records each painting’s actual health/power openings. It does not erase a rectangular name corridor, warp shoulders or force the divider into a four-pixel band. Thirteen decorative sections register to the two actual bars. The existing power bar is aligned below health, with width, height and gap derived from those openings. At a 20-unit health height, the Priest separator is about 6.6 UI units, matching the source ratio. Endcap proportions follow health height and effective scale; center spans follow bar width. The lower ornament hangs below power. Target/Focus mirror the artwork. Portrait sliders remain independent. Native bar layouts outside the pinned baselines require in-game fitting checks.

Blizzard keeps the StatusBars, values, fill direction, masks, predictions, labels, resources and secure clicks. The addon changes the existing fill region's texture/UVs and the power bar’s presentation geometry. It snapshots the power bar’s points and size first; health geometry is unchanged. Two addon-owned, mouse-transparent shell halves follow the bars, use the unit's configured strata/level/draw layer, and default to BACKGROUND behind native controls. Raising these settings may cover native UI. No secure object is reparented or replaced. Turning off unit-frame artwork or resetting the component restores captured native appearance and power geometry; hiding portrait artwork has no effect on the bars; texture redraws update the restoration record. New attachment, power fitting/restoration, fill changes/restoration and shell reconfiguration wait until combat ends. The latest queued setting wins.

Shells follow Blizzard bars independently of the selected portrait provider. Blinkii, mMediaTag, ElvUI and EllesmereUI portrait surrounds can coexist with a skin on visible Blizzard bars. Replacement addon bars retain their provider's styling; if the native bars are hidden, the JiberishUI shells hide too.

Commands:

```text
/jf set playerFrame unitFrameShown on
/jf set targetFrame unitFrameShown on
/jf set focusFrame unitFrameShown on
/jf set playerFrame shown off
/jf set playerFrame unitFrameShown off
```

Source paths are verified against the Retail and Forever revisions in `phase1-sources.json`. Retail Player uses PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar and ManaBarArea.ManaBar. Target/Focus use TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar and ManaBar. Forever first follows `healthbar` and `manabar`, which its `UnitFrame_Initialize` binds to the active native bars. Verified Mainline child paths remain a fallback before those bindings exist. Every inspected frame must be present and non-forbidden. Shell layout requires only public bar geometry. Unreadable or unrestorable fill metadata retains the native fill while leaving the shell visible; metadata is retried without reading health/power values. `/jui status` and the options window report shell/fill status separately.

Offline checks cover restoration, native redraws, combat queuing, hidden/replaced/forbidden bars, source-proportional fitting, power geometry restoration, source changes, settings and frame/hook reuse. They cannot certify WoW's secure engine. Live tests must cover resource changes, combat, vehicles, prediction overlays, target/focus switching and turning the mode off on both clients. The standalone fitting comparison is in `artwork/unit-frames/index.html`.
