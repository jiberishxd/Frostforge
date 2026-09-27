# Contributing to Frostforge

Frostforge brings class, race and faction artwork to existing Warcraft frames. Useful contributions include reproducible bug reports, provider compatibility fixes, fitting corrections, documentation and clearly scoped artwork improvements.

For a substantial feature or visual redesign, open an issue describing the intended result before implementing it. Preserve the established artwork direction and shared fitting geometry when making corrections.

## Work locally

See [Development and local previews](docs/DEVELOPMENT.md) for package builds, dependencies and artwork tooling. Read [Architecture](docs/ARCHITECTURE.md) before changing rendering, frame discovery or saved settings.

Keep a pull request focused. Explain the problem, the resulting behavior and how you checked it. Include before/after images for visual changes and identify whether they are game captures or offline previews. Retain source references and generation records for artwork changes, and update matching manifests when an asset changes.

## Validate changes

Run the relevant Lua and artwork checks, then validate both client packages using the commands in the development guide. Check modified links and image paths for documentation changes. Preserve independent component toggles, provider ownership, saved settings and combat deferral.

Offline tests do not reproduce WoW's secure runtime. Clearly distinguish automated checks from any manual in-game tests and state which client/provider versions were used. The [manual checklist](docs/VALIDATION.md) describes the remaining runtime checks.

Do not bundle another addon's implementation or textures as part of an integration. Use public frame structure for attachment and retain the source references used to verify it. See [artwork credits](docs/ARTWORK-CREDITS.md) for the existing asset provenance.
