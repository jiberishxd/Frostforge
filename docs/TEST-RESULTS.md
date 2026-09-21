# Offline test report — 2026-09-20

Build: **0.1.0-alpha.6**. Status: **offline checks pass; Forever reload settings loss user-reproduced; curved trim and ElvUI/Ellesmere live validation pending**. Earlier builds' attachment successes and visual failures are recorded below.

| Check | Result |
|---|---|
| Lua 5.1 load/parse and behavioral harness | 51 test groups passed |
| Saved-data recovery parser | 4 tests passed; executable Lua, malformed data, duplicate keys, and excessive input rejected |
| Source manifest and safety boundary checks | Passed |
| Asset hashes/dimensions/casing/alpha bounds | 212 of 212 passed, including the bar-interior exclusion mask |
| Generated edge-tile repeat seams | All 44 generated edge tiles have matching endpoint pixels |
| Catalog coverage | 52 presets / 15 materials; 13 classes, 26 race identities, 2 factions, 8 standard styles |
| Source tracing | 146 Retail files; 110 Forever files; pinned manifests/includes/overrides verified |
| Adapter region paths | Checked against both cached source baselines |
| Retail package | Root, interface 120100, source/assets, and hash checked |
| Forever package | Root, interface 16001, source/assets, and hash checked |
| Retail live checks | Alpha.3: 155/155 applied but visual fit failed; alpha.5 validation pending |
| ElvUI / Ellesmere | Installed-source inspection and mocked provider tests passed; in-game testing pending |
| Forever live checks | Alpha.6: 169/169 applied, zero failed; no saved table received at startup. Visual fit, combat safety, and import recovery pending |

The behavioral groups cover startup/native Settings registration; skin/global/group precedence and copying; profile export/import and malformed rejection; full valid power palettes; named profiles/character selection; future-schema preservation; compact pets and nameplate exclusion; stable texture/hook counts; latest-state combat queuing and deferred attachment; reload-required disable; native dead/tapped/disconnected/restricted/threat priority; neutral-fill reapplication and native restoration; class/reaction and power-type modes without quantity reads; native/addon mask ownership; missing skin artwork; missing required frame regions; missing neutral artwork; overlapping-addon skips; native button state resets; pooled ownership loss; independent Forever endcaps; diagnostics without unit data; synthetic Settings preview; and independent adapters/unsupported-client rejection.

Commands used from the repository root:

```sh
.tools/lua-5.1.5/src/lua tests/run.lua
python3 tools/check.py
python3 tests/test_recovery.py
python3 tools/package.py
python3 tools/check.py --packages
```

The six new behavioral groups additionally cover every skin's import/export round trip and stable classic IDs; category/literal search; preset defaults with explicit global/group overrides; visual-browser card reuse/pagination/empty results; selection scope; and combat-deferred library selection. Eleven generated master PNGs are retained and hashed; their exact built-in image_gen prompts are saved with the project.

## Alpha.3 portrait-frame regression

On 2026-09-20, the user's Retail 12.1.0 / 69875 / 120100 diagnostics showed player, target, focus, pet, all five bosses, both small targets, four portrait party members, and four party pets attached but failed. Five compact party members, five compact pets, and all discovered action-bar families applied. The user confirmed action bars visibly worked. This pattern isolates attachment of portrait textures: the addon checked only for `HookScript` before registering `OnSizeChanged`, although a widget exposing `HookScript` need not support that script.

The test host previously allowed every script on every widget. Rejecting unsupported texture resize scripts reproduced the attachment failure before the fix. Alpha.3 checks `HasScript`, uses the owning frame for portrait resize notifications, and guards the other attachment script hooks. Additional tests exercise all six portrait-unit layouts on both adapters, color application, repeated refreshes, sanitized failure reports, and accurate live status. All 33 groups pass. After alpha.3 was installed, the user's screenshot confirmed visible live player portrait, health-bar, and power-bar borders on Retail. The subsequent diagnostics reported 155/155 discovered frames applied, zero failed, and no recorded notices, including every previously failing portrait family. Raid frames, spell flyouts, and Forever totems had zero discovered instances. Attachment success does not establish visual fit, functional states, or combat safety for every family; Forever remains untested.

