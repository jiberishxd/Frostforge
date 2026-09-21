local _, J = ...
local H = {}
J.Hubs = H

J.Core.properties.hubMode = {CLASS=true,RACE=true,FACTION=true,FIXED=true}
J.Core.properties.hub = {}
for id in pairs(J.HubCatalog.entries) do J.Core.properties.hub[id] = true end

function H:Resolve(config)
    -- A hub follows the player's identity, never the selected target. Reuse
    -- the guarded public-token reader without reading health/power quantities.
    local id = J.Portraits:Resolve({unit="player",portraitMode=config.hubMode,portrait=config.hub})
    local entry = J.HubCatalog.entries[id] or J.HubCatalog.entries.FACTION_NEUTRAL
    return id,entry.texture
end

function H:Refresh(module,combat)
    local id,path = self:Resolve(module.applied)
    if id == module.hubID then return end
    if combat and module.frame:IsProtected() then J.Core.dirty=true; return end
    module.assetOK = true
    for _,texture in pairs(module.textures) do
        if texture:SetTexture(path) == false then module.assetOK=false end
    end
    module.hubID,module.applied.texture = id,path
    module.status = module.assetOK and "attached" or "Artwork could not be loaded"
end
