# Offline test report — 2026-09-20

Build: **0.1.0-alpha.3**. Status: **offline checks pass; Retail reports all 155 discovered frames applied with zero failures; full validation pending**.

| Check | Result |
|---|---|
| Lua 5.1 load/parse and behavioral harness | 33 test groups passed |
| Source manifest and safety boundary checks | Passed |
| Asset hashes/dimensions/casing/alpha bounds | 211 of 211 passed |
| Generated edge-tile repeat seams | All 44 generated edge tiles have matching endpoint pixels |
| Catalog coverage | 52 presets / 15 materials; 13 classes, 26 race identities, 2 factions, 8 standard styles |
| Source tracing | 146 Retail files; 110 Forever files; pinned manifests/includes/overrides verified |
| Adapter region paths | Checked against both cached source baselines |
| Retail package | Root, interface 120100, source/assets, and hash checked |
| Forever package | Root, interface 16001, source/assets, and hash checked |
| Retail live checks | Alpha.3: all 155 discovered frames applied, zero failed, no recorded notices; player portrait/health/power borders visible in user screenshot; full scenario testing pending |
| Forever live checks | Not run |

The behavioral groups cover startup/native Settings registration; skin/global/group precedence and copying; profile export/import and malformed rejection; full valid power palettes; named profiles/character selection; future-schema preservation; compact pets and nameplate exclusion; stable texture/hook counts; latest-state combat queuing and deferred attachment; reload-required disable; native dead/tapped/disconnected/restricted/threat priority; neutral-fill reapplication and native restoration; class/reaction and power-type modes without quantity reads; native/addon mask ownership; missing skin artwork; missing required frame regions; missing neutral artwork; overlapping-addon skips; native button state resets; pooled ownership loss; independent Forever endcaps; diagnostics without unit data; synthetic Settings preview; and independent adapters/unsupported-client rejection.

Commands used from the repository root:

```sh
.tools/lua-5.1.5/src/lua tests/run.lua
python3 tools/check.py
python3 tools/package.py
python3 tools/check.py --packages
```

The six new behavioral groups additionally cover every skin's import/export round trip and stable classic IDs; category/literal search; preset defaults with explicit global/group overrides; visual-browser card reuse/pagination/empty results; selection scope; and combat-deferred library selection. Eleven generated master PNGs are retained and hashed; their exact built-in image_gen prompts are saved with the project.

## Alpha.3 portrait-frame regression

On 2026-09-20, the user's Retail 12.1.0 / 69875 / 120100 diagnostics showed player, target, focus, pet, all five bosses, both small targets, four portrait party members, and four party pets attached but failed. Five compact party members, five compact pets, and all discovered action-bar families applied. The user confirmed action bars visibly worked. This pattern isolates attachment of portrait textures: the addon checked only for `HookScript` before registering `OnSizeChanged`, although a widget exposing `HookScript` need not support that script.

The test host previously allowed every script on every widget. Rejecting unsupported texture resize scripts reproduced the attachment failure before the fix. Alpha.3 checks `HasScript`, uses the owning frame for portrait resize notifications, and guards the other attachment script hooks. Additional tests exercise all six portrait-unit layouts on both adapters, color application, repeated refreshes, sanitized failure reports, and accurate live status. All 33 groups pass. After alpha.3 was installed, the user's screenshot confirmed visible live player portrait, health-bar, and power-bar borders on Retail. The subsequent diagnostics reported 155/155 discovered frames applied, zero failed, and no recorded notices, including every previously failing portrait family. Raid frames, spell flyouts, and Forever totems had zero discovered instances. Attachment success does not establish visual fit, functional states, or combat safety for every family; Forever remains untested.

Runtime failures now retain a fixed error category and addon source location, with stack-location fallback for C API errors. Raw error payloads and locals are excluded. Diagnostics distinguish attached, applied, and failed frames; Settings no longer claims successful application merely because a synthetic preview renders.

The mocked Lua host does not enforce WoW's protected/secret execution model or reproduce its renderer. The source/asset checks establish consistency with the audited inputs, not actual client compatibility. Complete `VALIDATION.md` before approving a production release. Exact output archive SHA-256 values are recorded in `dist/packages.json`.
