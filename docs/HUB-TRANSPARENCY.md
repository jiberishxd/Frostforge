# Hub transparency cleanup (0.8.1)

All 42 action hubs were inspected over a solid background. Twenty-four contained enclosed checkerboard, pale matte or colored spill that the earlier edge-connected background removal had missed. This includes the reported Human lion and Highmountain Tauren gaps.

The correction clears only reviewed background alpha. Source colors, ornaments, atlas dimensions, five-piece seams and vertical registration remain unchanged. Intentional patterns, including the Goblin checkered cloth, are retained. The other 18 hub textures remain byte-identical to the previous build.

`artwork/hubs/alpha-cleanup/manifest.json` records all 42 reviewed identities and the 24 corrections. Each binary mask has a hash, source-pixel hash, cleared-pixel count and previous runtime texture hash. `tools/clean_hub_alpha.py` validates those inputs before applying a mask. The original generated images remain unchanged.

`tests/test_hub_alpha.py` checks that cleanup changes only approved alpha pixels, preserves the source RGB and registration, removes the reported holes, protects selected colored metal edges, and produces identical PNG/TGA pixels. Three retained review sheets show all 42 complete runtime hub compositions over solid teal. Rebuild them with `python3 tools/render_readme_media.py --hub-review`.

Unchanged minimap generations retain their original hub inputs under `artwork/minimaps/reference-history/hubs-before-alpha-cleanup/`; their provenance does not claim the newer alpha-corrected files were used to generate them.

These are offline source and export checks. The updated hubs have not been validated in a live client.
