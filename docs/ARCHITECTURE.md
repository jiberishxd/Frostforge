# Implementation contract

The addon is cosmetic. Blizzard or the selected frame provider retains secure buttons, attributes, parentage, layout, frame dimensions, frame levels, and event scripts. No global native function is replaced by addon code. Post-hooks are registered once, and the ownership registry and lifecycle flags live in addon-owned tables.

## Layers

| Component | Responsibility |
|---|---|
| `Build.lua` | Packaging flavor and audited interface |
| `SkinCatalog.lua` / `Skins.lua` | 52 stable profile IDs, category/search metadata, shared material paths, palette defaults |
| `Adapters/Common.lua` | Explicit containers, texture allowlists, shared field paths, conflicts |
| `Adapters/Retail.lua` | Retail descriptor, interface 120100, independent definitions |
| `Adapters/Forever.lua` | Forever descriptor, interface 16001, Camelot medallion preservation, multicast coverage |
| `Adapters/Integrations.lua` | ElvUI/Ellesmere registry discovery, ownership selection, optional refresh hooks |
| `Core/Main.lua` | Discovery, ownership, lifecycle, coalesced events, combat deferral, reload rules |
| `Core/Renderer.lua` | Native artwork silhouette masks, addon-owned corner/edge textures, bounded geometry, Blizzard button-state textures |
| `Core/Colors.lua` | Neutral status-bar fills, mask ownership, native-priority fallback, no quantity reads |
| `Core/Profiles.lua` | Schema validation, precedence, character assignments, bounded data-only import/export |
| `Core/Settings.lua` | Native Settings canvas, searchable/paged visual skin browser, synthetic preview, profile controls |
| `Core/Diagnostics.lua` | Build, geometry, attachment count, compatibility failures |

Skin choice resolves group skin → explicit global skin → profile skin. The resulting skin defaults are merged with explicit global options and group options. Settings schema version 1 preserves unknown future versions without modifying them. An invalid default profile is retained as recovery data and replaced with a valid default; invalid named profiles are excluded from selection.

Blizzard decorative textures contain both trim and bar backdrops; alpha.4 incorrectly painted the whole silhouette. Alpha.5 keeps the native texture and its opacity intact. Health/power trim is restricted to edge-only pieces outside each status bar. Portrait material follows 32 curved quadrilaterals around the portrait, with continuous texture coordinates along the arc. Addon-owned masks clip both to the native decorative texture's atlas/file and any extra native clipping masks. Additional opaque-outside/transparent-inside masks prevent portrait trim from entering either bar's horizontal span, including dead and partially empty bars. No whole-frame material or undercoat is used for Blizzard units. Native geometry and functional indicators remain unchanged, and native artwork stays visible if qualification fails. Mask pools are reused; creation, anchors, and vertex offsets wait until outside combat.

The separate full-silhouette renderer is used only for Ellesmere's dedicated border-only portrait/button artwork. Its material and undercoat follow that source's exact bounds and visibility. Both renderers use the source's draw layer and sublevel.

External providers are discovered only through their specific registries and known containers. Their rectangular frames receive an outer border limited to 3 UI units. Ellesmere shaped portraits/buttons use the same silhouette renderer where native border artwork exists. Button state textures are never replaced on external-provider buttons, including the special Blizzard buttons those addons style. Unit colors use ElvUI's existing unit field, Ellesmere unit frames' `_euiUnit`, or Ellesmere raid/party buttons' read-only `unit` attribute. Replaced bars restore their previous fill before being retired. Provider selection is recalculated on discovery, old ownership is revoked, and attachment waits until login and until outside combat. See `COMPATIBILITY.md` for coverage and limitations.

The expanded library keeps all four original profile IDs unchanged. Category membership is descriptive: any preset can be selected on either client regardless of the player's actual race/class. Presets reuse 15 shared material directories; palette/default differences are explicit catalog data. Browser previews show the skin's defaults and disclose that saved appearance overrides still apply. Browsing and synthetic preview creation touch only addon-owned frames, including during combat; selecting a style uses the existing deferred application path.

## Source evidence and load order

All research is pinned to these revisions of the Blizzard UI source mirror:

