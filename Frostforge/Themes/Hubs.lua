local _, J = ...
-- Data only; all variants use the same five-piece fitting template.
J.HubCatalog = { entries = {} }
J.HubCatalog.entries.CLASS_WARRIOR = {label="Warrior",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_warrior.png"}
J.HubCatalog.entries.CLASS_PALADIN = {label="Paladin",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_paladin.png"}
J.HubCatalog.entries.CLASS_HUNTER = {label="Hunter",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_hunter.png"}
J.HubCatalog.entries.CLASS_ROGUE = {label="Rogue",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_rogue.png"}
J.HubCatalog.entries.CLASS_PRIEST = {label="Priest",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_priest.png"}
J.HubCatalog.entries.CLASS_DEATHKNIGHT = {label="Death Knight",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_deathknight.png"}
J.HubCatalog.entries.CLASS_SHAMAN = {label="Shaman",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_shaman.png"}
J.HubCatalog.entries.CLASS_MAGE = {label="Mage",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_mage.png"}
J.HubCatalog.entries.CLASS_WARLOCK = {label="Warlock",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_warlock.png"}
J.HubCatalog.entries.CLASS_MONK = {label="Monk",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_monk.png"}
J.HubCatalog.entries.CLASS_DRUID = {label="Druid",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_druid.png"}
J.HubCatalog.entries.CLASS_DEMONHUNTER = {label="Demon Hunter",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_demonhunter.png"}
J.HubCatalog.entries.CLASS_EVOKER = {label="Evoker",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_evoker.png"}
J.HubCatalog.entries.RACE_HUMAN = {label="Human",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_human.png"}
J.HubCatalog.entries.RACE_DWARF = {label="Dwarf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_dwarf.png"}
J.HubCatalog.entries.RACE_NIGHTELF = {label="Night Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_nightelf.png"}
J.HubCatalog.entries.RACE_GNOME = {label="Gnome",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_gnome.png"}
J.HubCatalog.entries.RACE_DRAENEI = {label="Draenei",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_draenei.png"}
J.HubCatalog.entries.RACE_WORGEN = {label="Worgen",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_worgen.png"}
J.HubCatalog.entries.RACE_ORC = {label="Orc",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_orc.png"}
J.HubCatalog.entries.RACE_SCOURGE = {label="Undead",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_scourge.png"}
J.HubCatalog.entries.RACE_TAUREN = {label="Tauren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_tauren.png"}
J.HubCatalog.entries.RACE_TROLL = {label="Troll",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_troll.png"}
J.HubCatalog.entries.RACE_BLOODELF = {label="Blood Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_bloodelf.png"}
J.HubCatalog.entries.RACE_GOBLIN = {label="Goblin",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_goblin.png"}
J.HubCatalog.entries.RACE_PANDAREN = {label="Pandaren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_pandaren.png"}
J.HubCatalog.entries.RACE_DRACTHYR = {label="Dracthyr",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_dracthyr.png"}
J.HubCatalog.entries.RACE_VOIDELF = {label="Void Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_voidelf.png"}
J.HubCatalog.entries.RACE_LIGHTFORGEDDRAENEI = {label="Lightforged Draenei",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_lightforgeddraenei.png"}
J.HubCatalog.entries.RACE_DARKIRONDWARF = {label="Dark Iron Dwarf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_darkirondwarf.png"}
J.HubCatalog.entries.RACE_KULTIRAN = {label="Kul Tiran",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_kultiran.png"}
J.HubCatalog.entries.RACE_MECHAGNOME = {label="Mechagnome",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_mechagnome.png"}
J.HubCatalog.entries.RACE_NIGHTBORNE = {label="Nightborne",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_nightborne.png"}
J.HubCatalog.entries.RACE_HIGHMOUNTAINTAUREN = {label="Highmountain Tauren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_highmountaintauren.png"}
J.HubCatalog.entries.RACE_MAGHARORC = {label="Mag'har Orc",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_magharorc.png"}
J.HubCatalog.entries.RACE_ZANDALARITROLL = {label="Zandalari Troll",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_zandalaritroll.png"}
J.HubCatalog.entries.RACE_VULPERA = {label="Vulpera",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_vulpera.png"}
J.HubCatalog.entries.RACE_EARTHENDWARF = {label="Earthen",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_earthendwarf.png"}
J.HubCatalog.entries.RACE_HARANIR = {label="Haranir",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\race_haranir.png"}
J.HubCatalog.entries.FACTION_ALLIANCE = {label="Alliance",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\faction_alliance.png"}
J.HubCatalog.entries.FACTION_HORDE = {label="Horde",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\faction_horde.png"}
J.HubCatalog.entries.FACTION_NEUTRAL = {label="Neutral",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Hubs\\faction_neutral.png"}
