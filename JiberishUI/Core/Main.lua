local addon,J=...
local U,R,C,A=J.Util,J.Renderer,J.Colors,J.AdapterCommon
J.records={}; J.regionOwners={}; J.hooks={}; J.failures={}; J.active={}; J.reloadGroups={}
J.conflicts={}

function J:Failure(key,message)
    if self.failures[key]~=message then self.failures[key]=message; self:Print(key..': '..message) end
end
function J:Protect(key,fn,...)
    local args,count={...},select('#',...)
    local ok,result=xpcall(function() return fn(unpack(args,1,count)) end,function(message)
        local stack
        if debugstack then
            local captured,value=pcall(debugstack,2,12,0)
            if captured then stack=value end
        end
        return U.ErrorSummary(message,stack)
    end)
    if not ok then
        local message=result..' See /jui diagnostics; reload after updating the addon.'
        local changed=self.failures[key]~=message
        self:Failure(key,message)
        -- Forward only the sanitized summary so error collectors can identify the failure.
        if changed and geterrorhandler then pcall(geterrorhandler(), 'JiberishUI '..key..': '..message) end
    end
    return ok,result
end
function J:RequestApply()
    local alreadyQueued=self.pendingSettings
    self.pendingSettings=true
    if U.Combat() then
        if not alreadyQueued then self:Print('Appearance changes queued until combat ends.') end
        return
    end
    self:Schedule()
end
function J:ResolveRequested()
    if not self.pendingSettings and next(self.active) then return end
    for _,group in ipairs(self.Groups) do
        local config=self.Profiles:Resolve(group)
        local old=self.active[group]
        if old and old.enabled and not config.enabled then
            self.reloadGroups[group]=true -- Keep the current live state until reload.
        else self.active[group]=config; self.reloadGroups[group]=nil end
    end
    self.pendingSettings=false
    if next(self.reloadGroups) then self:Print('Disabling a module requires Reload UI. Your choice has been saved.') end
