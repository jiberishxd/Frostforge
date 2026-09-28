local addonName, J = ...
-- Keep the addon folder and saved-variable keys stable for existing installs.
J.Brand = { name="Jiberish's Frostforge", shortName="Frostforge", website="https://theigloo.io" }
local Core = {
    version = "0.9.7",
    modules = {}, clients = {}, owned = {}, notices = {},
    order = { "minimap", "playerFrame", "targetFrame", "focusFrame", "actionHub" },
    propertyOrder = { "width", "height", "x", "y", "scale", "anchor", "point", "relativePoint", "strata", "level", "layer", "opacity", "shown", "portraitMode", "portrait", "portraitSource", "hubMode", "hub", "hubSource", "minimapMode", "minimap", "unitFrameShown", "unitFrameSource", "unitFrameFill", "unitFrameWidth", "unitFrameHeight", "unitFrameInset", "unitFrameX", "unitFrameY", "castBarShown", "castBarSource", "castBarStyle", "castBarArt", "castBarWeight", "castBarPadding", "castBarWidth", "castBarHeight", "unitFrameStrata", "castBarStrata", "castBarLevel", "blizzardPortraitHidden", "blizzardPortraitFrameHidden", "blizzardNameEnabled", "blizzardNameX", "blizzardNameY", "blizzardNameSize", "blizzardNameAlign", "blizzardNameOutline", "blizzardStone" },
    dirty = true,
}
J.Core = Core

local points = { CENTER=true, TOP=true, BOTTOM=true, LEFT=true, RIGHT=true,
    TOPLEFT=true, TOPRIGHT=true, BOTTOMLEFT=true, BOTTOMRIGHT=true }
Core.properties = {
    width={16,2048}, height={16,2048}, x={-2048,2048}, y={-2048,2048}, scale={0.25,3}, opacity={0,1},
    point=points, relativePoint=points,
    anchor={FRAME=true,SCREEN=true},
    strata={BACKGROUND=true,LOW=true,MEDIUM=true,HIGH=true,DIALOG=true,FULLSCREEN=true,FULLSCREEN_DIALOG=true,TOOLTIP=true},
    level={0,128,integer=true},
    layer={BACKGROUND=true,BORDER=true,ARTWORK=true,OVERLAY=true},
    shown={boolean=true},
}

function Core:IsSafe(value)
    return not issecretvalue or not issecretvalue(value)
end

function Core:IsNumber(value)
    return self:IsSafe(value) and type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Core:Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = self:Copy(v) end
    return result
end

function Core:ValidateProperty(property, value)
    if not self:IsSafe(property) or not self:IsSafe(value) then return nil end
    local rule = self.properties[property]
    if not rule then return nil end
    if rule[1] then
        if type(value) == "string" then value = tonumber(value) end
        if self:IsNumber(value) and value >= rule[1] and value <= rule[2]
            and (not rule.integer or value == math.floor(value)) then return value end
    elseif rule.hex then
        if type(value)=="string" then
            local hex=value:gsub("^#",""):upper()
            if #hex==6 and hex:match("^%x+$") then return hex end
        end
    elseif rule.boolean then
        if value == true or value == "true" or value == "on" then return true end
        if value == false or value == "false" or value == "off" then return false end
    elseif type(value) == "string" then
        value = value:upper()
        -- Cast borders now have one Bold style. Preserve old saved profiles,
        -- commands and backups without keeping the retired rendering variants.
        if property=="castBarStyle" and (value=="SLIM" or value=="CARVED") then value="CAPPED" end
        if rule[value] then return value end
    end
end

