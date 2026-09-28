local _, J = ...
local S = { units = {}, status = {}, summary = {}, powerLayouts = {}, attachedLayouts = {}, watched = setmetatable({}, {__mode="k"}) }
J.UnitSkins = S
J.Core.properties.blizzardStone = {boolean=true}
J.Core.properties.unitFrameShown = {boolean=true}
J.Core.properties.unitFrameFill = {AUTO=true,PROVIDER=true,JIBERISH=true}
J.Core.properties.unitFrameWidth = {75,150}
J.Core.properties.unitFrameHeight = {75,150}
J.Core.properties.unitFrameX = {-512,512}
J.Core.properties.unitFrameY = {-512,512}
-- Import compatibility only. The old inset strips are no longer rendered.
J.Core.properties.unitFrameInset = {0,6}
J.Core.properties.unitFrameStrata = J.Core:Copy(J.Core.properties.strata)
J.Core.properties.unitFrameStrata.AUTO=true
-- Kept as an import/command alias for profiles made before separate toggles.
J.Core.properties.unitStyle = {PORTRAIT=true,FULL=true}

-- Presentation only. The full shell fits the existing power bar below the
-- painted divider. Never read values, change ranges or secure attributes.
local function usable(frame) return J.Core:IsUsableFrame(frame) end
local function readCapture(texture,stock)
    if not usable(texture) then return end
    if type(texture.GetTexture)~="function" then return end
    local atlas = type(texture.GetAtlas)=="function" and texture:GetAtlas() or nil
    local path = texture:GetTexture()
    if not J.Core:IsSafe(atlas) or not J.Core:IsSafe(path) then return end
    if atlas=="" then atlas=nil end
    if not atlas and path==nil and type(texture.GetTextureFileID)=="function" then path=texture:GetTextureFileID() end
    if not J.Core:IsSafe(path) then return end
    if atlas ~= nil and type(atlas) ~= "string" then return end
    if not atlas and type(path) ~= "string" and not J.Core:IsNumber(path) then return end
    if not atlas and (path=="" or (type(path)=="number" and path<=0)) then return end
    -- A stock StatusBar owns its live UVs. They can be restricted and encode
    -- current fill, so capture only the public asset and let its setter restore
    -- the atlas coordinates. Third-party custom UVs still require a safe copy.
    if stock then return {atlas=atlas,path=path} end
    if type(texture.GetTexCoord)~="function" then return end
    local coords = {texture:GetTexCoord()}
    if #coords ~= 8 then return end
    for _,v in ipairs(coords) do if not J.Core:IsNumber(v) then return end end
    return {atlas=atlas,path=path,coords=coords}
end
local function capture(texture,stock)
    local ok,state=pcall(readCapture,texture,stock)
    if ok then return state end
end

function S:Watch(record)
    local function changed(frame, selection)
        -- Observe redraws here. The color controller may reassert an already
        -- prepared power material; layout and other fills wait outside combat.
        if not usable(frame) or record.writing or not record.active then return end
        -- Stock StatusBars own live fill UVs (health/power animation). Only
        -- asset selection needs reapplication; UV movement is not a new skin.
        if record.stock and not selection then return end
        record.external = true
        if selection then record.externalSelection = true end
        -- The regular skin pass observes this record. A native fill redraw
        -- must not invalidate every portrait, minimap and action-hub layout.
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
        if watched[method] then
            local selection=method~="SetTexCoord"
            watched[method][record]=function(received) changed(received,selection) end
        end
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
        local latest=capture(record.texture,record.stock)
        if not latest then return false end
        if record.externalSelection or (not isOurFill(latest) and (latest.atlas or latest.path~=record.fillPath)) then
            record.original,record.active,record.external,record.externalSelection=latest,false,false,false
            return true
        end
        record.external,record.externalSelection=false,false
    end
    local old=record.original
    local ok=write(record,function()
        local current=record.stock and record.bar:GetStatusBarTexture()
        if record.stock and J.Core:IsSafe(current) and current==record.texture and type(record.bar.SetStatusBarTexture)=="function" then
            record.bar:SetStatusBarTexture(old.atlas or old.path)
        end
        if old.atlas then record.texture:SetAtlas(old.atlas)
        else record.texture:SetTexture(old.path) end
        if old.coords then record.texture:SetTexCoord(unpack(old.coords)) end
    end)
    if ok then record.active=false end
    return ok
end

