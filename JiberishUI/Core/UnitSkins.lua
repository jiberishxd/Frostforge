local _, J = ...
local S = { units = {}, status = {}, summary = {}, powerLayouts = {}, ellesmereLayouts = {}, watched = setmetatable({}, {__mode="k"}) }
J.UnitSkins = S
J.Core.properties.unitFrameShown = {boolean=true}
-- Kept as an import/command alias for profiles made before separate toggles.
J.Core.properties.unitStyle = {PORTRAIT=true,FULL=true}

-- Presentation only. The full shell fits the existing power bar below the
-- painted divider. Never read values, change ranges or secure attributes.
local function usable(frame) return J.Core:IsUsableFrame(frame) end
local function readCapture(texture)
    if not usable(texture) then return end
    if type(texture.GetTexture)~="function" or type(texture.GetTexCoord)~="function" then return end
    local atlas = type(texture.GetAtlas)=="function" and texture:GetAtlas() or nil
    local path = texture:GetTexture()
    if not J.Core:IsSafe(atlas) or not J.Core:IsSafe(path) then return end
    if atlas=="" then atlas=nil end
    if not atlas and path==nil and type(texture.GetTextureFileID)=="function" then path=texture:GetTextureFileID() end
    if not J.Core:IsSafe(path) then return end
    if atlas ~= nil and type(atlas) ~= "string" then return end
    if not atlas and type(path) ~= "string" and not J.Core:IsNumber(path) then return end
    if not atlas and (path=="" or (type(path)=="number" and path<=0)) then return end
    local coords = {texture:GetTexCoord()}
    if #coords ~= 8 then return end
    for _,v in ipairs(coords) do if not J.Core:IsNumber(v) then return end end
    return {atlas=atlas,path=path,coords=coords}
end
local function capture(texture)
    local ok,state=pcall(readCapture,texture)
    if ok then return state end
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
        if type(frame[method])=="function" and not watched[method] then
            watched[method]={}
            local listeners=watched[method]
            hooksecurefunc(frame,method,function(received)
                if not usable(received) then return end
                for current,callback in pairs(listeners) do
                    if not current.retired then callback(received) end
                end
            end)
        end
        if watched[method] then watched[method][record]=changed end
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

local function layoutState(bar)
    if not usable(bar) then return end
    local count=bar:GetNumPoints()
    local w,h=bar:GetWidth(),bar:GetHeight()
    if not J.Core:IsNumber(count) or count<1 or count>8 or not J.Core:IsNumber(w) or not J.Core:IsNumber(h) then return end
    local state={w=w,h=h,points={}}
    for i=1,count do
        local point,relative,relativePoint,x,y=bar:GetPoint(i)
        if not J.Core:IsSafe(point) or not J.Core:IsSafe(relativePoint) or not usable(relative)
            or not J.Core.properties.point[point] or not J.Core.properties.point[relativePoint]
            or not J.Core:IsNumber(x) or not J.Core:IsNumber(y) then return end
        state.points[i]={point,relative,relativePoint,x,y}
    end
    return state
end

local function sameLayout(a,b)
    if not a or not b or math.abs(a.w-b.w)>.001 or math.abs(a.h-b.h)>.001 or #a.points~=#b.points then return false end
    for i,p in ipairs(a.points) do
        for j,v in ipairs(p) do
            local other=b.points[i][j]
            if type(v)=="number" then
                if math.abs(v-other)>.001 then return false end
            elseif v~=other then return false end
        end
    end
    return true
end

local function writeLayout(bar,state)
    assert(not InCombatLockdown(),"Native bar layout deferred in combat")
    bar:ClearAllPoints()
    bar:SetSize(state.w,state.h)
    for _,point in ipairs(state.points) do bar:SetPoint(unpack(point)) end
end

function S:RestorePowerLayout(key)
    local record=self.powerLayouts[key]
    if not record then return true end
    if InCombatLockdown() then J.Core.dirty=true;return false end
    if not usable(record.bar) then J.Core.dirty=true;return false end
    local ok,current=pcall(layoutState,record.bar)
    if not record.partial and (not ok or not current) then J.Core.dirty=true;return false end
    -- A later native layout is authoritative; do not overwrite it on disable.
    if sameLayout(current,record.applied) or record.partial then
        if not J.Core:Protect(key.." power layout restore",function() writeLayout(record.bar,record.original) end) then return false end
    end
    self.powerLayouts[key]=nil
    return true
