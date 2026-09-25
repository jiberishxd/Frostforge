local _, J = ...
local S = { units = {}, watched = setmetatable({}, {__mode="k"}) }
J.UnitSkins = S
J.Core.properties.unitStyle = {PORTRAIT=true,FULL=true}

-- Presentation only. Never read health/power values, change bar ranges, replace
-- a StatusBar, or touch its masks/predictions/events/secure attributes.
local function usable(frame) return J.Core:IsUsableFrame(frame) end
local function capture(texture)
    if not usable(texture) then return end
    local atlas, path = texture:GetAtlas(), texture:GetTexture()
    if not J.Core:IsSafe(atlas) or not J.Core:IsSafe(path) then return end
    if atlas ~= nil and type(atlas) ~= "string" then return end
    if not atlas and type(path) ~= "string" and not J.Core:IsNumber(path) then return end
    local coords = {texture:GetTexCoord()}
    if #coords ~= 8 then return end
    for _,v in ipairs(coords) do if not J.Core:IsNumber(v) then return end end
    return {atlas=atlas,path=path,coords=coords}
end

function S:Watch(record)
    local function changed(frame)
        -- Hooks only observe redraws; all writes happen in the out-of-combat tick.
        if not usable(frame) or record.writing then return end
        record.external = true
        J.Core.dirty = true
    end
    for _,item in ipairs({{record.bar,"SetStatusBarTexture"},{record.texture,"SetTexture"},
                          {record.texture,"SetAtlas"},{record.texture,"SetTexCoord"}}) do
        local frame,method=item[1],item[2]
        local watched=self.watched[frame]
        if not watched then watched={}; self.watched[frame]=watched end
        -- Reuse a single dispatcher if the same texture is reattached later.
        if not watched[method] then
            watched[method]={}
            local listeners=watched[method]
            hooksecurefunc(frame,method,function(received)
                if not usable(received) then return end
                for current,callback in pairs(listeners) do
                    if not current.retired then callback(received) end
                end
            end)
        end
        watched[method][record]=changed
    end
end

function S:Retire(record)
    record.retired=true
    for _,frame in ipairs({record.bar,record.texture}) do
        for _,listeners in pairs(self.watched[frame] or {}) do listeners[record]=nil end
    end
end

local function write(record,callback)
    assert(not InCombatLockdown(),"Unit skin writes deferred in combat")
    if not usable(record.bar) or not usable(record.texture) then return false end
    record.writing=true
    local ok=J.Core:Protect("unit skin texture",callback)
    record.writing=false
    return ok
end

local function isOurFill(state)
    if state.atlas then return false end
    for _,entry in pairs(J.UnitSkinCatalog.entries) do
        if state.path==entry.health or state.path==entry.power then return true end
    end
    return false
end

function S:Restore(record)
    if not record.active then return true end
    if InCombatLockdown() then J.Core.dirty=true; return false end
    if not usable(record.bar) or not usable(record.texture) then return false end
    -- An external redraw supersedes our replacement. Never restore stale art
    -- over a later Blizzard atlas (vehicle/power-type changes in particular).
    if record.external then
        local latest=capture(record.texture)
        if not latest then return false end
        if not isOurFill(latest) then
            record.original,record.active,record.external=latest,false,false
            return true
        end
        record.external=false
    end
    local old=record.original
    local ok=write(record,function()
        if old.atlas then record.texture:SetAtlas(old.atlas)
        else record.texture:SetTexture(old.path) end
        record.texture:SetTexCoord(unpack(old.coords))
    end)
    if ok then record.active=false end
    return ok
end

function S:ApplyFill(record,kind,id)
    local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
    local path=entry[kind]
    if InCombatLockdown() then J.Core.dirty=true; return false end
    if not usable(record.bar) or not usable(record.texture) then return false end
    if record.external or not record.active then
        local latest=capture(record.texture)
        if not latest then return false end
        if not isOurFill(latest) then record.original=latest end
        record.active,record.external=false,false
    end
    if record.active and record.fillPath==path then return true end
    -- SetTexture on the existing fill region preserves the native mask and
    -- StatusBar's ownership of its size, fill direction and value animation.
    local loaded
    local ok=write(record,function()
        loaded=record.texture:SetTexture(path)
        record.texture:SetTexCoord(0,1,0,1)
    end)
    record.active,record.fillPath=true,path -- also restore after a partially failed write
    if not ok or loaded==false then self:Restore(record);return false end
    return true
