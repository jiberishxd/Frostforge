# Official Jiberish's Frostforge logo

`logo.png` is the official Frostforge penguin logo, selected by the project owner on September 25, 2026. It replaces the gold compass emblem in the project README. The full-resolution square PNG is the canonical public branding asset.

The design uses the owner-supplied Warcraft penguin reference, preserving its long golden beak, cyan eye and distinctive headpiece. Blue ice fills the weathered metal medallion, with small ice accents attached around its rim. The design was created with the built-in image generation tool.

The Warcraft character reference and underlying game designs belong to their respective owners; see [artwork credits](../ARTWORK-CREDITS.md). The canonical PNG is used in documentation; `tools/build_branding.py` exports a 512 × 512 RGBA TGA for the in-game header, The Igloo tab, and AddOns icon. The addon was named **Jiberish's Frostforge** on September 26, 2026.

## Transparent export

The generated artwork was converted locally to a transparent PNG by removing the neutral checkerboard connected to the outside of the emblem. The penguin, metal frame, blue ice inside the circle, and attached icy accents were retained. A subpixel edge transition smooths the cutout; detached neutral checkerboard specks were removed.

The final PNG is 1254 × 1254, RGBA, with verified real transparency outside the emblem. All original RGB values are unchanged. The opaque interior remains intact. The export was inspected over both light and dark backgrounds and at icon size.

Source SHA-256: `99a1af8bd4d3ee96f8215a08dac52838967ae8aaf8e078a429d5eb7a197b63df`

Logo SHA-256: `03959cf7a2826487eda1d1c268639e062787f3adbec9f7084b8b558f16dd2da7`

## Generation prompt

Edit this penguin medallion logo to produce a finished transparent-background PNG cutout. Keep the reference's penguin exactly recognizable: same long golden hooked beak pointing left, cyan eye, angular olive bronze headpiece and hanging strips, dark feathers and pale chest; preserve the gritty hand-painted World of Warcraft fantasy style.
The user clarifies the desired layout: blue ice INSIDE the metal circle behind the penguin; SOME icy elements attached around the metal circle; TRANSPARENT ONLY OUTSIDE the entire emblem.
Keep a rich cobalt and midnight blue cracked glacial-ice background confined inside the circular medallion, visible behind the penguin. Keep the battered dark steel circular rim with its faceted metal ornaments. Reduce the excessive icicles from the reference: add only 4 to 6 small clusters of frosted ice shards or short icicles attached to the rim, leaving most of the worn steel exposed. Keep the penguin mostly free of ice. Remove all scenery and texture outside the medallion and attached ice, and make that exterior genuinely transparent. No painted checkerboard, no white background, no black background. Use a real transparent alpha channel in the exported PNG, rather than illustrating transparency.
Fit the COMPLETE emblem including all projecting metal points and ice clusters within the square canvas with about 7 percent transparent padding, so nothing touches or clips the edges. No text, no watermark, no added compass. One finished square logo.
