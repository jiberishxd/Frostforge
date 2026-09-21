# Frame provider compatibility — alpha.7

These integrations are implemented and tested in the mocked host. **In-game compatibility is not yet verified.** Source inspection used the installed Retail copies of ElvUI 15.26 and Ellesmere Unit Frames, Raid Frames, and Action Bars 9.1.8. `integration-sources.json` records exact files and SHA-256 hashes without redistributing their code. Future versions can change private registries; unsupported layouts must retain native appearance and report the problem.

## Ownership and coverage

| Provider | Discovery | Styling |
|---|---|---|
| Blizzard | Existing Retail/Forever adapters and explicit containers | Curved portrait trim and bar-edge pieces clipped to native artwork; original backdrops preserved; compact borders; action-button states and main-bar decorations |
| ElvUI unit frames | Enabled UnitFrames module; `UF.units`, boss globals, party/raid/raid-pet headers | Thin outer frame border; separate 2D/3D portrait backdrops where portrait overlay is off; optional health/power colors |
| ElvUI action bars | Enabled ActionBars module; handled bars, pet/stance buttons, LibActionButton flyout registry | Outer border; native pressed/hover/checked/cooldown/proc styling preserved |
| Ellesmere unit frames | Enabled unit module; per-unit `GetUnitFrameSource`, `ns.frames`, boss globals | Thin outer border; detached/attached portrait backdrop borders; shaped portrait silhouette where available; inside portraits stay integrated |
| Ellesmere raid/party | Registered raid/party buttons and `GetFFD` data; extra frames excluded | Thin outer borders; optional health/power colors; existing unit attributes read only |
| Ellesmere action bars | `ns.barButtons`; shape data from the module's existing external frame-data registry | Rectangular borders or shaped border silhouettes; native button states retained |
| Shared special buttons | Existing Blizzard extra/zone, flyout, vehicle/override discovery when either action-bar provider owns styling | Added borders only; native/provider button states retained |

Ellesmere's explicit Blizzard unit-frame selection stays on the Blizzard adapter. An explicitly hidden unit group remains hidden. External party-pet groups have no invented replacement frames: only instances actually supplied by a supported provider are discovered. ElvUI header traversal is limited to its registered containers, never nameplates. Ellesmere raid extra-unit displays are outside this integration.

Use one provider for each group. ElvUI unit frames with Ellesmere action bars can coexist. Two enabled providers claiming the same group cause that group to be skipped with a diagnostic. Other known replacements (SUF, PitBull, Bartender, Dominos, Masque Blizzard) still cause conservative group skips. Masque styling owned by ElvUI is preserved; an additional JiberishUI border may need to be disabled for the desired visual result.

## Sizing and settings

Use the owning UI's layout editor. JiberishUI never moves or resizes protected frames or changes click attributes. On Blizzard portrait families, the native silhouette determines border width and curved bar ends; JiberishUI changes material, tint, and opacity. Thickness, inset, and ornament sliders are disabled for those individual groups. Party groups can contain both portrait and compact frames, so their size settings affect only the compact instances.

External rectangular borders clamp thickness to 3 UI units and have no hanging ornaments. Shaped Ellesmere borders follow Ellesmere's own border size and visibility. Change those dimensions in Ellesmere. Native color mode preserves each provider's bar styling; custom colors use the neutral-fill service. Values that are unavailable or restricted retain native presentation. Provider changes and module disabling require reload; ordinary skin changes apply outside combat.

Alpha.7 makes individual main/additional button borders optional and defaults to one shared surround, with separate micro-menu/bag inclusion. It reads ElvUI's `ElvUI_MicroBar` and `ElvUIBagBar` geometry when available; Ellesmere retains Blizzard's `MicroMenu` and `BagsBar` objects. Independent portrait trim and optional crests apply only to the external portrait backdrops already discovered above. Gradient fills share the native-priority color service. These additions are mocked and source-inspected, not live compatibility claims; see `FANTASY.md`.

## Required live checks

1. With the base Blizzard UI, check player and mirrored target portrait/bar outlines. Change target classification, portrait visibility, frame scale, and vehicle state. Check alpha edges and text/health/power visibility with Human, Dwarf, Night Elf, Mage, Warlock, and Black Stone.
2. Enable JiberishUI alongside ElvUI alone. Confirm diagnostics identify `elvui`; test all unit groups, portrait overlay on/off, bars, flyouts, and profile/layout changes. Verify original click bindings and button states.
3. Repeat with Ellesmere alone. Test Blizzard/Ellesmere/hidden per-unit selections after reload, shaped/rectangular/inside portraits, party and raid reuse, action-button shapes, flyouts, and layout changes.
4. Test mixed ownership and then a deliberate same-group conflict. Verify that the mixed configuration works and the conflicting group is skipped with an explanation.
5. On each setup, test combat, queued settings, summon/dismiss, group changes, reload, logout/login, full restart, and disable/reload restoration. Capture exact versions, diagnostics, screenshots, and BugSack errors.

Forever 1.60.1 build 69913 was tested on alpha.4: all 169 discovered instances applied, but portrait material banded and leaked into empty health backdrops. Alpha.5 addresses those failures and awaits a new live result. ElvUI/Ellesmere live validation remains pending. Source inspection of installed Retail addons does not establish that those addons support Forever.