end

-- Two owned halves follow the actual health/power anchors independently. Their
-- thirteen sections preserve sculpted endcaps while stretching only the spans.
function S:CreateTrim(key,kind)
    local trim={key=key.."."..kind.."Skin"}
    local frame=CreateFrame("Frame",nil,UIParent)
    frame:EnableMouse(false)
    local textures={}
    for row=1,(kind=="health" and 3 or 2) do
        for column=1,3 do
            local opening=(kind=="health" and row==2 or kind=="power" and row==1) and column==2
            if not opening then textures[row.."_"..column]=frame:CreateTexture(nil,"BACKGROUND") end
        end
    end
    J.Core:FinishCreate(trim,frame,textures)
    return trim
end

local function geometry(bar)
    if not usable(bar) or not usable(UIParent) then return end
    local w,h,s,p=bar:GetWidth(),bar:GetHeight(),bar:GetEffectiveScale(),UIParent:GetEffectiveScale()
    local level,strata=bar:GetFrameLevel(),bar:GetFrameStrata()
    if not J.Core:IsNumber(w) or not J.Core:IsNumber(h) or not J.Core:IsNumber(s) or not J.Core:IsNumber(p)
        or w<=0 or h<=0 or s<=0 or p<=0 or not J.Core:IsNumber(level)
        or not J.Core:IsSafe(strata) or type(strata)~="string" or not J.Core.properties.strata[strata] then return end
    return {w=w,h=h,scale=s,parentScale=p,level=level,strata=strata}
end

function S:Layout(record,key,kind,config,id,g)
    local trim=record.trim
    if not trim then trim=self:CreateTrim(key,kind);record.trim=trim end
    local f,t=trim.frame,trim.textures
    local old=record.geometry
    local changed=not old or old.w~=g.w or old.h~=g.h or old.scale~=g.scale or old.parentScale~=g.parentScale
        or old.capScale~=g.capScale
    local applied=trim.applied
    if changed or record.id~=id or not applied or applied.strata~=config.strata
        or applied.level~=config.level or applied.layer~=config.layer or trim.debugApplied~=J.ProfileManager.current.debug then
        if InCombatLockdown() then J.Core.dirty=true;return end
        local mirror=config.unit~="player"
        local k=g.capScale
        local left,right=(mirror and 116 or 96)*k,(mirror and 96 or 116)*k
        local top=kind=="health" and 84*k or 0
        -- The native 1-unit seam stays small; the substantial lower ornament is
        -- below the power bar, never stretched over either functional opening.
        local heights=kind=="health" and {top,g.h,1} or {g.h,96*k}
        local rows=kind=="health" and {0,84,132,136} or {136,160,256}
        local cols=mirror and {512,396,96,0} or {0,96,396,512}
        local widths={left,g.w,right}
        local height=0;for _,v in ipairs(heights) do height=height+v end
        f:SetScale(g.scale/g.parentScale)
        f:SetSize(g.w+left+right,height)
        f:ClearAllPoints();f:SetPoint("TOPLEFT",record.bar,"TOPLEFT",-left,top)
        f:SetFrameStrata(config.strata);f:SetFrameLevel(config.level)
        local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
        local path=entry.shell
        trim.assetOK=true
        local y=0
        for row,h in ipairs(heights) do
            local x=0
            for column,w in ipairs(widths) do
                local texture=t[row.."_"..column]
                if texture then
                    texture:ClearAllPoints();texture:SetPoint("TOPLEFT",f,"TOPLEFT",x,-y)
                    texture:SetSize(w,h)
                    texture:SetTexCoord(cols[column]/512,cols[column+1]/512,rows[row]/256,rows[row+1]/256)
                    texture:SetDrawLayer(config.layer)
                    if texture:SetTexture(path)==false then trim.assetOK=false end
                end
                x=x+w
            end
            y=y+h
        end
        applied={width=g.w+left+right,height=height,scale=1,x=-left,y=top,anchor="FRAME",point="TOPLEFT",relativePoint="TOPLEFT",
            strata=config.strata,level=config.level,layer=config.layer,texture=path,shown=true,opacity=config.opacity,mirror=mirror}
        local snapshot={frame=record.bar,name=key.."."..kind.."Bar",scale=g.scale,visible=true,alpha=1}
        trim.applied,trim.snapshot=applied,snapshot
        J.Core:UpdateDebug(trim,snapshot,applied)
        record.geometry,record.id=g,id
    end
    if trim.applied then trim.applied.opacity=config.opacity end
