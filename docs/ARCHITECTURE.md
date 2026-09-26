# Decorative rendering architecture

Five independent addon-owned roots cover Player portrait, Target portrait, Focus portrait, Minimap and Action hub. Each is a mouse/keyboard/wheel-transparent UIParent child. Blizzard or the selected UI addon remains the functional owner. Portrait-only mode uses read-only anchors. Optional full skins may change and restore the existing health/power fill texture and its UVs, plus presentation points/sizes (Blizzard power only; Ellesmere health and power) to fit the source artwork’s thick divider. No native reparenting, scripts, attributes, values or secure behavior are changed. All presentation writes defer in combat.

Core/Core.lua owns lifecycle, geometry, visibility, diagnostics and commands. ThemeManager resolves validated data-only configuration. ProfileManager stores versioned settings and data-only backups. Core/Portraits.lua selects safe public identity tokens. Themes/Portraits.lua contains only catalog data and media references. Each Modules file creates its own ordinary frame and textures. Retail and Forever use separate adapter methods for native root discovery and portrait visibility checks.

Portrait-only mode has five decorative frames, nine artwork textures, 20 debug-edge textures and five labels. Each unit has a single texture; only the hub uses five independently laid-out pieces. Debug regions belong to those same roots. The nonvisual event driver and separately created options/picker windows are not decorative components.

## Native ownership and geometry

Local decorative scale is native effective scale / UIParent effective scale × configured scale. FRAME positioning follows the native root; SCREEN uses UIParent while preserving native scale/visibility. X/Y offsets remain expressed in native-anchor units. Width/height affect addon artwork only.

Native roots and each inspected portrait container/region pass IsForbidden checks before access. Missing or forbidden portraits hide the decoration. Default Background strata, level 0 and Background layer keep native portraits, bars, names and functional indicators above the art. Settings expose strata, level and layer without touching Blizzard objects.

All 42 portraits share an inner-contour fitting process and fixed center at (154,148). Each 512 × 256 atlas stores a 256-square Player teardrop fit on the left and a round Target/Focus fit on the right. Their opening radii are 60 and 58 respectively. Side cloth, feathers and stone retain their natural endings; there is no lower-band crop or level-badge notch. Target/Focus mirror only their atlas half. The hub uses its original five-piece layout with a separate 42-entry data-only catalog and guarded player identity resolver. Hub selection cannot follow target or focus changes.

## Identity changes and combat

The default CLASS mode uses UnitIsPlayer and the nonlocalized UnitClass token. Recognized NPC city affiliations use existing race art; other NPCs use Neutral rather than their generic UnitClass result. RACE uses the nonlocalized UnitRace token; FACTION uses UnitFactionGroup. Every result is protected by pcall, checked with issecretvalue when available, and type-checked before lookup/comparison/formatting. Unknown, unavailable or restricted inputs resolve to Neutral. No health, power or identity strings are printed in diagnostics.

A 0.2-second read-only scan catches native visibility/scale changes and identity changes. Target/focus/portrait/faction events request immediate refresh. Stable scans perform no writes. Identity changes on already-attached unprotected addon frames replace only their texture. If anchoring makes the owned frame protected, the change waits for PLAYER_REGEN_ENABLED. All new attachment, geometry, layering and user-requested configuration changes defer during combat and apply the latest state afterward.

Portrait-only mode installs no native hooks. Full skins use secure post-hooks only to observe texture redraws and queue a refresh. All frames/textures are reused. A replaced or forbidden root hides stale artwork when safe. Missing media never causes native decoration to be hidden.

## Profiles and options

JiberishUIDB.phase1 version 2 stores theme, debug, modules and optional options-window position. Version-1 unit shell dimensions convert once to compact portrait dimensions; relative offsets are translated to the new defaults. Non-unit settings and layering/visibility are retained. JF2 export includes portrait mode/choice; JF1 imports are converted. Validation is atomic and never executes Lua. Unknown/future versions stay read-only.

The movable /jui window has Player, Target, Focus, Minimap and Action hub tabs. Portrait tabs offer automatic class/race/faction or fixed artwork, plus a grouped thumbnail picker. Picking artwork selects FIXED; choosing an automatic mode resumes identity-driven selection. The picker never writes native frames. First creation is outside combat; existing settings can record deferred changes during combat. Opening, browsing or changing tabs does not create profile overrides.

Options use the nonsecure BackdropTemplate only on addon-owned settings objects. Native dialog/slider border files and button/check artwork provide the classic styling; decorative world modules still use plain frames. Every control is reused and checkbox/selection art reflects the saved value after validation, including rejected or combat-deferred changes.

Hub settings (`hubMode`, `hub`) are restricted to actionHub; portrait settings remain restricted to units. Both are included in bounded JF2 exports. The hub gallery uses 12 thumbnails per page and clears texture references when hidden. Options/picker backdrops have opaque addon-owned underlays.

## Minimap collection