function S:ApplyFill(record,kind,id,overridePath)
    local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
    local path=overridePath or entry[kind]
    if InCombatLockdown() then J.Core.dirty=true; return false end
    if not usable(record.bar) or not usable(record.texture) then return false end
    if record.external or not record.active then
        local latest=capture(record.texture,record.stock)
        if not latest then return false end
        if not record.active or record.externalSelection or (not isOurFill(latest) and (latest.atlas or latest.path~=record.fillPath)) then record.original=latest end
        record.active,record.external,record.externalSelection=false,false,false
    end
    if record.active and record.fillPath==path then return true end
    -- SetTexture on the existing fill region preserves the native mask and
    -- StatusBar's ownership of its size, fill direction and value animation.
    local loaded
    local ok=write(record,function()
        if record.stock and type(record.bar.SetStatusBarTexture)=="function" then
            loaded=record.bar:SetStatusBarTexture(path)
        else loaded=record.texture:SetTexture(path) end
        record.texture:SetTexCoord(0,1,0,1)
    end)
    record.active,record.fillPath=true,path -- also restore after a partially failed write
    if not ok or loaded==false then self:Restore(record);return false end
    record.revision=(record.revision or 0)+1
    return true
end

-- Two owned halves follow the actual health/power anchors independently. Their
-- sections preserve sculpted endcaps and the lower central ornament.
function S:CreateTrim(key,kind)
    local trim={key=key.."."..kind.."Skin"}
    local frame=CreateFrame("Frame",nil,UIParent)
    frame:EnableMouse(false)
    local textures={}
    for row=1,(kind=="health" and 3 or 2) do
        for column=1,3 do
            -- Keep the transparent opening cells too: their alpha contains the
            -- original curved corners and bevels that must cover the fill.
            textures[row.."_"..column]=frame:CreateTexture(nil,"BACKGROUND")
        end
    end
    if kind=="power" then
        textures.footerLeft=frame:CreateTexture(nil,"BACKGROUND")
        textures.footerRight=frame:CreateTexture(nil,"BACKGROUND")
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
        local ready=record and record.bar==bar and not record.partial or false
        if not ready or record.id~=id then J.Core.dirty=true end
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

-- Reserve the painted divider inside an attached provider stack. Keep the
-- original outer dimensions, clipping containers and parent relationships.
local function barRect(bar)
    if not usable(bar) or type(bar.GetRect)~="function" then return end
    local x,y,w,h=bar:GetRect()
    local scale=bar:GetEffectiveScale()
    if not J.Core:IsNumber(x) or not J.Core:IsNumber(y) or not J.Core:IsNumber(w) or not J.Core:IsNumber(h)
        or not J.Core:IsNumber(scale) or w<=0 or h<=0 or scale<=0 then return end
    return {left=x*scale,bottom=y*scale,right=(x+w)*scale,top=(y+h)*scale}
end

function S:RestoreAttachedLayout(key)
    local record=self.attachedLayouts[key]
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
            if not J.Core:Protect(key.." attached layout restore",function() writeLayout(item.bar,item.original) end) then return false end
            item.partial=false
        end
    end
    self.attachedLayouts[key]=nil
    return true
end

