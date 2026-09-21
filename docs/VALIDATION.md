# Phase 1 live validation gate

Do not add themes or components until the four-component prototype passes this gate on both clients. Artwork refinement follows reliable attachment, visibility and safety.

Install the matching 0.2.0-phase1.1 package and fully restart the client once. Keep SavedVariables. Enable only the required test/bug-reporting addons plus JiberishUI initially.

1. Run `/jf theme paladin_ret`, select a target, and run `/jf debug on`. Confirm four non-interactive rectangular bounds with module name, width/height, anchor, X/Y, scale, strata/layer and texture paths. Use `/jf status` if a label is clipped or an anchor is missing.
2. Confirm native minimap interaction, player/target clicks and menus, targeting, action buttons, keybinds, cooldowns, proc highlights, health/power updates and functional indicators still work. No original borders or controls should disappear.
3. Change each component's width, height, X/Y, scale, strata and layer using `/jf set`. Toggle each with `show`/`hide`. Confirm only that artwork changes, and hides require no reload.
4. In Blizzard Edit Mode, move/scale each supported native frame. Save and cancel layouts. Test 1080p, 1440p and 4K where available, several UI scales, native frame scales, and window resizing. Expect the artwork anchor and effective scale to follow; manually adjust its width/height for different bar arrangements.
5. Clear/reacquire targets, enter/exit vehicles, page action bars, change native visibility/alpha settings, and load addons late. Confirm hidden native roots do not leave floating artwork. Debug may intentionally display bounds for disabled/hidden components; turn debug off for visibility tests.
6. Enter combat. Request multiple size/offset changes, hide/show, theme reload and debug changes. Confirm the most recent configuration applies on combat exit, with no blocked-action or taint errors. Log in/reload during combat where safely reproducible; newly encountered roots must not attach until combat ends.
7. Repeatedly run `/jf reloadtheme`. Confirm no growing set of art objects, duplicated borders, native style changes or extra hooks. A missing texture must not hide native art.
8. Set obvious custom values. Test `/reload`, logout/login and full client restart separately. Check the startup-settings notice. Forever 69913's previous saved-table failure remains unresolved; do not count an offline profile round trip as a client persistence pass.
9. Disable JiberishUI and reload. Confirm Blizzard layout/behavior is normal. For the transition from alpha.8 or older, a full restart is needed to remove the old loaded code and refresh the manifest.

Record client/build, resolution/UI scale, the four component settings, status output, exact action and any BugSack/blocked-action message for a failed case. No additional UI providers or components need to be implemented to complete this gate.