Core/Minimaps.lua reuses the guarded player identity resolver with the data-only Themes/Minimaps.lua catalog. `minimapMode` and `minimap` settings are scoped to the minimap and round-trip in JF2 backups. Automatic modes never follow target/focus. The 12-thumbnail paginated picker clears hidden references and reuses its controls.

All 42 textures share a circular opening, center and 512-square canvas. Core applies native diameter / 198 to the configured artwork dimensions, then follows native effective scale using the normal owned-frame path. No native dimensions are written. Existing user overrides persist; debug reports the resulting applied geometry. Combat deferral, forbidden-frame gating and visibility handling are shared with the other decorations.

## Addon portrait anchors

Compatibility/AddOns.lua discovers Blinkii's active Portraits registry, ElvUI's current Portrait.backdrop and EllesmereUI's current Portrait.backdrop without calling their update methods. It uses the active registry rather than historical Blinkii frame globals, so clickable/display switches cannot strand artwork. Separate portraitSource and hubSource properties are module-scoped, persisted in version-2 settings and exported in JF2. Optional dependencies establish normal load order; the existing discovery scan and ADDON_LOADED path handle delayed frames.

mMediaTag uses `ElvUI_mMediaTag[3].Portraits.portraits[unit]` on 4.x, or `mMT.Modules.Portraits.Player/Target/Focus` on 3.x. The current engine takes precedence over legacy fields; a missing active unit never falls back to a historical frame global. Both adapters read the actual mask dimensions and selected texture path. The 4.x mask is twice the secure button size; the legacy mask matches its frame. Portrait content zoom therefore does not enlarge the surround. Automatic selection checks Blinkii, mMediaTag, ElvUI and EllesmereUI before Blizzard. Disabled legacy frames are hidden and skipped by Automatic; explicit MMT selection stays hidden until the portrait returns. No secure buttons, masks, update methods or saved provider settings are modified.

Source snapshots carry a provider and opening fit. External portraits normally use the round atlas half; Ellesmere’s stock player mask selects the teardrop half and its published portrait side determines mirroring. Fitting scales the 58-unit opening to a containing circle and offsets the off-center (154,148) opening, mirrored to (102,148) for Target/Focus, onto the external portrait center. Saved width/height remain relative multipliers; X/Y are adjustments from the native theme defaults. Scale changes keep the opening centered. SCREEN mode centers against UIParent while still following the selected portrait's visibility and size.

Themes/PortraitMaskFits.lua contains measurements only: the maximum occupied radius of 40 Blinkii masks, seven Ellesmere masks and 72 mMediaTag masks (48 current, 24 legacy). Blinkii renders textures at twice its portrait frame dimensions. Ellesmere's active detached mask bounds are used independently of the enlarged portrait content; unmasked 3D and rectangular portraits use a containing circle. Unknown custom Blinkii and mMediaTag masks use the full texture extent. Native frames retain their original fit. Minimap remains a shared native root, and the hub can follow each suite's main bar. Bar skins independently select visible Blizzard or Ellesmere frames with `unitFrameSource`; ElvUI bars are not reskinned.

## Optional native unit-frame skins

Core/UnitSkins.lua owns opt-in appearance records, with data-only paths in Themes/UnitSkins.lua. `unitFrameShown=false` is the default for Player/Target/Focus. Enabling it creates two additional UIParent shell roots per enabled unit, each click-through, with eight health-half and five power-half art regions plus the usual debug outline/label. Their sizing follows the actual health or power bar, independent of portrait adjustments. Catalog entries carry measured source openings. Endcap scale derives from health height; power is aligned beneath the source-proportional divider. Original power points/size are restored when disabled. A later native layout supersedes the saved geometry, and stable scans do not repeat writes. A retired record leaves its shell half in a reusable pool rather than creating new frames on each toggle.

Retail and Forever separately walk and IsForbidden-check content/main/health/mana containers. Existing StatusBar fill regions are reused; their current atlas/file and eight UV coordinates are captured only when public and restorable. All native writes go through an out-of-combat presentation gate. No status values, ranges, colors, animations, mask lists or prediction regions are inspected or changed. One plain grayscale stone health material and the existing identity-specific power textures modulate the provider's colors. Names, badges and class resources stay native.

Secure hooks on bar SetStatusBarTexture and fill SetTexture/SetAtlas/SetTexCoord only mark an external redraw. Hook-supplied objects are gated before inspection. The next safe scan captures the newest native appearance and reapplies the fill; UV-only redraws never replace the saved native asset with our own. Disable/hide/reset, source changes and region replacement restore the latest original outside combat. Forbidden/secret regions remain native, or retain a pending restoration until they are usable. Missing fill files restore the original immediately. The ElvUI and Ellesmere adapters also style replacement-addon bars.

### Independent artwork (0.7.1)

`shown` controls portrait surrounds and `unitFrameShown` controls shell/fill styling per unit. Legacy `unitStyle` loads/imports/commands map to that boolean. Portrait providers do not gate native shells. Forever resolves the initialized `healthbar`/`manabar` bindings, then verified child paths. Shells are laid out from public bar geometry before attempting native texture capture. Unavailable fill metadata keeps the native fill and reports that state while leaving decorative shells usable.