end

function S:FitPowerLayout(key,bars,id,enabled)
    local record=self.powerLayouts[key]
    local bar=bars and bars.power
    if record and (not enabled or record.bar~=bar or record.partial) and not self:RestorePowerLayout(key) then return false end
    if not enabled or not bars or not bar then return false end
    if InCombatLockdown() then
        local ready=record and record.id==id or false
        if not ready then J.Core.dirty=true end
        return ready
    end
    local health,power=geometry(bars.health),geometry(bar)
    if not health or not power then return false end
    local ok,current=pcall(layoutState,bar)
    if not ok or not current then return false end
    record=self.powerLayouts[key]
    if not record then record={bar=bar,original=current};self.powerLayouts[key]=record
    elseif not record.partial and not sameLayout(current,record.applied) then record.original=current end
    local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
    local h,p=entry.opening.health,entry.opening.power
    local k=health.h/(h[4]-h[2])*health.scale/power.scale
    local desired={w=health.w*health.scale/power.scale,h=(p[4]-p[2])*k,
        points={{"TOPLEFT",bars.health,"BOTTOMLEFT",0,-(p[2]-h[4])*k}}}
    if not sameLayout(current,desired) then
        record.partial=true
        if not J.Core:Protect(key.." power layout",function() writeLayout(bar,desired) end) then return false end
    end
    record.applied,record.partial,record.id=desired,false,id
    return true
end

-- Ellesmere clips attached bars to their existing container. Reserve the
-- painted divider INSIDE the original stack; never grow or disable that clip.
local function barRect(bar)
    if not usable(bar) or type(bar.GetRect)~="function" then return end
    local x,y,w,h=bar:GetRect()
    local scale=bar:GetEffectiveScale()
    if not J.Core:IsNumber(x) or not J.Core:IsNumber(y) or not J.Core:IsNumber(w) or not J.Core:IsNumber(h)
        or not J.Core:IsNumber(scale) or w<=0 or h<=0 or scale<=0 then return end
    return {left=x*scale,bottom=y*scale,right=(x+w)*scale,top=(y+h)*scale}
end

function S:RestoreEllesmereLayout(key)
    local record=self.ellesmereLayouts[key]
    if not record then return true end
    if InCombatLockdown() then J.Core.dirty=true;return false end
    for _,kind in ipairs({"health","power"}) do
        local item=record[kind]
        if not usable(item.bar) then J.Core.dirty=true;return false end
        local ok,current=pcall(layoutState,item.bar)
        if not item.partial and (not ok or not current) then J.Core.dirty=true;return false end
        local parent=item.bar:GetParent()
        if not J.Core:IsSafe(parent) then J.Core.dirty=true;return false end
        if parent==item.parent and (item.partial or sameLayout(current,item.applied)) then
            if not J.Core:Protect(key.." Ellesmere layout restore",function() writeLayout(item.bar,item.original) end) then return false end
            item.partial=false
        end
    end
    self.ellesmereLayouts[key]=nil
    return true
end

