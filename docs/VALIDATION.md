# Portrait build validation

Install 0.8.4 and fully restart WoW to load the source-faithful shells and new controls. Keep saved settings. In `/jui`, select Player, Target or Focus and test **Portrait art** and **Unit-frame art** in all four on/off combinations. Unit-frame art is off by default; existing FULL settings migrate. If bars still do not show their artwork, copy the per-unit lines from `/jui status`, including shell and fill status. All in-game testing is performed by the user.

1. Open /jui. Confirm textured window borders, red/gold buttons, checkboxes, five component tabs and a movable window. Verify Show artwork and Debug bounds check marks, selected tabs, and gallery selection after switching components. Player, Target and Focus default to Automatic class; Minimap and hub default to automatic player class; existing geometry overrides are retained.
2. At default portrait dimensions, check Player's teardrop corner, level badge, name and bars. Select players of different classes and verify only Target's portrait background changes; the art should share the same visible envelope without a lower loop or level-badge circle. Verify Mage uses an eye and Hunter uses a skull. Set another class as Focus and verify independent selection. Clear Target/Focus and confirm their decoration disappears.
3. Test all 13 class tokens, NPCs, unavailable identities, vehicles and target changes in combat. No previous target's class should persist on a new readable identity. Restricted identity data uses Neutral; a client-protected decoration must defer changes safely.
4. Select automatic race and faction modes; exercise neutral and allied races. Browse every fixed artwork category, then switch back to Automatic class. Confirm unrelated components remain unchanged.
5. Test absent/forbidden roots, portrait visibility options, small/large Focus, Edit Mode movement/scaling/save/cancel, and login while in combat. No blocked actions, Lua secret-value errors or functional native-frame writes are acceptable. Only opted-in texture/UV and documented bar presentation fitting writes are allowed.
6. Check 1080p, 1440p and 4K at several native/UI scales. Inspect portrait/badge clearances, edges and the absence of bar-end decoration in Portrait only mode. Custom width/height/offset settings can change fit; reset only the affected component to inspect defaults.
7. Exercise all options, typed validation, profile reset and JF2 export/import. Import a legacy JF1 backup and verify one-time sizing conversion. Verify reload, logout/login and full restart separately; offline persistence tests do not resolve the Forever loader issue.
8. In Minimap, browse all three groups and check several selections at different native map sizes and UI scales. The same center/opening should fit without per-art offsets. Verify clicking the map/buttons, zone labels, screen-edge clipping, combat-deferred changes and hidden-map visibility. Verify Warrior has no faction insignia in portrait, hub or minimap. In Action hub, select each group, page the gallery, switch automatic modes and choose a fixed hub. Verify width changes stretch only rails, target changes never alter the hub, and settings survive export/import. Check several native bar layouts: this artwork does not reposition bars, micro menu or bags.

Record client/build, resolution, UI/frame scale, mode/artwork, /jf status and exact BugSack/blocked-action details. In-game compatibility is not claimed until both clients pass.

## Addon compatibility pass

Test Retail and Forever separately where the upstream addons run. Test ElvUI alone, EllesmereUI alone, Blinkii with each suite, mMediaTag with ElvUI, and coexistence with per-unit manual source choices. Test mMediaTag 4.x on Retail and 3.x only on clients supported by that upstream build.

1. In `/jui`, leave Portrait addon on Automatic. Enable Player/Target/Focus portraits in the provider. For the closest fit use Blinkii/mMediaTag Circle or Ellesmere detached Circle. Confirm the printed Following anchor, opening center, artwork mirroring and click-through behavior. When mMediaTag and ElvUI portraits coexist, Automatic should choose mMediaTag; visible Blinkii portraits retain first priority.
2. Resize, move, fade, hide and change portrait shapes/profiles. Toggle Blinkii clickable mode, mMediaTag mirrored masks and zoom, ElvUI 2D/3D/class modes and Ellesmere attached/detached modes. Turn portraits off, clear target/focus and remove/re-enable providers. No stale surround should remain. Health-overlay portraits intentionally have no separate surround.
3. Change source and size in combat; test clickable Blinkii portraits and protected dependencies. Deferred changes must apply after combat without blocked-action errors. Target identity artwork should still update when permitted.
4. Select ElvUI or EllesmereUI as the Action bar addon. Confirm SCREEN and FRAME anchors, alpha/visibility, paging, vehicle transitions and click-through. Use a circular minimap for the existing circular surround. Arbitrary bar layouts and square maps need manual fitting.
5. Export/import and reload all source settings. If Unit-frame art is enabled, changing the portrait provider must not disable skins on visible Blizzard bars. Hiding the selected provider’s bars must hide their shells. Turning off only Portrait art must leave shell and fill styling active.

