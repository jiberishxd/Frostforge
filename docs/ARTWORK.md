# Phase 1 prototype media

No new artwork is being commissioned or generated in this phase. Three existing local RGBA TGA assets are packaged as geometry fixtures:

| Asset | Stored size | Use |
|---|---|---|
| Media/sacred_gold/portrait.tga | 128 × 128 | Transparent gold surround for minimap/player/target artwork frames |
| Media/fantasy/paladin.tga | 512 × 256 | Paladin crest, displayed at 3:1 |
| Media/hub/console.tga | 2048 × 1024 | Single hub background texture |

Each rendering frame has its own main texture and crest texture. The gold surround and console stretch to the configured dimensions; this is deliberately an attachment/layout prototype, not a claim of final ornament proportions or a fitted portrait mask. No native portrait, status-bar fill, backdrop, mask, or border is changed.

[phase1-assets.json](phase1-assets.json) records exact packaged hashes, dimensions, alpha bounds and source artwork references/hashes. The sources are existing generated artwork from earlier development. The full historical asset manifest remains in assets.json but is not packaged.

Checks validate power-of-two dimensions, RGBA format, alpha bounds and hashes. These establish file integrity, not in-game rendering quality. Missing/failed texture loads hide owned artwork; Blizzard presentation remains intact. Some asynchronous missing-texture behavior can only be confirmed in WoW.
