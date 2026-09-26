# Changelog

## 0.8.8 — Target/Focus aura positioning

- Fix Blizzard aura layout updates overwriting both horizontal and vertical offsets. Reapply the saved position directly after the native anchor update, using the public aura-container accessor with the existing XML path as a fallback.
- Keep fresh native anchor baselines, including above/below flips, threat spacing and updates deferred during combat. Disable, reset and profile changes restore native positioning.
- Show placement status beside **Customize position** and in `/jui status`, including waiting, combat deferral and restricted-operation states.
- No artwork changes or game interaction. Validation is offline; live-client confirmation remains required.

## 0.8.7 — Power styling and Blizzard placement

- Fitted Blizzard player power fills temporarily release their fixed-size native mana mask so the fill reaches the shell opening. Restore that mask when the shell is disabled or the bar changes; preserve unrelated masks and all artwork.
- Added native-resource, class and custom power colors, with independent solid/gradient shading. Player, Target and Focus have individual choices; Party & raid share a separate set. Custom colors support a picker and six-digit hex input.
- Added Target/Focus Blizzard buff/debuff group and cast-bar X/Y offsets, independent enable/reset controls, profile persistence and restoration. The stock aura group moves together; placement changes wait until combat ends.
- Pin cast-border strata/level and handle native cast-layer changes separately from geometry, so a cast beginning in combat does not suppress the border solely because its layer changed. Covers Player, Target and Focus.
- Artwork images remain unchanged. This is an offline-validated development build; live-client confirmation is still required.

## 0.8.6 — Stock bar textures, class gradients and power visibility

- Removed the separate dark well behind visible power bars. It could compete with native layering after login/reload; the opaque opening remains only for units without a visible power bar.
- Stock texture changes no longer depend on reading the live bar's texture coordinates. Restore the original atlas through the StatusBar API, including its atlas selection, and leave replacement fill regions intact.
- Class-colored health uses a neutral material so Blizzard's baked-in green cannot distort the class hue. The health option is now **Class gradient (players)**, with subtle vertical shading in the requested 13-class palette. Names use the same base palette.
- Neutral stone/smooth textures retain stock health green and the native resource hue when Blizzard uses precolored atlases. Native grey/disconnect tints remain in effect with Blizzard color selected.
- Existing profile choices remain valid. No artwork images changed; checks are offline and live-client confirmation remains outstanding.

## 0.8.5 — Full frames and Blizzard styling

- Added Player/Target/Focus shell attachment for ElvUI's health and power bars, independent of portrait, hub, map and cast artwork. **Unit-frame provider** now includes ElvUI; Automatic detects its active frames.
- Fits the existing 42 shells to attached, aligned, full-width health/power stacks. Preserves total stack size, restores original ElvUI anchors on disable and follows provider redraws/resizing. Detached, inset, mini/spaced, offset or vertical power arrangements retain their layout with a diagnostic.
- Automatic fill mode respects ElvUI's selected textures. Explicit JiberishUI fills use the existing restore/combat gates. Artwork images and provider settings are unchanged.
- Fixed lower artwork disappearing when a unit has no visible power. Complete original shells remain, with an opaque near-black empty power opening. Visible empty power bars also receive a dark backing below the native fill.
- Full Blizzard portrait removal now includes resting, combat/attack effects and portrait damage/healing numbers, with restoration when disabled.
- Added **Blizzard → Colors & textures**: independent player/target/focus and shared party/raid class colors for names and health, dark stone health, and separate stock-wide health/power texture choices. Power retains its resource color.
- Stock textures use the native StatusBar texture setter and initialized-bar discovery, including standard party references. Existing artwork is unchanged.
- Offline fixtures cover both client paths against the inspected ElvUI v15.26 frame structure. Live-client appearance and secure behavior remain user-tested.

## 0.8.4 — Blizzard cast layers and independent text controls

- Fixed automatic Blizzard cast-border layering to clear the owning Player/Target/Focus frame and enabled JUI portrait/shell layers. Explicit strata and the level offset are together on **Cast bar**; status reports the resolved layer. Ellesmere and ElvUI retain their provider-based layering.
- Fixed repeated Blizzard text offsets accumulating after rounded position readback or partial native anchor updates. X/Y settings now use a stable original position and retain the actual applied position separately.
- Added independent **Name**, **Health**, **Power**, **Level**, **Cast name** and **Cast time** controls on **Blizzard**, each with X/Y, size, alignment, outline, enable and reset. Existing profile name settings are preserved; new groups start disabled. Native text visibility, content and values stay with Blizzard.
- All presentation edits and restoration wait until combat ends. Artwork files are unchanged. Validation is offline; no WoW interaction was performed.

## 0.8.3 — Original unit-frame artwork over the bars

- Removed duplicated inset border strips and the Inset edge depth control. Old saved depths have no visual effect.
- Draw the complete original shell, including its curved inner contours, above health and power. Default fitting slightly overlaps both bar sides; width adjustments can bring the real artwork inward.
- Added independent unit-frame horizontal and vertical offsets alongside width/height. Reset returns to 100%/100% and zero offsets.
- Retained the source-proportional divider, protected center footer ornament, provider fill ownership and combat deferral.

All artwork image files are unchanged. Validation is offline; live-client testing remains pending.

## 0.8.2 — Sculpted hubs and frame presentation

- Restyled all 42 class, race and faction action hubs to match the approved unit-frame materials, colors and dimensional finish. Hub fitting and button space are unchanged.
- Removed the added black inset shadow strips around health and power. Inner edges now sample the painted bevel beyond the dark opening outline.
- Kept the lower center ornament, including the Night Elf moon, proportional when provider bars change width.
- Added **Hide full Blizzard portrait** under each unit's **Blizzard** page. With unit-frame artwork enabled, it hides the stock face, rim, shared stock border and level badge. Name position, size, alignment and outline remain independently adjustable.
- Moved **Cast-border strata** onto the **Cast bar** page. Automatic layering clears native decorative child frames; **Advanced** provides a separate **Cast-border level above bar** control.

Portrait and unit-frame image assets are unchanged. No game interaction was used for testing; live-client verification remains pending.
