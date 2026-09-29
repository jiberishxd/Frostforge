# Maintenance

Player support and project questions: [The Igloo Discord](https://discord.com/servers/igloo-460933747731070996).

## Build and check

Run from the repository root with Lua 5.1 and Python 3; image validation needs `tools/requirements-artwork.txt`.

```sh
lua5.1 tests/run.lua
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/package.py
python3 tools/check.py --packages
```

Upload the appropriate client ZIP from `dist/`. Each contains one `Frostforge/` folder: active Lua, the TOC, all 298 runtime textures, an install readme and credits. The [CI workflow](../../.github/workflows/validate.yml) also checks the cast preview.

Preserve saved settings, combat deferral and provider ownership. Decorations must not capture input or change gameplay. Keep changes scoped; report automated checks separately from [in-game checks](VALIDATION.md).

For missing party borders, a player can run `/jf partydebug` while grouped and share the output. It reports cached attachments and current visibility checks without changing frames, printing character names or exposing restricted values.

## Artwork and records

[Current source records](ARTWORK.md) describe the retained art and manifests. Active builders are in `tools/`; run only the builder for the asset being changed, then check its hashes and fitting. Full source artwork and its original history are retained in the separate artwork library and migration backup, not in addon Git history. See the artwork guide for source-builder and optional audit instructions.

The [0.9.7 benchmark samples](performance-0.9.7.csv) measure 1,000 offline mock updates, not live CPU or memory. Reproduce with `lua5.1 tools/benchmark.lua Frostforge 1000`. Earlier architecture, validation and performance notes remain in code history; the migration backup also preserves the original commit IDs.

For distribution pages, retain the [artwork notice](../../Frostforge/CREDITS.md) and link support to Discord. Packaging does not establish a new license or live-client compatibility.

## CurseForge updates

One-time setup in GitHub **Settings → Secrets and variables → Actions**:

- Secret `CF_API_TOKEN`: your [CurseForge upload token](https://authors.curseforge.com/account/api-tokens). Keep it out of chat and source files.
- Variable `CF_PROJECT_ID`: the numeric ID from the CurseForge author dashboard, not the project URL.
- Variable `CF_CLIENTS`: `Retail`, `Forever`, or `Retail,Forever`.

For each update, update the version in `Frostforge.toc` and `Core/Core.lua`, then publish a GitHub release from that commit with a matching tag (for example `v1.0.0`) and release notes. A GitHub prerelease uploads as **Beta**; a normal release uploads as **Release**. The workflow runs all checks, builds both ZIPs and uploads only the selected clients with exact game-version labels. Keep `CF_CLIENTS` set to `Retail,Forever` to publish a separate file for each client. CurseForge moderation still applies. Ordinary commits and tags without a published release do not upload.

**Actions → Publish to CurseForge → Run workflow** is a build-only test requiring no credentials. Download its `frostforge-packages` artifact and extract the outer artifact ZIP to access the individual player ZIPs. Upload those intact for a first manual submission.

If an upload fails or times out, inspect CurseForge and the workflow's upload receipts before retrying. A confirmed file may already exist; retry only missing clients via `CF_CLIENTS`, then restore the normal selection. [Upload API reference](https://support.curseforge.com/support/solutions/articles/9000197321).