function S:FitAttachedLayout(key,bars,id,enabled)
    local record=self.attachedLayouts[key]
    local health,power=bars and bars.health,bars and bars.power
    if bars and bars.layoutReason then
        self:RestoreAttachedLayout(key)
        return false,bars.layoutReason
    end
    if record and (not enabled or record.health.bar~=health or record.power.bar~=power) then
        if not self:RestoreAttachedLayout(key) then return false,"Layout restoration queued" end
        record=nil
    end
    if not enabled then return false end
    if InCombatLockdown() then
        J.Core.dirty=true
        return record and not record.health.partial and not record.power.partial or false,"Layout queued until combat ends"
    end
    local hg,pg=geometry(health),geometry(power)
    if not hg or not pg then
        self:RestoreAttachedLayout(key)
        return false,"Full shell needs an enabled health and power bar"
    end
    local shown,hp,pp=power:IsShown(),health:GetParent(),power:GetParent()
    if not J.Core:IsSafe(shown) or shown~=true or not usable(hp) or not usable(pp) or hp~=pp then
        self:RestoreAttachedLayout(key)
        return false,"Shell needs attached power below health; textures only"
    end
    local current={}
    for kind,bar in pairs({health=health,power=power}) do
        if type(bar.GetOrientation)=="function" then
            local direction=bar:GetOrientation()
            if not J.Core:IsSafe(direction) or direction~="HORIZONTAL" then
                self:RestoreAttachedLayout(key)
                return false,"Full shell needs horizontal bars; textures only"
            end
        end
        local ok,state=pcall(layoutState,bar)
        if not ok or not state then return false,"Waiting for public provider bar layout" end
        current[kind]=state
    end
    local parentBounds
    if bars.source=="ELVUI" then
        local ok,bounds=pcall(barRect,hp)
        if not ok or not bounds then return false,"Waiting for public ElvUI container bounds" end
        parentBounds={w=bounds.right-bounds.left,h=bounds.top-bounds.bottom}
    end
    local parentChanged=record and parentBounds and record.parentBounds and
        (math.abs(parentBounds.w-record.parentBounds.w)>.001 or math.abs(parentBounds.h-record.parentBounds.h)>.001)
    if record and (parentChanged or record.health.partial or record.power.partial
        or not sameLayout(current.health,record.health.applied) or not sameLayout(current.power,record.power.applied)
        or hg.scale~=record.healthScale or pg.scale~=record.powerScale) then
        if not self:RestoreAttachedLayout(key) then return false,"Waiting to restore provider layout" end
        return self:FitAttachedLayout(key,bars,id,enabled)
    end
    if not record then
        local hok,hr=pcall(barRect,health)
        local pok,pr=pcall(barRect,power)
        if not hok or not pok or not hr or not pr then return false,"Waiting for public provider bar bounds" end
        local gap=hr.bottom-pr.top
        -- Detached/off-center/above layouts keep their geometry and receive
        -- materials only. Never drag a separately positioned resource bar.
        if gap < -.5 or math.abs(hr.left-pr.left)>2 or math.abs(hr.right-pr.right)>12 then
            return false,"Shell needs power below health and aligned; textures only"
        end
        record={health={bar=health,parent=hp,original=current.health},power={bar=power,parent=pp,original=current.power},
            gap=math.max(0,gap)/hg.scale,healthScale=hg.scale,powerScale=pg.scale,parentBounds=parentBounds}
        if bars.source=="ELVUI" then
            local bounds=barRect(hp)
            -- ElvUI anchors opposite vertical edges. SetHeight alone cannot
            -- resize that region: use its current top-left while fitted and
            -- restore the complete native anchor set when disabled/redrawn.
            record.health.fittedPoints={{"TOPLEFT",hp,"TOPLEFT",(hr.left-bounds.left)/hg.scale,(hr.top-bounds.top)/hg.scale}}
        end
        self.attachedLayouts[key]=record
    end
    local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
    local h,p=entry.opening.health,entry.opening.power
    local total=(record.health.original.h+record.gap)*hg.scale+record.power.original.h*pg.scale
    local scale=total/(p[4]-h[2])
    local desiredHealth={w=current.health.w,h=(h[4]-h[2])*scale/hg.scale,points=record.health.fittedPoints or record.health.original.points}
    local desiredPower={w=hg.w*hg.scale/pg.scale,h=(p[4]-p[2])*scale/pg.scale,
        points={{"TOPLEFT",health,"BOTTOMLEFT",0,-(p[2]-h[4])*scale/pg.scale}}}
    for _,kind in ipairs({"health","power"}) do
        local desired=kind=="health" and desiredHealth or desiredPower
        local item=record[kind]
        local unchanged=item.wanted and sameLayout(item.wanted,desired) and sameLayout(current[kind],item.applied)
        if not unchanged and not sameLayout(current[kind],desired) then
            item.partial=true
            if not J.Core:Protect(key.." attached "..kind.." fitting",function() writeLayout(item.bar,desired) end) then
                return false,"Waiting to finish provider bar fitting"
            end
        end
        -- Record engine readback rather than treating rounded dimensions as
        -- a provider redraw on the next tick. Keep the request separately.
        item.wanted=desired
        item.applied=layoutState(item.bar) or desired
        item.partial=false
    end
    record.id=id
    return true
end

-- Scale both shell halves around the same bar-stack center so their joining
-- seam stays continuous. These controls never resize the provider's bars.
local function artTransform(kind,config,entry,g)
    local h,p=entry.opening.health,entry.opening.power
    local sx,sy=config.unitFrameWidth/100,config.unitFrameHeight/100
    local center=(p[4]-h[2])*g.capScale/2
    local origin=kind=="health" and 0 or (p[2]-h[2])*g.capScale
    -- Place the original side edges one UI unit inside the native bar. This
    -- is a smaller opening in the single shell, not another set of borders.
    local openingWidth=math.max(g.w-2*g.artScale,g.w*.8)
    return sx,sy,(g.w-openingWidth*sx)/2+config.unitFrameX*g.artScale,
        (origin-center)*(1-sy)+config.unitFrameY*g.artScale,openingWidth
end

local strataRank={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8}

local function shellStrata(config,g)
    local requested=config.unitFrameStrata=="AUTO" and config.strata or config.unitFrameStrata
    if strataRank[requested]<strataRank[g.strata] then return g.strata end
    return requested
end

local function shellCuts(kind,entry,mirror)
    local h,p=entry.opening.health,entry.opening.power
    local rows=kind=="health" and {0,h[2],h[4],p[2]} or {p[2],p[4],256}
    local cols=mirror and {512,h[3],h[1],0} or {0,h[1],h[3],512}
    local center=(h[1]+h[3])/2
    local footer=mirror and {h[3],center+48,center-48,h[1]} or {h[1],center-48,center+48,h[3]}
    return rows,cols,footer
end

local function writableArt(trim)
    if not usable(trim.frame) or (InCombatLockdown() and trim.frame:IsProtected()) then return false end
    for _,texture in pairs(trim.textures) do
        if not usable(texture) or (InCombatLockdown() and type(texture.IsProtected)=="function" and texture:IsProtected()) then return false end
    end
    return true
end

