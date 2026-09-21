local _, J = ...
local P = {}
J.Portraits = P

J.Core.properties.portraitMode = {CLASS=true,RACE=true,FACTION=true,FIXED=true}
J.Core.properties.portrait = {}
for id in pairs(J.PortraitCatalog.entries) do J.Core.properties.portrait[id] = true end

function P:IsUnitKey(key)
    return key == "playerFrame" or key == "targetFrame" or key == "focusFrame"
end

-- One atlas keeps both native shapes aligned to the same 128-unit frame.
-- Player has a squared lower corner; Target/Focus use a smaller round opening.
function P:TexCoords(unit)
    if unit == "player" then return 0,0.5 end
    return 0.5,1
end

-- Never index, compare or format restricted API results. Localized display names
-- are intentionally ignored; only public, typed file tokens enter the registry.
local function token(api,unit,index)
    if type(api) ~= "function" then return nil end
    local values = {pcall(api,unit)}
    if not values[1] then return nil end
    local value = values[index+1]
    if J.Core:IsSafe(value) and type(value) == "string" then return value end
end

function P:Resolve(config)
    local id
    if config.portraitMode == "FIXED" then
        id = config.portrait
    elseif config.portraitMode == "CLASS" then
        -- NPC UnitClass commonly returns WARRIOR regardless of appearance.
        -- Keep those on a neutral background rather than inventing a class.
        local ok, player = false, nil
        if type(UnitIsPlayer) == "function" then ok,player=pcall(UnitIsPlayer,config.unit) end
        if ok and J.Core:IsSafe(player) and player == true then
            local value = token(UnitClass,config.unit,2)
            if value then id = J.PortraitCatalog.classes[value] end
        end
    elseif config.portraitMode == "RACE" then
        local value = token(UnitRace,config.unit,2)
        if value then id = J.PortraitCatalog.races[value] end
    elseif config.portraitMode == "FACTION" then
        local value = token(UnitFactionGroup,config.unit,1)
        if value then id = J.PortraitCatalog.factions[value] end
    end
    id = id or "FACTION_NEUTRAL"
    local entry = J.PortraitCatalog.entries[id] or J.PortraitCatalog.entries.FACTION_NEUTRAL
    return id,entry.texture
end

function P:Refresh(module,combat)
    local id,path = self:Resolve(module.applied)
    if id == module.portraitID then return end
    if combat and module.frame:IsProtected() then J.Core.dirty=true; return end
    -- Only change the texture of a previously attached, non-interactive frame.
    -- Geometry, layering and user configuration still wait for combat to end.
    module.assetOK = true
    for _,texture in pairs(module.textures) do
        if texture:SetTexture(path) == false then module.assetOK=false end
    end
    module.portraitID, module.applied.texture = id,path
    module.status = module.assetOK and "attached" or "Artwork could not be loaded"
end
