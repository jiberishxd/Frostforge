# Decorative rendering architecture

Five independent addon-owned roots cover Player portrait, Target portrait, Focus portrait, Minimap and Action hub. Each is a mouse/keyboard/wheel-transparent UIParent child. Blizzard frames are read-only anchors; no native reparenting, scripts, textures, attributes, layout or secure behavior are changed.

Core/Core.lua owns lifecycle, geometry, visibility, diagnostics and commands. ThemeManager resolves validated data-only configuration. ProfileManager stores versioned settings and data-only backups. Core/Portraits.lua selects safe public identity tokens. Themes/Portraits.lua contains only catalog data and media references. Each Modules file creates its own ordinary frame and textures. Retail and Forever use separate adapter methods for native root discovery and portrait visibility checks.

There are five decorative frames, nine artwork textures, 20 debug-edge textures and five labels. Each unit has a single texture; only the hub uses five independently laid-out pieces. Debug regions belong to those same roots. The nonvisual event driver and separately created options/picker windows are not decorative components.

## Native ownership and geometry

Local decorative scale is native effective scale / UIParent effective scale × configured scale. FRAME positioning follows the native root; SCREEN uses UIParent while preserving native scale/visibility. X/Y offsets remain expressed in native-anchor units. Width/height affect addon artwork only.

Native roots and each inspected portrait container/region pass IsForbidden checks before access. Missing or forbidden portraits hide the decoration. Default Background strata, level 0 and Background layer keep native portraits, bars, names and functional indicators above the art. Settings expose strata, level and layer without touching Blizzard objects.

All 42 portraits share an inner-contour fitting process and fixed center at (154,148). Each 512 × 256 atlas stores a 256-square Player teardrop fit on the left and a round Target/Focus fit on the right. Their opening radii are 60 and 58 respectively. Side cloth, feathers and stone retain their natural endings; there is no lower-band crop or level-badge notch. Target/Focus mirror only their atlas half. The hub uses its original five-piece layout with a separate 42-entry data-only catalog and guarded player identity resolver. Hub selection cannot follow target or focus changes.

## Identity changes and combat

The default CLASS mode uses UnitIsPlayer and the nonlocalized UnitClass token. NPCs use Neutral rather than their generic UnitClass result. RACE uses the nonlocalized UnitRace token; FACTION uses UnitFactionGroup. Every result is protected by pcall, checked with issecretvalue when available, and type-checked before lookup/comparison/formatting. Unknown, unavailable or restricted inputs resolve to Neutral. No health, power or identity strings are printed in diagnostics.

A 0.2-second read-only scan catches native visibility/scale changes and identity changes. Target/focus/portrait/faction events request immediate refresh. Stable scans perform no writes. Identity changes on already-attached unprotected addon frames replace only their texture. If anchoring makes the owned frame protected, the change waits for PLAYER_REGEN_ENABLED. All new attachment, geometry, layering and user-requested configuration changes defer during combat and apply the latest state afterward.

No Blizzard hooks are required. All frames/textures are reused. A replaced or forbidden root hides stale artwork when safe. Missing media never causes native decoration to be hidden.

## Profiles and options

JiberishUIDB.phase1 version 2 stores theme, debug, modules and optional options-window position. Version-1 unit shell dimensions convert once to compact portrait dimensions; relative offsets are translated to the new defaults. Non-unit settings and layering/visibility are retained. JF2 export includes portrait mode/choice; JF1 imports are converted. Validation is atomic and never executes Lua. Unknown/future versions stay read-only.

The movable /jui window has Player, Target, Focus, Minimap and Action hub tabs. Portrait tabs offer automatic class/race/faction or fixed artwork, plus a grouped thumbnail picker. Picking artwork selects FIXED; choosing an automatic mode resumes identity-driven selection. The picker never writes native frames. First creation is outside combat; existing settings can record deferred changes during combat. Opening, browsing or changing tabs does not create profile overrides.

Options use the nonsecure BackdropTemplate only on addon-owned settings objects. Native dialog/slider border files and button/check artwork provide the classic styling; decorative world modules still use plain frames. Every control is reused and checkbox/selection art reflects the saved value after validation, including rejected or combat-deferred changes.

Hub settings (`hubMode`, `hub`) are restricted to actionHub; portrait settings remain restricted to units. Both are included in bounded JF2 exports. The hub gallery uses 12 thumbnails per page and clears texture references when hidden. Options/picker backdrops have opaque addon-owned underlays.
