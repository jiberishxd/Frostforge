# Commands and advanced fitting

Start with `/jui` for the visual settings window. These commands offer the same appearance controls for advanced use.

`/jui`, `/jiberishui` and `/jf` open the movable options window. Commands:

| Command | Effect |
|---|---|
| `/jf debug [on\|off]` | Show decorative bounds and geometry/texture information |
| `/jf status` | Print client, settings and component diagnostics |
| `/jf reloadtheme` | Reapply current in-memory settings |
| `/jf set <component> <property> <value>` | Adjust one decorative component |
| `/jf show <component>` / `/jf hide <component>` | Show or hide artwork |
| `/jf reset [component]` | Reset one component, or all when omitted |
| `/jf export` / `/jf import <backup>` | Export/import validated appearance data |

Components: `playerFrame`, `targetFrame`, `focusFrame`, `minimap`, `actionHub`.

Properties: width/height (16–2048), X/Y (−2048–2048), scale (0.25–3), opacity, shown, anchor (FRAME/SCREEN), anchor points, strata, frame level (0–128), and texture layer. Minimap additionally exposes `minimapMode` (CLASS/RACE/FACTION/FIXED) and a catalog `minimap` ID. Action hub additionally exposes `hubMode` (CLASS/RACE/FACTION/FIXED) and a catalog `hub` ID. Portrait components additionally expose `unitFrameShown` (on/off; legacy `unitStyle` commands are still accepted), `unitFrameWidth`/`unitFrameHeight` (75–150%), `unitFrameInset` (0–6, default 3), `unitFrameFill` (AUTO/PROVIDER/JIBERISH), `portraitMode` (CLASS/RACE/FACTION/FIXED), a catalog `portrait` ID, and `portraitSource` (AUTO/BLIZZARD/BLINKII/MMT/ELVUI/ELLESMERE), and `unitFrameSource` (AUTO/BLIZZARD/ELLESMERE). Cast-border properties are `castBarShown`, `castBarSource` (AUTO/BLIZZARD/ELLESMERE/ELVUI), `castBarArt` (MATCH or a catalog ID), `castBarWeight` (0.5–2) `castBarPadding` (0–8), and `castBarWidth`/`castBarHeight` (50–150%, default 100). The action hub also supports `hubSource` (AUTO/BLIZZARD/ELVUI/ELLESMERE).

```text
/jf set playerFrame unitFrameShown on
/jf set targetFrame portraitMode CLASS
/jf set focusFrame portraitMode RACE
/jf set playerFrame portrait CLASS_PALADIN
/jf set playerFrame portraitMode FIXED
/jf set actionHub hubMode RACE
/jf set actionHub hub RACE_SCOURGE
/jf set actionHub hubMode FIXED
/jf set minimap minimapMode RACE
/jf set minimap minimap CLASS_WARRIOR
/jf set minimap minimapMode FIXED
```

Blizzard defaults use Background strata and level 0. Ellesmere defaults follow its panel/portrait layer so opaque panels do not bury the artwork; explicit saved strata/level choices take priority. Custom dimensions/offsets/strata can change the fit. Use Reset this component to return to the fitted defaults.


## Stock appearance and independent strata (0.8.1)

```text
/jui set playerFrame blizzardPortraitHidden on
/jui set targetFrame blizzardNameEnabled on
/jui set targetFrame blizzardNameX 20
/jui set targetFrame blizzardNameY 5
/jui set targetFrame blizzardNameSize 16
/jui set targetFrame blizzardNameAlign CENTER
/jui set targetFrame blizzardNameOutline OUTLINE
/jui set playerFrame blizzardStone on
/jui set playerFrame strata HIGH
/jui set playerFrame unitFrameStrata MEDIUM
/jui set playerFrame castBarStrata HIGH
```

`blizzardStone` is a stock-wide option stored on Player; other new appearance settings are per unit. `AUTO` returns shell/cast strata to automatic fitting. See [stock controls](BLIZZARD-CONTROLS.md).
