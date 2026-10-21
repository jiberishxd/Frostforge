# Public-facing media

- `overview.jpg`: actual addon textures composed by `tools/render_readme_media.py`; five artwork types, with illustrative health/power fills. Not a game screenshot.
- `unit-frames.jpg`: the same tool renders Paladin, Mage, Shaman and Night Elf shells using their measured openings and existing fill textures. Not a game screenshot.
- `minimal-stone.jpg`: the same tool renders the current painted stone in two shells and three actual-size tinted fill samples. Not a game screenshot.
- `settings.jpg`: browser capture of `artwork/settings/?capture=1`, Artwork page, cropped to the settings panel. The page exports the real Lua settings layout and uses browser approximations for native panel textures/fonts.
- `profiles.jpg`: the same exported settings preview on the Profiles page, with illustrative Paladin/Hunter names. No real character data is used.
- `paladin-ingame.png`: player-supplied earlier Paladin/EllesmereUI test capture. It predates the plain-stone health update. Retained unedited.
- `logo.png`: the official Frostforge penguin logo, with blue ice inside a weathered metal medallion and small icy accents on its rim. The 1254 × 1254 PNG has a transparent exterior. Use this image for the README and public addon branding. Its source, generation prompt and transparency verification are retained in `LOGO-SOURCE.md`.
- `social-preview.jpg`: 1280 × 640 sharing image made from the existing Paladin/Shaman textures and text. Prepared for GitHub's social preview field; not a game screenshot.

The composition tool uses existing images only; it does not generate or replace addon artwork. The addon loads its exported PNG textures from `Frostforge/Media/`; these documentation images are not installed. All images have captions identifying previews versus game captures.

`blizzard-controls.jpg` shows the actual exported stock portrait/name controls and the stock-wide stone switch. Capture mode hides only the preview-page header so the full options panel fits in the browser viewport.

- `the-igloo.jpg`: the website tab with the official transparent logo and copyable website address; an offline rendering of the real settings objects.

## Seasonal showcases

`seasonal/` contains one 1800 × 2500 overview and seven 1600 × 1200 collection cards, on pure black with white uppercase titles. These replace the older seasonal contact sheet. Each uses final shipped textures, one round portrait atlas half, uniformly fitted unit frames and minimaps, and hubs restored to their declared 2172 × 724 display proportions before uniform scaling. No addon artwork is modified.

The gallery uses optimized JPEGs (about 3.9 MB total). Full-quality PNGs and the CurseForge upload bundle are generated under ignored `output/seasonal-gallery/`; neither they nor local fonts are included in addon packages.

Titles use [Cinzel Decorative Black](https://github.com/google/fonts/tree/main/ofl/cinzeldecorative) by Natanael Gama, available under the SIL Open Font License. Labels use Arial Bold. To reproduce the cards, download `CinzelDecorative-Black.ttf` and its `OFL.txt` into ignored `.tools/gallery-fonts/`, then run:

```sh
python3 tools/render_seasonal_gallery.py \
  --font .tools/gallery-fonts/CinzelDecorative-Black.ttf \
  --label-font "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
```

On other systems, pass the path to a locally installed bold label font. The tool verifies the display font checksum and records image sizes alongside the local PNG bundle.