function S:FitEllesmereLayout(key,bars,id,enabled)
    local record=self.ellesmereLayouts[key]
    local health,power=bars and bars.health,bars and bars.power
    if record and (not enabled or record.health.bar~=health or record.power.bar~=power) then
        if not self:RestoreEllesmereLayout(key) then return false,"Layout restoration queued" end
        record=nil
    end
    if not enabled then return false end
    if InCombatLockdown() then
        J.Core.dirty=true
        return record and record.id==id and not record.health.partial and not record.power.partial or false,"Layout queued until combat ends"
    end
    local hg,pg=geometry(health),geometry(power)
    if not hg or not pg then return false,"Full shell needs an enabled health and power bar" end
    local shown,hp,pp=power:IsShown(),health:GetParent(),power:GetParent()
    if not J.Core:IsSafe(shown) or shown~=true or not usable(hp) or not usable(pp) or hp~=pp then
        self:RestoreEllesmereLayout(key)
        return false,"Shell needs attached power below health; textures only"
    end
    local current={}
    for kind,bar in pairs({health=health,power=power}) do
        if type(bar.GetOrientation)=="function" then
            local direction=bar:GetOrientation()
            if not J.Core:IsSafe(direction) or direction~="HORIZONTAL" then
                self:RestoreEllesmereLayout(key)
                return false,"Full shell needs horizontal bars; textures only"
            end
        end
        local ok,state=pcall(layoutState,bar)
        if not ok or not state then return false,"Waiting for public Ellesmere bar layout" end
        current[kind]=state
    end
    if record and (record.health.partial or record.power.partial
        or not sameLayout(current.health,record.health.applied) or not sameLayout(current.power,record.power.applied)
        or hg.scale~=record.healthScale or pg.scale~=record.powerScale) then
        if not self:RestoreEllesmereLayout(key) then return false,"Waiting to restore Ellesmere layout" end
        return self:FitEllesmereLayout(key,bars,id,enabled)
    end
    if not record then
        local hok,hr=pcall(barRect,health)
        local pok,pr=pcall(barRect,power)
        if not hok or not pok or not hr or not pr then return false,"Waiting for public Ellesmere bar bounds" end
        local gap=hr.bottom-pr.top
        -- Detached/off-center/above layouts keep their geometry and receive
        -- materials only. Never drag a separately positioned resource bar.
        if gap < -.5 or math.abs(hr.left-pr.left)>2 or math.abs(hr.right-pr.right)>12 then
            return false,"Shell needs power below health and aligned; textures only"
        end
        record={health={bar=health,parent=hp,original=current.health},power={bar=power,parent=pp,original=current.power},
            gap=math.max(0,gap)/hg.scale,healthScale=hg.scale,powerScale=pg.scale}
        self.ellesmereLayouts[key]=record
    end
    local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
    local h,p=entry.opening.health,entry.opening.power
    local total=(record.health.original.h+record.gap)*hg.scale+record.power.original.h*pg.scale
    local scale=total/(p[4]-h[2])
    local desiredHealth={w=current.health.w,h=(h[4]-h[2])*scale/hg.scale,points=record.health.original.points}
    local desiredPower={w=hg.w*hg.scale/pg.scale,h=(p[4]-p[2])*scale/pg.scale,
        points={{"TOPLEFT",health,"BOTTOMLEFT",0,-(p[2]-h[4])*scale/pg.scale}}}
    for _,kind in ipairs({"health","power"}) do
        local desired=kind=="health" and desiredHealth or desiredPower
        local item=record[kind]
        if not sameLayout(current[kind],desired) then
            item.partial=true
            if not J.Core:Protect(key.." Ellesmere "..kind.." fitting",function() writeLayout(item.bar,desired) end) then
                return false,"Waiting to finish Ellesmere bar fitting"
            end
        end
        item.applied,item.partial=desired,false
    end
    record.id=id
    return true
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
        local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
        local health,power=entry.opening.health,entry.opening.power
        local k=g.capScale
        local left,right=(mirror and 512-health[3] or health[1])*k,(mirror and health[1] or 512-health[3])*k
        local top=kind=="health" and health[2]*k or 0
        local heights=kind=="health" and {top,g.h,(power[2]-health[4])*k} or {g.h,(256-power[4])*k}
        local rows=kind=="health" and {0,health[2],health[4],power[2]} or {power[2],power[4],256}
        local cols=mirror and {512,health[3],health[1],0} or {0,health[1],health[3],512}
        local widths={left,g.w,right}
        local height=0;for _,v in ipairs(heights) do height=height+v end
        f:SetScale(g.scale/g.parentScale)
        f:SetSize(g.w+left+right,height)
        f:ClearAllPoints();f:SetPoint("TOPLEFT",record.bar,"TOPLEFT",-left,top)
        f:SetFrameStrata(config.strata);f:SetFrameLevel(config.level)
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
    record.barVisible=snapshot and snapshot.visible and snapshot.alpha>0 or false
    J.Core:SyncVisibility(trim,snapshot)
end

