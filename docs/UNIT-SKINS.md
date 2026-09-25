# Optional full Blizzard unit-frame skins

Build 0.7.0-art.1 adds Full unit frame style independently to Player, Target and Focus. In `/jui`, select the unit tab and click **Style: Portrait only** to enable **Style: Full unit frame**. Click again to restore native fills. The default remains portrait-only, and all existing portrait artwork/settings are retained.

The full skin combines a substantial sculpted shell with painted health/power materials. All 42 class/race/faction identities have original shells inspired by their existing portraits and the Warcraft identity references recorded in the artwork provenance. Each has its own full-bleed health and power material. Blizzard's health/reaction and mana/rage/energy hues remain native. There are no new portrait or level-badge circles.

Every 512 × 256 shell has the same clear health opening (96,84)-(396,132), power opening (96,136)-(396,160), and name corridor (96,0)-(396,70). Thirteen decorative sections register to the two actual bars. Endcap proportions follow health height and effective scale; center spans follow bar width. The lower ornament hangs below power. Target/Focus mirror the artwork. Portrait sliders remain independent. Native bar layouts outside the pinned baselines require in-game fitting checks.

Blizzard keeps the StatusBars, values, fill direction, masks, predictions, labels, resources and secure clicks. The addon changes only the existing fill region's texture/UVs. Two addon-owned, mouse-transparent shell halves follow the bars, use the unit's configured strata/level/draw layer, and default to BACKGROUND behind native controls. Raising these settings may cover native UI. No secure object is reparented or replaced. Turning off/hiding/resetting the component restores captured native appearance; texture redraws update the restoration record. New attachment, fill changes/restoration and shell reconfiguration wait until combat ends. The latest queued setting wins.

Full styling is scoped to the Blizzard provider. Blinkii, mMediaTag, ElvUI and EllesmereUI portrait surrounds can still be used, but their bars keep their provider's styling. Selecting an external source restores/suspends the native skin; returning to Blizzard resumes it if FULL is still selected.

Commands:

```text
/jf set playerFrame unitStyle FULL
/jf set targetFrame unitStyle FULL
/jf set focusFrame unitStyle FULL
/jf set playerFrame unitStyle PORTRAIT
```

Source paths are verified against the Retail and Forever revisions in `phase1-sources.json`. Retail Player uses PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar and ManaBarArea.ManaBar. Target/Focus use TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar and ManaBar. Forever has separate resolver code for its verified Mainline structures with Camelot overrides. Each intermediate object must be present and non-forbidden. Secret/unrestorable texture metadata prevents styling that region rather than guessing.

Offline checks cover restoration, native redraws, combat queuing, hidden/replaced/forbidden bars, identical theme fitting, source changes, settings and frame/hook reuse. They cannot certify WoW's secure engine. Live tests must cover resource changes, combat, vehicles, prediction overlays, target/focus switching and turning the mode off on both clients. The standalone fitting comparison is in `artwork/unit-frames/index.html`.
