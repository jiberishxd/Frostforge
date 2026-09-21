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
            powerMode='native', powerColor={0.2,0.45,1}, powerColors={},
            healthGradient=false,powerGradient=false,gradientDirection='HORIZONTAL',gradientStrength=0.5,
            portraitBorder=true,portraitSkin='inherit',portraitStyle='none',portraitScale=0.8,portraitOpacity=1,portraitTint={1,1,1},portraitX=0,portraitY=0,
            actionMode='hub',hubStyle='class',hubScope='cluster',hubPadding=10,hubArtworkScale=0.8,hubArtworkX=0,hubArtworkY=0,
            hubOpacity=1,hubBackdrop=0.3,hubMicro=true,hubBags=true,hubDock=true,
            hubX=0,hubY=0,hubWidth=1100,hubHeight=310,
            hubActionsX=0,hubActionsY=90,hubActionsScale=1,hubRowGap=8,
            hubBar2X=0,hubBar2Y=0,hubBar2Scale=1,hubBar3X=0,hubBar3Y=0,hubBar3Scale=1,
            hubMicroX=-155,hubMicroY=42,hubMicroScale=0.85,
            hubBagsX=195,hubBagsY=42,hubBagsScale=0.85}})
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