function Core:PropertyHelp(property)
    local rule = self.properties[property]
    if not rule then return "Properties: " .. table.concat(self.propertyOrder, ", ") end
    if rule[1] then return property .. ": choose " .. (rule.integer and "a whole number" or "a number") .. " from " .. rule[1] .. " to " .. rule[2] .. "." end
    if rule.boolean then return property .. ": on or off." end
    if rule.hex then return property .. ": use a six-digit color such as #0070DE." end
    local values = {}
    for value in pairs(rule) do values[#values + 1] = value end
    table.sort(values)
    return property .. ": " .. table.concat(values, ", ")
end

function Core:Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff9edfff" .. J.Brand.name .. "|r " .. message) end
end

function Core:Notice(key, message)
    if self.notices[key] ~= message then self.notices[key] = message; self:Print(key .. ": " .. message) end
end

function Core:Protect(key, fn)
    local ok, errorText = pcall(fn)
    if not ok then
        local message = "Unavailable/restricted frame operation."
        if self:IsSafe(errorText) and type(errorText) == "string" then message = errorText:sub(1,500) end
        self:Notice(key, message)
    end
    return ok
end

function Core:RegisterModule(module)
    assert(not self.modules[module.key], "Duplicate component")
    self.modules[module.key] = module
end

-- This gate is also mandatory for any future hook-supplied Blizzard frame.
-- Optional full unit skins observe native texture redraws through secure hooks.
function Core:IsUsableFrame(frame)
    if not self:IsSafe(frame) or (type(frame) ~= "table" and type(frame) ~= "userdata") then return false end
    if type(frame.IsForbidden) ~= "function" then return false end
    local ok, forbidden = pcall(frame.IsForbidden, frame)
    return ok and self:IsSafe(forbidden) and forbidden == false
end

function Core:ReadAnchor(key)
    local external, reason, handled = J.AddOnAnchors:Resolve(key)
    if handled and not external then return nil,reason end
    local frame,name
    if external then frame,name = external.frame,external.name
    else frame,name,reason = self.client:Resolve(key) end
    if not frame then return nil, reason or "Anchor unavailable" end
    -- The adapters check too; recheck before reading any geometry.
    if not self:IsUsableFrame(frame) or not self:IsUsableFrame(UIParent) then return nil, "Forbidden anchor" end
    local bounds = external and external.bounds or frame
    if not self:IsUsableFrame(bounds) then return nil,"Portrait bounds unavailable" end
    local w, h, scale, parentScale = bounds:GetWidth(), bounds:GetHeight(), frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
    if not self:IsNumber(w) or not self:IsNumber(h) or not self:IsNumber(scale) or not self:IsNumber(parentScale)
        or w <= 0 or h <= 0 or scale <= 0 or parentScale <= 0 then return nil, "Geometry unavailable" end
    local visible = frame:IsVisible()
    local alpha
    if frame.GetEffectiveAlpha then alpha=frame:GetEffectiveAlpha() else alpha=frame:GetAlpha() end
    if not self:IsSafe(visible) or not self:IsNumber(alpha) then return nil, "Visibility unavailable" end
    if external then
        visible = visible and J.AddOnAnchors:Visible(external)
        local rootAlpha = external.root:GetEffectiveAlpha()
        if not self:IsNumber(rootAlpha) then return nil,"Root visibility unavailable" end
        alpha = math.min(alpha,rootAlpha)
    else visible = visible and self.client:PortraitVisible(key,frame) end
    visible=visible and J.Portraits:HasUnit(key)
    local providerStrata,providerLevel
    if external and external.source=="ELLESMERE" then
        local strata,level=frame:GetFrameStrata(),frame:GetFrameLevel()
        if self:IsSafe(strata) and type(strata)=="string" and self.properties.strata[strata] then providerStrata=strata end
        if self:IsNumber(level) then providerLevel=math.max(0,level-1) end
    end
    return { frame=frame, name=name, w=w, h=h, scale=scale, parentScale=parentScale, visible=visible == true, alpha=alpha,
        source=external and external.source or "BLIZZARD", portraitFit=external and external.portrait and external.fit or nil,
        portraitShape=external and external.shape,portraitMirror=external and external.mirror,
        providerStrata=providerStrata,providerLevel=providerLevel }
end

function Core:FinishCreate(module, frame, textures)
    assert(not InCombatLockdown(), "Attachment deferred in combat")
    assert(frame:GetParent() == UIParent and not self.owned[frame], "Invalid artwork ownership")
    self.owned[frame] = module.key
    frame:EnableMouse(false)
    if frame.EnableMouseWheel then frame:EnableMouseWheel(false) end
    if frame.EnableKeyboard then frame:EnableKeyboard(false) end
    frame:SetFrameLevel(0)
    frame:Hide()
    module.frame, module.textures = frame, textures
    for _, texture in pairs(textures) do
        assert(texture:GetParent() == frame, "Invalid texture ownership")
    end
    -- Debug regions belong to the same artwork frame; no interactive debug widgets.
    module.outline = {}
    for i = 1,4 do
        local edge = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        edge:SetColorTexture(1,0.25,0.8,1)
        edge:Hide()
        module.outline[i] = edge
    end
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetJustifyH("LEFT")
    label:SetTextColor(1,0.9,0.55,1)
    label:SetWidth(450)
    if module.key == "minimap" then label:SetPoint("TOPRIGHT",frame,"TOPLEFT",-12,0)
    elseif module.key == "targetFrame" or module.key == "focusFrame" then label:SetPoint("TOPLEFT",frame,"BOTTOMLEFT",0,-4)
    else label:SetPoint("BOTTOMLEFT",frame,"TOPLEFT",0,4) end
    label:Hide()
    module.debugLabel = label
end

-- Layout only addon-owned artwork. Endcaps use height-based sizing; the spans
-- between them absorb width changes. Native frames are never repositioned.
function Core:PieceGeometry(config, piece)
    if not piece then return 0,0,config.width,config.height,0,1,0,1,0 end
    local scale = math.min(config.height/config.designHeight,config.width/config.minimumWidth)
    local x = config.width*piece.leftAnchor + piece.leftOffset*scale
    local right = config.width*piece.rightAnchor + piece.rightOffset*scale
    local y = piece.y*scale + (config.height-config.designHeight*scale)
    return x,y,right-x,piece.height*scale,piece.u1,piece.u2,piece.v1,piece.v2,piece.order
end

function Core:UpdateDebug(module, snapshot, config)
    local frame = module.frame
    local px = 1 / (snapshot.scale * config.scale)
    local anchors = {
        {"TOPLEFT","TOPRIGHT",true}, {"BOTTOMLEFT","BOTTOMRIGHT",true},
        {"TOPLEFT","BOTTOMLEFT",false}, {"TOPRIGHT","BOTTOMRIGHT",false},
    }
    for i, edge in ipairs(module.outline) do
        local pair = anchors[i]
        edge:ClearAllPoints()
        edge:SetPoint(pair[1],frame,pair[1],0,0)
        edge:SetPoint(pair[2],frame,pair[2],0,0)
        if pair[3] then edge:SetHeight(px) else edge:SetWidth(px) end
        edge:SetShown(J.ProfileManager.current.debug)
    end
    self:UpdateDebugText(module,snapshot,config)
    module.debugLabel:SetShown(J.ProfileManager.current.debug)
    module.debugApplied = J.ProfileManager.current.debug
end

function Core:UpdateDebugText(module,snapshot,config)
    local state
    if not config.shown then state = "component hidden; debug outline only"
    elseif not snapshot.visible or snapshot.alpha <= 0 then state = "native anchor hidden; debug outline only"
    elseif not module.assetOK then state = "artwork unavailable; debug outline only"
    else state = "artwork visible" end
    local text = string.format(
        "%s | %.1f x %.1f | scale %.2f (effective %.3f)\nAnchor %s: %s -> %s\nX/Y %.1f / %.1f | %s / level %d / %s | %s\n%s\nVisibility/scale: %s | mirrored: %s",
        module.key, config.width, config.height, config.scale, snapshot.scale * config.scale,
        config.anchor == "SCREEN" and "UIParent" or snapshot.name,
        config.point, config.relativePoint, config.x, config.y, config.strata, config.level, config.layer,
        state, config.texture, snapshot.name, config.mirror and "yes" or "no")
    if module.debugText ~= text then
        module.debugLabel:SetText(text)
        module.debugText = text
    end
end

function Core:Apply(module, snapshot)
    if InCombatLockdown() then self.dirty = true; return end
    if not module.frame then module:Create() end
    local frame, config = module.frame, J.ThemeManager:Resolve(module.key)
    assert(self.owned[frame] == module.key, "Only owned artwork may be modified")
    if module.key == "minimap" then
        -- Register the shared opening to the native map diameter. User size and
        -- scale remain independent multipliers; never resize the map itself.
        local fit = math.min(snapshot.w,snapshot.h)/198
        config.width,config.height = config.width*fit,config.height*fit
    end
    J.AddOnAnchors:Fit(module.key,config,snapshot)
    frame:SetSize(config.width,config.height)
    -- Artwork uses the native anchor's UI units. Decorative scale changes its
    -- size independently; divide offsets so scale does not move the anchor.
    frame:SetScale(snapshot.scale / snapshot.parentScale * config.scale)
    frame:ClearAllPoints()
    local positionAnchor = config.anchor == "SCREEN" and UIParent or snapshot.frame
    frame:SetPoint(config.point,positionAnchor,config.relativePoint,config.x/config.scale,config.y/config.scale)
    frame:SetFrameStrata(config.strata)
    frame:SetFrameLevel(config.level)
    if config.unit then
        local id, path = J.Portraits:Resolve(config)
        config.texture, module.portraitID = path, id
    elseif module.key == "actionHub" then
        local id, path = J.Hubs:Resolve(config)
        config.texture, module.hubID = path, id
    elseif module.key == "minimap" then
        local id, path = J.Minimaps:Resolve(config)
        config.texture, module.minimapID = path, id
    end
    module.assetOK = true
    for name, texture in pairs(module.textures) do
        local piece = config.pieces and config.pieces[name]
        local x,y,w,h,u1,u2,v1,v2,order = self:PieceGeometry(config,piece)
        if config.unit then u1,u2 = J.Portraits:TexCoords(config.portraitAtlasUnit or (config.roundPortrait and "target" or config.unit)) end
        if config.mirror then x,u1,u2 = config.width-x-w,u2,u1 end
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT",frame,"TOPLEFT",x,-y)
        texture:SetSize(w,h)
        texture:SetDrawLayer(config.layer,order)
        texture:SetTexCoord(u1,u2,v1,v2)
        if texture:SetTexture(config.texture) == false then module.assetOK = false end
    end
    module.applied, module.snapshot, module.attachment = config, snapshot, snapshot
    module.status = module.assetOK and "attached" or "Artwork could not be loaded"
    if not module.assetOK then self:Notice(module.key,module.status) end
    self:UpdateDebug(module,snapshot,config)
    self:SyncVisibility(module,snapshot)
end

function Core:SyncVisibility(module, snapshot)
    module.nativeVisible=snapshot and snapshot.visible and snapshot.alpha>0 or false
    local frame, config = module.frame, module.applied
    if not frame or not config then return end
    -- Anchoring can create protection dependencies. Never assume an owned
    -- frame remains unprotected; defer these writes if the client protects it.
    if InCombatLockdown() and frame:IsProtected() then self.dirty = true; return end
    local debug = module.debugApplied
    if debug and snapshot then self:UpdateDebugText(module,snapshot,config) end
    local nativeVisible = snapshot and snapshot.visible and snapshot.alpha > 0
    local showArt = nativeVisible and config.shown and module.assetOK or false
    for _, texture in pairs(module.textures) do
        if texture:IsShown() ~= showArt then texture:SetShown(showArt) end
    end
    local alpha = debug and 1 or (snapshot and snapshot.alpha or 0) * config.opacity
    if module.lastAlpha ~= alpha then frame:SetAlpha(alpha); module.lastAlpha = alpha end
    local shown = snapshot ~= nil and (showArt or debug) or false
    if frame:IsShown() ~= shown then frame:SetShown(shown) end
end

local function geometryChanged(a,b)
    return not a or a.frame ~= b.frame or a.w ~= b.w or a.h ~= b.h
        or a.scale ~= b.scale or a.parentScale ~= b.parentScale
        or a.source ~= b.source or a.portraitFit ~= b.portraitFit
        or a.portraitShape~=b.portraitShape or a.portraitMirror~=b.portraitMirror
        or a.providerStrata~=b.providerStrata or a.providerLevel~=b.providerLevel
end

function Core:Tick()
    if not self.started or not self.client then return end
    J.ThemeManager.readPass = {}
    local combat, refresh = InCombatLockdown(), self.dirty
    if not combat then self.dirty = false end
    for _, key in ipairs(self.order) do
        local module = self.modules[key]
        local ok = self:Protect(key,function()
            local snapshot, reason = self:ReadAnchor(key)
            -- A failed observation does not undo the last successful SetPoint.
            -- Keep that attachment separately so a temporary combat read failure
            -- can recover without creating or moving a protected dependency.
            local attached=module.attachment
            if not snapshot then
                module.status, module.snapshot = reason, nil
                self:SyncVisibility(module,nil)
            elseif not combat and (refresh or geometryChanged(attached,snapshot)) then
                self:Apply(module,snapshot)
            else
                if combat and (refresh or geometryChanged(attached,snapshot)) then self.dirty = true end
                local sameAnchor = attached and attached.frame == snapshot.frame and attached.source == snapshot.source
                module.snapshot=sameAnchor and snapshot or nil
                if sameAnchor then module.status=module.assetOK and "attached" or "Artwork could not be loaded" end
                -- Identity changes only replace addon texture bytes. Recheck
                -- protection because anchoring may establish a secure dependency.
                if sameAnchor and module.applied and module.applied.unit then
                    J.Portraits:Refresh(module,combat)
                elseif sameAnchor and module.applied and key == "actionHub" then
                    J.Hubs:Refresh(module,combat)
                elseif sameAnchor and module.applied and key == "minimap" then
                    J.Minimaps:Refresh(module,combat)
                end
                self:SyncVisibility(module,sameAnchor and snapshot or nil)
            end
        end)
        if not ok then
            module.status = "Failed; see /jf status"
            -- Hide stale artwork without touching its Blizzard anchor.
            self:Protect(key .. " cleanup",function() self:SyncVisibility(module,nil) end)
        end
    end
    if J.UnitSkins then J.UnitSkins:Tick() end
    if J.BlizzardUnits then J.BlizzardUnits:Tick() end
    if J.CastBars then J.CastBars:Tick() end
    self:Protect("minimap presentation",function() J.Minimaps:Tick() end)
    self:Protect("settings access",function() J.Access:Tick() end)
    J.ThemeManager.readPass = nil
    self:Protect("quick setup",function() J.Setup:Tick() end)
end

function Core:RequestRefresh(immediate)
    self.dirty = true
    if immediate then self:Tick() end
    if J.SettingsUI then
        self:Protect("settings",function()
            if J.SettingsUI.pendingOpen and not InCombatLockdown() then J.SettingsUI:Open() end
            J.SettingsUI:Refresh()
        end)
    end
end

function Core:Status()
    self:Print(self.version .. " | " .. (self.client and self.client.id or "unsupported client") .. " | " .. J.ProfileManager.current.theme)
    if self.client then self:Print("Source baseline: " .. self.client.revision) end
    self:Print(J.ProfileManager.notice)
    self:Print("Character profile: "..J.ProfileManager:ProfileName())
    if InCombatLockdown() and self.dirty then self:Print("Artwork changes queued until combat ends.") end
    for _, key in ipairs(self.order) do
        local module = self.modules[key]
        self:Print(key .. ": " .. (module.status or "waiting for anchor"))
        if module.debugLabel then self:Print(module.debugLabel:GetText()) end
        if J.Portraits:IsUnitKey(key) then
            local config=J.ThemeManager:Resolve(key)
            local source=module.snapshot and module.snapshot.source or "unavailable"
            local visible=module.nativeVisible
            self:Print(key.." portrait: "..(config.shown and "on" or "off").." | requested "..config.portraitSource.." | resolved "..source.." | "..(visible and "visible" or "hidden"))
            self:Print(key.." unit frame: "..(config.unitFrameShown and "on" or "off").." | requested "..config.unitFrameSource.." | "..(J.UnitSkins.status[key] or "waiting").." | fill "..config.unitFrameFill)
        end
    end
    if J.CastBars then
        for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do self:Print(key.." cast border: "..(J.CastBars.status[key] or "waiting")) end
    end
    if J.UnitSkins.stockStatus then self:Print(J.UnitSkins.stockStatus) end
    if J.BlizzardUnits then
        for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do self:Print(key.." stock appearance: "..(J.BlizzardUnits.status[key] or "unchanged")) end
        for key,message in pairs(J.BlizzardUnits.placementStatus or {}) do self:Print(key.." placement: "..message) end
    end
    for key, message in pairs(self.notices) do self:Print(key .. ": " .. message) end
    if self.client and self.client.id == "forever" then
        self:Print("Forever build 69913 has a reported settings-loading failure. /jf export backs up Phase 1 settings.")
    end
end

function Core:Command(input)
    if not self.started then self:Print("Waiting for player login."); return end
    local command, rest = input:match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    local ok, message
    if command == "" or command == "options" or command == "config" then
        J.SettingsUI:Toggle(); return
    elseif command == "theme" then ok, message = J.ThemeManager:Load(rest)
    elseif command == "reloadtheme" then
        self:RequestRefresh(true); ok = true
    elseif command == "debug" then
        local value = not J.ProfileManager.current.debug
        if rest ~= "" then value = self:ValidateProperty("shown",rest) end
        if value == nil then self:Print("Use /jf debug [on|off]."); return end
        J.ProfileManager.current.debug = value
        self:RequestRefresh(true)
        self:Print(value and "Debug outlines on. /jf status prints the same details." or "Debug outlines off.")
        ok = true
    elseif command == "set" then
        local key, property, value = rest:match("^(%w+)%s+(%w+)%s+(%S+)$")
        if not key then self:Print("Use /jf set <component> <property> <value>."); return end
        ok, message = J.ProfileManager:Set(key,property,value)
    elseif command == "show" or command == "hide" then
        ok, message = J.ProfileManager:Set(rest,"shown",command == "show")
    elseif command == "reset" then ok, message = J.ProfileManager:Reset(rest ~= "" and rest or nil)
    elseif command == "export" then self:Print(J.ProfileManager:Export()); return
    elseif command == "import" then ok, message = J.ProfileManager:Import(rest)
    elseif command == "status" or command == "diagnostics" then self:Status(); return
    else
        self:Print("/jui opens the movable options window. Phase 1: /jf theme paladin_ret | reloadtheme | debug [on|off] | status")
        self:Print("/jf set <component> <property> <value> | show/hide <component> | reset [component] | export | import <backup>")
        self:Print("Components: " .. table.concat(self.order,", "))
        self:Print("Properties: " .. table.concat(self.propertyOrder,", "))
        self:Print("Example: /jf set actionHub width 800")
        return
    end
    if not ok then self:Print(message or "Command failed.")
    elseif InCombatLockdown() then self:Print("Saved; artwork changes will apply after combat.")
    else self:Print("Artwork configuration reapplied. /jf debug shows bounds.") end
end

function Core:Start()
    if self.started then return end
    self.started = true
    J.ProfileManager:Initialize()
    local version, build, _, interface = GetBuildInfo()
    if self:IsSafe(version) and self:IsSafe(build) and type(version) == "string" and type(build) == "string" then
        self:Print("Client " .. version .. " / build " .. build)
    end
    for _, id in ipairs({"retail","forever"}) do
        local candidate = self.clients[id]
        if candidate:Matches(interface) and (J.Build.flavor == "development" or J.Build.flavor == id) then
            self.client = candidate
        end
    end
    if not self.client then self:Notice("client","Unsupported client/package; no artwork attached."); return end
    if interface ~= self.client.baseline then
        self:Notice("client","Interface differs from the researched baseline; in-game validation required.")
    end
    if J.ProfileManager.writable then
        if J.ProfileManager.firstRun and JiberishUIDB.setupVersion==nil then JiberishUIDB.setupVersion=0 end
        J.Setup.pending=JiberishUIDB.setupVersion==0 or nil
    end
    self:RequestRefresh(true)
    self:Print("Portrait backgrounds loaded. /jui opens options | /jf debug | /jf help")
end

-- Event driver has no visual regions. The separate options window is created on demand.
local driver = CreateFrame("Frame",nil,UIParent)
driver:EnableMouse(false)
driver:SetSize(1,1)
Core.driver = driver
for _, event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED",
    "PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UNIT_PORTRAIT_UPDATE","UNIT_FACTION",
    "UI_SCALE_CHANGED","DISPLAY_SIZE_CHANGED","EDIT_MODE_LAYOUTS_UPDATED"}) do
    Core:Protect("event " .. event,function() driver:RegisterEvent(event) end)
