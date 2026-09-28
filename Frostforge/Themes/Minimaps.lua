local _, J = ...
-- Data only; every identity shares one circular aperture.
J.MinimapCatalog = { entries = {} }
J.MinimapCatalog.entries.CLASS_WARRIOR = {label="Warrior",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_warrior.png"}
J.MinimapCatalog.entries.CLASS_PALADIN = {label="Paladin",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_paladin.png"}
J.MinimapCatalog.entries.CLASS_HUNTER = {label="Hunter",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_hunter.png"}
J.MinimapCatalog.entries.CLASS_ROGUE = {label="Rogue",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_rogue.png"}
J.MinimapCatalog.entries.CLASS_PRIEST = {label="Priest",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_priest.png"}
J.MinimapCatalog.entries.CLASS_DEATHKNIGHT = {label="Death Knight",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_deathknight.png"}
J.MinimapCatalog.entries.CLASS_SHAMAN = {label="Shaman",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_shaman.png"}
J.MinimapCatalog.entries.CLASS_MAGE = {label="Mage",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_mage.png"}
J.MinimapCatalog.entries.CLASS_WARLOCK = {label="Warlock",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_warlock.png"}
J.MinimapCatalog.entries.CLASS_MONK = {label="Monk",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_monk.png"}
J.MinimapCatalog.entries.CLASS_DRUID = {label="Druid",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_druid.png"}
J.MinimapCatalog.entries.CLASS_DEMONHUNTER = {label="Demon Hunter",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_demonhunter.png"}
J.MinimapCatalog.entries.CLASS_EVOKER = {label="Evoker",group="CLASS",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_evoker.png"}
J.MinimapCatalog.entries.RACE_HUMAN = {label="Human",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_human.png"}
J.MinimapCatalog.entries.RACE_DWARF = {label="Dwarf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_dwarf.png"}
J.MinimapCatalog.entries.RACE_NIGHTELF = {label="Night Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_nightelf.png"}
J.MinimapCatalog.entries.RACE_GNOME = {label="Gnome",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_gnome.png"}
J.MinimapCatalog.entries.RACE_DRAENEI = {label="Draenei",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_draenei.png"}
J.MinimapCatalog.entries.RACE_WORGEN = {label="Worgen",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_worgen.png"}
J.MinimapCatalog.entries.RACE_ORC = {label="Orc",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_orc.png"}
J.MinimapCatalog.entries.RACE_SCOURGE = {label="Undead",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_scourge.png"}
J.MinimapCatalog.entries.RACE_TAUREN = {label="Tauren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_tauren.png"}
J.MinimapCatalog.entries.RACE_TROLL = {label="Troll",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_troll.png"}
J.MinimapCatalog.entries.RACE_BLOODELF = {label="Blood Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_bloodelf.png"}
J.MinimapCatalog.entries.RACE_GOBLIN = {label="Goblin",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_goblin.png"}
J.MinimapCatalog.entries.RACE_PANDAREN = {label="Pandaren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_pandaren.png"}
J.MinimapCatalog.entries.RACE_DRACTHYR = {label="Dracthyr",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_dracthyr.png"}
J.MinimapCatalog.entries.RACE_VOIDELF = {label="Void Elf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_voidelf.png"}
J.MinimapCatalog.entries.RACE_LIGHTFORGEDDRAENEI = {label="Lightforged Draenei",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_lightforgeddraenei.png"}
J.MinimapCatalog.entries.RACE_DARKIRONDWARF = {label="Dark Iron Dwarf",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_darkirondwarf.png"}
J.MinimapCatalog.entries.RACE_KULTIRAN = {label="Kul Tiran",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_kultiran.png"}
J.MinimapCatalog.entries.RACE_MECHAGNOME = {label="Mechagnome",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_mechagnome.png"}
J.MinimapCatalog.entries.RACE_NIGHTBORNE = {label="Nightborne",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_nightborne.png"}
J.MinimapCatalog.entries.RACE_HIGHMOUNTAINTAUREN = {label="Highmountain Tauren",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_highmountaintauren.png"}
J.MinimapCatalog.entries.RACE_MAGHARORC = {label="Mag'har Orc",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_magharorc.png"}
J.MinimapCatalog.entries.RACE_ZANDALARITROLL = {label="Zandalari Troll",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_zandalaritroll.png"}
J.MinimapCatalog.entries.RACE_VULPERA = {label="Vulpera",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_vulpera.png"}
J.MinimapCatalog.entries.RACE_EARTHENDWARF = {label="Earthen",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_earthendwarf.png"}
J.MinimapCatalog.entries.RACE_HARANIR = {label="Haranir",group="RACE",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\race_haranir.png"}
J.MinimapCatalog.entries.FACTION_ALLIANCE = {label="Alliance",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\faction_alliance.png"}
J.MinimapCatalog.entries.FACTION_HORDE = {label="Horde",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\faction_horde.png"}
J.MinimapCatalog.entries.FACTION_NEUTRAL = {label="Neutral",group="FACTION",texture="Interface\\AddOns\\Frostforge\\Media\\Minimaps\\faction_neutral.png"}
