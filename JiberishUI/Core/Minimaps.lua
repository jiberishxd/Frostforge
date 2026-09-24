local _, J = ...
local Maps = {}
J.Minimaps = Maps

J.Core.properties.minimapMode = {CLASS=true,RACE=true,FACTION=true,FIXED=true}
J.Core.properties.minimap = {}
for id in pairs(J.MinimapCatalog.entries) do J.Core.properties.minimap[id] = true end

function Maps:Resolve(config)
    -- A minimap follows the player's identity, never the selected target. Reuse
    -- the guarded public-token reader without reading health/power quantities.
    local id = J.Portraits:Resolve({unit="player",portraitMode=config.minimapMode,portrait=config.minimap})
    local entry = J.MinimapCatalog.entries[id] or J.MinimapCatalog.entries.FACTION_NEUTRAL
    return id,entry.texture
end

function Maps:Refresh(module,combat)
    local id,path = self:Resolve(module.applied)
    if id == module.minimapID then return end
    if combat and module.frame:IsProtected() then J.Core.dirty=true; return end
    module.assetOK = true
    for _,texture in pairs(module.textures) do
        if texture:SetTexture(path) == false then module.assetOK=false end
    end
    module.minimapID,module.applied.texture = id,path
    module.status = module.assetOK and "attached" or "Artwork could not be loaded"
end
