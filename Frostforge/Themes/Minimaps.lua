local _, J = ...
-- Data only; every identity shares one circular aperture.
J.MinimapCatalog = { entries = {} }
J.MinimapCatalog.entries.CLASS_WARRIOR = {label="Warrior",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_warrior"}
J.MinimapCatalog.entries.CLASS_PALADIN = {label="Paladin",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_paladin"}
J.MinimapCatalog.entries.CLASS_HUNTER = {label="Hunter",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_hunter"}
J.MinimapCatalog.entries.CLASS_ROGUE = {label="Rogue",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_rogue"}
J.MinimapCatalog.entries.CLASS_PRIEST = {label="Priest",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_priest"}
J.MinimapCatalog.entries.CLASS_DEATHKNIGHT = {label="Death Knight",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_deathknight"}
J.MinimapCatalog.entries.CLASS_SHAMAN = {label="Shaman",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_shaman"}
J.MinimapCatalog.entries.CLASS_MAGE = {label="Mage",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_mage"}
J.MinimapCatalog.entries.CLASS_WARLOCK = {label="Warlock",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_warlock"}
J.MinimapCatalog.entries.CLASS_MONK = {label="Monk",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_monk"}
J.MinimapCatalog.entries.CLASS_DRUID = {label="Druid",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_druid"}
J.MinimapCatalog.entries.CLASS_DEMONHUNTER = {label="Demon Hunter",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_demonhunter"}
J.MinimapCatalog.entries.CLASS_EVOKER = {label="Evoker",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_evoker"}
J.MinimapCatalog.entries.RACE_HUMAN = {label="Human",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_human"}
J.MinimapCatalog.entries.RACE_DWARF = {label="Dwarf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_dwarf"}
J.MinimapCatalog.entries.RACE_NIGHTELF = {label="Night Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_nightelf"}
J.MinimapCatalog.entries.RACE_GNOME = {label="Gnome",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_gnome"}
J.MinimapCatalog.entries.RACE_DRAENEI = {label="Draenei",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_draenei"}
J.MinimapCatalog.entries.RACE_WORGEN = {label="Worgen",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_worgen"}
J.MinimapCatalog.entries.RACE_ORC = {label="Orc",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_orc"}
J.MinimapCatalog.entries.RACE_SCOURGE = {label="Undead",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_scourge"}
J.MinimapCatalog.entries.RACE_TAUREN = {label="Tauren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_tauren"}
J.MinimapCatalog.entries.RACE_TROLL = {label="Troll",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_troll"}
J.MinimapCatalog.entries.RACE_BLOODELF = {label="Blood Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_bloodelf"}
J.MinimapCatalog.entries.RACE_GOBLIN = {label="Goblin",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_goblin"}
J.MinimapCatalog.entries.RACE_PANDAREN = {label="Pandaren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_pandaren"}
J.MinimapCatalog.entries.RACE_DRACTHYR = {label="Dracthyr",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_dracthyr"}
J.MinimapCatalog.entries.RACE_VOIDELF = {label="Void Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_voidelf"}
J.MinimapCatalog.entries.RACE_LIGHTFORGEDDRAENEI = {label="Lightforged Draenei",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_lightforgeddraenei"}
J.MinimapCatalog.entries.RACE_DARKIRONDWARF = {label="Dark Iron Dwarf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_darkirondwarf"}
J.MinimapCatalog.entries.RACE_KULTIRAN = {label="Kul Tiran",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_kultiran"}
J.MinimapCatalog.entries.RACE_MECHAGNOME = {label="Mechagnome",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_mechagnome"}
J.MinimapCatalog.entries.RACE_NIGHTBORNE = {label="Nightborne",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_nightborne"}
J.MinimapCatalog.entries.RACE_HIGHMOUNTAINTAUREN = {label="Highmountain Tauren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_highmountaintauren"}
J.MinimapCatalog.entries.RACE_MAGHARORC = {label="Mag'har Orc",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_magharorc"}
J.MinimapCatalog.entries.RACE_ZANDALARITROLL = {label="Zandalari Troll",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_zandalaritroll"}
J.MinimapCatalog.entries.RACE_VULPERA = {label="Vulpera",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_vulpera"}
J.MinimapCatalog.entries.RACE_EARTHENDWARF = {label="Earthen",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_earthendwarf"}
J.MinimapCatalog.entries.RACE_HARANIR = {label="Haranir",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_haranir"}
J.MinimapCatalog.entries.FACTION_ALLIANCE = {label="Alliance",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\faction_alliance"}
J.MinimapCatalog.entries.FACTION_HORDE = {label="Horde",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\faction_horde"}
J.MinimapCatalog.entries.FACTION_NEUTRAL = {label="Neutral",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\faction_neutral"}
