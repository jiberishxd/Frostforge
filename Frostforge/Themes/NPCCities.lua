local _, J = ...
-- Reputation IDs localize affiliation labels via the client. Existing artwork
-- is shared by portrait and full-shell selection; no new geometry or assets.
J.NPCCities = {
    {factionID=68,name="Undercity",artwork="RACE_SCOURGE"},
    {factionID=72,name="Stormwind",artwork="RACE_HUMAN"},
    {factionID=47,name="Ironforge",artwork="RACE_DWARF"},
    {factionID=76,name="Orgrimmar",artwork="RACE_ORC"},
    {factionID=69,name="Darnassus",artwork="RACE_NIGHTELF"},
    {factionID=81,name="Thunder Bluff",artwork="RACE_TAUREN"},
    {factionID=54,name="Gnomeregan",artwork="RACE_GNOME"},
    {factionID=530,name="Darkspear Trolls",artwork="RACE_TROLL"},
    {factionID=911,name="Silvermoon City",artwork="RACE_BLOODELF"},
    {factionID=930,name="Exodar",artwork="RACE_DRAENEI"},
    {factionID=1133,name="Bilgewater Cartel",artwork="RACE_GOBLIN"},
    {factionID=1134,name="Gilneas",artwork="RACE_WORGEN"},
}
-- Public creature-ID fallback for the core city guards when the client omits
-- the affiliation line. Source records are linked in docs/NPC-CITIES.md.
J.NPCCityGuards = {
    [5624]="RACE_SCOURGE", -- Undercity Guardian (Classic)
    [36213]="RACE_SCOURGE", -- Undercity Guardian (Retail)
    [68]="RACE_HUMAN", -- Stormwind City Guard
    [5595]="RACE_DWARF", -- Ironforge Guard
    [3296]="RACE_ORC", -- Orgrimmar Grunt
}
