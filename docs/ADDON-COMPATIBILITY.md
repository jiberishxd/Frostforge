# Portrait addon setup

Build **0.6.0-compat.1** adds Player, Target and Focus surrounds for **Blinkii's Portraits**, **ElvUI** and **EllesmereUI**, plus main action-bar anchors for both UI suites. The implementation passes offline checks; fitting and secure behavior still need validation inside WoW.

Install the matching JiberishUI package, keep your preferred frame addon enabled, and fully restart WoW. Open `/jui` and select Player, Target or Focus. **Portrait addon → Automatic (Blinkii first)** follows Blinkii when its active portrait is visible, otherwise ElvUI, EllesmereUI or Blizzard. Set a specific provider per unit when multiple frame addons are active. An explicit choice waits for that provider and never silently switches to another. The Following line identifies the resolved anchor.

Enable portraits in the selected provider. Blinkii's **Circle** and EllesmereUI's detached **Circle** give the closest fit. JiberishUI follows the portrait center, dimensions, effective scale, visibility and parent alpha. It leaves the portrait, its border, buttons and addon settings under their original owner's control. Blinkii clickable/display switches, late frame creation and profile changes are rediscovered automatically.

The existing art has a round opening. Known Blinkii masks and Ellesmere detached masks are fitted inside that opening; angular/asymmetric masks can leave space between their edges and the round artwork. Unmasked ElvUI/Ellesmere rectangular or 3D portraits use a containing circle. Custom Blinkii masks use a conservative full-texture bound. Use width, height and artwork scale for additional visual adjustment. Health-bar overlay/inside portraits have no separate surround. Large decorative extras from Blinkii may extend beyond the portrait opening.

For addon portraits, width/height are relative to the fitted size, and X/Y preserve the adjustment from the original Blizzard defaults. Scale keeps the opening centered. Reset this component restores the automatic fit. Frame strata and texture layer remain configurable; defaults keep other controls above the artwork. Geometry and source changes wait until combat ends.

**Action hub → Action bar addon** selects Automatic, ElvUI, EllesmereUI or Blizzard. FRAME follows the main bar position; SCREEN retains the screen anchor while following its visibility and scale. Bar row count and layout remain manual fitting concerns. Both suites continue to use the shared Minimap anchor; select a circular minimap for the circular surround. JiberishUI does not change the map mask or bar layout.

```text
/jf set playerFrame portraitSource BLINKII
/jf set targetFrame portraitSource ELVUI
/jf set focusFrame portraitSource ELLESMERE
/jf set actionHub hubSource ELLESMERE
/jf set playerFrame portraitSource AUTO
```

These settings are included in existing JF2 exports. Source code revisions and measured mask hashes are recorded in [addon-sources.json](addon-sources.json). No third-party addon code or textures are shipped.
