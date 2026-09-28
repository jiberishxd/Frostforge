local _, J = ...
-- Data only. Individual hand-painted portrait textures share the same fit template.
J.PortraitCatalog = { entries = {}, classes = {}, races = {}, factions = {} }
local C = J.PortraitCatalog
C.entries.CLASS_WARRIOR = {label="Warrior",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_warrior"}
C.classes["WARRIOR"] = "CLASS_WARRIOR"
C.entries.CLASS_PALADIN = {label="Paladin",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_paladin"}
C.classes["PALADIN"] = "CLASS_PALADIN"
C.entries.CLASS_HUNTER = {label="Hunter",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_hunter"}
C.classes["HUNTER"] = "CLASS_HUNTER"
C.entries.CLASS_ROGUE = {label="Rogue",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_rogue"}
C.classes["ROGUE"] = "CLASS_ROGUE"
C.entries.CLASS_PRIEST = {label="Priest",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_priest"}
C.classes["PRIEST"] = "CLASS_PRIEST"
C.entries.CLASS_DEATHKNIGHT = {label="Death Knight",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_deathknight"}
C.classes["DEATHKNIGHT"] = "CLASS_DEATHKNIGHT"
C.entries.CLASS_SHAMAN = {label="Shaman",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_shaman"}
C.classes["SHAMAN"] = "CLASS_SHAMAN"
C.entries.CLASS_MAGE = {label="Mage",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_mage"}
C.classes["MAGE"] = "CLASS_MAGE"
C.entries.CLASS_WARLOCK = {label="Warlock",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_warlock"}
C.classes["WARLOCK"] = "CLASS_WARLOCK"
C.entries.CLASS_MONK = {label="Monk",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_monk"}
C.classes["MONK"] = "CLASS_MONK"
C.entries.CLASS_DRUID = {label="Druid",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_druid"}
C.classes["DRUID"] = "CLASS_DRUID"
C.entries.CLASS_DEMONHUNTER = {label="Demon Hunter",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_demonhunter"}
C.classes["DEMONHUNTER"] = "CLASS_DEMONHUNTER"
C.entries.CLASS_EVOKER = {label="Evoker",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\class_evoker"}
C.classes["EVOKER"] = "CLASS_EVOKER"
C.entries.RACE_HUMAN = {label="Human",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_human"}
C.races["Human"] = "RACE_HUMAN"
C.entries.RACE_DWARF = {label="Dwarf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_dwarf"}
C.races["Dwarf"] = "RACE_DWARF"
C.entries.RACE_NIGHTELF = {label="Night Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_nightelf"}
C.races["NightElf"] = "RACE_NIGHTELF"
C.entries.RACE_GNOME = {label="Gnome",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_gnome"}
C.races["Gnome"] = "RACE_GNOME"
C.entries.RACE_DRAENEI = {label="Draenei",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_draenei"}
C.races["Draenei"] = "RACE_DRAENEI"
C.entries.RACE_WORGEN = {label="Worgen",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_worgen"}
C.races["Worgen"] = "RACE_WORGEN"
C.entries.RACE_ORC = {label="Orc",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_orc"}
C.races["Orc"] = "RACE_ORC"
C.entries.RACE_SCOURGE = {label="Undead",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_scourge"}
C.races["Scourge"] = "RACE_SCOURGE"
C.entries.RACE_TAUREN = {label="Tauren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_tauren"}
C.races["Tauren"] = "RACE_TAUREN"
C.entries.RACE_TROLL = {label="Troll",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_troll"}
C.races["Troll"] = "RACE_TROLL"
C.entries.RACE_BLOODELF = {label="Blood Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_bloodelf"}
C.races["BloodElf"] = "RACE_BLOODELF"
C.entries.RACE_GOBLIN = {label="Goblin",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_goblin"}
C.races["Goblin"] = "RACE_GOBLIN"
C.entries.RACE_PANDAREN = {label="Pandaren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_pandaren"}
C.races["Pandaren"] = "RACE_PANDAREN"
C.entries.RACE_DRACTHYR = {label="Dracthyr",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_dracthyr"}
C.races["Dracthyr"] = "RACE_DRACTHYR"
C.entries.RACE_VOIDELF = {label="Void Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_voidelf"}
C.races["VoidElf"] = "RACE_VOIDELF"
C.entries.RACE_LIGHTFORGEDDRAENEI = {label="Lightforged Draenei",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_lightforgeddraenei"}
C.races["LightforgedDraenei"] = "RACE_LIGHTFORGEDDRAENEI"
C.entries.RACE_DARKIRONDWARF = {label="Dark Iron Dwarf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_darkirondwarf"}
C.races["DarkIronDwarf"] = "RACE_DARKIRONDWARF"
C.entries.RACE_KULTIRAN = {label="Kul Tiran",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_kultiran"}
C.races["KulTiran"] = "RACE_KULTIRAN"
C.entries.RACE_MECHAGNOME = {label="Mechagnome",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_mechagnome"}
C.races["Mechagnome"] = "RACE_MECHAGNOME"
C.entries.RACE_NIGHTBORNE = {label="Nightborne",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_nightborne"}
C.races["Nightborne"] = "RACE_NIGHTBORNE"
C.entries.RACE_HIGHMOUNTAINTAUREN = {label="Highmountain Tauren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_highmountaintauren"}
C.races["HighmountainTauren"] = "RACE_HIGHMOUNTAINTAUREN"
C.entries.RACE_MAGHARORC = {label="Mag'har Orc",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_magharorc"}
C.races["MagharOrc"] = "RACE_MAGHARORC"
C.entries.RACE_ZANDALARITROLL = {label="Zandalari Troll",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_zandalaritroll"}
C.races["ZandalariTroll"] = "RACE_ZANDALARITROLL"
C.entries.RACE_VULPERA = {label="Vulpera",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_vulpera"}
C.races["Vulpera"] = "RACE_VULPERA"
C.entries.RACE_EARTHENDWARF = {label="Earthen",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_earthendwarf"}
C.races["EarthenDwarf"] = "RACE_EARTHENDWARF"
C.entries.RACE_HARANIR = {label="Haranir",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\race_haranir"}
C.races["Haranir"] = "RACE_HARANIR"
C.entries.FACTION_ALLIANCE = {label="Alliance",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\faction_alliance"}
C.factions["Alliance"] = "FACTION_ALLIANCE"
C.entries.FACTION_HORDE = {label="Horde",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\faction_horde"}
C.factions["Horde"] = "FACTION_HORDE"
C.entries.FACTION_NEUTRAL = {label="Neutral",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Portraits\\faction_neutral"}
C.factions["Neutral"] = "FACTION_NEUTRAL"
C.races.Undead = C.races.Scourge
C.races.Earthen = C.races.EarthenDwarf
C.races.Maghar = C.races.MagharOrc