-- Identity can change while the native bar layout is locked. Remap the new
-- painting's measured openings onto the existing cells: swapping only the file
-- would put bevels inside the fill. No anchors, dimensions or native fills are
-- written here. The source-proportional fit is reconciled after combat.
function S:RefreshArt(record,kind,id)
    local trim=record.trim
    if not trim or not trim.applied then return false end
    local mirror=trim.applied.mirror
    if record.id==id and trim.assetOK and trim.paintMirror==mirror then return true end
    if not writableArt(trim) then
        J.Core.dirty=true;return false
    end
    local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
    local rows,cols,footer=shellCuts(kind,entry,mirror)
    trim.assetOK=true
    local function paint(texture,l,r,t,b)
        texture:SetTexCoord(l/512,r/512,t/256,b/256)
        if texture:SetTexture(entry.shell)==false then trim.assetOK=false end
    end
    for row=1,#rows-1 do
        for column=1,3 do
            -- The center of the bottom row is painted with the dedicated
            -- ornament below, preserving all three footer spans.
            if kind~="power" or row~=2 or column~=2 then
                paint(trim.textures[row.."_"..column],cols[column],cols[column+1],rows[row],rows[row+1])
            end
        end
    end
    if kind=="power" then
        for i,name in ipairs({"footerLeft","2_2","footerRight"}) do
            paint(trim.textures[name],footer[i],footer[i+1],rows[2],rows[3])
        end
    end
    record.id,trim.paintMirror,trim.applied.texture=id,mirror,entry.shell
    return trim.assetOK
end

function S:Layout(record,key,kind,config,id,g)
    local trim=record.trim
    if not trim then trim=self:CreateTrim(key,kind);record.trim=trim end
    local f,t=trim.frame,trim.textures
    local old=record.geometry
    local changed=not old or old.w~=g.w or old.h~=g.h or old.scale~=g.scale or old.parentScale~=g.parentScale
        or old.capScale~=g.capScale or old.artScale~=g.artScale or old.anchorY~=g.anchorY or old.level~=g.level or old.strata~=g.strata
    local applied=trim.applied
    if changed or record.layoutID~=id or not applied or applied.strata~=config.strata
        or applied.unitFrameStrata~=config.unitFrameStrata or applied.level~=config.level or applied.layer~=config.layer or applied.unitFrameWidth~=config.unitFrameWidth
        or applied.unitFrameHeight~=config.unitFrameHeight or applied.unitFrameX~=config.unitFrameX or applied.unitFrameY~=config.unitFrameY
        or trim.debugApplied~=J.ProfileManager.current.debug then
        if InCombatLockdown() then J.Core.dirty=true;return end
        local mirror=config.unit~="player"
        local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
        local health,power=entry.opening.health,entry.opening.power
        local k=g.capScale
        local left,right=(mirror and 512-health[3] or health[1])*k,(mirror and health[1] or 512-health[3])*k
        local top=kind=="health" and health[2]*k or 0
        local heights=kind=="health" and {top,g.h,(power[2]-health[4])*k} or {g.h,(256-power[4])*k}
        local sx,sy,dx,dy,openingWidth=artTransform(kind,config,entry,g)
        local widths={left,openingWidth,right}
        for i,v in ipairs(widths) do widths[i]=v*sx end
        for i,v in ipairs(heights) do heights[i]=v*sy end
        local height=0;for _,v in ipairs(heights) do height=height+v end
        f:SetScale(g.scale/g.parentScale)
        f:SetSize((openingWidth+left+right)*sx,height)
        f:ClearAllPoints();f:SetPoint("TOPLEFT",record.bar,"TOPLEFT",-left*sx+dx,top*sy+dy+(g.anchorY or 0))
        -- The actual artwork must cover the native fill. Older Background /
        -- level-zero profiles are safely raised to the owning bar's layer.
        f:SetFrameStrata(shellStrata(config,g));f:SetFrameLevel(math.max(config.level,g.level+1))
        local path=entry.shell
        local y=0
        for row,h in ipairs(heights) do
            local x=0
            for column,w in ipairs(widths) do
                local texture=t[row.."_"..column]
                if texture then
                    texture:ClearAllPoints();texture:SetPoint("TOPLEFT",f,"TOPLEFT",x,-y)
                    texture:SetSize(w,h)
                    texture:SetDrawLayer(config.layer)
                end
                x=x+w
            end
            y=y+h
        end
        if kind=="power" then
            -- Keep the moon/crest at the same aspect ratio as the endcaps.
            -- Only the two cloth/rail spans on either side stretch to bar width.
            local half=48
            local centerWidth=math.min(half*2*k,openingWidth*.8)
            local span=(openingWidth-centerWidth)/2
            local sizes={span,centerWidth,span}
            local names={"footerLeft","2_2","footerRight"}
            local x=left*sx
            for i,name in ipairs(names) do
                local texture=t[name]
                texture:ClearAllPoints();texture:SetPoint("TOPLEFT",f,"TOPLEFT",x,-heights[1])
                texture:SetSize(sizes[i]*sx,heights[2])
                texture:SetDrawLayer(config.layer)
                x=x+sizes[i]*sx
            end
            if record.backing then
                -- Only the empty resource opening is opaque. Keep all outside
                -- silhouette cutouts transparent and the bevels above it.
                record.backing:ClearAllPoints()
                record.backing:SetPoint("TOPLEFT",f,"TOPLEFT",left*sx,0)
                record.backing:SetSize(openingWidth*sx,heights[1])
                record.backing:SetDrawLayer("BACKGROUND",-8)
            end
        end
        applied={width=(openingWidth+left+right)*sx,height=height,scale=1,x=-left*sx+dx,y=top*sy+dy+(g.anchorY or 0),anchor="FRAME",point="TOPLEFT",relativePoint="TOPLEFT",
            unitFrameStrata=config.unitFrameStrata,unitFrameWidth=config.unitFrameWidth,unitFrameHeight=config.unitFrameHeight,unitFrameX=config.unitFrameX,unitFrameY=config.unitFrameY,
            strata=config.strata,level=config.level,layer=config.layer,texture=path,shown=true,opacity=config.opacity,mirror=mirror}
        local snapshot={frame=record.bar,name=key.."."..kind.."Bar",scale=g.scale,visible=true,alpha=1}
        trim.applied,trim.snapshot=applied,snapshot
        J.Core:UpdateDebug(trim,snapshot,applied)
        record.geometry,record.layoutID=g,id
    end
    self:RefreshArt(record,kind,id)
    if trim.applied then trim.applied.opacity=config.opacity end