end
function J:NativeDecoration(record,region)
    local item={region=region,alpha=region:GetAlpha()}; record.decorations[#record.decorations+1]=item
    hooksecurefunc(region,'SetAlpha',function(_,alpha)
        if item.busy then return end
        if U.Number(alpha) then item.alpha=alpha end
        if record.applied and item.active~=false then item.busy=true; region:SetAlpha(0); item.busy=false end
        self:Schedule()
    end)
    return item
end
function J:Decorations(record,hidden)
    for _,item in ipairs(record.decorations) do
        item.busy=true; item.region:SetAlpha(hidden and item.active~=false and 0 or (U.Number(item.alpha) and item.alpha or 1)); item.busy=false
    end
end
function J:Refresh(record,layout)
    if record.busy or record.failed then return end
    if record.owned==false or self.conflicts[record.group] then
        if record.applied then
            record.applied=false; self:Decorations(record,false)
            for _,color in ipairs(record.colors) do C.Apply(color,{healthMode='native',powerMode='native'}) end
            for _,border in ipairs(record.borders) do R.Hide(border) end
            for _,cap in ipairs(record.endcaps or {}) do cap.texture:Hide() end
            self:Failure(record.group,'Ownership changed or a conflicting addon loaded. Updates stopped; reload to finish restoration.')
        end
        return
    end
    local config=self.active[record.group]; if not config or not config.enabled then return end
    record.busy=true
    local success=true
    if record.kind=='button' then
        success=R.Button(record.frame,config,layout)
    else
        for _,border in ipairs(record.borders) do
            local fitted
            if border.active==false then R.Hide(border);fitted=true
            elseif layout then fitted=R.Apply(border,config) else fitted=R.Refresh(border,config) end
            if border.region.GetObjectType and border.region:GetObjectType()=='Texture' and not border.region:IsShown() then R.Hide(border) end
            -- Hidden power bars can have zero geometry; they do not invalidate the main border.
            if border.required and not fitted then success=false end
        end
        for _,cap in ipairs(record.endcaps or {}) do
            local skin=J.Skins[config.skin]
            if cap.texture:SetTexture(skin.path..'ornament.tga')==false then success=false end
            cap.texture:SetVertexColor(config.tint[1],config.tint[2],config.tint[3],config.opacity)
            if layout then
                local width=cap.native:GetWidth()
                if U.Number(width) then cap.texture:SetSize(math.max(1,width*config.ornament),math.max(1,width*config.ornament/2)) end
            end
            cap.texture:SetShown(config.ornament>0)
        end
    end
    if success then
        record.applied=true; self:Decorations(record,true)
        for _,color in ipairs(record.colors) do C.Apply(color) end
    else
        record.applied=false; self:Decorations(record,false)
        for _,color in ipairs(record.colors) do C.Apply(color,{healthMode='native',powerMode='native'}) end
        for _,border in ipairs(record.borders) do R.Hide(border) end
        for _,cap in ipairs(record.endcaps or {}) do cap.texture:Hide() end
        self:Failure(record.group,'Artwork or geometry unavailable; retaining Blizzard decorations.')
    end
    if record.visibility and not record.visibility:IsShown() then for _,border in ipairs(record.borders) do R.Hide(border) end end
    record.busy=false
end
function J:RefreshSafely(record,layout)
    local ok=self:Protect(record.group,self.Refresh,self,record,layout)
    if not ok then
        record.busy=false; record.failed=true; record.applied=false
        self:Protect(record.group,self.Decorations,self,record,false)
        for _,border in ipairs(record.borders) do R.Hide(border) end
    end
end
function J:AddSilhouette(record,source)
    local value=R.CreateSilhouette(source);value.required=true
    record.borders[#record.borders+1]=value
    local item=self:NativeDecoration(record,source);value.decoration=item
    value.nativeAlpha=function()
        local _,_,_,vertexAlpha=source:GetVertexColor()
        return (U.Number(item.alpha) and item.alpha or 1)*(U.Number(vertexAlpha) and vertexAlpha or 1)
    end
    for _,method in ipairs({'SetAtlas','SetTexture','SetTexCoord','SetVertexColor','SetShown','Show','Hide'}) do
        if source[method] then hooksecurefunc(source,method,function() self:Schedule() end) end
    end
    return value
end
function J:AddContour(record,source,regions)
    local value=R.CreateContour(source,regions);value.required=true
    record.borders[#record.borders+1]=value
    for _,method in ipairs({'SetAtlas','SetTexture','SetTexCoord','SetAlpha','SetVertexColor','SetShown','Show','Hide'}) do
        if source[method] then hooksecurefunc(source,method,function() self:Schedule() end) end
    end
    return value
end
function J:SyncExternal(record,descriptor)
    record.regions=descriptor.regions or {}
    record.externalBorders=record.externalBorders or {};record.colorMap=record.colorMap or {}
    for bar,color in pairs(record.colorMap) do
        if record.regions[color.kind]~=bar then C.Apply(color,{healthMode='native',powerMode='native'}) end
    end
    for _,value in pairs(record.externalBorders) do
        value.active=false;if value.decoration then value.decoration.active=false end
    end
    local function edge(owner,region,shell)
        local key=shell or region
        local value=record.externalBorders[key]
        if not value then
            if shell then value=self:AddSilhouette(record,shell)
            else
                value=R.Create(owner,region,'external');record.borders[#record.borders+1]=value
            end
            record.externalBorders[key]=value
        end
        value.active=true;if value.decoration then value.decoration.active=true end
        return value
    end
    edge(record.frame,record.frame,record.regions.shell).required=true
    for _,p in ipairs(record.regions.portraits or {}) do edge(p.region,p.region,p.shell) end
    for _,kind in ipairs({'health','power'}) do
        local bar=record.regions[kind]
        if bar and bar.GetStatusBarTexture and not record.colorMap[bar] then
            local function config()
                if record.applied and record.owned and not record.failed and not self.conflicts[record.group] and record.regions[kind]==bar then
                    return self.active[record.group]
                end
            end
            local color=C.Attach(record.frame,bar,kind,nil,config,record.regions.unitField)
            if color then
                record.colorMap[bar]=color;record.colors[#record.colors+1]=color;self.regionOwners[bar]=record
            end
        end
    end
end
function J:Attach(descriptor)
    if U.Combat() then return end
    local existing=self.records[descriptor.frame]
    if existing then
        if existing.kind~=descriptor.kind or existing.provider~=(descriptor.provider or 'blizzard') then
            existing.owned=false
            self:Failure(descriptor.group,'Frame provider changed. Reload UI to finish switching providers.')
            return
        end
        if existing.kind=='external' or existing.kind=='externalbutton' then self:SyncExternal(existing,descriptor) end
        return
    end
    local frame,group=descriptor.frame,descriptor.group
    local config=self.active[group]
    if not config or not config.enabled then return end
    local conflict=A.Conflict(group)
    if conflict then self:Failure(group,conflict..' Module skipped.'); return end
    local record={frame=frame,group=group,kind=descriptor.kind,provider=descriptor.provider or 'blizzard',owned=true,borders={},colors={},decorations={}}
    local regions
    if descriptor.kind=='unit' or descriptor.kind=='compact' then
        local err; regions,err=A.Resolve(frame,descriptor.definition)
        if not regions then self:Failure(group,err); return end
    end
    -- Reserve before creating hooks. A partial failure cannot install duplicate hooks.
    self.records[frame]=record
    local function border(owner,region,variant,required)
        local value=R.Create(owner,region,variant); value.required=required
        record.borders[#record.borders+1]=value
        local resize=function() self:Schedule() end
        if not U.HookScript(region,'OnSizeChanged',resize) and owner~=region then
            U.HookScript(owner,'OnSizeChanged',resize)
        end
    end
    if descriptor.kind=='external' or descriptor.kind=='externalbutton' then
        self:SyncExternal(record,descriptor)
    elseif regions then
        if descriptor.kind=='compact' then border(frame,frame,'compact',true)
        else
            for _,source in ipairs(regions.decorations) do
                self:AddContour(record,source,regions)
            end
        end
        local function getConfig() return record.applied and record.owned and not self.conflicts[group] and not record.failed and self.active[group] or nil end
        local health=C.Attach(frame,regions.health,'health',regions.healthMask,getConfig)
        if health then record.colors[#record.colors+1]=health; self.regionOwners[regions.health]=record end
        if regions.power and regions.power.GetStatusBarTexture then
            local power=C.Attach(frame,regions.power,'power',regions.powerMask,getConfig)
            if power then record.colors[#record.colors+1]=power; self.regionOwners[regions.power]=record end
        end
    elseif descriptor.kind=='button' then
        if not frame.GetNormalTexture then self.records[frame]=nil; return end
        if not frame:GetNormalTexture() then frame:SetNormalTexture(J.Skins[config.skin].path..'button-normal.tga') end
        for _,method in ipairs({'SetNormalTexture','SetNormalAtlas','SetPushedTexture','SetPushedAtlas','SetHighlightTexture','SetHighlightAtlas','SetCheckedTexture','SetCheckedAtlas'}) do
            if frame[method] then hooksecurefunc(frame,method,function() self:RefreshSafely(record,false) end) end
        end
        for _,getter in ipairs({'GetNormalTexture','GetPushedTexture','GetHighlightTexture','GetCheckedTexture'}) do
            local texture=frame[getter] and frame[getter](frame)
            if texture then
                hooksecurefunc(texture,'SetAtlas',function() self:RefreshSafely(record,false) end)
                hooksecurefunc(texture,'SetTexture',function() self:RefreshSafely(record,false) end)
            end
        end
    elseif descriptor.kind=='rail' then
        border(frame,frame,'rail',true); self:NativeDecoration(record,frame.BorderArt); record.visibility=frame.BorderArt
        if frame.EndCaps then
            -- Both flavors use children; Forever gives each child its own Edit Mode system.
            for _,key in ipairs({'LeftEndCap','RightEndCap'}) do
                local parent=frame.EndCaps[key]; local region=parent and parent.Texture
                if region then
                    self:NativeDecoration(record,region)
                    local texture=parent:CreateTexture(nil,'BACKGROUND')
                    texture:SetPoint('CENTER',region,'CENTER')
                    record.endcaps=record.endcaps or {}; record.endcaps[#record.endcaps+1]={texture=texture,native=parent}
                end
            end
        end
    end
    U.HookScript(frame,'OnShow',function() self:RefreshSafely(record,not U.Combat()); self:Schedule() end)
    U.HookScript(frame,'OnSizeChanged',function() self:Schedule() end)
    self:RefreshSafely(record,true)
end
function J:InstallHooks()
    if self.Integrations then self.Integrations:InstallHooks() end
    for _,name in ipairs(A.NativeFunctions) do
        if type(_G[name])=='function' and not self.hooks[name] then
            self.hooks[name]=true
            hooksecurefunc(name,function(frame)
                local record=U.Safe(frame) and (self.records[frame] or self.regionOwners[frame])
                if record and record.owned then
                    if name=='UnitFrameHealthBar_Update' or name=='UnitFrameManaBar_UpdateType' then
                        for _,color in ipairs(record.colors) do self:Protect(record.group,C.Apply,color) end
                    else self:RefreshSafely(record,not U.Combat()) end
                end
            end)
        end
    end
    local function method(object,name)
        if not object or type(object[name])~='function' then return end
        self.hooks[object]=self.hooks[object] or {}
        if self.hooks[object][name] then return end
        self.hooks[object][name]=true; hooksecurefunc(object,name,function() self:Schedule() end)
    end
    for _,name in ipairs({'Update','CheckClassification','CheckFaction','UpdateStatus'}) do
        method(TargetFrame,name); method(FocusFrame,name)
    end
    method(PartyFrame,'InitializePartyMemberFrames'); method(CompactPartyFrame,'UpdateVisibility')
    method(SpellFlyout,'Toggle'); method(SpellFlyout,'Update')
    method(ZoneAbilityFrame,'UpdateDisplayedZoneAbilities'); method(MainActionBar,'UpdateEndCaps')
    if EditModeManagerFrame then
        method(EditModeManagerFrame,'ExitEditMode'); method(EditModeManagerFrame,'UpdateLayoutInfo')
    end
end
function J:RefreshAll()
    if not self.ready or not self.adapter then return end
    if IsLoggedIn and not IsLoggedIn() then return end
    local layout=not U.Combat()
    local discovered=A.Discover(self.adapter)
    for _,group in ipairs(self.Groups) do self.conflicts[group]=A.Conflict(group) end
    for _,record in pairs(self.records) do record.owned=false end
    for _,descriptor in ipairs(discovered) do
        local record=self.records[descriptor.frame]
        if record then record.owned=record.kind==descriptor.kind and record.provider==(descriptor.provider or 'blizzard') end
    end
    if layout then
        self:ResolveRequested(); self:InstallHooks()
        for _,descriptor in ipairs(discovered) do
            local ok=self:Protect(descriptor.group,self.Attach,self,descriptor)
            if not ok and self.records[descriptor.frame] then self.records[descriptor.frame].failed=true end
        end
    end
    for _,record in pairs(self.records) do self:RefreshSafely(record,layout) end
end
function J:Schedule()
    if self.scheduled or not self.ready then return end
    self.scheduled=true
    C_Timer.After(0,function()
        self.scheduled=false; self:Protect('lifecycle',self.RefreshAll,self)
        local settings=self.SettingsUI
        if settings and settings.panel and settings.panel:IsShown() then self:Protect('settings',settings.Refresh,settings) end
    end)
end
function J:Initialize()
    if self.ready then return end
    local version,build,_,interface=GetBuildInfo()
    self.client={version=version,build=build,interface=interface}
    self.adapter=nil
    for _,adapter in pairs(self.Adapters) do if interface==adapter.interface then self.adapter=adapter end end
    if not self.adapter or (self.Build.flavor~='development' and self.Build.flavor~=self.adapter.id) then
        self:Failure('client','This package does not support this interface version. No Blizzard frames changed.'); return
    end
    local ok,err=self.Profiles:Init(); if not ok then self:Failure('profiles',err); return end
    self.ready=true; self.pendingSettings=true
    if self.SettingsUI then self.SettingsUI:Create() end
    self:Schedule()
end
local events=CreateFrame('Frame')
for _,event in ipairs({'ADDON_LOADED','PLAYER_LOGIN','PLAYER_ENTERING_WORLD','PLAYER_REGEN_ENABLED','GROUP_ROSTER_UPDATE',
    'PLAYER_TARGET_CHANGED','PLAYER_FOCUS_CHANGED','UNIT_PET','UNIT_ENTERED_VEHICLE','UNIT_EXITED_VEHICLE','UNIT_DISPLAYPOWER',
    'UNIT_FACTION','UNIT_CONNECTION','UNIT_FLAGS','EDIT_MODE_LAYOUTS_UPDATED','UI_SCALE_CHANGED','DISPLAY_SIZE_CHANGED',
    'UPDATE_SHAPESHIFT_FORM','ACTIONBAR_PAGE_CHANGED','UPDATE_BONUS_ACTIONBAR','UPDATE_OVERRIDE_ACTIONBAR','SPELL_FLYOUT_UPDATE'}) do
    pcall(events.RegisterEvent,events,event)
end
events:SetScript('OnEvent',function(_,event,name)
    if event=='ADDON_LOADED' and name==addon then J:Initialize() end
    if event=='PLAYER_LOGIN' and not J.ready then J:Initialize() end
    J:Schedule()
end)
J.eventFrame=events
SLASH_JIBERISHUI1='/jui'; SLASH_JIBERISHUI2='/jiberishui'
SlashCmdList.JIBERISHUI=function(command)
    command=(command or ''):lower():match('^%s*(.-)%s*$')
    if command=='diagnostics' or command=='diag' then J:Print(J:Diagnostics())
    elseif command=='reload' then if U.Combat() then J:Print('Reload UI after combat.'); else ReloadUI() end
    elseif J.ready then J.SettingsUI:Open()
    else J:Print('Unavailable on this client or profile version. Use /jui diagnostics.') end
end