### EllesmereUI integration (0.7.2)

`unitFrameSource` (AUTO/BLIZZARD/ELVUI/ELLESMERE) is independent from `portraitSource`, validated per unit and included in JF2 exports. AUTO follows visible ElvUI then Ellesmere unit roots, with Blizzard fallback; an explicit provider waits for its own root. Ellesmere 9.2.9 exposes `Health`, `Power`, `Portrait.backdrop`, active masks and `_ufPortraitSide`. Only these public objects are inspected; no upstream methods or saved settings are called/changed.

The attached health/power bars share a clipping container. Their original combined physical height is divided by the measured shell opening span, yielding proportional health, divider and power sizes inside that same envelope. Both layouts are captured and restored; the clip/root/parent relationships are never written. New provider layouts supersede captured ones, and partial writes remain queued for restoration. Unsupported layouts (detached/vertical/above or off-center power) retain geometry and receive available texture replacements only. All writes wait out combat.

Default Ellesmere artwork layering follows its frame strata: shells use root level + 1 and portraits use backdrop level − 1, clamped to zero. Saved strata/level overrides remain authoritative. These are addon-owned frame writes only. Layer changes, stock portrait mask changes and side changes participate in refresh detection. `/jui status` reports independent toggles, requested/resolved portrait provider, current visibility and shell/fill outcomes.

### NPC city selection (0.7.3)

`Themes/NPCCities.lua` supplies twelve reputation-to-art mappings and five known guard creature IDs. `Portraits:NPCCity` requires public NPC/creature identity and excludes controlled units. It compares bounded data-only tooltip affiliation lines against client-localized reputation names, with the public guard-ID fallback when the line is unavailable. All fields pass the existing secret/type gates before comparison. The per-unit/GUID cache expires after half a second, and a changed GUID refreshes immediately. Fixed mode bypasses city selection; automatic modes share the result between portraits and shells. No zone guessing, tooltip mutation, identity logging or saved NPC database is used. See NPC-CITIES.md for sources and limits.

## Optional cast-bar borders

`Core/CastBars.lua` owns at most one reusable UIParent border per enabled Player/Target/Focus unit. Each renders the eight outer regions of a dedicated transparent CastBars texture; the complete outer contour is retained with no center artwork. All 42 cast assets share a 512 × 128 canvas and a (48,48)–(464,80) clear opening. Corner scaling is uniform; width/height controls center the border around the native bar and never resize the bar. It uses the shared unit identity resolver or an independent fixed catalog choice, reads only public cast-bar geometry/visibility and never writes native UI, hooks native callbacks or reads spell progress. `Compatibility/AddOns.lua` resolves Ellesmere/ElvUI Castbar members; each client adapter supplies its verified Blizzard cast bars. Attachment/layout defer in combat. The 0.05-second visibility scan is separate from the existing 0.2-second geometry discovery. Settings are unit-scoped and disabled by default; 42 new cast textures are included. Only the Mage portrait and unit-shell textures changed among the 252 existing assets, to correct their arcane-eye emblems. See CAST-BARS.md and cast-bar-sources.json.

## ElvUI full shells (0.8.5)

The same attached-stack fitter resolves `ElvUF_Player/Target/Focus.Health` and `.Power`, independently of portrait discovery. Public ElvUI layout flags exclude detached, inset, mini/spaced, offset and disabled power. Geometry checks still require horizontal bars with the same parent and aligned power below health.

ElvUI health normally uses opposing vertical anchors, so changing height alone is ineffective. While fitting, it receives a single equivalent top-left anchor; both original layouts remain captured for restoration. Parent-size changes and provider redraws trigger restoration and a fresh measurement. Desired geometry and actual engine readback are tracked separately to avoid accumulated shrinkage or repeated writes when dimensions are rounded. The full original stack height and clipping/parent relationships are preserved. Automatic texture ownership remains with ElvUI; explicit JIBERISH mode uses the existing observer/restoration gates. No upstream configuration or status values are accessed.

## Complete shells and stock styling (0.8.5)

A reusable footer anchored to health preserves the complete shell when power or its container is hidden, transparent, missing or collapsed. A near-black opening backing is separate from the original RGBA art. Visible power uses a separate lower-level well so resource fills remain on top. No fake StatusBar, health/power reads or image edits are introduced.

Full stock-portrait removal also suppresses PlayerRestLoop, HitIndicator and AttackIcon. An additional transparent mask on FrameFlash/Flash/StatusTexture survives native alpha/color/atlas animation; masks are attached/removed outside combat without changing native masks.

Stock texture discovery prefers initialized bars, with XML fallback, and covers upper/lower-case party references. Explicit health and power choices use the native StatusBar texture setter; the existing capture/restore and redraw gates remain. Stock name/health color records use guarded public class identity or a fixed charcoal color. Their opt-in color-only post-hooks keep native redraws consistent in combat; no native value, range, name text or secure attribute is read or changed. New hooks, options and restoration wait outside combat. Retired pooled frames restore their prior colors.