end
driver:SetScript("OnEvent",function(_,event,name)
    if event=="PLAYER_ENTERING_WORLD" then Core.worldReady=true end
    if event=="ADDON_LOADED" or event=="PLAYER_LOGIN" then
        Core:Protect("shared media",function() J.Media:RegisterShared() end)
    end
    if event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and name == addonName and IsLoggedIn and IsLoggedIn()) then
        Core:Protect("startup",function() Core:Start() end)
    elseif Core.started then
        if event=="PLAYER_TARGET_CHANGED" or event=="PLAYER_FOCUS_CHANGED" or event=="UNIT_PORTRAIT_UPDATE" or event=="UNIT_FACTION" then
            Core:Tick()
            if J.SettingsUI.frame and J.SettingsUI.frame:IsShown() then
                Core:Protect("settings",function() J.SettingsUI:Refresh() end)
            end
        else Core:RequestRefresh(true) end
    end
end)
local elapsedTime,castElapsed = 0,0
driver:SetScript("OnUpdate",function(_,elapsed)
    elapsedTime = elapsedTime + elapsed
    castElapsed = castElapsed + elapsed
    if castElapsed >= .05 then
        castElapsed = 0
        if Core.started and Core.client and J.CastBars then J.CastBars:Sync() end
    end
    if elapsedTime >= 0.2 then elapsedTime = 0; Core:Tick() end
end)
SLASH_JIBERISHFANTASY1 = "/jf"
SLASH_JIBERISHFANTASY2 = "/jui"
SLASH_JIBERISHFANTASY3 = "/jiberishui"
SLASH_JIBERISHFANTASY4 = "/frostforge"
SlashCmdList.JIBERISHFANTASY = function(input) Core:Protect("command",function() Core:Command(input or "") end) end
