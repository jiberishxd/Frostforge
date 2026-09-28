# Maintenance

Player support and project questions: [The Igloo Discord](https://discord.com/servers/igloo-460933747731070996).

## Build and check

Run from the repository root with Lua 5.1 and Python 3; artwork tests need `tools/requirements-artwork.txt`.

```sh
lua5.1 tests/run.lua
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/package.py
python3 tools/check.py --packages
```

Upload the appropriate client ZIP from `dist/`. Each contains one `Frostforge/` folder: active Lua, the TOC, all 298 runtime textures, an install readme and credits. The [CI workflow](../../.github/workflows/validate.yml) also checks the cast preview.

Preserve saved settings, combat deferral and provider ownership. Decorations must not capture input or change gameplay. Keep changes scoped; report automated checks separately from [in-game checks](VALIDATION.md).

## Artwork and records

[Current source records](ARTWORK.md) describe the retained art and manifests. Active builders are in `tools/`; run only the builder for the asset being changed, then check its hashes and fitting. Retired material-library art and its unused tools are recoverable from Git history.

The [0.9.7 benchmark samples](performance-0.9.7.csv) measure 1,000 offline mock updates, not live CPU or memory. Reproduce with `lua5.1 tools/benchmark.lua Frostforge 1000`. Earlier architecture, validation and performance notes remain in [Git history](https://github.com/jiberishxd/Frostforge/tree/07b6e86cf854de745e8b6bd8b62b656d3a0c91c2/docs/maintainer).

For distribution pages, retain the [artwork notice](../../Frostforge/CREDITS.md) and link support to Discord. Packaging does not establish a new license or live-client compatibility.