Runtime failures now retain a fixed error category and addon source location, with stack-location fallback for C API errors. Raw error payloads and locals are excluded. Diagnostics distinguish attached, applied, and failed frames; Settings no longer claims successful application merely because a synthetic preview renders.

## Alpha.4 fit and provider integration

The user reported that alpha.3's rectangular portrait, health, and power borders did not fit the native teardrop and bar shapes. Alpha.4 replaced those separate boxes with material clipped to the existing decorative artwork's silhouette and exact anchors. The subsequent Forever screenshots showed horizontal bands around the portrait and material inside a dead target's health backdrop. Diagnostics on 1.60.1 / 69913 / 16001 reported all 169 discovered instances applied, including 14 totem-bar instances, with zero failures. This is a visual failure despite successful attachment. No combat-safety or persistence pass was recorded.

New tests verify silhouette anchors, atlas coordinates, clipping, visibility, repeated mask reuse, and combat refresh without geometry writes; ElvUI frame/container discovery and nameplate exclusion; Ellesmere per-unit source selection, shaped portraits, and unit field reads; Ellesmere's external raid/party data registry; native button-state preservation; mixed/competing providers; combat-deferred external attachment; shaped/shared special buttons and shape switching; replacement-bar restoration and stable hooks; missing external artwork; provider hook coalescing; login deferral; and missing-provider diagnostics. The installed-source snapshot covers ElvUI 15.26 and Ellesmere modules 9.1.8. No vendor code is bundled. These tests do not render the real client or establish compatibility.

The mocked Lua host does not enforce WoW's protected/secret execution model or reproduce its renderer. The source/asset checks establish consistency with the audited inputs, not actual client compatibility. Complete `VALIDATION.md` before approving a production release. Exact output archive SHA-256 values are recorded in `dist/packages.json`.

## Alpha.5 backdrop and curved-trim correction

Blizzard unit frames now retain their native decorative texture and backdrop. No whole-frame material fill is created for them. Bar textures occupy only the exterior perimeter; portrait material is mapped along a 32-segment arc and clipped to the native artwork. An additional generated rectangle-exclusion mask keeps every portrait segment outside the health/power interiors. Dedicated Ellesmere border-only textures retain the silhouette renderer.

Two regression groups verify edge-only placement, arc vertex/UV setup, exclusion-mask geometry, unchanged native backdrop/opacity and fills in the dead state, combat refresh without geometry/allocation, and missing-exclusion-mask fallback. The mask's exact alpha pixels are also checked. All 48 test groups and 212 asset checks pass. Alpha.5 was installed into the existing Retail and Forever folders after backing up their alpha.4 copies; live results remain pending.

## Alpha.6 Forever persistence investigation and recovery

The user reported appearance and class-color settings resetting after `/reload` on Forever build 69913. Read-only inspection found valid changes in the current SavedVariables file and a different valid profile in its previous backup. Both were copied to private recovery storage, converted without executing Lua, accepted by the normal profile importer, and retained by a fresh profile-service initialization. Neither the installed SavedVariables file nor its backup was edited. See `PERSISTENCE.md` for the evidence and manual recovery procedure.

Three new Lua groups cover restoration of serialized styles/color modes, startup diagnostics distinguishing absent data from rejected Default profiles, and direct export/import dialogs with malformed input rejection. Four Python tests exercise the saved-data recovery parser. All 51 Lua groups and 4 parser tests pass. This does not repair or prove the exact cause of the client's loading failure.

The user's subsequent alpha.6 diagnostics on Forever 1.60.1 / 69913 / 16001 reported `Settings at startup: No saved settings table received (first run or client loading failure).` The installed addon therefore received no saved table at initialization despite the prior valid disk data. All 169 discovered frames applied with zero failures; raid and flyout counts remained zero. This confirms the startup diagnostic in game and the missing data at the addon boundary. It does not confirm restoration from exports, visual fit, provider compatibility, combat safety, or successful persistence.
