# Validation and release gates

Status on 2026-09-20: **alpha implementation; not approved for production release**.

Completed locally: classic WC3 source extraction/measurement, 11 original material masters, 52-choice catalog and synthetic preview sheets, complete relevant manifest/XML tracing at both pins, Lua 5.1 parsing and 51 mocked behavioral test groups, 4 saved-data recovery parser tests, 212 asset/manifests integrity checks, installed ElvUI/Ellesmere source inspection, and separate client packages. Mocked tests cannot reproduce combat lockdown, taint propagation, secret-value engine enforcement, real Settings layout, or Blizzard's renderer.

Initial user testing on Retail 12.1.0 build 69875 confirmed action bars applying in alpha.2; diagnostics showed every portrait-unit attachment failed, while compact party members/pets and action-button families applied. Alpha.3 fixed the unsupported portrait-texture resize hook and applied all 155 discovered instances, but rectangular visual fit failed. Forever alpha.4 testing on 1.60.1 build 69913 applied all 169 discovered instances; screenshots showed material banding and a textured dead-target health backdrop. The user subsequently reproduced Forever settings loss on `/reload`, while read-only inspection found valid changed settings on disk. This matches [first-hand build 69913 persistence reports](https://us.forums.blizzard.com/en/wow/t/uiaddon-settings-wiped-on-client-restart/2353992); the precise loading failure is not yet instrumented in game. No blocked-action-free, fully compatible, seamless-fit, or restart-persistence claim is made.

Alpha.5 replaces the full-frame material with curved portrait trim and edge-only bar pieces, keeping native backdrops intact. All live checks for this correction and the external-provider adapters remain pending. Earlier attachment counts do not validate the new renderer. See `COMPATIBILITY.md` for the provider-specific test sequence.

## Gate 1: Human feasibility — required before wider rollout

On both clients, begin with only JiberishUI enabled and an exported backup of any existing profile. Verify Human player, target, and action-button examples first. Check neutral fill color/masks, border fit, target classification, action-button pressed/checked/hover states, profile change outside combat, and disable/reload restoration. Record exact client build, addon version, screenshots, and errors. If this gate fails, retain alpha status and fix it before treating the other race skins as release-ready.

## Coverage matrix

Every row requires **Retail and Forever** testing, unless marked Forever-only. The Retail alpha.3 user diagnostics reported 155/155 discovered frames applied, zero failed, and no recorded notices. This confirms attachment of all present families, including every previously failing portrait variant; raid, flyout, and totem instances were absent. Full behavior and visual scenarios below remain pending unless explicitly recorded.

| Family | Required cases | Live status |
|---|---|---|
| Player | Normal; vehicle; alternate resources; portrait/class icon choices | Alpha.3/4 visual fit failed; alpha.5 correction pending on both clients |
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
| Forever totems | Action pages, summon/recall, multicast flyout, empty slots | Alpha.4: 14 instances applied; visual/behavioral scenarios pending |
| Main-bar art | Border visibility, both endcaps, Forever separate endcap Edit Mode controls | Pending |
| Input | Mouse, keybindings, controller navigation, quick keybind mode | Pending |

## Behavior and safety

- Enter combat, request several themes/colors/sizes, then exit. Only the final requested settings apply after exit. No geometry/attachment writes should occur during combat.
- First encounter an unregistered pooled frame in combat. It stays native until combat ends. Confirm the frame is subsequently attached once.
- Repeat group changes, show/hide, Edit Mode save/cancel, skin switches, target changes, and addon loads. Confirm stable attachment counts and no growth in hooks/textures.
- Exercise dead/disconnected/tapped states and native threat-health coloring. Custom neutral fills must yield to the native presentation and preserve absorb, heal prediction, temporary health loss, selection and threat signals.
- Verify restricted/secret unit inputs do not produce Lua errors or expose unit quantities in diagnostics.
- Test ElvUI and Ellesmere modules individually, including profile changes, shaped portraits/buttons, and mixed provider configurations. Confirm diagnostics name the correct provider, native button states/clicks survive, and same-group provider conflicts are skipped with an explanation. SUF, PitBull, Bartender, Dominos, and Masque Blizzard remain conservative skips for affected modules.
- Inspect nameplates before and after group/target updates: no JiberishUI textures or state changes.
- Disable each module, then reload; disable the addon entirely and reload. Native appearance, secure clicks, actions, and controller navigation must work. No taint or blocked-action errors are acceptable.

## Visual checks

Test all 15 material families at 1920 × 1080, 2560 × 1440, and 3840 × 2160, with representative UI scales (0.64, 0.8, 1.0) and frame scales (0.75, 1.0, 1.25) where supported. Spot-check all 52 presets for palette readability. Test the minimum and maximum thickness, inset, opacity, and ornament settings on rectangular layouts. Native silhouettes must retain the owning UI's geometry at every setting. Include narrow party frames, dense 40-member raid layouts, vertical/multiline action bars, portrait-off states, ElvUI portrait overlays, and Ellesmere shaped/inside portraits.

Exercise the visual browser's four categories, search, empty search results, first/last page, and repeated open/close. Verify that selection applies to the intended Global/frame-group scope, existing profile IDs remain valid, and choosing a skin during combat changes the preview immediately while deferring protected-frame appearance until afterward. Confirm the dialog/card text fits on both clients.

Check alpha edges, repeat seams, pixel snapping, native curved masks, portrait/bar intersections, name/level/value text overlap, and visibility of every functional highlight. Inspect artwork without the other installed loose texture replacements, then with them, to distinguish addon behavior from client texture overrides. No production visual-fit claim is possible until these checks are recorded.

## Profiles and persistence

Verify profile precedence, switching/copy/reset, per-character assignments, global/group enable overrides, and export/import into the other client. Reject malformed versions, unknown skins/groups/fields, out-of-range values, duplicate/conflicting paths, oversized payloads, and executable Lua. Canceling the color picker should preserve inheritance.

Run **reload**, **logout/login**, and **full client quit/restart** as separate tests on each client. Record the exact build and whether profile names, assignments, colors, and group overrides persist. Keep an external export during Forever beta. Reload loss is user-reproduced on build 69913; logout/login and full restart results remain pending. Alpha.6 must also be checked for its `Settings at startup` diagnostic and manual `/jui export` / `/jui import` restoration. Do not treat successful import as a persistence pass. See `PERSISTENCE.md`.

## Release evidence

Replace Pending only with an actual dated result and tester/client evidence. Keep failed cases and reproduction steps. Rebuild archives after fixes, run offline checks, compare archive hashes, and verify that each ZIP contains one `JiberishUI` root with its client interface metadata. Current artifacts are labeled alpha and explicitly record `in_game_validated: false`.
