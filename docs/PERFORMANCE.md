# Performance work in 0.9.7

All 296 pre-existing runtime artwork files remain byte-for-byte unchanged. Texture quality, dimensions, alpha and artwork fitting have not been reduced. Two new, small onboarding captures are loaded only on their visible tour page and released when the tour closes.

## What changed

- Read-only settings are resolved once per component per update pass. Layout code still gets independent mutable copies. The cache expires at the end of every pass, so profile changes and imports cannot leave stale settings.
- Stock StatusBars retain ownership of animated fill UVs. Ordinary health/power animation no longer triggers texture reapplication or invalidates unrelated portrait, hub and minimap layouts. Actual native texture/atlas changes still restore the selected material.
- Target/focus/identity events still update immediately, including during combat, without forcing every unrelated decoration through a full layout. Visible settings previews still refresh.
- Artwork browsers are created only when opened. Search, pagination, selected states and all themes remain available. Closing a browser releases its thumbnails; reopening reuses its existing controls.

The 0.2-second geometry/provider poll, 0.05-second cast-visibility check and combat protections are unchanged. No runtime forced garbage collection or lower-resolution artwork is used.

## Offline comparison

The Lua 5.1 mock host compared the 0.9.6 working baseline (`6a42747`) with 0.9.7, using 1,000 updates per workload. These are synthetic measurements, **not live WoW CPU percentages or AddOns-tooltip memory measurements**. They include the test host's bookkeeping and exclude the game's renderer/texture memory. Timing below is the median of three local runs; [raw samples](performance-0.9.7.csv) are retained.

| Workload | Baseline time | Updated time | Temporary allocation, before → after |
| --- | ---: | ---: | ---: |
| Idle, two full shells | 0.490 s | 0.341 s | 152.4 → 68.3 MiB (55% less) |
| Native fill animation | 0.599 s | 0.348 s | 188.4 → 68.4 MiB (64% less) |
| Combat target switching | 0.389 s | 0.275 s | 121.7 → 52.4 MiB (57% less) |

Opening settings creates 2,399 mock UI objects instead of 3,822 (37% fewer); additional retained mock-host memory is 4.76 MiB instead of 7.29 MiB (35% less). That saving applies before browsing collections. Controls for a collection are created the first time it is opened and reused thereafter. Steady passes retain under 1 KiB after collection, with no growing frame/texture count in these workloads.

Reproduce with `lua tools/benchmark.lua [path-to-addon-folder] [iterations]`. Garbage collection is stopped temporarily **inside this offline benchmark only** to count temporary allocations, then restarted. The addon itself never changes the collector.

## In-game comparison

The supplied AddOns-tooltip screenshot shows **0.9.3**, **3% average CPU** and **52 MB**; the earlier reported values were 4% and 63 MB. These are observations from the older installed build, not measurements of this update.

1. Install the new `Frostforge` folder, remove the old `JiberishUI` addon folder, and fully restart WoW. Preserve or transfer saved settings as described in [Getting started](GETTING-STARTED.md#upgrading-to-frostforge). Confirm **0.9.7** in the AddOns tooltip.
2. Compare similar sessions with the same UI addons, artwork, location, and encounter. Record the tooltip after login, after several minutes with settings closed, and after opening/closing the artwork browsers.
3. Check target/focus switching in combat, a Hunter's custom power color, casts, provider redraws and the minimap. Functionality should remain the same.
4. If memory continues rising over a longer session or CPU stays high, report the tooltip/version, client, enabled UI addons, elapsed time, and whether settings were open. We cannot infer a leak or a guaranteed new CPU percentage from the old tooltip alone.