- [Retail `7828252`](https://github.com/Gethe/wow-ui-source/tree/78282522143e25c3540583734fd192c3d69be910/Interface/AddOns): 12.1.0.69875.
- [Forever `70ef1b2`](https://github.com/Gethe/wow-ui-source/tree/70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e/Interface/AddOns): 1.60.1.69913.

`source-load-order.json` records 146 Retail and 110 Forever files for the five frame-owning addons: UnitFrame, ActionBar, CompactRaidFrames, OverrideActionBar, and ZoneAbility. It records their declared dependencies, excluded game-type lines, ordered manifest entries, recursively expanded XML Includes and Script files, and SHA-256 hashes. It does not claim to trace every unrelated Blizzard addon or every dependency's internal implementation.

Retail uses Mainline-specific TOCs for UnitFrame, ActionBar, and ZoneAbility. Forever uses unified TOCs with Mainline family files and Camelot game overrides. In Forever, the Camelot player/target methods and templates load after shared/Mainline behavior, and Camelot MainMenuBarEndCaps provides independently editable endcap children. Those differences must not be flattened into a Retail-only adapter.

| Frame family | Geometry/discovery evidence | Decorations intentionally preserved |
|---|---|---|
| Player | Mainline `PlayerFrame.xml`; `PlayerFrameContentMain.HealthBarsContainer.HealthBar`, `ManaBarArea.ManaBar` | Class resources, status indicators, Forever level/PvP medallions |
| Target/focus/boss | Mainline `TargetFrame.xml`; target content health/power regions; `BossTargetFrameContainer.BossTargetFrames` | Boss/elite classification art, selection/threat, level/PvP, auras |
| Pet | Mainline `PetFrame.xml/lua`; initialized `healthbar`, named power/mask regions | Attack/status flash, happiness when present, predictions |
| Small targets | `TargetofTargetFrameTemplate`; health, mana, portrait | Aura/functional regions |
| Portrait party/pets | Mainline `PartyFrameTemplates.xml`; `PartyFrame.MemberFrame1..4` and their `PetFrame` | PartyMemberOverlay, role/leader/ready/disconnect/threat signals |
| Compact party/pets | Shared `CompactPartyFrame.lua/xml`; member/pet arrays | Every functional compact indicator |
| Raid | Raid container descendants only, including reserved/pet/flagged frames | Same compact indicators; native threat-health mode |
| Buttons | Explicit bar arrays, verified named special buttons, zone container and flyout lists | Icon, cooldown, count/key text, proc/selection/threat overlays |
| Main-bar art | `MainActionBar.BorderArt`, `EndCaps.LeftEndCap.Texture`, `RightEndCap.Texture` | Native endcap containers, visibility and layout |

Source dimensions such as 232 × 100 describe the initial player/target frame in UI units. The renderer reads each region's runtime size/effective scale. No 232 × 100 asset is stretched across every frame. Power-bar artwork can change with power type, vehicle, or classification; post-hooks retain the latest native texture/color and reapply a neutral fill only when the requested color can be resolved safely.

## Lifecycle and failure behavior

Initial attachment, texture creation, masks, and geometry writes occur outside combat. During combat, attached frames may refresh texture/color only; newly discovered frames remain native. Settings resolve into an applied snapshot only after combat, with the latest requested values winning. No health/power quantities are read, compared, calculated, or logged.

Discovery runs after initialization, relevant addon loads, group/target/pet/vehicle changes, Edit Mode/layout changes, and special-bar refreshes. Repeated discovery reuses records and textures. Shared compact/unit helpers only act on registered owners. Each discovery verifies current ownership; removed frames stop receiving updates. A conflict or ownership change restores addon-owned borders/native decoration alpha and stops hooks from applying custom art; a reload completes restoration of button artwork. Ordinary module disabling retains the current live appearance until reload to avoid applying stale native snapshots.

Suppressed decorations are a small texture allowlist, not all regions under a frame. A failed/unqualified border does not suppress its native decoration. Mask removal only removes masks added by JiberishUI. Native masks that were already present remain attached. Function hooks are not removable in WoW, so disabled modules are excluded from attachment after reload.

Compact/rectangular border pieces use the border layer; native-shaped trim retains the source decoration's layer and sublevel. Endcaps inherit the visibility and positioning of their native decorative child. Dense layouts, unusual scaling, gamepad modes, and relative frame levels still require in-game verification; an offline host cannot certify those engine behaviors.
