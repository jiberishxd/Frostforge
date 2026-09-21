# Phase 1 test results

Build: **0.2.0-phase1.1**. Date: **2026-09-21**.

**34 Lua 5.1 behavior tests passed.** The host rejects writes to Blizzard frames and secure/native templates; no native-frame writes occurred. It also rejects native hooks, since this prototype requires none.

Covered: four-module/one-theme ownership; mouse transparency; both compatibility paths; wrong-client and unsupported packages; missing/forbidden/restricted roots; effective-scale calculations and anchor-relative offsets; simulated 1080p/1440p/4K dimensions; Edit Mode events; all exposed settings; latest-state combat deferral; login and root replacement during combat; protected artwork; target/main-bar visibility and fading; individual hiding/reset; debug metadata; idle read-only polling; object reuse; missing-art fallback; theme immutability; retained legacy data; invalid/future profiles; simulated settings reload; atomic data-only backup import; invalid commands and repeated startup.

Source/media/package checks validate the required file layout, exact active modules/theme, absence of legacy code in the load manifest/packages, prohibited API use, data-only theme declarations, three TGA hashes/dimensions/alpha, and both client package manifests.

The mocked resolution tests verify coordinate calculations and anchor references, not pixels. The host does not reproduce WoW's secure execution, restricted APIs, texture cache, renderer or SavedVariables loader.

## Live status

**This Phase 1 refactor has not yet been tested in Retail or Forever.** Prior alpha screenshots and diagnostics showed fit/layout problems in the replaced renderer and a missing saved table on Forever 69913. Their attachment counts are not evidence for this implementation.

The four-component checklist in VALIDATION.md remains required. Pixel-perfect artwork, replacement-addon support and additional themes/components are not release claims.
