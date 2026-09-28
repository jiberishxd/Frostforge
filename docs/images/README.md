# Public-facing media

- `overview.jpg`: actual addon textures composed by `tools/render_readme_media.py`; five artwork types, with illustrative health/power fills. Not a game screenshot.
- `unit-frames.jpg`: the same tool renders Paladin, Mage, Shaman and Night Elf shells using their measured openings and existing fill textures. Not a game screenshot.
- `minimal-stone.jpg`: the same tool renders the current painted stone in two shells and three actual-size tinted fill samples. Not a game screenshot.
- `settings.jpg`: browser capture of `artwork/settings/?capture=1`, Artwork page, cropped to the settings panel. The page exports the real Lua settings layout and uses browser approximations for native panel textures/fonts.
- `profiles.jpg`: the same exported settings preview on the Profiles page, with illustrative Paladin/Hunter names. No real character data is used.
- `paladin-ingame.png`: player-supplied earlier Paladin/EllesmereUI test capture. It predates the plain-stone health update. Retained unedited.
- `logo.png`: the official Frostforge penguin logo, with blue ice inside a weathered metal medallion and small icy accents on its rim. The 1254 × 1254 PNG has a transparent exterior. Use this image for the README and public addon branding. Its source, generation prompt and transparency verification are retained in `LOGO-SOURCE.md`.
- `social-preview.jpg`: 1280 × 640 sharing image made from the existing Paladin/Shaman textures and text. Prepared for GitHub's social preview field; not a game screenshot.

The composition tool uses existing images only; it does not generate or replace addon artwork. The game loads exported TGA textures; it does not load these PNG/JPEG documentation files. All images have captions identifying previews versus game captures.

`blizzard-controls.jpg` shows the actual exported stock portrait/name controls and the stock-wide stone switch. Capture mode hides only the preview-page header so the full options panel fits in the browser viewport.

- `the-igloo.jpg`: the website tab with the official transparent logo and copyable website address; an offline rendering of the real settings objects.
