# Profiles for your characters

Open `/jui` and choose **Profiles** on the left. Each character remembers its assigned JiberishUI profile and loads it automatically at login. A new character gets a separate setup with automatic class artwork, so a Paladin's fixed artwork and offsets are not automatically applied to a Hunter alt.

## Save and assign a setup

1. On your Paladin, configure the artwork and fitting you want.
2. In **Profiles**, enter a name such as **Paladin raids**, then choose **Rename active profile**. Changes already save automatically.
3. Log in to your Hunter. Its initial setup is separate. Configure it, then name its active profile **Night Elf hunter**. Choose Automatic race on the components where you want Night Elf artwork instead of Hunter artwork.
4. To reuse a saved setup, select it in the list and choose **Use selected for this character**. The selection remains assigned after logout or restart.

**Save as new profile** makes an independent copy of the current setup, gives it the entered name and assigns it to this character. **New profile from defaults** creates and assigns a clean setup with automatic class artwork. Neither overwrites the previous profile. Create or switch profiles outside combat; the page explains when an action cannot run.

If two characters deliberately select the same saved profile, they share future edits. Use **Save as new profile** to give an alt its own copy before changing it. Profiles cover all JiberishUI components and controls, including artwork, providers, fitting, strata, native appearance options and window position. Other addons retain their own separate profiles.

## Existing settings and backups

When upgrading from the single-setup build, the first character to log in receives the existing setup as **Imported setup**. It can be renamed immediately. Other characters start separately; they can select that imported profile or copy it if desired. Earlier renderer data is retained without being imported into the current renderer.

**Guide → Copy settings backup** exports the active profile's artwork settings. Restoring a backup replaces the active profile's artwork settings without deleting or renaming other saved profiles. It does not export the whole profile library or character assignments. If a profile is shared, restoring into it also changes that shared profile; create a copy first when needed.

Named profiles are stored account-wide in `JiberishUIDB.profileStore`; each character's selected ID is stored by WoW in `JiberishUICharacterDB` through `SavedVariablesPerCharacter`. `JiberishUIDB.phase1` remains an alias to the current setup for compatibility with existing diagnostics. Retail and Forever installations have separate saved files. Unknown or future data formats are preserved without writes.

Offline tests simulate both clients, multiple character saved-variable tables, switching and relogging, independent copies, intentionally shared profiles, migration, imports and native presentation restoration. Actual logout/login persistence still needs player verification. The earlier reported [Forever saved-data loading issue](PERSISTENCE.md) remains distinct from profile selection.
