# Validation and release gates

Status on 2026-09-20: **alpha implementation; not approved for production release**.

Completed locally: classic WC3 source extraction/measurement, 11 original material masters, 52-choice catalog and synthetic preview sheets, complete relevant manifest/XML tracing at both pins, Lua 5.1 parsing and 30 mocked behavioral test groups, 211 asset/manifests integrity checks, and separate client packages. Mocked tests cannot reproduce combat lockdown, taint propagation, secret-value engine enforcement, real Settings layout, or Blizzard's renderer.

No in-game test has been run on either client. No blocked-action-free, fully compatible, seamless-fit, or restart-persistence claim is made. No Forever persistence defect was reproduced. The [build 69913 persistence report](https://us.forums.blizzard.com/en/wow/t/uiaddon-settings-wiped-on-client-restart/2353992) is a report to investigate, not an established local finding.

## Gate 1: Human feasibility — required before wider rollout

On both clients, begin with only JiberishUI enabled and an exported backup of any existing profile. Verify Human player, target, and action-button examples first. Check neutral fill color/masks, border fit, target classification, action-button pressed/checked/hover states, profile change outside combat, and disable/reload restoration. Record exact client build, addon version, screenshots, and errors. If this gate fails, retain alpha status and fix it before treating the other race skins as release-ready.

## Coverage matrix

Every row requires **Retail and Forever** testing, unless marked Forever-only. Implementation means discovery/rendering is present; every live-test status below is pending.

| Family | Required cases | Live status |
|---|---|---|
| Player | Normal; vehicle; alternate resources; portrait/class icon choices | Pending |
| Target/focus | Player/NPC; minus/normal/elite/rare/boss; tapped, dead, disconnected where applicable | Pending |
| Boss | Multiple bosses; appearance/removal; classification overlays | Pending |
| Pet | Summon/dismiss; possession; attack flash; health/power/masks | Pending |
| Small targets | Target-of-target/focus-target; disappearance; portrait-off settings | Pending |
| Portrait party | Join/leave; reordered members; role/leader/ready/disconnected signals | Pending |
| Party pets | Portrait pets; compact pet members; pet replacement | Pending |
| Compact party/raid | Standard/compact switch; raid size; reservation reuse; pets; main-tank/assist variants; threat-health coloring | Pending |
| Main/additional bars | Every additional bar; paging; empty slots; row/column/direction changes | Pending |
| Action-button states | Normal, pressed, checked, hover, disabled/unusable, cooldown, range tint, proc and selection highlights | Pending |
| Special bars | Pet; stance/form; possess; vehicle; override | Pending |
| Extra/zone | Extra ability; pooled zone abilities; appear/disappear | Pending |
| Flyout | Open/close; change spell list; first encounter during combat | Pending |
| Forever totems | Action pages, summon/recall, multicast flyout, empty slots | Pending — Forever only |
| Main-bar art | Border visibility, both endcaps, Forever separate endcap Edit Mode controls | Pending |
| Input | Mouse, keybindings, controller navigation, quick keybind mode | Pending |

## Behavior and safety

- Enter combat, request several themes/colors/sizes, then exit. Only the final requested settings apply after exit. No geometry/attachment writes should occur during combat.
- First encounter an unregistered pooled frame in combat. It stays native until combat ends. Confirm the frame is subsequently attached once.
- Repeat group changes, show/hide, Edit Mode save/cancel, skin switches, target changes, and addon loads. Confirm stable attachment counts and no growth in hooks/textures.
- Exercise dead/disconnected/tapped states and native threat-health coloring. Custom neutral fills must yield to the native presentation and preserve absorb, heal prediction, temporary health loss, selection and threat signals.
- Verify restricted/secret unit inputs do not produce Lua errors or expose unit quantities in diagnostics.
- Test ElvUI, Ellesmere modules, SUF, PitBull, Bartender, Dominos, and Masque Blizzard overlap individually. Affected modules must be skipped, with an explanation.
- Inspect nameplates before and after group/target updates: no JiberishUI textures or state changes.
- Disable each module, then reload; disable the addon entirely and reload. Native appearance, secure clicks, actions, and controller navigation must work. No taint or blocked-action errors are acceptable.

## Visual checks

Test all 15 material families at 1920 × 1080, 2560 × 1440, and 3840 × 2160, with representative UI scales (0.64, 0.8, 1.0) and frame scales (0.75, 1.0, 1.25) where supported. Spot-check all 52 presets for palette readability. Test the minimum and maximum thickness, inset, opacity, and ornament settings. Include narrow party frames, dense 40-member raid layouts, vertical/multiline action bars, and portrait-off states.

Exercise the visual browser's four categories, search, empty search results, first/last page, and repeated open/close. Verify that selection applies to the intended Global/frame-group scope, existing profile IDs remain valid, and choosing a skin during combat changes the preview immediately while deferring protected-frame appearance until afterward. Confirm the dialog/card text fits on both clients.

Check alpha edges, repeat seams, pixel snapping, native curved masks, portrait/bar intersections, name/level/value text overlap, and visibility of every functional highlight. Inspect artwork without the other installed loose texture replacements, then with them, to distinguish addon behavior from client texture overrides. No production visual-fit claim is possible until these checks are recorded.

## Profiles and persistence

Verify profile precedence, switching/copy/reset, per-character assignments, global/group enable overrides, and export/import into the other client. Reject malformed versions, unknown skins/groups/fields, out-of-range values, duplicate/conflicting paths, oversized payloads, and executable Lua. Canceling the color picker should preserve inheritance.

Run **reload**, **logout/login**, and **full client quit/restart** as separate tests on each client. Record the exact build and whether profile names, assignments, colors, and group overrides persist. Keep an external export during Forever beta. If restart loss reproduces, document the observed steps/build and keep the beta limitation visible.

## Release evidence

Replace Pending only with an actual dated result and tester/client evidence. Keep failed cases and reproduction steps. Rebuild archives after fixes, run offline checks, compare archive hashes, and verify that each ZIP contains one `JiberishUI` root with its client interface metadata. Current artifacts are labeled alpha and explicitly record `in_game_validated: false`.
