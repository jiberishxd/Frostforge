# Saved settings and the reported Forever loading issue

Earlier player-reported Forever 1.60.1 build 69913 diagnostics reported that no JiberishUIDB table was received at startup, even though valid saved data had previously been inspected on disk. This refactor does not repair or make a new claim about the client's SavedVariables loader.

Named setups are stored in `JiberishUIDB.profileStore`; the chosen profile ID is stored per character in `JiberishUICharacterDB`. The first character upgrading from a single setup retains it as Imported setup. New characters receive separate automatic-class defaults. `JiberishUIDB.phase1` remains an alias to the active setup for existing diagnostics. Earlier renderer profiles remain untouched and inactive. The two client installations use separate saved files. See [Profiles](PROFILES.md) for copies, shared profiles and migration.

`/jf status` reports whether the addon received Phase 1 settings, created them, or encountered an unknown/future format. Unknown database formats and newer Phase 1 versions are preserved without writes. In a client-loading failure, the addon cannot read arbitrary disk files or reconstruct data that the client never supplied.

`/jf export` prints a bounded JF2 text backup of the active theme and appearance overrides to chat. Use a chat-copy facility if available to retain that text outside the client. For a copyable backup and restore dialog, open `/jui → Guide`. Restore with `/jf import <the complete JF2 text>`; the candidate is validated before application and never executed as Lua. JF1 backups are accepted with one-time portrait sizing conversion. Old JUI1 profiles are not imported into this renderer.

Offline tests prove a profile survives reinitialization when the saved table is supplied. Reload, logout/login and full-restart persistence must still be checked in the actual clients. Do not delete WTF or edit live SavedVariables as a troubleshooting step. Previous data recovery tools are historical and target the old JUI1 schema.