## Full unit-frame pass

1. Keep Player/Target/Focus on Blizzard sources. Test Portrait art and Unit-frame art independently on each tab; existing portrait dimensions/offsets and other units must not change.
2. Switch class, race, faction and fixed choices. Check the sculpted shell and both functional openings follow native edges without covering names, level badges, percentages, prediction/absorb overlays, auras or class resources. Resize native frames at multiple UI scales; no per-theme X/Y correction should be needed.
3. Lose/gain health and power, change mana/rage/energy type, target dead/NPC/friendly/hostile units and enter/exit vehicles. Fill proportions, native color semantics, tooltips, right-click menus and secure clicks must remain correct. Native hidden bars hide their shell half.
4. Toggle each artwork setting, reset, import profiles, change source and enter/exit combat. All native appearance and power-layout writes defer. Check thick separator clearance and continuous shoulders. Confirm switching off restores the latest native texture and original power-bar points/size, including after a vehicle or resource redraw. Check /reload and a full restart with the mode on/off.
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
4. Switch between a city NPC, another city NPC, an unrelated NPC, a player and an empty target. No former target artwork should persist. A remote focus should follow its own NPC affiliation. Repeat target changes in combat, checking queued appearance changes after combat.

Unknown NPCs retain the normal fallback; city location alone is not a match. See NPC-CITIES.md for the supported list.

## 0.7.4–0.7.5 user-run checks

- Open `/jui` on both clients. Check all four pages, artwork searches/pages, small-screen fitting, dragged position, scoped reset and backup round-trip.
- In EllesmereUI, choose JiberishUI Stone and another texture in turn. Confirm neither is replaced in AUTO or PROVIDER fill mode. Repeat after provider profile redraw and a combat transition. Explicit JIBERISH mode should replace fills until switched back or disabled.
- Select JiberishUI Stone in ElvUI and other shared texture menus; test Player/Target and raid/resource frames using the provider's own settings.
- Test Unit frame width/height and X/Y offsets on each unit, including 100% defaults, custom values, reset, hidden power bars and queued combat edits. Verify the original shell overlaps the fill, smaller width moves its sides inward, and no second rail appears. Check that center labels stay readable at the selected fit and the shell disappears when disabled. Legacy inset values must not change the result.
- Review the balanced, faction-neutral Shaman mask/totem shell and thick divider with Player/Target/Focus; check all original portrait toggles remain independent.

These are manual checks for the user. The agent does not operate WoW.

## 0.8.0 cast-border checks

Follow the manual checklist in [CAST-BARS.md](CAST-BARS.md) on Blizzard, EllesmereUI and ElvUI, for Player/Target/Focus. Include idle-to-cast transitions, fades, channels, interrupts and empower indicators, each style, matching versus fixed artwork, provider resizing/replacement, hidden providers, combat-deferred changes, independent toggles and backup restoration. No gameplay was automated during development.

## 0.8.4 Blizzard cast layering and text (user-run)

1. On Player, Target and Focus, enable the cast border with Blizzard selected. Start with **Cast bar → Cast-border strata → Automatic** and **Level above nearby artwork → 1**. Confirm the border clears the stock surround and enabled JUI shell/portrait when casts begin, including casts first shown in combat. Try High and Dialog with different levels, then return to Automatic. Repeat the existing Ellesmere layout.
2. On **Blizzard**, test all six label selectors. Enable customization, adjust X and Y repeatedly in both directions and return to zero. Test font size/alignment/outline separately. Unchanged labels should stay put, and the health/power center/left/right variants should move together. Only existing visible native labels should appear.
3. Change target, UI scale and Blizzard layout; start/stop a cast. Offsets should remain relative to the original layout with no accumulated movement. Disable or reset one group, then restore all stock portrait/text controls. Fonts and positions should return to the current Blizzard defaults. Full portrait removal still hides its level badge.
4. Adjust and reset in combat, then leave combat. Settings must apply afterward without blocked actions. Verify character profiles and backup round trips retain the separate label and cast-layer choices.
