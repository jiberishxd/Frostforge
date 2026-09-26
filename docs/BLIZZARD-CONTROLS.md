# Stock Blizzard appearance controls

Open `/jui`, choose **Player**, **Target** or **Focus**, then **Blizzard**. Portrait and name options are separate from JiberishUI's portrait-art, unit-frame-art and cast-border toggles. These options affect only stock Blizzard regions on Retail and Forever; use EllesmereUI or ElvUI's own settings for their labels and portraits.

## Portrait image and name

- **Hide Blizzard portrait image** hides the stock face image. The stock rim, level badge and other indicators remain. JiberishUI's portrait surround can remain on independently. Turn the option off to restore the original image opacity.
- **Hide full Blizzard portrait** removes the face, stock rim, level badge and portrait decoration while **Unit-frame art** is enabled. Blizzard combines its rim and bar outline in one texture, so this also hides that shared stock border. Health, power, names, clicks and group indicators remain active. Turning this option or unit-frame art off restores the original opacity.
- **Customize Blizzard name** enables X/Y offsets relative to the original position, font size (6–40), alignment and outline. Blizzard still supplies the displayed name and its color; JiberishUI never reads or copies the name text.
- **Restore stock portrait & name** disables these changes and resets their controls for the selected unit. The original font, alignment, anchors and portrait opacity are restored. It does not change the stock-wide stone switch.

These options start off. Edits and restoration wait until combat ends. Native layout/font updates are adopted outside combat so offsets do not accumulate. If another UI hides Blizzard's root, its original presentation is restored; no third-party frame is modified. Restricted or unavailable regions wait until they can be safely accessed.

## Stone on all stock health and power bars

**Stone textures on all Blizzard health/power bars** starts on. This is one shared setting for the stock UI, available on each unit's Blizzard page and stored with Player's settings. It covers:

- Player, Target and Focus.
- Standard party frames and their pets.
- Compact party and raid frames, including their registered mini frames.
- Pet, Boss, target-of-target and focus-target bars.

Both health and power use the original plain grayscale **JiberishUI Stone** texture. Blizzard retains class/resource/reaction colors, bar values, orientation, masks, fill animation, size, clicks and indicators. No ornamental shells are added to party or raid frames.

This toggle is independent of full shells and takes precedence over the per-unit fill selector for Blizzard bars. Turning it off restores the original or most recently observed stock textures. A separately enabled full shell can still manage its own fills; select **Advanced → Health & power textures → Keep provider textures** too when you want entirely stock textures.

Existing bars and late-created party/raid frames are rediscovered automatically outside combat. Blizzard redraws during combat are observed without writing to the native textures; they are corrected after combat. New frames first created during combat also wait. Nameplates, absorbs and prediction overlays are not included. EllesmereUI and ElvUI continue to select **JiberishUI Stone** through their own SharedMedia menus.

## Independent artwork strata

**Advanced → Portrait art strata**, **Advanced → Unit-frame art strata** and **Cast bar → Cast-border strata** control their respective decorations independently. Shells and casts offer **Automatic**; explicit values such as Medium or High affect only that artwork. Higher strata can cover other UI, including names. Existing profiles' shared strata is copied to the shell setting once to preserve the previous look. The complete original shell stays above the owning health/power bar, even when an older profile requests a lower strata or level. No separate inner lips are drawn.

Frame level and texture draw layer retain their existing portrait/shell behavior. Automatic cast layering follows the highest native bar/decorative child strata and level. **Advanced → Cast-border level above bar** adds 1–100 levels (default 1) independently for each unit. Strata and geometry updates wait until combat ends.

## Validation

Offline tests cover both client paths, original-state restoration, native redraws, pooled party/raid bars, combat deferral, independent controls and profile backups. Source references are recorded in [stock-frame-sources.json](stock-frame-sources.json). No gameplay was automated; live appearance and secure-runtime behavior still require player testing.
