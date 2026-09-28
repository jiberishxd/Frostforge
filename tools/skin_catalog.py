"""Canonical skin metadata; material families are shared deliberately, not duplicated art."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
CATEGORIES = [('race', 'Races'), ('class', 'Classes'), ('faction', 'Factions'), ('standard', 'Standard')]
SKINS = []

def skin(id, label, category, material, description, *, tint=(1,1,1), ornament=0.35, thickness=8, identity=None):
    SKINS.append(dict(id=id, label=label, category=category, material=material, description=description,
                      tint=list(tint), ornament=ornament, thickness=thickness, identity=identity))

# The four original IDs are permanent: existing profiles continue to resolve unchanged.
skin('human','Human','race','human','Classic Warcraft III stone and gold.',identity='Human')
skin('orc','Orc','race','orc','Classic Warcraft III timber and iron.',identity='Orc')
skin('nightelf','Night Elf','race','nightelf','Classic Warcraft III living vines and silver.',identity='Night Elf')
skin('undead','Undead','race','undead','Classic Warcraft III bone and amethyst.',identity='Undead')
skin('dwarf','Dwarf — Ironforge','race','dwarven_forge','Chiseled granite, brass, and forge-cut corners.',identity='Dwarf')
skin('gnome','Gnome — Clockwork','race','clockwork','Precision brass plates and mechanical joints.',identity='Gnome')
skin('draenei','Draenei — Exodar','race','arcane_crystal','Violet crystal and luminous geometric rails.',tint=(0.9,0.8,1),identity='Draenei')
skin('worgen','Worgen — Gilneas','race','shadow_steel','Dark Gothic steel with restrained silver edges.',tint=(0.85,0.85,1),identity='Worgen')
skin('pandaren','Pandaren — Jade Temple','race','jade_bamboo','Jade, bamboo joints, and warm bronze.',identity='Pandaren')
skin('dracthyr','Dracthyr — Dragonflight','race','dragon_scale','Layered dragon scales and wing-shaped corners.',identity='Dracthyr')
skin('tauren','Tauren — Earthmother','race','tribal_totem','Carved wood, leather bindings, and turquoise.',identity='Tauren')
skin('troll','Troll — Darkspear','race','tribal_totem','Darkspear teal on carved tribal rails.',tint=(0.6,0.95,1),identity='Troll')
skin('bloodelf','Blood Elf — Sunspire','race','sacred_gold','Sunlit gold and warm jewel accents.',tint=(1,0.75,0.65),identity='Blood Elf')
skin('goblin','Goblin — Bilgewater','race','clockwork','Weathered industrial brass with green accents.',tint=(0.65,1,0.65),identity='Goblin')
skin('voidelf','Void Elf — Rift','race','arcane_crystal','Deep violet crystal and void-tinted rails.',tint=(0.55,0.45,1),identity='Void Elf')
skin('lightforged','Lightforged Draenei','race','sacred_gold','Pale gold, ivory, and warm sacred light.',tint=(1,0.95,0.8),identity='Lightforged Draenei')
skin('darkiron','Dark Iron Dwarf','race','dwarven_forge','Dark forge stone with ember-colored seams.',tint=(0.65,0.38,0.24),identity='Dark Iron Dwarf')
skin('kultiran','Kul Tiran — Admiralty','race','tribal_totem','Sea-weathered timber and nautical turquoise.',tint=(0.65,0.9,0.85),identity='Kul Tiran')
skin('mechagnome','Mechagnome — Workshop','race','clockwork','Bright workshop metal and precision joints.',tint=(0.85,0.95,1),identity='Mechagnome')
skin('earthen','Earthen — Titan Forge','race','dwarven_forge','Cool mineral stone with titan-forged geometry.',tint=(0.6,0.9,1),identity='Earthen')
skin('haranir','Haranir — Ancient Roots','race','nightelf','Deep green roots and ancient silver supports.',tint=(0.6,0.8,0.65),identity='Haranir')
skin('nightborne','Nightborne — Suramar','race','moonstone','Moon-silver architecture and violet inlays.',tint=(0.7,0.65,1),identity='Nightborne')
skin('highmountain','Highmountain Tauren','race','tribal_totem','Mountain-carved timber and warm leather.',tint=(0.95,0.8,0.6),identity='Highmountain Tauren')
skin('maghar','Mag’har Orc','race','orc','Uncorrupted clan timber and burnished iron.',tint=(0.9,0.7,0.5),identity='Mag\'har Orc')
skin('zandalari','Zandalari Troll','race','sacred_gold','Temple gold and jade-toned highlights.',tint=(0.8,1,0.55),identity='Zandalari Troll')
skin('vulpera','Vulpera — Caravan','race','tribal_totem','Warm desert wood, leather, and small blue stones.',tint=(1,0.75,0.5),identity='Vulpera')
skin('nightelf_moonwell','Night Elf — Moonwell','race','moonstone','Elune-inspired crescents and cool moonstone.',identity='Night Elf')
skin('nightelf_grove','Night Elf — Ancient Grove','race','nightelf','Deep woodland foliage and subdued stone.',tint=(0.65,0.9,0.6),ornament=0.55,identity='Night Elf')
skin('nightelf_sentinel','Night Elf — Sentinel','race','moonstone','Violet sentinel metal and pale silver edges.',tint=(0.8,0.55,1),identity='Night Elf')

skin('warrior','Warrior — Battleplate','class','dwarven_forge','Heavy forged corners and weathered metal.',tint=(0.8,0.7,0.55),identity='WARRIOR')
skin('paladin','Paladin — Golden Oath','class','sacred_gold','Radiant gold, ivory, and rose-tinted inlays.',tint=(1,0.8,0.8),identity='PALADIN')
skin('hunter','Hunter — Wildstalker','class','tribal_totem','Forest timber, leather bindings, and green accents.',tint=(0.65,0.95,0.55),identity='HUNTER')
skin('rogue','Rogue — Shadowsteel','class','shadow_steel','Slim, dark steel with a muted warm edge.',tint=(0.9,0.85,0.6),ornament=0.2,thickness=6,identity='ROGUE')
skin('priest','Priest — Sanctum','class','sacred_gold','Pale ivory and restrained holy-gold detailing.',tint=(1,1,1),identity='PRIEST')
skin('deathknight','Death Knight — Runeblade','class','shadow_steel','Cold runic steel and icy blue highlights.',tint=(0.55,0.8,1),identity='DEATHKNIGHT')
skin('shaman','Shaman — Storm Totem','class','tribal_totem','Elemental blue on carved totemic supports.',tint=(0.5,0.7,1),identity='SHAMAN')
skin('mage','Mage — Arcane Crystal','class','arcane_crystal','Arcane crystal, silver channels, and violet light.',identity='MAGE')
skin('monk','Monk — Jade Serpent','class','jade_bamboo','Jade-green stone, bamboo, and bronze corners.',tint=(0.7,1,0.8),identity='MONK')
skin('druid','Druid — Dreamgrove','class','nightelf','Living roots and emerald leaves.',tint=(0.85,1,0.65),ornament=0.55,identity='DRUID')
skin('demonhunter','Demon Hunter — Illidari','class','fel_obsidian','Obsidian blades with violet-fel accents.',tint=(0.8,0.65,1),identity='DEMONHUNTER')
skin('warlock','Warlock — Fel Covenant','class','fel_obsidian','Dark obsidian, fel-green seams, and demonic corners.',identity='WARLOCK')
skin('evoker','Evoker — Aspect Scales','class','dragon_scale','Dragon scales with turquoise and bronze.',tint=(0.65,1,0.9),identity='EVOKER')

skin('alliance','Alliance — Royal Gold','faction','sacred_gold','Royal blue-tinted gold and carved heraldic corners.',tint=(0.7,0.8,1),identity='Alliance')
skin('horde','Horde — War Iron','faction','orc','Crimson-tinted timber and battle-worn iron.',tint=(1,0.5,0.4),identity='Horde')

skin('blackstone','Black Stone','standard','black_basalt','Charcoal basalt with a subtle silver bevel.',ornament=0,thickness=6)
skin('slate','Slate','standard','black_basalt','Cool blue-grey stone with a clean silhouette.',tint=(0.7,0.85,1),ornament=0,thickness=6)
skin('obsidian','Obsidian','standard','black_basalt','Almost-black stone for a quieter interface.',tint=(0.55,0.55,0.6),ornament=0,thickness=5)
skin('silver','Silver Steel','standard','shadow_steel','Neutral steel with restrained metal highlights.',ornament=0,thickness=5)
skin('bronze','Aged Bronze','standard','clockwork','Warm, muted mechanical bronze.',tint=(0.85,0.65,0.4),ornament=0,thickness=6)
skin('parchment','Ivory Gold','standard','sacred_gold','Soft ivory and warm gold for a lighter treatment.',ornament=0,thickness=5)
skin('forestwood','Forest Wood','standard','orc','Natural timber with subdued metal hardware.',tint=(0.8,0.9,0.65),ornament=0,thickness=5)
skin('froststone','Frost Stone','standard','moonstone','Pale blue stone and crystalline highlights.',tint=(0.7,0.9,1),ornament=0,thickness=6)

def write():
    assert len({s['id'] for s in SKINS})==len(SKINS)
    (ROOT/'docs/skin-catalog.json').write_text(json.dumps({'version':1,'categories':CATEGORIES,'skins':SKINS},indent=2,ensure_ascii=False)+'\n')
    quote=lambda s:json.dumps(s,ensure_ascii=False)
    lines=['-- Generated by tools/skin_catalog.py. Preserve published skin IDs.','local _,J=...','J.SkinCatalog={']
    for s in SKINS:
        fields=[f'{key}={quote(s[key])}' for key in ('id','label','category','material','description')]
        if s['identity']: fields.append('identity='+quote(s['identity']))
        fields.extend(['tint={'+','.join(map(str,s['tint']))+'}',f"ornament={s['ornament']}",f"thickness={s['thickness']}"])
        lines.append('    {'+','.join(fields)+'},')
    lines.append('}')
    (ROOT/'Frostforge/SkinCatalog.lua').write_text('\n'.join(lines)+'\n')
    print(f'Wrote {len(SKINS)} skin choices across {len(set(s["material"] for s in SKINS))} material families')

if __name__=='__main__': write()
