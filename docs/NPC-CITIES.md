# City NPC artwork

Build 0.7.3 reuses the existing race artwork for recognized NPC city affiliations. Player, Target and Focus use the same identity selection for portrait art and unit-frame art; the two visibility toggles remain independent. Automatic class, race and faction modes prefer a recognized NPC city. A fixed artwork choice always wins. Players retain their selected class/race/faction behavior.

| NPC affiliation | Existing artwork | Reputation ID |
| --- | --- | --- |
| Undercity | Undead | 68 |
| Stormwind | Human | 72 |
| Ironforge | Dwarf | 47 |
| Orgrimmar | Orc | 76 |
| Darnassus | Night Elf | 69 |
| Thunder Bluff | Tauren | 81 |
| Gnomeregan | Gnome | 54 |
| Darkspear Trolls | Troll | 530 |
| Silvermoon City | Blood Elf | 911 |
| Exodar | Draenei | 930 |
| Bilgewater Cartel | Goblin | 1133 |
| Gilneas | Worgen | 1134 |

## Identification and limits

The resolver requires a public creature GUID and an NPC that is not player-controlled. It reads data-only tooltip text with `C_TooltipInfo.GetUnit(unit, true)`, skipping the unit-name and typed quest/owner lines. An ordinary line must exactly match the city reputation name supplied by the client (or its English fallback). Modern `C_Reputation.GetFactionDataByID` and legacy `GetFactionInfoByID` are detected separately. No visible tooltip is created or changed, and no health or power values are inspected.

The client API shapes are documented in Blizzard's generated [tooltip API](https://github.com/Gethe/wow-ui-source/blob/70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua) and [reputation API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ReputationInfoDocumentation.lua). `Themes/NPCCities.lua` contains only the mapping data.

When an affiliation line is absent, a small public creature-ID fallback covers these guards, verified against their database records:

- Undercity Guardian: [Classic 5624](https://www.wowhead.com/classic/npc=5624/undercity-guardian), [Retail 36213](https://www.wowhead.com/npc=36213/undercity-guardian).
- [Stormwind City Guard 68](https://www.wowhead.com/npc=68/stormwind-city-guard).
- [Ironforge Guard 5595](https://www.wowhead.com/npc=5595/ironforge-guard).
- [Orgrimmar Grunt 3296](https://www.wowhead.com/mop-classic/npc=3296/orgrimmar-grunt).

This follows the NPC's affiliation, not the player's zone: visitors, critters, unrelated enemies and a remote focus do not inherit the city merely because the player stands there. Unrecognized NPCs retain the selected mode's previous fallback (Neutral in Automatic class). Missing or restricted identity data is not inferred. Pets, vehicles and controlled NPCs are excluded from city matching. No identity or tooltip text is logged or saved in profiles.

Tooltip results are cached per unit/GUID for at most half a second; a different public GUID refreshes immediately. Localized city names refresh at most every 30 seconds. Existing combat rules still apply to artwork and native fill changes. These paths have offline Retail/Forever coverage; actual NPC tooltips and renderer behavior still need user testing in game.
