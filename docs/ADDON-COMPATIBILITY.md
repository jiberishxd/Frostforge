# UI integrations and compatibility

Build **0.8.1** includes Player, Target and Focus portrait surrounds for **mMediaTag & Tools** alongside **Blinkii's Portraits**, **ElvUI** and **EllesmereUI**, plus main action-bar anchors for both UI suites. The implementation passes offline checks; fitting and secure behavior still need validation inside WoW.

Install the matching JiberishUI package, keep your preferred frame addon enabled, and fully restart WoW. Open `/jui` and select Player, Target or Focus. **Portrait provider → Automatic (Blinkii first)** follows Blinkii when its active portrait is visible, otherwise mMediaTag, ElvUI, EllesmereUI or Blizzard, in that order. Set a specific provider per unit when multiple frame addons are active. An explicit choice waits for that provider and never silently switches to another. The provider line identifies the resolved anchor; `/jui status` includes requested and resolved sources, portrait visibility, both toggles and bar status. Inactive or transparent portrait providers no longer block a later visible provider.

Enable portraits in the selected provider. Blinkii's **Circle** and EllesmereUI's detached **Circle** give the closest fit. JiberishUI follows the portrait center, dimensions, effective scale, visibility and parent alpha. It leaves the portrait, its border, buttons and addon settings under their original owner's control. Blinkii clickable/display switches, late frame creation and profile changes are rediscovered automatically.

For **mMediaTag & Tools**, enable its Player, Target and Focus portraits in ElvUI's mMediaTag options, then choose **mMediaTag & Tools** or Automatic in JiberishUI. **Circle** gives the closest fit. Both the current 4.x engine and older 3.x portrait module are recognized, including mirrored masks, resizing, zoom and profile changes. The current mMediaTag release is a Retail-only ElvUI plugin; the legacy adapter requires an upstream version that actually runs on your client. It does not make Retail mMediaTag run on Classic or Forever. Main action bars use the existing **ElvUI** source, and the minimap keeps the shared Minimap anchor.

External portraits normally use the round opening. Ellesmere’s Blizzard-style player mask uses the teardrop atlas half and its CircleMask uses the round half; its published portrait-side map determines mirroring. Known Blinkii, mMediaTag and Ellesmere detached masks are fitted inside that opening; angular/asymmetric masks can leave space between their edges and the round artwork. Unmasked ElvUI/Ellesmere rectangular or 3D portraits use a containing circle. Custom Blinkii and mMediaTag masks use a conservative full-texture bound. Use width, height and artwork scale for additional visual adjustment. Health-bar overlay/inside portraits have no separate surround. Large decorative extras from Blinkii or mMediaTag may extend beyond the portrait opening.

For addon portraits, width/height are relative to the fitted size, and X/Y preserve the adjustment from the original Blizzard defaults. Scale keeps the opening centered. Reset this component restores the automatic fit. Frame strata and texture layer remain configurable; Blizzard defaults keep other controls above the artwork. Ellesmere defaults follow its panel/portrait level so opaque panels do not bury the art. Explicit saved strata/level settings still win. Geometry and source changes wait until combat ends.

**Action hub → Action bar provider** selects Automatic, ElvUI, EllesmereUI or Blizzard. FRAME follows the main bar position; SCREEN retains the screen anchor while following its visibility and scale. Bar row count and layout remain manual fitting concerns. Both suites continue to use the shared Minimap anchor; select a circular minimap for the circular surround. JiberishUI does not change the map mask or bar layout.

The independent **Unit-frame art** toggle now supports **Blizzard and EllesmereUI** bars. Set **Unit-frame provider → EllesmereUI** (or Automatic) separately from Portrait provider, then enable either or both art toggles. For the complete Ellesmere shell, use horizontal bars with power attached below health and aligned to its edges. The thick divider is fitted inside the original stack height, with both bar sizes restored on disable. Above-health, detached, hidden or vertical power arrangements keep their geometry and receive fill textures only; `/jui status` explains the limitation. A portrait disabled or placed inside health in Ellesmere has no separate surround to decorate. ElvUI full-bar styling is not included.

```text
/jf set playerFrame portraitSource BLINKII
/jf set playerFrame portraitSource MMT
/jf set targetFrame portraitSource ELVUI
/jf set focusFrame portraitSource ELLESMERE
/jf set playerFrame unitFrameSource ELLESMERE
/jf set playerFrame unitFrameShown on
/jf set actionHub hubSource ELLESMERE
/jf set playerFrame portraitSource AUTO
```

These settings are included in existing JF2 exports. Source code revisions and measured mask hashes are recorded in [addon-sources.json](addon-sources.json). No third-party addon code or textures are shipped.

## Shared status-bar material (0.7.4)

EllesmereUI and ElvUI can select **JiberishUI Stone** through their existing LibSharedMedia texture menus. Choose it in the provider for any supported frame type, including frames beyond JiberishUI's own Player/Target/Focus shells. JiberishUI's default AUTO fill mode now respects Ellesmere choices; PROVIDER keeps native fills on any supported shell provider. JIBERISH explicitly restores the prior override behavior. Existing profiles with no fill setting inherit AUTO. No provider settings or third-party code are copied. See [settings setup](SETTINGS.md).

## Cast-bar borders (0.8.0)

Player, Target and Focus support optional minimal borders for Blizzard, EllesmereUI 9.2.9 and ElvUI v15.26 horizontal cast bars. Discovery uses their actual StatusBars; fills, colors, text, progress and native behavior stay with the provider. This does not extend ElvUI support to full unit-frame shells. [Setup, exact anchors and limitations](CAST-BARS.md). Offline checks cover both client paths; live validation remains pending.

Ellesmere Player cast discovery includes its **Resource Bars main cast bar** and the **Unit Frames mini cast bar**. A visible main bar wins; otherwise a visible mini bar can be used. With both idle, the main bar is prepared first. Target/Focus use Unit Frames cast bars. Source checks cover the Blizzard-style aura-layout template and drawing above its cast chrome; live validation is still required.

Stock portrait/name controls and stock-wide stone operate only on Blizzard regions. Ellesmere and ElvUI continue to choose their textures through SharedMedia. See [stock controls](BLIZZARD-CONTROLS.md).
