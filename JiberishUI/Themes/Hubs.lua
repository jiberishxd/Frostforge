local _, J = ...
-- Data only; all variants use the same five-piece fitting template.
J.HubCatalog = { entries = {} }
J.HubCatalog.entries.CLASS_WARRIOR = {label="Warrior",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_warrior.tga"}
J.HubCatalog.entries.CLASS_PALADIN = {label="Paladin",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_paladin.tga"}
J.HubCatalog.entries.CLASS_HUNTER = {label="Hunter",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_hunter.tga"}
J.HubCatalog.entries.CLASS_ROGUE = {label="Rogue",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_rogue.tga"}
J.HubCatalog.entries.CLASS_PRIEST = {label="Priest",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_priest.tga"}
J.HubCatalog.entries.CLASS_DEATHKNIGHT = {label="Death Knight",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_deathknight.tga"}
J.HubCatalog.entries.CLASS_SHAMAN = {label="Shaman",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_shaman.tga"}
J.HubCatalog.entries.CLASS_MAGE = {label="Mage",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_mage.tga"}
J.HubCatalog.entries.CLASS_WARLOCK = {label="Warlock",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_warlock.tga"}
J.HubCatalog.entries.CLASS_MONK = {label="Monk",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_monk.tga"}
J.HubCatalog.entries.CLASS_DRUID = {label="Druid",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_druid.tga"}
J.HubCatalog.entries.CLASS_DEMONHUNTER = {label="Demon Hunter",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_demonhunter.tga"}
J.HubCatalog.entries.CLASS_EVOKER = {label="Evoker",group="CLASS",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_evoker.tga"}
J.HubCatalog.entries.RACE_HUMAN = {label="Human",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_human.tga"}
J.HubCatalog.entries.RACE_DWARF = {label="Dwarf",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_dwarf.tga"}
J.HubCatalog.entries.RACE_NIGHTELF = {label="Night Elf",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_nightelf.tga"}
J.HubCatalog.entries.RACE_GNOME = {label="Gnome",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_gnome.tga"}
J.HubCatalog.entries.RACE_DRAENEI = {label="Draenei",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_draenei.tga"}
J.HubCatalog.entries.RACE_WORGEN = {label="Worgen",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_worgen.tga"}
J.HubCatalog.entries.RACE_ORC = {label="Orc",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_orc.tga"}
J.HubCatalog.entries.RACE_SCOURGE = {label="Undead",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_scourge.tga"}
J.HubCatalog.entries.RACE_TAUREN = {label="Tauren",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_tauren.tga"}
J.HubCatalog.entries.RACE_TROLL = {label="Troll",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_troll.tga"}
J.HubCatalog.entries.RACE_BLOODELF = {label="Blood Elf",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_bloodelf.tga"}
J.HubCatalog.entries.RACE_GOBLIN = {label="Goblin",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_goblin.tga"}
J.HubCatalog.entries.RACE_PANDAREN = {label="Pandaren",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_pandaren.tga"}
J.HubCatalog.entries.RACE_DRACTHYR = {label="Dracthyr",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_dracthyr.tga"}
J.HubCatalog.entries.RACE_VOIDELF = {label="Void Elf",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_voidelf.tga"}
J.HubCatalog.entries.RACE_LIGHTFORGEDDRAENEI = {label="Lightforged Draenei",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_lightforgeddraenei.tga"}
J.HubCatalog.entries.RACE_DARKIRONDWARF = {label="Dark Iron Dwarf",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_darkirondwarf.tga"}
J.HubCatalog.entries.RACE_KULTIRAN = {label="Kul Tiran",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_kultiran.tga"}
J.HubCatalog.entries.RACE_MECHAGNOME = {label="Mechagnome",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_mechagnome.tga"}
J.HubCatalog.entries.RACE_NIGHTBORNE = {label="Nightborne",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_nightborne.tga"}
J.HubCatalog.entries.RACE_HIGHMOUNTAINTAUREN = {label="Highmountain Tauren",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_highmountaintauren.tga"}
J.HubCatalog.entries.RACE_MAGHARORC = {label="Mag'har Orc",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_magharorc.tga"}
J.HubCatalog.entries.RACE_ZANDALARITROLL = {label="Zandalari Troll",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_zandalaritroll.tga"}
J.HubCatalog.entries.RACE_VULPERA = {label="Vulpera",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_vulpera.tga"}
J.HubCatalog.entries.RACE_EARTHENDWARF = {label="Earthen",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_earthendwarf.tga"}
J.HubCatalog.entries.RACE_HARANIR = {label="Haranir",group="RACE",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\race_haranir.tga"}
J.HubCatalog.entries.FACTION_ALLIANCE = {label="Alliance",group="FACTION",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\faction_alliance.tga"}
J.HubCatalog.entries.FACTION_HORDE = {label="Horde",group="FACTION",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\faction_horde.tga"}
J.HubCatalog.entries.FACTION_NEUTRAL = {label="Neutral",group="FACTION",texture="Interface\\AddOns\\JiberishUI\\Media\\Hubs\\faction_neutral.tga"}