end

function S:Visibility(record,enabled)
    local trim=record.trim
    if not trim then return end
    local snapshot
    if enabled and usable(record.bar) then
        local visible=record.bar:IsVisible()
        local alpha=record.bar:GetEffectiveAlpha()
        if J.Core:IsSafe(visible) and J.Core:IsNumber(alpha) then
            snapshot=trim.snapshot;snapshot.visible=visible==true;snapshot.alpha=alpha
        end
    end
    J.Core:SyncVisibility(trim,snapshot)
end

function S:TickUnit(key)
    local config=J.ThemeManager:Resolve(key)
    local enabled=config.unitStyle=="FULL" and config.shown
    -- Replacement portrait sources own their bars. Retire a previous native
    -- skin through the existing restoration path when the source switches.
    if enabled and J.AddOnAnchors then
        local _,_,external=J.AddOnAnchors:Resolve(key)
        enabled=not external
    end
    local unit=self.units[key]
    if not enabled and not unit then return end -- Portrait-only mode has no hooks or bar reads.
    if not unit then unit={trims={}};self.units[key]=unit end
    local bars=enabled and J.Core.client:UnitBars(key) or nil
    local id=J.Portraits:Resolve(config)
    for _,kind in ipairs({"health","power"}) do
        local bar=bars and bars[kind]
        local record=unit[kind]
        local texture=usable(bar) and bar:GetStatusBarTexture() or nil
        if not usable(texture) then bar=nil end
        if record and (not enabled or record.bar~=bar or record.texture~=texture) then
            self:Visibility(record,false)
            if self:Restore(record) then
                self:Retire(record);unit[kind]=nil;record=nil
            else
                -- Keep the pending original until the forbidden/combat state ends.
                J.Core.dirty=true;bar=nil
            end
        end
        local g=bar and geometry(bar)
        if g then
            local healthGeometry=bars and geometry(bars.health)
            g.capScale=healthGeometry and healthGeometry.h/48*healthGeometry.scale/g.scale or g.h/(kind=="health" and 48 or 24)
        end
        if bar and g and not record and not InCombatLockdown() then
            local original=capture(texture)
            if original then
                record={bar=bar,texture=texture,original=original,trim=unit.trims[kind]}
                unit[kind]=record;self:Watch(record)
            end
        end
        if record and bar and g then
            if not InCombatLockdown() and self:ApplyFill(record,kind,id) then
                self:Layout(record,key,kind,config,id,g)
                unit.trims[kind]=record.trim
            elseif InCombatLockdown() then
                local old=record.geometry
                if not record.active or record.external or record.id~=id or not old
                    or old.w~=g.w or old.h~=g.h or old.scale~=g.scale or old.parentScale~=g.parentScale
                    or old.capScale~=g.capScale or record.trim.applied.strata~=config.strata
                    or record.trim.applied.level~=config.level or record.trim.applied.layer~=config.layer then J.Core.dirty=true end
            end
            self:Visibility(record,record.active and enabled and record.id==id and not record.external)
        elseif record then self:Visibility(record,false) end
    end
end

function S:Tick()
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
        J.Core:Protect(key.." skin",function() self:TickUnit(key) end)
    end
end
