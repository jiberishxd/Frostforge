local _, J = ...
local P = {cityCache={}}
J.Portraits = P

J.Core.properties.portraitMode = {CLASS=true,RACE=true,FACTION=true,FIXED=true}
J.Core.properties.portrait = {}
for id in pairs(J.PortraitCatalog.entries) do J.Core.properties.portrait[id] = true end

function P:IsUnitKey(key)
    return key == "playerFrame" or key == "targetFrame" or key == "focusFrame"
end

-- Native/provider frames can remain visible for one event after their unit is
-- cleared. Hide on a public absence immediately, without treating unavailable
-- or secret identity as proof that a real unit disappeared.
local units={playerFrame="player",targetFrame="target",focusFrame="focus"}
function P:HasUnit(key)
    local unit=units[key]
    if not unit or type(UnitExists)~="function" then return true end
    local ok,exists=pcall(UnitExists,unit)
    if not ok or not J.Core:IsSafe(exists) then return true end
    return exists~=nil and exists~=false
end

-- One atlas keeps both native shapes aligned to the same 128-unit frame.
-- Player has a squared lower corner; Target/Focus use a smaller round opening.
function P:TexCoords(unit)
    if unit == "player" then return 0,0.5 end
    return 0.5,1
end

-- Never index, compare or format restricted API results. Player selection uses
-- public file tokens; NPC affiliations use exact, client-localized labels.
local function token(api,unit,index)
    if type(api) ~= "function" then return nil end
    local values = {pcall(api,unit)}
    if not values[1] then return nil end
    local value = values[index+1]
    if J.Core:IsSafe(value) and type(value) == "string" then return value end
end

local function field(object,key)
    if not J.Core:IsSafe(object) or type(object)~="table" then return end
    local value=object[key]
    if J.Core:IsSafe(value) then return value end
end

local function publicCall(api,...)
    if type(api)~="function" then return end
    local ok,value=pcall(api,...)
    if ok and J.Core:IsSafe(value) then return value end
end

local function plainText(value)
    if not J.Core:IsSafe(value) or type(value)~="string" or #value>256 then return end
    return value:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):match("^%s*(.-)%s*$")
end

function P:CityNames(now)
    if self.cityNames and now and self.cityNamesAt and now-self.cityNamesAt<30 then return self.cityNames end
    local names={}
    for _,city in ipairs(J.NPCCities) do
        names[city.name]=city.artwork
        local data=publicCall(field(C_Reputation,"GetFactionDataByID"),city.factionID)
        local name=plainText(field(data,"name")) or plainText(publicCall(GetFactionInfoByID,city.factionID))
        if name and name~="" then names[name]=city.artwork end
    end
    self.cityNames,self.cityNamesAt=names,now
    return names
end

function P:NPCCity(unit)
    -- City affiliation belongs to the NPC, not the player's current zone. A
    -- public creature GUID excludes players, pets and vehicles; restricted
    -- identity/tooltip fields never enter string matching or cache keys.
    local guid=token(UnitGUID,unit,1)
    if not guid or not guid:match("^Creature%-") then self.cityCache[unit]=nil;return end
    if publicCall(UnitPlayerControlled,unit)~=false then return end
    local now=publicCall(GetTime)
    if not J.Core:IsNumber(now) then now=nil end
    local cached=self.cityCache[unit]
    if cached and cached.guid==guid and now and cached.at and now>=cached.at and now-cached.at<.5 then return cached.id end
    local data=publicCall(field(C_TooltipInfo,"GetUnit"),unit,true)
    local lines=field(data,"lines")
    local id
    local names=self:CityNames(now)
    -- Affiliation is an ordinary text line. Skip the name, quest objectives,
    -- owner and all other typed lines; never substring-match an NPC's name.
    for i=2,12 do
        local line=field(lines,i)
        local kind=field(line,"type")
        if type(line)=="table" and J.Core:IsSafe(line.type) and (kind==nil or kind==0) then
            local text=plainText(field(line,"leftText"))
            if text and names[text] then id=names[text];break end
        end
    end
    if not id then
        local creatureID=tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
        id=creatureID and J.NPCCityGuards[creatureID]
    end
    self.cityCache[unit]={guid=guid,at=now,id=id}
    return id
end

function P:Resolve(config)
    local id
    if config.portraitMode == "FIXED" then
        id = config.portrait
    else
        local player=publicCall(UnitIsPlayer,config.unit)
        if player==false then id=self:NPCCity(config.unit) end
        if not id and config.portraitMode == "CLASS" then
            -- NPC UnitClass commonly returns WARRIOR regardless of appearance.
            -- Unrecognized NPC affiliations keep the neutral fallback.
            if player == true then
                local value = token(UnitClass,config.unit,2)
                if value then id = J.PortraitCatalog.classes[value] end
            end
        elseif not id and config.portraitMode == "RACE" then
            local value = token(UnitRace,config.unit,2)
            if value then id = J.PortraitCatalog.races[value] end
        elseif not id and config.portraitMode == "FACTION" then
            local value = token(UnitFactionGroup,config.unit,1)
            if value then id = J.PortraitCatalog.factions[value] end
        end
    end
    id = id or "FACTION_NEUTRAL"
    local entry = J.PortraitCatalog.entries[id] or J.PortraitCatalog.entries.FACTION_NEUTRAL
    return id,entry.texture
end

function P:Refresh(module,combat)
    if not self:HasUnit(module.key) then return end
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
