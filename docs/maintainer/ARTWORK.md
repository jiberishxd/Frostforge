# Artwork sources

The addon ships 346 lossless PNG textures in `Frostforge/Media/`. Public records include hashes of the PNG files and their uncompressed TGA pixel equivalents. Existing approved textures are retained without re-encoding. The installed [credits](../../Frostforge/CREDITS.md) describe attribution and the AI-assisted artwork process.

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

Back up the separate art library independently. Git ignores the entire local `artwork` path and `output/` preview directory, so source edits, superseded images and preview bundles there are not saved by addon commits. Only final runtime textures and current documentation images belong in the repository. The release checks reject unused or missing addon media and verify every packaged file.

## Creature collection

Ten creature types have dedicated portrait atlases and unit-frame shells. Existing matching cast trims and fill materials are referenced directly, so this adds 20 runtime PNGs. Public generation prompts and source hashes are in [creature-generation.json](../artwork/creature-generation.json). Originals, fitted sources and the review sheet are retained locally in `artwork/creatures/v1/`; the local `artwork/` link points into the separate source library.

Rebuild these assets with `python3 tools/build_creature_art.py --source-dir artwork/creatures/v1` (or a source directory linked inside the repository). It retains generated alpha, cleans low-alpha noise and reserved bar interiors, fits the established portrait openings, measures shell openings, and updates only creature catalog entries and inventory records. It leaves all existing runtime artwork unchanged. The new collection has offline validation but still needs live-client review.

NPC detection uses the public ID from Blizzard's [UnitCreatureType API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua). Legacy name-only results use exact English or client-localized names from [GetCreatureTypeInfo](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/CreatureInfoDocumentation.lua). Restricted values never become lookup keys. No reaction, health, power, name or zone is used to guess a creature type.

## Seasonal collections

Seven seasonal options add 28 runtime textures across portraits, unit-frame shells, action hubs and minimaps. The initial four collections retain their full-resolution originals and fitting outputs in `artwork/seasonal/v1/`; public prompts, source hashes and reference roles are in [seasonal-generation.json](../artwork/seasonal-generation.json). The first event previews remain archived in `artwork/seasonal/warcraft-events-v1/`, with historical [generation records](../artwork/warcraft-events-generation.json). Current event sources use `artwork/seasonal/warcraft-events-v4/`: the compact Hallow’s End unit frame and eleven retained event paintings. The Horseman hood, armor and sword and Wickerman straw are intertwined with the frame corners. The approved hub remains unchanged. Earlier event art remains in `warcraft-events-v1/`, `warcraft-events-v2/` and `warcraft-events-v3/`; [revision provenance](../artwork/warcraft-events-revision.json) records the selected sources, prompts and references. Winter Veil retains `SEASONAL_WINTER_VEIL` for the corrected Alliance dwarf set so earlier preview selections keep working; Horde uses `SEASONAL_WINTER_VEIL_HORDE`.

Run `python3 tools/build_seasonal_art.py` to rebuild only seasonal entries and assets with the shared fitting helpers. Original generated alpha is preserved; functional openings and tiny alpha noise are cleaned during fitting. Portraits use the existing dual atlas; hubs use the five-piece registration; minimaps retain the shared circular aperture. Event fitting uses uniform scaling for characters: only the two connecting hub rails stretch, and circular openings trim inward rim pixels without warping faces. Reviewed rail landmarks are retained beside the source art. `tests/test_event_art_fit.py` checks that circular character markers stay round through fitting and texture encoding. Cast trims and bar fills reference existing matching themes. Regenerate the cast preview and run runtime/media/package checks afterward. Live-client review remains required.
