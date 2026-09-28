local _, J = ...
local S = {keys={"targetTargetFrame","partyFrames"},groups={},status={}}
J.SmallFrames = S
S.properties={smallFrameArt=true,smallFrameWeight=true,smallFramePadding=true}
J.Core.properties.smallFrameArt=J.Core:Copy(J.Core.properties.castBarArt)
J.Core.properties.smallFrameWeight={.25,2}
J.Core.properties.smallFramePadding={0,8}
for _,property in ipairs({"smallFrameArt","smallFrameWeight","smallFramePadding"}) do
    J.Core.propertyOrder[#J.Core.propertyOrder+1]=property
end
local supported={width=true,height=true,x=true,y=true,scale=true,opacity=true,shown=true,
    strata=true,level=true,layer=true,portraitMode=true,portrait=true,portraitSource=true,
    unitFrameShown=true,unitFrameSource=true,unitFrameWidth=true,unitFrameHeight=true,
    unitFrameX=true,unitFrameY=true,unitFrameStrata=true}
function S:IsKey(key) return key=="targetTargetFrame" or key=="partyFrames" end
function S:Supports(property) return supported[property] or self.properties[property] or false end

local function usable(frame) return J.Core:IsUsableFrame(frame) end
local function rect(frame)
    if not usable(frame) then return end
    local x,y,w,h=frame:GetRect()
    local scale=frame:GetEffectiveScale()
    if not J.Core:IsNumber(x) or not J.Core:IsNumber(y) or not J.Core:IsNumber(w)
        or not J.Core:IsNumber(h) or not J.Core:IsNumber(scale) or w<=0 or h<=0 or scale<=0 then return end
    return {x=x,y=y,w=w,h=h,scale=scale}
end
local function same(a,b)
    if not a or not b then return false end
    for key,value in pairs(a) do if b[key]~=value then return false end end
    for key,value in pairs(b) do if a[key]~=value then return false end end
    return true
end
local ranks={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8}
local function layer(candidate,host,requested,offset)
    local strata,level="LOW",0
    local function inspect(frame)
        if not usable(frame) or type(frame.GetFrameLevel)~="function" then return end
        local s,l=frame:GetFrameStrata(),frame:GetFrameLevel()
        if not J.Core:IsSafe(s) or not ranks[s] or not J.Core:IsNumber(l) then return end
        if requested~="AUTO" then
            if s==requested then level=math.max(level,l) end
        elseif ranks[s]>ranks[strata] then strata,level=s,l
        elseif s==strata then level=math.max(level,l) end
    end
    inspect(candidate.root);inspect(candidate.health);inspect(candidate.power);inspect(candidate.chrome);inspect(host)
    return requested=="AUTO" and strata or requested,level+offset
end

-- Use the public bar rectangles, never their changing fill textures or values.
-- Detached/inset power stays native; only a full-width adjacent stack is joined.
function S:Geometry(candidate,kind,config)
    local parentScale=UIParent:GetEffectiveScale()
    if not J.Core:IsNumber(parentScale) or parentScale<=0 then return end
    if kind=="border" then
        local bar=candidate.health
        if not usable(bar) or type(bar.GetStatusBarTexture)~="function" then return end
        local h=rect(bar)
        if not h then return end
        local left,right,bottom=h.x,h.x+h.w,h.y
        local power=candidate.power
        if usable(power) and J.Core:IsSafe(power:IsShown()) and power:IsShown() then
            local p=rect(power)
            if p then
                local ratio=p.scale/h.scale
                -- Stock party/ToT mana extends four pixels left of health.
                local tolerance=candidate.source=="BLIZZARD" and 8 or 3
                if math.abs(p.x*ratio-h.x)<=tolerance and math.abs(p.w*ratio-h.w)<=tolerance
                    and math.abs((p.y+p.h)*ratio-h.y)<=8 and p.y*ratio<h.y then bottom=p.y*ratio end
                if bottom~=h.y then left=math.min(left,p.x*ratio);right=math.max(right,(p.x+p.w)*ratio) end
            end
        end
        return {anchor=bar,host=bar,w=right-left,h=h.h+h.y-bottom,scale=h.scale/parentScale,
            x=left-h.x+config.unitFrameX,y=config.unitFrameY,mirror=candidate.fixedUnit=="targettarget"}
    end
    local p=candidate.portrait
    if not p or not usable(p.region) or not usable(p.host) then return end
    local bounds=rect(p.bounds)
    if not bounds then return end
    local diameter=math.max(bounds.w,bounds.h)*(p.fit or 1)
    local opening=p.shape=="PLAYER" and 60 or 58
    local w,h=config.width*diameter/opening,config.height*diameter/opening
    local mirror=p.mirror==true
    return {anchor=p.bounds,host=p.host,w=w,h=h,scale=bounds.scale/parentScale*config.scale,
        x=config.x/config.scale+(128-(mirror and 102 or 154))/256*w,
        y=config.y/config.scale+(148-128)/256*h,mirror=mirror,shape=p.shape or "ROUND"}
end

function S:Create(key,kind)
    local module={key=key.."."..kind}
    local ok,frame=pcall(CreateFrame,"Frame",nil,UIParent,"DisableUntrustedLayoutScriptsTemplate")
    if not ok or not frame then frame=CreateFrame("Frame",nil,UIParent) end
    if frame.SetFixedFrameStrata then frame:SetFixedFrameStrata(true) end
    if frame.SetFixedFrameLevel then frame:SetFixedFrameLevel(true) end
    local textures={}
    if kind=="border" then
        for row=1,3 do for col=1,3 do
            if row~=2 or col~=2 then textures[row..col]=frame:CreateTexture(nil,"ARTWORK") end
        end end
    else textures.main=frame:CreateTexture(nil,"ARTWORK") end
    J.Core:FinishCreate(module,frame,textures)
    return module
end

function S:Paint(module,kind,id,config,layout)
    local g=module.geometry
    module.assetOK=true
    if kind=="border" then
        local entry=J.UnitSkinCatalog.entries[id]
        if layout then
            local pieces=J.CastBars:FitPieces(entry,g.w,g.h,config.smallFrameWeight,config.smallFramePadding,g.mirror,config.unitFrameWidth,config.unitFrameHeight)
            for name,p in pairs(pieces) do
                local t=module.textures[name]
                t:ClearAllPoints();t:SetPoint("TOPLEFT",module.frame,"TOPLEFT",p.x,-p.y);t:SetSize(p.w,p.h)
                t:SetTexCoord(p.u1,p.u2,p.v1,p.v2)
            end
        end
        for _,t in pairs(module.textures) do if t:SetTexture(entry.cast)==false then module.assetOK=false end end
    else
        local t=module.textures.main
        if layout then
            t:ClearAllPoints();t:SetAllPoints(module.frame);t:SetDrawLayer(config.layer)
            local u1,u2=J.Portraits:TexCoords(g.shape=="PLAYER" and "player" or "target")
            if g.mirror then u1,u2=u2,u1 end
            t:SetTexCoord(u1,u2,0,1)
        end
        if t:SetTexture(J.PortraitCatalog.entries[id].texture)==false then module.assetOK=false end
    end
    module.id=id
end

function S:Update(key,kind,state,candidate,config,combat,changed)
    local module=state.records[candidate.root]
    local g
    if combat then g=module and module.geometry else g=self:Geometry(candidate,kind,config) end
    local unit=J.SmallFrameAnchors:Unit(candidate)
    if not g then
        if module then module.active=false;J.Core:SyncVisibility(module,nil) end
        if combat then J.Core.dirty=true end
        return false
    end
    if not module then
        if combat then J.Core.dirty=true;return false end
        module=table.remove(state.pool) or self:Create(key,kind)
        module.geometry=nil;module.id=nil
        state.records[candidate.root]=module
    end
    local layout=not combat and (changed or module.assetOK==false or not same(g,module.geometry))
    module.candidate=candidate
    local present=unit and J.Portraits:HasToken(unit)
    local id=module.id or "FACTION_NEUTRAL"
    if present then
        if kind=="border" and config.smallFrameArt~="MATCH" then id=config.smallFrameArt
        else id=J.Portraits:Resolve({unit=unit,portraitMode=config.portraitMode,portrait=config.portrait}) end
    end
    if layout then
        module.geometry=g
        local f=module.frame
        f:SetScale(g.scale);f:SetSize(g.w,g.h);f:ClearAllPoints()
        local point=kind=="border" and "TOPLEFT" or "CENTER"
        f:SetPoint(point,g.anchor,point,g.x,g.y)
        module.applied={shown=true,opacity=config.opacity}
        self:Paint(module,kind,id,config,true)
    elseif module.id~=id then
        if not combat or not module.frame:IsProtected() then self:Paint(module,kind,id,config,false)
        else J.Core.dirty=true end
    end
    local strata,level=layer(candidate,g.host,kind=="border" and config.unitFrameStrata or "AUTO",kind=="border" and 1 or config.level)
    -- Portrait strata is relative to its provider by default; a saved override
    -- remains available without ever changing provider frame levels.
    local overrides=J.ProfileManager.current.modules[key]
    if kind=="portrait" and not combat and overrides and overrides.strata then
        strata,level=layer(candidate,g.host,config.strata,config.level)
    elseif kind=="portrait" and combat and state.portraitStrata then
        strata,level=layer(candidate,g.host,state.portraitStrata,config.level)
    end
    if module.frame:GetFrameStrata()~=strata or module.frame:GetFrameLevel()~=level then
        if not combat or not module.frame:IsProtected() then module.frame:SetFrameStrata(strata);module.frame:SetFrameLevel(level)
        else J.Core.dirty=true end
    end
    local visible,alpha=J.SmallFrameAnchors:Visible(candidate.root)
    local part=kind=="portrait" and candidate.portrait and candidate.portrait.region or candidate.health
    local partVisible,partAlpha=J.SmallFrameAnchors:Visible(part)
    module.unit, module.active=unit,true
    J.Core:SyncVisibility(module,present and visible and partVisible and {visible=true,alpha=math.min(alpha,partAlpha)} or nil)
    return true
end

function S:TickKind(key,kind,group,config,combat)
    local state=group[kind]
    local enabled=kind=="border" and config.unitFrameShown or kind=="portrait" and config.shown
    if not state and not enabled then return "off" end
    state=state or {records={},pool={}};group[kind]=state
    if not enabled then
        for _,m in pairs(state.records) do m.active=false;J.Core:SyncVisibility(m,nil) end
        return "off"
    end
    local changed=not same(config,state.config)
    if not combat then
        local source=kind=="border" and config.unitFrameSource or config.portraitSource
        local cached=group.discovery[source]
        if not cached then
            local candidates,provider=J.SmallFrameAnchors:Resolve(key,source)
            cached={candidates=candidates,provider=provider};group.discovery[source]=cached
        end
        state.candidates,state.provider=cached.candidates,cached.provider
        state.config=J.Core:Copy(config)
        local overrides=J.ProfileManager.current.modules[key]
        state.portraitStrata=overrides and overrides.strata
    end
    local seen,attached,shown={},0,0
    for _,candidate in ipairs(state.candidates or {}) do
        seen[candidate.root]=true
        local ok=J.Core:Protect(key.." "..kind,function()
            if self:Update(key,kind,state,candidate,config,combat,changed) then attached=attached+1 end
        end)
        local m=state.records[candidate.root]
        if not ok and m then m.active=false;J.Core:Protect("small frame cleanup",function() J.Core:SyncVisibility(m,nil) end) end
        if m and m.nativeVisible then shown=shown+1 end
    end
    for root,m in pairs(state.records) do
        if not seen[root] then
            m.active=false;J.Core:SyncVisibility(m,nil)
            if not combat then state.records[root]=nil;state.pool[#state.pool+1]=m end
        end
    end
    if attached==0 then return combat and "attachment waits until combat ends" or (kind=="portrait" and "enable separate portraits in your UI addon" or "waiting for party / Target of Target bars") end
    return (state.provider or "Provider")..": "..shown.." visible / "..attached.." attached"
end

function S:Tick()
    local combat=InCombatLockdown()
    for _,key in ipairs(self.keys) do
        local config=J.ThemeManager:Read(key)
        local group=self.groups[key]
        if group or config.shown or config.unitFrameShown then
            group=group or {};self.groups[key]=group
            if combat then config=group.config or {shown=false,unitFrameShown=false}
            else group.config=config;group.discovery={} end
            local parts={}
            for _,kind in ipairs({"border","portrait"}) do
                local ok=J.Core:Protect(key.." "..kind.." discovery",function() parts[kind]=self:TickKind(key,kind,group,config,combat) end)
                if not ok then
                    parts[kind]="unavailable; see /jf status"
                    for _,m in pairs(group[kind] and group[kind].records or {}) do
                        J.Core:Protect("small frame cleanup",function() J.Core:SyncVisibility(m,nil) end)
                    end
                end
            end
            group.borderStatus,group.portraitStatus=parts.border,parts.portrait
            self.status[key]="Border: "..parts.border.." | Portrait: "..parts.portrait
        else self.status[key]="off" end
    end
end
