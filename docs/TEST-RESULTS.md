# Offline test report — 2026-09-20

Build: **0.1.0-alpha.2**. Status: **offline checks pass; live-client validation pending**.

| Check | Result |
|---|---|
| Lua 5.1 load/parse and behavioral harness | 30 test groups passed |
| Source manifest and safety boundary checks | Passed |
| Asset hashes/dimensions/casing/alpha bounds | 211 of 211 passed |
| Generated edge-tile repeat seams | All 44 generated edge tiles have matching endpoint pixels |
| Catalog coverage | 52 presets / 15 materials; 13 classes, 26 race identities, 2 factions, 8 standard styles |
| Source tracing | 146 Retail files; 110 Forever files; pinned manifests/includes/overrides verified |
| Adapter region paths | Checked against both cached source baselines |
| Retail package | Root, interface 120100, source/assets, and hash checked |
| Forever package | Root, interface 16001, source/assets, and hash checked |
| In-game checks on either client | Not run |

The behavioral groups cover startup/native Settings registration; skin/global/group precedence and copying; profile export/import and malformed rejection; full valid power palettes; named profiles/character selection; future-schema preservation; compact pets and nameplate exclusion; stable texture/hook counts; latest-state combat queuing and deferred attachment; reload-required disable; native dead/tapped/disconnected/restricted/threat priority; neutral-fill reapplication and native restoration; class/reaction and power-type modes without quantity reads; native/addon mask ownership; missing skin artwork; missing required frame regions; missing neutral artwork; overlapping-addon skips; native button state resets; pooled ownership loss; independent Forever endcaps; diagnostics without unit data; synthetic Settings preview; and independent adapters/unsupported-client rejection.

Commands used from the repository root:

```sh
.tools/lua-5.1.5/src/lua tests/run.lua
python3 tools/check.py
python3 tools/package.py
python3 tools/check.py --packages
```

The six new behavioral groups additionally cover every skin's import/export round trip and stable classic IDs; category/literal search; preset defaults with explicit global/group overrides; visual-browser card reuse/pagination/empty results; selection scope; and combat-deferred library selection. Eleven generated master PNGs are retained and hashed; their exact built-in image_gen prompts are saved with the project.

The mocked Lua host does not enforce WoW's protected/secret execution model or reproduce its renderer. The source/asset checks establish consistency with the audited inputs, not actual client compatibility. Complete `VALIDATION.md` before approving a production release. Exact output archive SHA-256 values are recorded in `dist/packages.json`.