end

function S:Visibility(record,enabled)
    local trim=record.trim
    if not trim then return end
    if not writableArt(trim) then J.Core.dirty=true;return end
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

-- The footer belongs to the shell, not to the existence of a resource bar.
-- Prepare a decoration-only lower half against health, even while power is
-- visible, so a no-power target can keep its artwork when combat begins.
function S:Footer(unit,key,bars,config,id,enabled)
    local health=bars and bars.health
    local g=geometry(health)
    local record=unit.footer
    if g and not InCombatLockdown() then
        if not record then record={trim=unit.trims.footer};unit.footer=record end
        if not record.trim then record.trim=self:CreateTrim(key,"power") end
        if not record.backing then
            record.backing=record.trim.frame:CreateTexture(nil,"BACKGROUND",nil,-8)
            record.backing:SetColorTexture(.025,.022,.019,1)
        end
        if record.bar~=health then record.bar=health;record.geometry=nil end
        local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
        local h,p=entry.opening.health,entry.opening.power
        g.capScale=g.h/(h[4]-h[2]);g.artScale=1
        g.h=(p[4]-p[2])*g.capScale
        g.anchorY=-(p[2]-h[2])*g.capScale
        self:Layout(record,key,"power",config,id,g)
        unit.trims.footer=record.trim
    elseif g and record and record.bar==health then
        self:RefreshArt(record,"power",id)
    end
    if record then self:Visibility(record,enabled and g~=nil and record.bar==health and record.id==id) end
end

