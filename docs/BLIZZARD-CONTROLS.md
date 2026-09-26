# Stock Blizzard appearance controls

Open `/jui`, choose **Player**, **Target** or **Focus**, then **Blizzard**. Portrait and text options are separate from JiberishUI's portrait-art, unit-frame-art and cast-border toggles. These options affect only stock Blizzard regions on Retail and Forever; use EllesmereUI or ElvUI's own settings for their labels and portraits.

## Portrait image and text

- **Hide Blizzard portrait image** hides the stock face image. The stock rim, level badge and other indicators remain. JiberishUI's portrait surround can remain on independently. Turn the option off to restore the original image opacity.
- **Hide full Blizzard portrait** removes the face, stock rim, level badge, resting animation, combat/attack flashes and portrait damage/healing feedback while **Unit-frame art** is enabled. Blizzard combines its rim and bar outline in one texture, so this also hides that shared stock border. Health, power, names, clicks and group indicators remain active. Turning this option or unit-frame art off restores the original opacity and removes only JUI’s temporary effect masks. Health/power labels and combat feedback elsewhere are unaffected.
- Select **Name**, **Health**, **Power**, **Level**, **Cast name** or **Cast time**, then enable **Customize** for that group. Each has X/Y offsets (−300 to 300) relative to its original position, font size (6–40), alignment and outline. **Keep Blizzard alignment** preserves each label's original alignment. Blizzard still supplies all text, colors and values; JiberishUI never reads or copies their content.
- Health and power controls move each bar's center/left/right and state labels together. Cast controls style only existing native labels, including idle player variants. They do not add timers or reveal labels hidden by Blizzard or full-portrait removal.
- **Reset name/health/etc.** restores only the selected group. **Restore stock portrait & all text** disables these changes and resets their controls for the selected unit. The original font, alignment, anchors and portrait opacity are restored. It does not change the stock-wide stone switch.

These options start off. Edits and restoration wait until combat ends. Native layout/font updates are adopted outside combat so offsets do not accumulate. If another UI hides Blizzard's unit root, its unit labels return to their original presentation. Native cast labels remain independently configurable because the stock player cast bar can stay visible. No third-party frame is modified. Restricted or unavailable regions wait until they can be safely accessed.

## Colors and textures

Open **Blizzard → Colors & textures**. Player, Target and Focus each have **Name color → Blizzard/Class** and **Health color → Blizzard/Class/Dark stone**. Separate shared Party & raid choices cover standard party, compact party and raid frames. Class colors use public player class identity; NPCs retain native name/health colors in Class mode. Dark stone uses charcoal stone health, with resource colors unchanged. Colors do not require text customization or unit-frame art.

Health and power each have an independent stock-wide texture selector: **Automatic**, **JiberishUI Stone**, **Smooth**, or **Blizzard texture**. Explicit texture choices override per-shell fills on stock frames; Automatic follows the legacy stone switch. Dark stone forces stone on the selected health bars. Selecting Blizzard restores the latest captured native texture.

Options, new attachments and restoration apply outside combat. Once enabled, color-only post-hooks and updates keep chosen colors through native redraws and public class changes during combat; they never read health/power values or text content. Restricted identity/color results retain native behavior. Texture/geometry changes still wait until combat ends.

## Stone on all stock health and power bars

**Stone for Automatic texture** starts on. This is one shared setting for the stock UI, available on each unit's Blizzard page and stored with Player's settings. It covers:

- Player, Target and Focus.
- Standard party frames and their pets.
- Compact party and raid frames, including their registered mini frames.
- Pet, Boss, target-of-target and focus-target bars.

Both health and power use the original plain grayscale **JiberishUI Stone** texture. With color modes set to Blizzard, Blizzard retains class/resource/reaction colors, bar values, orientation, masks, fill animation, size, clicks and indicators. No ornamental shells are added to party or raid frames.

This toggle is independent of full shells and takes precedence over the per-unit fill selector for Blizzard bars. Turning it off restores the original or most recently observed stock textures. A separately enabled full shell can still manage its own fills; select **Advanced → Health & power textures → Keep provider textures** too when you want entirely stock textures.

Existing bars and late-created party/raid frames are rediscovered automatically outside combat. Blizzard redraws during combat are observed without writing to the native textures; they are corrected after combat. New frames first created during combat also wait. Nameplates, absorbs and prediction overlays are not included. EllesmereUI and ElvUI continue to select **JiberishUI Stone** through their own SharedMedia menus.

## Independent artwork strata

**Advanced → Portrait art strata**, **Advanced → Unit-frame art strata** and **Cast bar → Cast-border strata** control their respective decorations independently. Shells and casts offer **Automatic**; explicit values such as Medium or High affect only that artwork. Higher strata can cover other UI, including names. Existing profiles' shared strata is copied to the shell setting once to preserve the previous look. The complete original shell stays above the owning health/power bar, even when an older profile requests a lower strata or level. No separate inner lips are drawn.

Frame level and texture draw layer retain their existing portrait/shell behavior. Automatic cast layering follows the highest native bar/decorative child strata and level, plus the owning Blizzard unit frame and enabled JUI portrait/shell layers. This accounts for Target/Focus casts starting below their stock unit frame. **Cast bar → Level above nearby artwork** adds 1–100 levels (default 1) independently for each unit. Strata and geometry updates wait until combat ends.

## Validation

Offline tests cover both client paths, original-state restoration, native redraws, pooled party/raid bars, combat deferral, independent controls and profile backups. Source references are recorded in [stock-frame-sources.json](stock-frame-sources.json). No gameplay was automated; live appearance and secure-runtime behavior still require player testing.
