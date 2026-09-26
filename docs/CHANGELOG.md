# Changelog

## 0.8.4 — Blizzard cast layers and independent text controls

- Fixed automatic Blizzard cast-border layering to clear the owning Player/Target/Focus frame and enabled JUI portrait/shell layers. Explicit strata and the level offset are together on **Cast bar**; status reports the resolved layer. Ellesmere and ElvUI retain their provider-based layering.
- Fixed repeated Blizzard text offsets accumulating after rounded position readback or partial native anchor updates. X/Y settings now use a stable original position and retain the actual applied position separately.
- Added independent **Name**, **Health**, **Power**, **Level**, **Cast name** and **Cast time** controls on **Blizzard**, each with X/Y, size, alignment, outline, enable and reset. Existing profile name settings are preserved; new groups start disabled. Native text visibility, content and values stay with Blizzard.
- All presentation edits and restoration wait until combat ends. Artwork files are unchanged. Validation is offline; no WoW interaction was performed.

## 0.8.3 — Original unit-frame artwork over the bars

- Removed duplicated inset border strips and the Inset edge depth control. Old saved depths have no visual effect.
- Draw the complete original shell, including its curved inner contours, above health and power. Default fitting slightly overlaps both bar sides; width adjustments can bring the real artwork inward.
- Added independent unit-frame horizontal and vertical offsets alongside width/height. Reset returns to 100%/100% and zero offsets.
- Retained the source-proportional divider, protected center footer ornament, provider fill ownership and combat deferral.

All artwork image files are unchanged. Validation is offline; live-client testing remains pending.

## 0.8.2 — Sculpted hubs and frame presentation

- Restyled all 42 class, race and faction action hubs to match the approved unit-frame materials, colors and dimensional finish. Hub fitting and button space are unchanged.
- Removed the added black inset shadow strips around health and power. Inner edges now sample the painted bevel beyond the dark opening outline.
- Kept the lower center ornament, including the Night Elf moon, proportional when provider bars change width.
- Added **Hide full Blizzard portrait** under each unit's **Blizzard** page. With unit-frame artwork enabled, it hides the stock face, rim, shared stock border and level badge. Name position, size, alignment and outline remain independently adjustable.
- Moved **Cast-border strata** onto the **Cast bar** page. Automatic layering clears native decorative child frames; **Advanced** provides a separate **Cast-border level above bar** control.

Portrait and unit-frame image assets are unchanged. No game interaction was used for testing; live-client verification remains pending.