local function noPower(bars)
    if not bars or not usable(bars.health) then return false end
    if not bars.power or bars.powerDisabled then return true end
    if not usable(bars.power) then return false end
    local shown=bars.power:IsShown()
    local height=bars.power:GetHeight()
    local alpha=bars.power:GetAlpha()
    local healthVisible,powerVisible=bars.health:IsVisible(),bars.power:IsVisible()
    local healthAlpha,powerAlpha=bars.health:GetEffectiveAlpha(),bars.power:GetEffectiveAlpha()
    return (J.Core:IsSafe(shown) and shown==false) or (J.Core:IsNumber(height) and height<=0)
        or (J.Core:IsNumber(alpha) and alpha<=0)
        or (J.Core:IsSafe(healthVisible) and healthVisible==true and J.Core:IsSafe(powerVisible) and powerVisible==false)
        or (J.Core:IsNumber(healthAlpha) and healthAlpha>0 and J.Core:IsNumber(powerAlpha) and powerAlpha<=0)
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
    local healthOnly=enabled and noPower(bars)
    local external=bars and (bars.source=="ELLESMERE" or bars.source=="ELVUI")
    -- Portrait strata no longer drives the independent shell.
    config.strata=J.ThemeManager.registry[J.ProfileManager.current.theme][key].strata
    local manageFill=(external or not self.stoneEnabled) and (config.unitFrameFill=="JIBERISH" or (config.unitFrameFill=="AUTO" and not external))
    if external then
        local strata,level=bars.root:GetFrameStrata(),bars.root:GetFrameLevel()
        J.AddOnAnchors:Layer(key,config,strata,J.Core:IsNumber(level) and level+1 or nil)
        if J.Core:IsSafe(strata) and J.Core.properties.strata[strata] then config.strata=strata end
    end
    if healthOnly then
        self:RestorePowerLayout(key);self:RestoreAttachedLayout(key)
        fitted=true -- Only artwork follows health; no resource bar is created.
    elseif external then
        if self:RestorePowerLayout(key) then fitted,fitReason=self:FitAttachedLayout(key,bars,id,enabled) end
    else
        if self:RestoreAttachedLayout(key) then fitted=self:FitPowerLayout(key,bars,id,enabled) end
    end
    if config.unitFrameStrata~="AUTO" then config.strata=config.unitFrameStrata end
    if key=="playerFrame" and enabled and not external and not healthOnly and fitted then self.powerMaskBar=bars.power end
    local states={}
    for _,kind in ipairs({"health","power"}) do
        local bar=bars and bars[kind]
        if not usable(bar) then bar=nil end
        local record=unit[kind]
        local fillThisBar=manageFill and not (healthOnly and kind=="power")
        if not external then
            local shared=J.ThemeManager:Read("playerFrame")
            local selection=shared[kind=="health" and "blizzardHealthTexture" or "blizzardPowerTexture"]
            if selection~="AUTO" or (kind=="health" and config.blizzardHealthColor~="STOCK") then fillThisBar=false end
            if kind=="power" and (config.blizzardPowerColor~="STOCK" or config.blizzardPowerShading=="GRADIENT") then fillThisBar=false end
        end
        local texture
        if bar then
            local ok,result=pcall(bar.GetStatusBarTexture,bar)
            if ok and usable(result) then texture=result end
        end
        if record and (not enabled or record.bar~=bar or record.texture~=texture) then
            if InCombatLockdown() then
                -- Fill identity is independent of the decorative bar anchor.
                -- Reconcile native textures after combat. Preserve the record
                -- so a temporarily missing bar can resume on the same object.
                J.Core.dirty=true
                if not enabled or record.bar~=bar then self:Visibility(record,false);bar=nil end
            else
                self:Visibility(record,false)
                if self:Restore(record) then
                    self:Retire(record);unit[kind]=nil;record=nil
                else
                    J.Core.dirty=true;bar=nil
                end
            end
        end
        local g=bar and geometry(bar)
        if g then
            local healthGeometry=bars and geometry(bars.health)
            local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
            local h,p=entry.opening.health,entry.opening.power
            -- Offsets and the small side overlap share the health bar's UI
            -- scale so differently scaled power bars stay joined to the shell.
            g.artScale=healthGeometry and healthGeometry.scale/g.scale or 1
            g.capScale=healthGeometry and healthGeometry.h/(h[4]-h[2])*healthGeometry.scale/g.scale
                or g.h/(kind=="health" and h[4]-h[2] or p[4]-p[2])
        end
        if bar and g and not record and not InCombatLockdown() then
            record={bar=bar,texture=texture,trim=unit.trims[kind],stock=not external}
            unit[kind]=record
        end
        if record and bar and g then
            if not InCombatLockdown() then
                -- Shells need only bar geometry. Unreadable native fill metadata
                -- must not silently suppress the entire ornamental frame.
                if not external or fitted then self:Layout(record,key,kind,config,id,g) end
                unit.trims[kind]=record.trim
                if fillThisBar and not record.original then
                    local original=capture(texture,record.stock)
                    if original then record.original=original;self:Watch(record) end
                end
                if fillThisBar then
                    record.fillReady=record.original and self:ApplyFill(record,kind,id) or false
                    record.fillManaged=true
                elseif self:Restore(record) then
                    record.fillReady,record.fillManaged=false,false
                end
            elseif InCombatLockdown() then
                local old=record.geometry
                if record.fillManaged~=fillThisBar or (fillThisBar and (not record.active or record.external)) or record.id~=id or not old
                    or old.w~=g.w or old.h~=g.h or old.scale~=g.scale or old.parentScale~=g.parentScale
                    or old.capScale~=g.capScale or old.artScale~=g.artScale or not record.trim or not record.trim.applied or record.trim.applied.strata~=config.strata
                    or record.trim.applied.unitFrameStrata~=config.unitFrameStrata or old.level~=g.level or old.strata~=g.strata or record.trim.applied.unitFrameWidth~=config.unitFrameWidth
                    or record.trim.applied.unitFrameHeight~=config.unitFrameHeight or record.trim.applied.unitFrameX~=config.unitFrameX or record.trim.applied.unitFrameY~=config.unitFrameY
                    or record.trim.applied.level~=config.level or record.trim.applied.layer~=config.layer then J.Core.dirty=true end
                if not external or fitted then self:RefreshArt(record,kind,id) end
            end
            self:Visibility(record,enabled and not (healthOnly and kind=="power") and record.id==id and (not external or fitted))
            local shellReady=record.trim and record.trim.assetOK and (not external or fitted)
            states[#states+1]=kind..(shellReady and
                (record.fillReady and ": shell + texture" or ": shell; native fill retained") or
                (record.fillReady and ": texture only" or ": native fill retained"))
                ..(shellReady and not record.barVisible and " (native bar hidden)" or "")
        elseif record then self:Visibility(record,false) end
    end
    self:Footer(unit,key,bars,config,id,enabled and healthOnly)
    if enabled then
        self.status[key]=#states>0 and ((bars.name or "Blizzard")..": "..table.concat(states,"; ")) or reason or "Waiting for unit-frame bars"
        if healthOnly then self.status[key]=self.status[key].."; complete artwork follows health (no power bar)" end
        if not fitted and bars and (external or bars.power) then self.status[key]=(fitReason or "Waiting to fit power-bar spacing").."; "..self.status[key] end
        if InCombatLockdown() and J.Core.dirty then self.status[key]="Changes queued until combat ends" end
        if bars then
            self.summary[key]=bars.name..(fitted and ": fitted" or ": see /jui status")
        end
        if InCombatLockdown() and J.Core.dirty then self.summary[key]="queued until combat ends" end
    end
