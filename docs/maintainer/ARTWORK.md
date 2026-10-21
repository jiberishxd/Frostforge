# Artwork sources

The addon ships 318 lossless PNG textures in `Frostforge/Media/`. Their decoded pixels match the approved TGA exports; the tested compressed files are retained without re-encoding. The installed [credits](../../Frostforge/CREDITS.md) describe attribution and the AI-assisted artwork process.

## Public records

The repository retains the [runtime inventory and source hashes](../phase1-assets.json), [reference URLs and hashes](../ARTWORK-SOURCES.json), [unit-frame fitting records](../artwork/unit-frame-fit-report.json), [cast-border geometry](../artwork/cast-borders.js), and [logo provenance](../images/LOGO-SOURCE.md). These small records support independent runtime validation without downloading the production art library.

Full-resolution sources, intermediate exports, drafts, masks, prompts, and the compressed source-art edition are maintained in a separately backed-up artwork library. They are not required to run, package, or test the addon runtime. The original repository history was archived before source artwork was removed from the published history.

## Work with the local art library

The library's primary `artwork/` directory contains the full-resolution source edition and local drafts. Its separate `compression-test/artwork/` directory retains the compressed branch's source edition. Keep both; the original production builders and provenance audits use the full-resolution edition.

From the addon repository, attach that primary directory as an ignored local `artwork` symlink (or copy it into an ignored `artwork/` directory):

```sh
ln -s "/path/to/Frostforge Artwork/artwork" artwork
FROSTFORGE_ARTWORK_TESTS=1 python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/check.py --with-artwork
```

Source-art audits are explicitly opt-in and fail if requested without the library. Standard CI always checks the shipped image hashes, decoded pixels, transparent openings, fitting, addon behavior, and exact package contents. It does not require private source files.

For artwork edits, run only the appropriate source builder in `tools/`. Those builders preserve their historical TGA production records. Then run `python3 tools/finalize_media.py` to export lossless PNGs and update runtime paths, the public inventory, and fitting metadata. Matching existing PNG bytes are retained; no resizing or recoloring occurs. Regenerate `docs/artwork/cast-borders.js` with `lua5.1 tools/export_cast_preview.lua` and run both runtime and source-art checks before packaging.

Back up the separate art library independently. Git ignores the entire local `artwork` path, so edits and drafts there are not saved by addon commits.

## Creature collection

Ten creature types have dedicated portrait atlases and unit-frame shells. Existing matching cast trims and fill materials are referenced directly, so this adds 20 runtime PNGs. Public generation prompts and source hashes are in [creature-generation.json](../artwork/creature-generation.json). Originals, fitted sources and the review sheet are retained locally in `artwork/creatures/v1/`; the local `artwork/` link points into the separate source library.

Rebuild these assets with `python3 tools/build_creature_art.py --source-dir artwork/creatures/v1` (or a source directory linked inside the repository). It retains generated alpha, cleans low-alpha noise and reserved bar interiors, fits the established portrait openings, measures shell openings, and updates only creature catalog entries and inventory records. It leaves all existing runtime artwork unchanged. The new collection has offline validation but still needs live-client review.

NPC detection uses the public ID from Blizzard's [UnitCreatureType API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua). Legacy name-only results use exact English or client-localized names from [GetCreatureTypeInfo](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/CreatureInfoDocumentation.lua). Restricted values never become lookup keys. No reaction, health, power, name or zone is used to guess a creature type.
