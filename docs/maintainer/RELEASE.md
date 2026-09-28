# Release preparation

## Build and check the player downloads

1. Follow the [build and validation steps](README.md#build-installable-zips), including `python3 tools/check.py --packages`.
2. Upload the intended client-specific ZIP from `dist/` to the distribution page. The project description and screenshots are page content, not files to copy into the addon folder. GitHub's source ZIP is a developer checkout; it is not the prepared player package.
3. Check the ZIP contains one `Frostforge/` folder with `Frostforge.toc`, all active Lua/media, `README.md` and `CREDITS.md`. Do not add the outer repository, `artwork/`, `docs/`, `tests/`, `tools/`, local caches or backups.
4. Complete the relevant [live client checks](VALIDATION.md), record results, and keep the release label accurate about remaining validation. Packaging checks do not certify in-game behavior.
5. Review the version, changelog, installation links and project license/reuse terms before publishing. This cleanup does not select a new license or grant rights to third-party artwork.

The packager uses an explicit runtime inventory. Source code, all 298 runtime images, settings data names and compatibility aliases are unchanged by the documentation cleanup. Source-ZIP installation and packaged installation include the same two short documents. The repository keeps the complete artwork provenance; credits are included in every install.

## CurseForge listing notice

Place this notice near the end of the addon description, with a link to the repository’s artwork credits.

Blizzard artwork, icons, emblems and other Blizzard game assets depicted or referenced are © Blizzard Entertainment, Inc. World of Warcraft and Warcraft are trademarks or registered trademarks of Blizzard Entertainment, Inc. Jiberish's Frostforge is an independent fan-made addon and is not affiliated with, sponsored by or endorsed by Blizzard Entertainment.

[Artwork credits and provenance](https://github.com/jiberishxd/Frostforge/blob/main/Frostforge/CREDITS.md).

This notice records ownership and independence; it does not create a license or confirm permission for distribution. Keep the applicable source notices with any Blizzard assets.
