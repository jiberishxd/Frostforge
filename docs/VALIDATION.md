# Portrait build validation

Install 0.9.6 and fully restart WoW to load the source-faithful shells and new controls. If upgrading from the old `JiberishUI` folder, follow the [one-time saved-file transfer](GETTING-STARTED.md#upgrading-to-frostforge) first. In `/frostforge`, select Player, Target or Focus and test **Portrait art** and **Unit-frame art** in all four on/off combinations. Unit-frame art is off by default; existing FULL settings migrate. If bars still do not show their artwork, copy the per-unit lines from `/jui status`, including shell and fill status. All in-game testing is performed by the user.

1. Open /jui. Confirm textured window borders, frost-blue buttons with white labels and fitted hover/selected outlines, checkboxes, five component tabs and a movable window. Verify Show artwork and Debug bounds check marks, selected tabs, and gallery selection after switching components. Player, Target and Focus default to Automatic class; Minimap and hub default to automatic player class; existing geometry overrides are retained.
2. At default portrait dimensions, check Player's teardrop corner, level badge, name and bars. Select players of different classes and verify only Target's portrait background changes; the art should share the same visible envelope without a lower loop or level-badge circle. Verify Mage uses an eye and Hunter uses a skull. Set another class as Focus and verify independent selection. Clear Target/Focus and confirm their decoration disappears.
3. Test all 13 class tokens, NPCs, unavailable identities, vehicles and target changes in combat. Both portrait surround and full shell should update to a new readable identity during combat when permitted. Exact shell proportions and native bar fitting reconcile afterward. Restricted identity data uses Neutral; a client-protected decoration must defer changes safely.
4. Select automatic race and faction modes; exercise neutral and allied races. Browse every fixed artwork category, then switch back to Automatic class. Confirm unrelated components remain unchanged.
5. Test absent/forbidden roots, portrait visibility options, small/large Focus, Edit Mode movement/scaling/save/cancel, and login while in combat. No blocked actions, Lua secret-value errors or functional native-frame writes are acceptable. Only opted-in texture/UV and documented bar presentation fitting writes are allowed.
6. Check 1080p, 1440p and 4K at several native/UI scales. Inspect portrait/badge clearances, edges and the absence of bar-end decoration in Portrait only mode. Custom width/height/offset settings can change fit; reset only the affected component to inspect defaults.
7. Exercise all options, typed validation, profile reset and JF2 export/import. Import a legacy JF1 backup and verify one-time sizing conversion. Verify reload, logout/login and full restart separately; offline persistence tests do not resolve the Forever loader issue.
8. In Minimap, browse all three groups and check several selections at different native map sizes and UI scales. The same center/opening should fit without per-art offsets. Verify clicking the map/buttons, zone labels, screen-edge clipping, combat-deferred changes and hidden-map visibility. Verify Warrior has no faction insignia in portrait, hub or minimap. In Action hub, select each group, page the gallery, switch automatic modes and choose a fixed hub. Verify width changes stretch only rails, target changes never alter the hub, and settings survive export/import. Check several native bar layouts: this artwork does not reposition bars, micro menu or bags.

Record client/build, resolution, UI/frame scale, mode/artwork, /jf status and exact BugSack/blocked-action details. In-game compatibility is not claimed until both clients pass.

## Addon compatibility pass

Test Retail and Forever separately where the upstream addons run. Test ElvUI alone, EllesmereUI alone, Blinkii with each suite, mMediaTag with ElvUI, and coexistence with per-unit manual source choices. Test mMediaTag 4.x on Retail and 3.x only on clients supported by that upstream build.

1. In `/frostforge`, leave Portrait addon on Automatic. Enable Player/Target/Focus portraits in the provider. For the closest fit use Blinkii/mMediaTag Circle or Ellesmere detached Circle. Confirm the printed Following anchor, opening center, artwork mirroring and click-through behavior. When mMediaTag and ElvUI portraits coexist, Automatic should choose mMediaTag; visible Blinkii portraits retain first priority.
2. Resize, move, fade, hide and change portrait shapes/profiles. Toggle Blinkii clickable mode, mMediaTag mirrored masks and zoom, ElvUI 2D/3D/class modes and Ellesmere attached/detached modes. Turn portraits off, clear target/focus and remove/re-enable providers. No stale surround should remain. Health-overlay portraits intentionally have no separate surround.
3. Change source and size in combat; test clickable Blinkii portraits and protected dependencies. Deferred changes must apply after combat without blocked-action errors. Target identity artwork should still update when permitted.
4. Select ElvUI or EllesmereUI as the Action bar addon. Confirm SCREEN and FRAME anchors, alpha/visibility, paging, vehicle transitions and click-through. Use a circular minimap for the existing circular surround. Arbitrary bar layouts and square maps need manual fitting.
5. Export/import and reload all source settings. If Unit-frame art is enabled, changing the portrait provider must not disable skins on visible Blizzard bars. Hiding the selected provider’s bars must hide their shells. Turning off only Portrait art must leave shell and fill styling active.

## Full unit-frame pass

1. Keep Player/Target/Focus on Blizzard sources. Test Portrait art and Unit-frame art independently on each tab; existing portrait dimensions/offsets and other units must not change.
2. Switch class, race, faction and fixed choices. Check the sculpted shell and both functional openings follow native edges without covering names, level badges, percentages, prediction/absorb overlays, auras or class resources. Resize native frames at multiple UI scales; no per-theme X/Y correction should be needed.
3. Lose/gain health and power, change mana/rage/energy type, target dead/NPC/friendly/hostile units and enter/exit vehicles. Fill proportions, native color semantics, tooltips, right-click menus and secure clicks must remain correct. Hidden power keeps complete artwork and an opaque dark empty opening; hidden health/root hides the entire shell.
4. Toggle each artwork setting, reset, import profiles, change source and enter/exit combat. Setting-driven native appearance and all power-layout writes defer; an already enabled power color/gradient can reassert its prepared material on the same native fill. Check thick separator clearance and continuous shoulders. Confirm switching off restores the latest native texture and original power-bar points/size, including after a vehicle or resource redraw. Check /reload and a full restart with the mode on/off.
5. Turn on /jf debug and inspect the two additional health/power shell bounds per opted-in unit. Inspect target/focus clearing, native fades, forbidden/missing children and replacement texture regions. No taint or secret-value errors are acceptable.

## EllesmereUI 9.2.9 unit-frame pass (user performed)

1. Set Portrait addon and Unit frames addon to EllesmereUI for each unit. Enable portraits in Ellesmere (detached Circle is closest to the existing art), then independently toggle Portrait art and Unit-frame art. An inside-health or disabled provider portrait should not acquire a surround.
2. Start with horizontal health and attached power below it. Check all 42 themes share the original stack height, visible thick divider, continuous endcaps, clear labels and untouched clicks. Check default layers and any custom strata/level overrides.
3. Switch Ellesmere portrait modes/masks/sides and profiles, resize frames and change UI scale. Test reload/login, late frame creation and replacing a frame. Switching back to Blizzard must restore Ellesmere’s textures and both bar layouts.
4. Hide/detach/move power above health or use vertical bars: geometry should stay provider-owned and the shell should hide, with texture-only status. Restore attached horizontal power below health and confirm the complete shell returns.
5. Change targets/resources, clear Focus, enter/exit combat and vehicles, and inspect prediction/absorb overlays and class resources. Queued edits apply after combat. Test restoring the mode after a provider redraw and preserve the newest provider layout/texture when disabled.
6. Use Automatic with an inactive Blinkii/ElvUI portrait, then with a visible Blinkii portrait over Ellesmere bars. Confirm portrait selection can skip inactive providers and does not control the bar source. Export/import and restart to verify both source settings persist.

Offline tests cannot validate real clip rasterization, secure dependencies or third-party redraw timing. Record those findings with the full per-unit `/jui status` lines.

## Plain stone and city NPCs (user-run)

1. With Unit-frame art enabled, inspect Player/Target/Focus health in several themes and provider colors. The fill should have quiet stone grain with no emblems, cloth or rail markings; power and the sculpted borders should retain their existing appearance.
2. In Automatic class mode, target an Undercity Guardian, Stormwind City Guard, Ironforge Guard and Orgrimmar Grunt. Expect Undead, Human, Dwarf and Orc artwork respectively. Test other NPCs with matching city affiliation lines, including the client locale you use.
3. Toggle portrait and unit-frame artwork separately; both should select the same city identity when enabled. Try automatic race/faction and a fixed choice; fixed artwork must win.
4. Switch between a city NPC, another city NPC, an unrelated NPC, a player and an empty target. No former target artwork should persist when the new identity is public and the existing artwork is writable, including during combat. A remote focus should follow its own NPC affiliation. Repeat target changes in combat, checking immediate design changes and deferred bar fitting afterward.

Unknown NPCs retain the normal fallback; city location alone is not a match. See NPC-CITIES.md for the supported list.

## 0.7.4–0.7.5 user-run checks

- Open `/frostforge` on both clients. Check all four pages, artwork searches/pages, small-screen fitting, dragged position, scoped reset and backup round-trip.
- In EllesmereUI, choose Frostforge Stone and another texture in turn. Confirm neither is replaced in AUTO or PROVIDER fill mode. Repeat after provider profile redraw and a combat transition. Explicit JIBERISH mode should replace fills until switched back or disabled.
- Select Frostforge Stone in ElvUI and other shared texture menus; test Player/Target and raid/resource frames using the provider's own settings.
- Test Unit frame width/height and X/Y offsets on each unit, including 100% defaults, custom values, reset, hidden power bars and queued combat edits. Verify the original shell overlaps the fill, smaller width moves its sides inward, and no second rail appears. Check that center labels stay readable at the selected fit and the shell disappears when disabled. Legacy inset values must not change the result.
- Review the balanced, faction-neutral Shaman mask/totem shell and thick divider with Player/Target/Focus; check all original portrait toggles remain independent.

These are manual checks for the user. The agent does not operate WoW.

## 0.8.0 cast-border checks

Follow the manual checklist in [CAST-BARS.md](CAST-BARS.md) on Blizzard, EllesmereUI and ElvUI, for Player/Target/Focus. Include idle-to-cast transitions, fades, channels, interrupts and empower indicators, each style, matching versus fixed artwork, provider resizing/replacement, hidden providers, combat-deferred changes, independent toggles and backup restoration. No gameplay was automated during development.

## 0.8.4 Blizzard cast layering and text (user-run)

1. On Player, Target and Focus, enable the cast border with Blizzard selected. Start with **Cast bar → Cast-border strata → Automatic** and **Level above nearby artwork → 1**. Confirm the border clears the stock surround and enabled Frostforge shell/portrait when casts begin, including casts first shown in combat. Try High and Dialog with different levels, then return to Automatic. Repeat the existing Ellesmere layout.
2. On **Blizzard**, test all six label selectors. Enable customization, adjust X and Y repeatedly in both directions and return to zero. Test font size/alignment/outline separately. Unchanged labels should stay put, and the health/power center/left/right variants should move together. Only existing visible native labels should appear.
3. Change target, UI scale and Blizzard layout; start/stop a cast. Offsets should remain relative to the original layout with no accumulated movement. Disable or reset one group, then restore all stock portrait/text controls. Fonts and positions should return to the current Blizzard defaults. Full portrait removal still hides its level badge.
4. Adjust and reset in combat, then leave combat. Settings must apply afterward without blocked actions. Verify character profiles and backup round trips retain the separate label and cast-layer choices.

## 0.8.5 ElvUI full shells (user-run)

1. Use ElvUI with attached full-width power below horizontal health. In `/frostforge` select each of Player, Target and Focus, enable **Unit-frame art**, and choose **ElvUI** or Automatic as its provider. Portraits may be disabled or supplied separately. Check the full shell appears, its divider fits between the bars and values/clicks/labels remain functional.
2. Retain **Automatic (respect UI addon)** fill mode and choose textures in ElvUI. Confirm those choices remain; optionally select Frostforge Stone there. Explicit Frostforge fills should restore the latest provider selection when disabled.
3. Resize/move frames and switch ElvUI profiles, resources and targets. Turn artwork off and verify original health/power anchors and total size return. Test all artwork categories and independent fitting controls.
4. Try detached, inset, mini/spaced, offset and vertical power layouts: the shell should hide with a diagnostic, leaving the new ElvUI layout alone. Return to full-width attached power and confirm recovery. Check hidden/auto-hidden power and missing targets.
5. Test login, reload, first target/focus appearance, combat transitions and saved character profiles. No blocked actions or secure-value errors are acceptable. Fitting/restoration wait until combat ends. Capture `/jui status` if your layout differs.

## 0.8.5 stock styling and no-power regression checks (user-run)

1. On Retail and Forever with stock Blizzard frames, choose Stone/Smooth/Blizzard independently for health and power. Repeat with shell art off/on. Confirm values, prediction overlays, class/resource colors and clicks remain functional.
2. Choose class-colored names and health on Player/Target/Focus and party/raid; switch between different player classes and NPCs, regroup and change combat state. NPC class mode keeps native colors. Dark stone affects health only. Switch back to Blizzard to restore defaults.
3. With full portrait removal and shell enabled, rest, enter combat and receive damage/healing. No resting animation, combat pulse, attack badge or portrait feedback should remain. Restore the option outside combat and verify normal effects return.
4. Target a powerless creature/city NPC and a power-using unit, including transitions during combat. Verify the complete bottom artwork, dark empty opening, no fake power bar, original footer proportions, and no black backing covering real resource fill.


## 0.8.6 stock bar appearance (user-run)

- On Forever and Retail with stock frames, reload with a visible mana bar and unit-frame artwork enabled. Mana must appear immediately without hovering or clicking. Test login as well as reload.
- Choose Stone, Smooth and Blizzard independently for health and power. Confirm changes take effect after combat and survive reload. Stock mana/rage/etc. must retain their resource color.
- Choose Class gradient for Player/Target/Focus and party/raid health. Confirm the base class hue with darker shading below it, including white/grey Priest and blue Shaman. Names should use the matching solid base hue. Test a class change or a new player target, then an NPC.
- Restore Blizzard health color and texture. Confirm original atlas, tint and native behavior return. Test Dark stone and a disconnected/dead unit.
- Target an NPC without power: the complete shell and opaque empty opening should remain. Target a unit with power again: the no-power backing must disappear. Test this transition in combat.
- Confirm ElvUI/Ellesmere provider textures remain in control in Automatic mode. Artwork assets are unchanged.

## 0.8.7 power and placement (user-run)

1. On stock Player with a Frostforge shell, confirm the power fill reaches the upper edge of the opening after login/reload and resizing. Compare Target, which should retain its current contour. Disable the shell and check native mana-mask restoration, including alternate resources and vehicles.
2. In Blizzard → Colors & textures → Power colors, exercise native/class/custom, solid/gradient, hex input, picker Cancel/Okay and Party & raid scope. Verify class colors, mana/rage/energy changes, native disconnected tints, profiles and reload; no black cover should appear over visible power.
3. Enable Target/Focus buff/debuff group offsets; change targets and aura rows. Check hidden aura groups stay hidden, tooltips remain functional, and reset/profile changes restore the native placement. Repeat for cast-bar offsets, with and without aura anchoring. Edits and protected native reanchors reconcile after combat.
4. On Blizzard Player/Target/Focus, enable cast borders before combat. Check Automatic and highest strata, casts/channels/empower FX, first cast in combat, target aura reanchors, and raising native FX layers while casting. Border visibility must follow the cast; text/timing stay native. Confirm ElvUI/Ellesmere remain unchanged.

## 0.8.8 aura offsets (user-run)

1. On stock Target, open Blizzard → Buffs & debuffs, enable Customize position, and change both X and Y by slider and typed input outside combat. Confirm the group visibly moves and the status shows those offsets. Repeat on Focus.
2. Change targets, add/remove aura rows, switch Blizzard's above/below placement and show/hide numeric threat. Confirm saved offsets persist relative to the new native position without drifting. Check native cast-bar anchoring below the moved auras.
3. Edit offsets or disable customization during combat; confirm placement changes wait until combat ends. Reset, switch to a clean profile and reload; verify restoration and persistence. If a setting remains ineffective, capture the displayed placement status or `/jui status` output.

Offline tests reproduce native aura reanchoring after Frostforge's scan; the mock does not emulate the secure client or render real aura icons. No game was operated during development.

## 0.9.1 combat recovery and frost highlights (user-run)

1. Enable Target portrait and unit-frame art on Blizzard frames before combat. Fight one mob while targeting another, cycle powered and powerless targets, and clear/reacquire Target and Focus. Decorations should return with the same native frame. In 0.9.4+, the full shell changes design during combat; exact fitting applies afterward.
2. Hover and leave sidebar tabs, page buttons, toggles, dropdown options and artwork cards. Hover should brighten the edge; selected/enabled choices retain a fitted blue outline, and deselected choices clear it. Verify white labels, normal clicks, window scaling and no stretched border corners.

## 0.9.2 combat power colors and cast trim (user-run)

1. On a Hunter with Blizzard Player frames, select a distinct custom power color. Enter combat, spend/regenerate Focus, switch targets and leave combat. Test Solid and Gradient shading. The selected hue should persist throughout; changing the setting in combat still waits until combat ends. Repeat after reload and with Stone/Smooth textures.
2. Return power color and shading to Blizzard/Solid, then restore Blizzard texture. Confirm the latest native resource appearance returns. Test vehicles/resource changes and watch for blocked-action or secret-value errors.
3. Enable a Blizzard cast border before combat. Test crafting (including the reported Light Leather cast), spells, channels and an uninterruptible/empowered cast where available. Check Automatic and highest strata with the saved fitting: the native gold rim and dark textbox should no longer compete with the artwork. Fill, spell name, timer, spark, shield and stage cues must remain intact.
4. Disable the border, switch provider and reset the component outside combat. Blizzard's original trim should return, while ElvUI/Ellesmere trim remains unchanged. Repeat enabling/disabling in combat and confirm it applies after combat. Test first casts, fades, reload and alternate player cast bars. These checks require the live client; offline tests do not emulate its renderer or secure engine.

## 0.9.3 setup, access, minimap and Night Elf art (user-run)

- On a fresh install, confirm the wizard opens after entering the world, has three steps, and applies only on Finish. Skip it and reload: it should stay dismissed. Existing settings must not trigger it. Rerun through Guide and verify small-screen fitting.
- Adjust portrait Size, then Advanced sizing; both dimensions should change together only when using Size. Verify import, character profiles and combat deferral.
- Open via AddOn Compartment, ElvUI and the optional minimap icon. Drag the icon, click it again, reload and verify its position and visibility.
- With ElvUI’s square minimap, enable art and round shape. Check the map becomes round, the surround sits above it and native map clicks/icons work. Disable the art, reload, and switch ElvUI profiles to check restoration. Repeat changes during combat and confirm they apply afterward.
- Inspect the Night Elf unit-frame right emblem, hub left emblem and top minimap crescent at several UI scales. Check transparent gaps, complete blade tips, unchanged native bar openings and hub seams.


## 0.9.4 combat identity switching (user-run)

1. Enable Blizzard Target unit-frame art in Automatic class mode. Target a neutral beast before entering combat, then target a nearby Druid while still fighting the beast. The shell and enabled portrait surround should change to Druid immediately. Repeat Druid → beast → another class, including targets with no visible power bar.
2. Keep a different class on Focus while switching Target, then switch Focus during combat. Each frame should retain its own current identity. Clear and reacquire targets; confirm the shell returns and the empty-power footer never covers a visible resource fill.
3. Confirm health/power bars and artwork rectangles do not move during combat. The current design's exact proportions refit after combat. Repeat with customized shell width/height/offsets and enabled ElvUI/Ellesmere attached shells. Native fills and secure clicks must continue working.
4. Check for blocked-action or secret-value errors. Restricted identity uses Neutral; protected artwork and new bar attachments must wait safely. Offline regression tests cannot certify the live secure renderer.

## 0.9.5 install folder and saved-file transfer (user-run)

1. Extract the client-specific ZIP and verify its only top-level folder is `Frostforge`, containing `Frostforge.toc`. Install under `Interface/AddOns/Frostforge`, remove the old addon folder and fully restart WoW.
2. For existing users, first follow the saved-file transfer guide while WoW is closed. Confirm the profile library, each character's assignment, wizard completion and optional minimap-icon settings survive. Fresh installs should receive the first-launch wizard normally.
3. Confirm the logo and portrait/unit-frame/minimap/hub/cast artwork load, ElvUI's Frostforge settings entry opens the window, old slash commands still work, and the 0.9.4 combat identity switch still updates. Log out and back in to check persistence under the new saved filename.


## 0.9.6 GitHub source download (user-run)

1. Download a fresh Code → Download ZIP from GitHub's main branch. Inside `Frostforge-main`, confirm the addon folder is `Frostforge` with `Frostforge.toc`; there should be no `JiberishUI` source folder.
2. Copy only `Frostforge` into `Interface/AddOns/`, following the saved-file transfer guide when upgrading from the old folder. Restart the client and confirm the addon and artwork load. The source folder supports both Retail and Forever; client-specific packages use the same name.
