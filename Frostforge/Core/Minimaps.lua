local _, J = ...
local Maps = {}
J.Minimaps = Maps

J.Core.properties.minimapMode = {CLASS=true,RACE=true,FACTION=true,FIXED=true}
J.Core.properties.minimapRound = {boolean=true}
table.insert(J.Core.propertyOrder,"minimapRound")
J.Core.properties.minimap = {}
for id in pairs(J.MinimapCatalog.entries) do J.Core.properties.minimap[id] = true end

function Maps:Resolve(config)
    -- A minimap follows the player's identity, never the selected target. Reuse
    -- the guarded public-token reader without reading health/power quantities.
    local id = J.Portraits:Resolve({unit="player",portraitMode=config.minimapMode,portrait=config.minimap})
    local entry = J.MinimapCatalog.entries[id] or J.MinimapCatalog.entries.FACTION_NEUTRAL
    return id,entry.texture
end

local ranks={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8}
function Maps:Layer(module)
    local f,map=module.frame,module.attachment and module.attachment.frame
    if not f or not module.applied or not J.Core:IsUsableFrame(map) then return end
    if InCombatLockdown() and f:IsProtected() then J.Core.dirty=true;return end
    local c=module.applied
    local strata,level=c.strata,c.level
    local function inspect(frame)
        if not J.Core:IsUsableFrame(frame) then return end
        local ok,s,l=pcall(function() return frame:GetFrameStrata(),frame:GetFrameLevel() end)
        if not ok or not J.Core:IsSafe(s) or not ranks[s] or not J.Core:IsNumber(l) then return end
        if ranks[s]>ranks[strata] then strata,level=s,l+1
        elseif s==strata then level=math.max(level,l+1) end
    end
    inspect(map);inspect(map.backdrop)
    -- Match the map and its surrounding frame, without raising above every icon.
    local parent=map:GetParent()
    if parent~=UIParent then inspect(parent) end
    if f:GetFrameStrata()~=strata then f:SetFrameStrata(strata) end
    if f:GetFrameLevel()~=level then f:SetFrameLevel(level) end
end

local function elvui()
    local E=type(ElvUI)=="table" and ElvUI[1]
    if type(E)~="table" or type(E.GetModule)~="function" then return end
    local ok,M=pcall(E.GetModule,E,"Minimap",true)
    local db=E.db and E.db.general and E.db.general.minimap
    local profile=E.data and E.data.keys and E.data.keys.profile
    if not ok or type(M)~="table" or not M.Initialized or M.db~=db or type(db)~="table"
        or type(db.circle)~="boolean" or type(profile)~="string"
        or type(M.SetMinimapMask)~="function" or type(M.UpdateSettings)~="function" then return end
    if not (E.private and E.private.general and E.private.general.minimap and E.private.general.minimap.enable) then return end
    return M,db,profile
end

function Maps:RoundShape(module)
    if InCombatLockdown() or not J.ProfileManager.writable then return end
    local map=Minimap
    if not J.Core:IsUsableFrame(map) then return end
    local M,db,profile=elvui()
    local saved=JiberishUIDB.minimapShapeRestore
    if saved~=nil and type(saved)~="table" then return end
    saved=saved or {};JiberishUIDB.minimapShapeRestore=saved
    local c=J.ThemeManager:Read("minimap")
    local wanted=M and c.shown and c.minimapRound and module.assetOK and module.snapshot~=nil
    local old=self.round
    if old and (not wanted or old.db~=db) then
        -- The old profile's table may no longer be the active ElvUI profile.
        if old.db.circle==true then old.db.circle=old.original end
        if old.db==db then M:SetMinimapMask(not db.circle);M:UpdateSettings() end
        saved[old.profile]=nil;self.round=nil
    end
    -- Recover the pre-Frostforge setting after a reload, including disabling art.
    if M and not wanted and type(saved[profile])=="boolean" then
        if db.circle==true then db.circle=saved[profile] end
        -- Keep the journal until both native calls succeed, even if the stored
        -- circle value was already restored by an interrupted earlier attempt.
        M:SetMinimapMask(not db.circle);M:UpdateSettings()
        saved[profile]=nil
    end
    if not wanted then
        self.shapeStatus=M and "ElvUI shape unchanged." or "Round-shape integration available with ElvUI's minimap enabled."
        return
    end
    if not self.round then
        local original=saved[profile]
        if type(original)~="boolean" then original=db.circle end
        self.round={db=db,profile=profile,original=original}
        saved[profile]=original
    end
    if db.circle~=true then
        self.round.original=db.circle;saved[profile]=db.circle
        db.circle=true;self.round.pending=true
    end
    if self.round.pending then
        M:SetMinimapMask(false);M:UpdateSettings()
        self.round.pending=nil
    end
    self.shapeStatus="ElvUI round shape active; disabling artwork restores its previous shape."
end

function Maps:Tick()
    local module=J.Core.modules.minimap
    if not module then return end
    self:RoundShape(module)
    self:Layer(module)
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