function S:TickUnit(key)
    local config=J.ThemeManager:Resolve(key)
    -- Portrait visibility/provider must never disable independent bar artwork.
    local enabled=config.unitFrameShown
    self.status[key]=enabled and "Waiting for unit-frame bars" or "Unit frame: off"
    self.summary[key]=enabled and "waiting for bars" or "off"
    local unit=self.units[key]
    if not enabled and not unit then return end -- Portrait-only mode has no hooks or bar reads.
    if not unit then unit={trims={}};self.units[key]=unit end
    local bars,reason
    if enabled then bars,reason=J.AddOnAnchors:UnitBars(key,config.unitFrameSource) end
    local id=J.Portraits:Resolve(config)
    local fitted,fitReason
    local external=bars and bars.source=="ELLESMERE"
    if external then
        local strata,level=bars.root:GetFrameStrata(),bars.root:GetFrameLevel()
        J.AddOnAnchors:Layer(key,config,strata,J.Core:IsNumber(level) and level+1 or nil)
        if self:RestorePowerLayout(key) then fitted,fitReason=self:FitEllesmereLayout(key,bars,id,enabled) end
    else
        if self:RestoreEllesmereLayout(key) then fitted=self:FitPowerLayout(key,bars,id,enabled) end
    end
    local states={}
    for _,kind in ipairs({"health","power"}) do
        local bar=bars and bars[kind]
        if not usable(bar) then bar=nil end
        local record=unit[kind]
        local texture
        if bar then
            local ok,result=pcall(bar.GetStatusBarTexture,bar)
            if ok and usable(result) then texture=result end
        end
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
            local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
            local h,p=entry.opening.health,entry.opening.power
            g.capScale=healthGeometry and healthGeometry.h/(h[4]-h[2])*healthGeometry.scale/g.scale
                or g.h/(kind=="health" and h[4]-h[2] or p[4]-p[2])
        end
        if bar and g and not record and not InCombatLockdown() then
            record={bar=bar,texture=texture,trim=unit.trims[kind]}
            unit[kind]=record
        end
        if record and bar and g then
            if not InCombatLockdown() then
                -- Shells need only bar geometry. Unreadable native fill metadata
                -- must not silently suppress the entire ornamental frame.
                if not external or fitted then self:Layout(record,key,kind,config,id,g) end
                unit.trims[kind]=record.trim
                if not record.original then
                    local original=capture(texture)
                    if original then record.original=original;self:Watch(record) end
                end
                record.fillReady=record.original and self:ApplyFill(record,kind,id) or false
            elseif InCombatLockdown() then
                local old=record.geometry
                if not record.active or record.external or record.id~=id or not old
                    or old.w~=g.w or old.h~=g.h or old.scale~=g.scale or old.parentScale~=g.parentScale
                    or old.capScale~=g.capScale or not record.trim or not record.trim.applied or record.trim.applied.strata~=config.strata
                    or record.trim.applied.level~=config.level or record.trim.applied.layer~=config.layer then J.Core.dirty=true end
            end
            self:Visibility(record,enabled and record.id==id and (not external or fitted))
            local shellReady=record.trim and record.trim.assetOK and (not external or fitted)
            states[#states+1]=kind..(shellReady and
                (record.fillReady and ": shell + texture" or ": shell; native fill retained") or
                (record.fillReady and ": texture only" or ": native fill retained"))
                ..(shellReady and not record.barVisible and " (native bar hidden)" or "")
        elseif record then self:Visibility(record,false) end
    end
    if enabled then
        self.status[key]=#states>0 and ((bars.name or "Blizzard")..": "..table.concat(states,"; ")) or reason or "Waiting for unit-frame bars"
        if not fitted and bars and (external or bars.power) then self.status[key]=(fitReason or "Waiting to fit power-bar spacing").."; "..self.status[key] end
        if InCombatLockdown() and J.Core.dirty then self.status[key]="Changes queued until combat ends" end
        if bars then
            self.summary[key]=bars.name..(fitted and ": fitted" or ": see /jui status")
        end
        if InCombatLockdown() and J.Core.dirty then self.summary[key]="queued until combat ends" end
    end
end

function S:Tick()
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
        J.Core:Protect(key.." skin",function() self:TickUnit(key) end)
    end
end
