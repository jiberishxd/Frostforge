# Forever settings recovery

On 2026-09-20, the user reported that changing appearance or health color mode in Forever 1.60.1 build 69913 was undone by `/reload`. Read-only inspection found the changed settings in `JiberishUI.lua` on disk. Its current Default profile contained the player Alliance skin and class health colors; the previous `.bak` contained Night Elf Ancient Grove for player and Aged Bronze for target. Both were recovered as data-only JUI1 exports and accepted by the addon's validator. A fresh profile-service initialization retained those choices when given the saved data.

This matches [first-hand reports of Forever's SavedVariables loading failure](https://us.forums.blizzard.com/en/wow/t/uiaddon-settings-wiped-on-client-restart/2353992): account/character files are written, but their data is not restored on reload/login. This is evidence pointing to the client loader, not an independently instrumented trace of that loader. Alpha.6 diagnostics record whether WoW supplied a saved table, or whether the addon rejected a supplied Default profile. A missing table is also normal on a genuine first run.

## Keep and restore your choices

1. Before reloading or logging out, run `/jui export`, select all, and copy the text to a file outside the game.
2. If settings reset, run `/jui import`, paste that text, and apply it.
3. Check `/jui diagnostics` for **Settings at startup**. Report whether it says a saved table was received, no table was received, or an invalid Default profile was recovered.

Exports restore appearance in the current session. They do not fix automatic loading on the next reload. The addon cannot read arbitrary disk files or force WoW to load SavedVariables. Switching to class colors does not itself reset a profile. Retail and Forever have separate settings stores.

## Recover settings already written to disk

The current saved file and its `.bak` can contain different sessions. Copy them before further reloads overwrite either one. Do not edit a live game's SavedVariables or delete its WTF directory as part of this procedure.

From the repository, use the data-only recovery tool with a new output folder:

```sh
python3 tools/recover_profiles.py /path/to/SavedVariables/JiberishUI.lua --output recovery/my-forever-save
```

The tool reads WoW's simple data-table format without executing Lua and writes one `.jui.txt` per profile plus an index. Repeat for `.lua.bak` into a different output folder if needed. Import the desired export through JiberishUI's normal validated importer. Private recovery outputs are excluded from Git and client packages.

No automatic persistence fix or successful Forever restart test is claimed. The settings-loss symptom is now user-reproduced; restoration from an export still needs an in-game confirmation.
