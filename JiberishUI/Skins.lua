local _, J = ...
J.Skins = {}
J.SkinOrder = {}
J.SkinCategories={{'all','All styles'},{'race','Races'},{'class','Classes'},{'faction','Factions'},{'standard','Standard'}}
local root = 'Interface\\AddOns\\'..J.name..'\\Media\\'
J.MediaRoot, J.Neutral = root, root..'neutral.tga'
function J:RegisterSkin(id, definition)
    assert(type(id)=='string' and not self.Skins[id], 'duplicate or invalid skin')
    assert(type(definition.path)=='string' and type(definition.defaults)=='table', 'invalid skin')
    self.Skins[id] = definition
end
for _,entry in ipairs(J.SkinCatalog) do
    J.SkinOrder[#J.SkinOrder+1]=entry.id
    J:RegisterSkin(entry.id, {label=entry.label, category=entry.category, material=entry.material,
        description=entry.description, identity=entry.identity, path=root..entry.material..'\\', qualified=true,
        defaults={enabled=true, thickness=entry.thickness, inset=0, opacity=1, ornament=entry.ornament,
            tint=J.Util.Copy(entry.tint), healthMode='native', healthColor={0.2,0.8,0.3},
            powerMode='native', powerColor={0.2,0.45,1}, powerColors={}}})
end
function J:FindSkins(category,query)
    local out={}; query=(query or ''):lower():match('^%s*(.-)%s*$')
    for _,id in ipairs(self.SkinOrder) do
        local skin=self.Skins[id]
        local haystack=(skin.label..' '..skin.description..' '..(skin.identity or '')..' '..id):lower()
        if (not category or category=='all' or category==skin.category) and (query=='' or haystack:find(query,1,true)) then
            out[#out+1]=id
        end
    end
    return out
end
J.Variants = {
    portrait={min=3,max=12,ornament=true}, bar={min=2,max=6}, compact={min=2,max=5},
    small={min=2,max=5}, button={min=3,max=10}, rail={min=3,max=12,ornament=true}, external={min=1,max=3}, nativebar={min=2,max=2},
}