end

-- Shared stone on Blizzard's existing health/power regions. Discovery is
-- limited to stock roots and their own party/raid registries, never nameplates
-- or third-party frames. No health, power, unit identity or progress is read.
function S:StockUnits()
    local units={}
    local function add(root,key,token)
        if usable(root) then units[root]={root=root,key=key,unit=token} end
    end
    for key,root in pairs({playerFrame=PlayerFrame,targetFrame=TargetFrame,focusFrame=FocusFrame}) do
        add(root,key,key:gsub("Frame",""))
    end
    for _,name in ipairs({"PetFrame","TargetFrameToT","FocusFrameToT"}) do add(_G[name]) end
    for i=1,5 do add(_G["Boss"..i.."TargetFrame"]) end
    local function party(frame) add(frame,"party");if usable(frame) then add(frame.PetFrame,"party") end end
    if usable(PartyFrame) then
        local pool=PartyFrame.PartyMemberFramePool
        if J.Core:IsSafe(pool) and type(pool)=="table" and type(pool.EnumerateActive)=="function" then
            for frame in pool:EnumerateActive() do party(frame) end
        end
    end
    if usable(CompactPartyFrame) then
        for _,key in ipairs({"memberUnitFrames","petUnitFrames"}) do
            local list=CompactPartyFrame[key]
            if J.Core:IsSafe(list) and type(list)=="table" then
                for i=1,5 do party(list[i]) end
            end
        end
    end
    if usable(CompactRaidFrameContainer) and type(CompactRaidFrameContainer.ApplyToFrames)=="function" then
        CompactRaidFrameContainer:ApplyToFrames("all",party)
    end
    return units
end

function S:StockBars(units)
    local bars={}
    for root,info in pairs(units or self:StockUnits()) do
        local function add(bar,kind)
            if usable(bar) and type(bar.GetStatusBarTexture)=="function" then
                bars[bar]={root=root,key=info.key,unit=info.unit,kind=kind}
            end
        end
        for _,field in ipairs({"healthbar","healthBar","HealthBar"}) do add(root[field],"health") end
        for _,field in ipairs({"manabar","powerBar","ManaBar"}) do add(root[field],"power") end
        if info.key and info.key~="party" then
            local found=J.Core.client:UnitBars(info.key)
            if found then add(found.health,"health");add(found.power,"power") end
        end
    end
    return bars
end

function S:StockTexture(info,configs)
    local shared=configs and configs.playerFrame or J.ThemeManager:Read("playerFrame")
    local selection=shared[info.kind=="health" and "blizzardHealthTexture" or "blizzardPowerTexture"]
    local healthMode=info.key=="party" and shared.blizzardPartyHealthColor
        or info.key and (configs and configs[info.key] or J.ThemeManager:Read(info.key)).blizzardHealthColor
    if info.kind=="health" and healthMode=="DARK" then return J.Media.stone end
    if selection=="STONE" or (selection=="AUTO" and shared.blizzardStone) then return J.Media.stone end
    if selection=="SMOOTH" then return "Interface\\Buttons\\WHITE8X8" end
    -- Modern stock health atlases are painted green. Class tint needs a
    -- neutral material even when the user otherwise prefers Blizzard textures.
    if info.kind=="health" and healthMode=="CLASS" then return "Interface\\TargetingFrame\\UI-StatusBar" end
    if info.kind=="power" and info.key then
        local config=info.key=="party" and shared or (configs and configs[info.key] or J.ThemeManager:Read(info.key))
        local prefix=info.key=="party" and "blizzardPartyPower" or "blizzardPower"
        if config[prefix.."Color"]~="STOCK" or config[prefix.."Shading"]=="GRADIENT" then
            return "Interface\\TargetingFrame\\UI-StatusBar"
        end
    end
end

