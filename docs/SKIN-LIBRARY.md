# Border library

Historical design reference only. These presets were retired before the current portrait, hub, minimap and unit-frame collections. Their unused runtime textures have been removed from `JiberishUI/Media`; source artwork and this record remain for design history. See [the active artwork inventory](ARTWORK.md). The old library builders are not part of the current build instructions.

52 selectable presets across 15 material families. Families share texture files; palettes and default ornament/thickness settings distinguish variants.

The original four Warcraft III IDs remain valid. Other choices are original generated materials or explicitly named palette variants of shared materials. These are cosmetic choices on either client, independent of which races/classes that client offers.

Roster checked against Blizzard’s [playable races](https://worldofwarcraft.blizzard.com/en-gb/game/races) and [classes](https://worldofwarcraft.blizzard.com/en-gb/game/classes).

## Races

| Style | Material family | Identity |
|---|---|---|
| Human | human | Human |
| Orc | orc | Orc |
| Night Elf | nightelf | Night Elf |
| Undead | undead | Undead |
| Dwarf — Ironforge | dwarven_forge | Dwarf |
| Gnome — Clockwork | clockwork | Gnome |
| Draenei — Exodar | arcane_crystal | Draenei |
| Worgen — Gilneas | shadow_steel | Worgen |
| Pandaren — Jade Temple | jade_bamboo | Pandaren |
| Dracthyr — Dragonflight | dragon_scale | Dracthyr |
| Tauren — Earthmother | tribal_totem | Tauren |
| Troll — Darkspear | tribal_totem | Troll |
| Blood Elf — Sunspire | sacred_gold | Blood Elf |
| Goblin — Bilgewater | clockwork | Goblin |
| Void Elf — Rift | arcane_crystal | Void Elf |
| Lightforged Draenei | sacred_gold | Lightforged Draenei |
| Dark Iron Dwarf | dwarven_forge | Dark Iron Dwarf |
| Kul Tiran — Admiralty | tribal_totem | Kul Tiran |
| Mechagnome — Workshop | clockwork | Mechagnome |
| Earthen — Titan Forge | dwarven_forge | Earthen |
| Haranir — Ancient Roots | nightelf | Haranir |
| Nightborne — Suramar | moonstone | Nightborne |
| Highmountain Tauren | tribal_totem | Highmountain Tauren |
| Mag’har Orc | orc | Mag'har Orc |
| Zandalari Troll | sacred_gold | Zandalari Troll |
| Vulpera — Caravan | tribal_totem | Vulpera |
| Night Elf — Moonwell | moonstone | Night Elf |
| Night Elf — Ancient Grove | nightelf | Night Elf |
| Night Elf — Sentinel | moonstone | Night Elf |

## Classes

| Style | Material family | Identity |
|---|---|---|
| Warrior — Battleplate | dwarven_forge | WARRIOR |
| Paladin — Golden Oath | sacred_gold | PALADIN |
| Hunter — Wildstalker | tribal_totem | HUNTER |
| Rogue — Shadowsteel | shadow_steel | ROGUE |
| Priest — Sanctum | sacred_gold | PRIEST |
| Death Knight — Runeblade | shadow_steel | DEATHKNIGHT |
| Shaman — Storm Totem | tribal_totem | SHAMAN |
| Mage — Arcane Crystal | arcane_crystal | MAGE |
| Monk — Jade Serpent | jade_bamboo | MONK |
| Druid — Dreamgrove | nightelf | DRUID |
| Demon Hunter — Illidari | fel_obsidian | DEMONHUNTER |
| Warlock — Fel Covenant | fel_obsidian | WARLOCK |
| Evoker — Aspect Scales | dragon_scale | EVOKER |

## Factions

| Style | Material family | Identity |
|---|---|---|
| Alliance — Royal Gold | sacred_gold | Alliance |
| Horde — War Iron | orc | Horde |

## Standard

| Style | Material family | Identity |
|---|---|---|
| Black Stone | black_basalt | Neutral |
| Slate | black_basalt | Neutral |
| Obsidian | black_basalt | Neutral |
| Silver Steel | shadow_steel | Neutral |
| Aged Bronze | clockwork | Neutral |
| Ivory Gold | sacred_gold | Neutral |
| Forest Wood | orc | Neutral |
| Frost Stone | moonstone | Neutral |

## Artwork

Original masters: `artwork/masters/`. Exact built-in image_gen prompts: `artwork/prompts.json`. Runtime crops, alpha bounds, hashes, and transforms: `docs/assets.json`. Preview sheets are synthetic fit examples, not game screenshots.
