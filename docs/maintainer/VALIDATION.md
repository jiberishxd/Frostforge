# In-game checks

Record the client/build and provider versions. Offline tests do not replace these checks:

- Fresh settings: first-login tour, skip/reopen, settings access and optional minimap icon. Check the blue Frostforge row after AddOns inside the Escape menu with Blizzard, ElvUI and Ellesmere menu styles, repeated opens, menu scaling and combat. Confirm the row matches neighboring buttons and remains inside the menu background without overlap or cumulative height growth. After installing the Game Menu fix, reload the UI to clear the previous hook/taint, then verify native Options, AddOns, Return to Game, Logout and Exit Game after repeated menu opens and Frostforge settings visits. Confirm no protected `callback()` errors; offline tests cannot validate the secure engine.
- Profiles: separate characters, shared/copy behavior, backups, reload and full-restart persistence.
- Artwork: each component, fixed/automatic themes, fit, scale, hiding and restoration on disable.
- Combat: switch between NPCs and players, clear target/focus, and check artwork recovery afterward.
- Blizzard: custom Hunter power color, native text/texture restoration, aura/cast offsets and cast-border layering.
- ElvUI/Ellesmere: supported portrait/frame layouts, provider switches and profile changes; round minimap restoration.
- Casts and action bars: cast/channel visibility, interrupts, empowered casts where available, and vehicle/override transitions.
- Performance: comparable sessions with settings closed and after browsing artwork; report the installed version and elapsed time.

- Party / Target of Target: all three providers, sorted groups, join/leave, combat identity changes, no-target hiding, separate/disabled portraits and provider switches. Check all five Ellesmere party members with range fading enabled, outside and during combat, including Frostforge opacity and out-of-range fades. Check automatic/manual strata and separate border levels above native highlights, including layers raised in combat. Confirm no input blocking or protected-frame errors; artwork-only changes stay deferred during combat.

Send results and screenshots to [The Igloo Discord](https://discord.com/servers/igloo-460933747731070996). Preserve saved settings when troubleshooting.