function S:TickStockStone(restoreOnly,bars,configs)
    self.stockRecords=self.stockRecords or {}
    if InCombatLockdown() then J.Core.dirty=true;return end
    bars=bars or self:StockBars()
    for bar,info in pairs(bars) do if not self:StockTexture(info,configs) then bars[bar]=nil end end
    for bar,record in pairs(self.stockRecords) do
        local texture=bars[bar] and usable(bar) and bar:GetStatusBarTexture()
        if not bars[bar] or texture~=record.texture then
            if self:Restore(record) then self:Retire(record);self.stockRecords[bar]=nil end
        end
    end
    if restoreOnly then return end
    local ready=0
    for bar,info in pairs(bars) do
        local texture=bar:GetStatusBarTexture()
        local record=self.stockRecords[bar]
        if not record and usable(texture) then
            local original=capture(texture,true)
            if original then
                record={bar=bar,texture=texture,original=original,stock=true}
                self.stockRecords[bar]=record;self:Watch(record)
            end
        end
        if record and record.texture==texture and self:ApplyFill(record,info.kind,"CLASS_PALADIN",self:StockTexture(info,configs)) then ready=ready+1 end
    end
    self.stockStatus="Custom textures on "..ready.." stock bars; health and power choices are independent."
end

function S:StockFill(bar)
    local record=self.stockRecords and self.stockRecords[bar]
    if record and record.active then return record end
    for _,unit in pairs(self.units) do
        for _,kind in ipairs({"health","power"}) do
            record=unit[kind]
            if record and record.bar==bar and record.stock and record.active then return record end
        end
    end
end

-- A precolored Focus/Rage/etc. atlas changes the result of a custom tint.
-- Reassert only an already prepared stock material on the same native fill.
-- The StatusBar owns its live UVs and progress; do not move, recreate or refit it.
function S:RefreshCombatPowerTexture(bar)
    local record=self:StockFill(bar)
    if not InCombatLockdown() or not record or record.writing or not record.externalSelection
        or not usable(bar) or not usable(record.texture) or type(bar.SetStatusBarTexture)~="function" then return end
    local ok,current=pcall(bar.GetStatusBarTexture,bar)
    if not ok or not J.Core:IsSafe(current) or current~=record.texture then return end
    local latest=capture(record.texture,true)
    if not latest then return end
    if latest.atlas or latest.path~=record.fillPath then
        record.original=latest
        record.writing=true
        local loaded
        ok=J.Core:Protect("stock power material",function() loaded=bar:SetStatusBarTexture(record.fillPath) end)
        record.writing=false
        if not ok or not J.Core:IsSafe(loaded) or loaded==false then J.Core.dirty=true;return end
        record.revision=(record.revision or 0)+1
    end
    record.external,record.externalSelection=false,false
end

local function hasMask(texture,mask)
    if not usable(texture) or not usable(mask) or type(texture.GetNumMaskTextures)~="function"
        or type(texture.GetMaskTexture)~="function" then return end
    local count=texture:GetNumMaskTextures()
    if not J.Core:IsNumber(count) or count<0 or count>16 then return end
    for i=1,count do
        local current=texture:GetMaskTexture(i)
        if not J.Core:IsSafe(current) then return end
        if current==mask then return true end
    end
    return false
end

-- The stock player mask keeps its original atlas dimensions when the mana
-- StatusBar is fitted to our shell. Let the existing rectangular fill reach
-- that opening; the shell provides the contour. Touch only this known mask,
-- never provider masks, mask artwork, progress, or any other native region.
function S:TickPowerMask()
    self.powerMasks=self.powerMasks or {}
    if InCombatLockdown() then return end
    local bar=self.powerMaskBar
    local ok,texture=pcall(function() return usable(bar) and bar:GetStatusBarTexture() end)
    if not ok then texture=nil end
    local mask=usable(bar) and bar.ManaBarMask
    if not usable(texture) or not usable(mask) then texture,mask=nil,nil end
    for region,record in pairs(self.powerMasks) do
        if region~=texture or record.mask~=mask then
            local attached=hasMask(region,record.mask)
            if attached~=nil then
                if not attached then region:AddMaskTexture(record.mask) end
                self.powerMasks[region]=nil
            end
        end
    end
    if texture and not self.powerMasks[texture] and hasMask(texture,mask)==true then
        self.powerMasks[texture]={mask=mask}
    end
    local record=texture and self.powerMasks[texture]
    if record and record.mask==mask and hasMask(texture,mask)==true then texture:RemoveMaskTexture(mask) end
end

function S:Tick()
    local configs={}
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do configs[key]=J.ThemeManager:Read(key) end
    self.stoneEnabled=configs.playerFrame.blizzardStone
    self.powerMaskBar=nil
    local bars
    if not InCombatLockdown() then J.Core:Protect("stock bar discovery",function() bars=self:StockBars() end) end
    J.Core:Protect("stock stone restoration",function() self:TickStockStone(true,bars,configs) end)
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
        J.Core:Protect(key.." skin",function() self:TickUnit(key) end)
    end
    J.Core:Protect("stock stone",function() self:TickStockStone(false,bars,configs) end)
    J.Core:Protect("stock power contour",function() self:TickPowerMask() end)
end
