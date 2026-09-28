local _, J = ...
local C = {units={},status={}}
J.CastBars = C
J.Core.properties.castBarShown = {boolean=true}
J.Core.properties.castBarSource = {AUTO=true,BLIZZARD=true,ELLESMERE=true,ELVUI=true}
J.Core.properties.castBarStyle = {CAPPED=true} -- Retained for older profile backups.
J.Core.properties.castBarArt = {MATCH=true}
J.Core.properties.castBarWeight = {.5,2}
J.Core.properties.castBarPadding = {0,8}
J.Core.properties.castBarWidth = {50,150}
J.Core.properties.castBarHeight = {50,150}
J.Core.properties.castBarStrata = J.Core:Copy(J.Core.properties.strata)
J.Core.properties.castBarStrata.AUTO=true
J.Core.properties.castBarLevel={1,100}
for id in pairs(J.UnitSkinCatalog.entries) do J.Core.properties.castBarArt[id]=true end

local keys={"playerFrame","targetFrame","focusFrame"}
local labels={BLIZZARD="Blizzard",ELLESMERE="EllesmereUI",ELVUI="ElvUI"}
local function usable(frame) return J.Core:IsUsableFrame(frame) end
local function visibility(bar)
    if not usable(bar) then return end
    local shown,alpha=bar:IsVisible(),bar:GetEffectiveAlpha()
    if not J.Core:IsSafe(shown) or not J.Core:IsNumber(alpha) then return end
    return {visible=shown==true,alpha=math.max(0,math.min(1,alpha))}
end

local function geometry(bar)
    if not usable(bar) or not usable(UIParent) or type(bar.GetStatusBarTexture)~="function" then return end
    local orientation=bar:GetOrientation()
    if not J.Core:IsSafe(orientation) or orientation~="HORIZONTAL" then return end
    local w,h,s,p=bar:GetWidth(),bar:GetHeight(),bar:GetEffectiveScale(),UIParent:GetEffectiveScale()
    local level,strata=bar:GetFrameLevel(),bar:GetFrameStrata()
    if not J.Core:IsNumber(w) or not J.Core:IsNumber(h) or not J.Core:IsNumber(s) or not J.Core:IsNumber(p)
        or w<8 or h<4 or s<=0 or p<=0 or not J.Core:IsNumber(level)
        or not J.Core:IsSafe(strata) or type(strata)~="string" or not J.Core.properties.strata[strata] then return end
    return {w=w,h=h,scale=s,parentScale=p,level=level,strata=strata}
end

function C:Artwork(config)
    if config.castBarArt=="MATCH" then return J.Portraits:Resolve(config) end
    return config.castBarArt
end

-- Register the painted rails, not the differently padded transparent canvases.
-- Outer contours are never sampled out of a thin unit-shell strip. Corners use
-- the same horizontal/vertical scale; only connecting spans fit the native bar.
function C:Pieces(entry,w,h,weight,padding,mirror)
    local factor=1.25*weight
    local scale=math.min(h/32, .65)*factor
    local limits=J.CastBorderFitLimits
    -- One common cap keeps every design usable at extreme weight / tiny bars.
    -- A design never changes corner scale just because its class changed.
    scale=math.min(scale,(w+2*padding)*.95/limits[1],(h+2*padding)*.95/limits[2])
    local side=48*scale
    local inset=entry.castInsets
    local left=(mirror and inset[3] or inset[1])*scale
    local right=(mirror and inset[1] or inset[3])*scale
    local top,bottom=inset[2]*scale,inset[4]*scale
    local x={-padding-side+left,-padding+left,w+padding-right,w+padding+side-right}
    local y={-padding-side+top,-padding+top,h+padding-bottom,h+padding+side-bottom}
    local u=mirror and {512,464,48,0} or {0,48,464,512}
    local v={0,48,80,128}
    local pieces={}
    for row=1,3 do for col=1,3 do
        if row~=2 or col~=2 then
            pieces[row..col]={x=x[col],y=y[row],w=x[col+1]-x[col],h=y[row+1]-y[row],
                u1=u[col]/512,u2=u[col+1]/512,v1=v[row]/128,v2=v[row+1]/128}
        end
    end end
    return pieces
end

function C:FitPieces(entry,w,h,weight,padding,mirror,widthPercent,heightPercent)
    local width,height=w*widthPercent/100,h*heightPercent/100
    local pieces=self:Pieces(entry,width,height,weight,padding,mirror)
    for _,piece in pairs(pieces) do
        piece.x=piece.x+(w-width)/2
        piece.y=piece.y+(h-height)/2
    end
    return pieces
end

function C:Create(key)
    local module={key=key..".castBorder"}
    -- Ellesmere's Blizzard-style bars can inherit the aura-layout aspect.
    -- Opt into its layout-only template; we have no layout scripts to disable.
    local ok,frame=pcall(CreateFrame,"Frame",nil,UIParent,"DisableUntrustedLayoutScriptsTemplate")
    if not ok or not frame then frame=CreateFrame("Frame",nil,UIParent) end
    -- Keep native anchor/show propagation from replacing our chosen layer.
    if frame.SetFixedFrameStrata then frame:SetFixedFrameStrata(true) end
    if frame.SetFixedFrameLevel then frame:SetFixedFrameLevel(true) end
    local textures={}
    for row=1,3 do for col=1,3 do
        if row~=2 or col~=2 then textures[row..col]=frame:CreateTexture(nil,"ARTWORK") end
    end end
    J.Core:FinishCreate(module,frame,textures)
    self.units[key]=module
    return module
end

local properties={"castBarShown","castBarSource","castBarStyle","castBarArt","castBarWeight","castBarPadding","castBarWidth","castBarHeight","castBarStrata","castBarLevel"}

local ranks={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8}
function C:Layering(bar,chrome,config,g,key,nativeRoot)
    local levels={[g.strata]=g.level}
    local highest=g.strata
    local visited,budget={},64
    local function inspect(frame,depth)
        if budget<=0 or not usable(frame) or visited[frame]
            or type(frame.GetFrameStrata)~="function" or type(frame.GetFrameLevel)~="function" then return end
        budget=budget-1;visited[frame]=true
        local ok,strata,level=pcall(function() return frame:GetFrameStrata(),frame:GetFrameLevel() end)
        if ok and J.Core:IsSafe(strata) and ranks[strata] and J.Core:IsNumber(level) then
            levels[strata]=math.max(levels[strata] or 0,level)
            if ranks[strata]>ranks[highest] then highest=strata end
        end
        -- Native cast chrome can live in child frames above the StatusBar.
        -- Inspect public frame layers only; do not modify the provider.
        if depth<3 and type(frame.GetChildren)=="function" then
            local ok,children=pcall(function() return {frame:GetChildren()} end)
            if ok then for _,child in ipairs(children) do inspect(child,depth+1) end end
        end
    end
    inspect(bar,0);inspect(chrome,0)
    if usable(nativeRoot) then
        -- Blizzard target/focus casts start below their unit root (499 vs 500).
        -- Their border must also clear the stock surround and JUI artwork,
        -- including hidden artwork that will become visible on the next cast.
        inspect(nativeRoot,3)
        local prefix=key=="playerFrame" and "PlayerFrame" or "TargetFrame"
        inspect(nativeRoot[prefix.."Container"],0)
        inspect(nativeRoot[prefix.."Content"],0)
        local portrait=J.Core.modules[key]
        if config.shown and portrait then inspect(portrait.frame,3) end
        local skins=J.UnitSkins.units[key]
        if config.unitFrameShown and skins then
            for _,trim in pairs(skins.trims) do inspect(trim.frame,3) end
        end
    end
    local strata=config.castBarStrata=="AUTO" and highest or config.castBarStrata
    return strata,(levels[strata] or g.level)+config.castBarLevel
end
local function changed(module,bar,g,config)
    local old=module.geometry
    if not old or module.bar~=bar then return true end
    -- Layers are reconciled separately; only size/scale and preferences
    -- require a layout update, which must wait outside combat.
    for _,key in ipairs({"w","h","scale","parentScale"}) do if g[key]~=old[key] then return true end end
    for _,key in ipairs(properties) do if module.config[key]~=config[key] then return true end end
    return false
end

function C:Paint(module,id,layout)
    local entry=J.UnitSkinCatalog.entries[id] or J.UnitSkinCatalog.entries.FACTION_NEUTRAL
    local g,c=module.geometry,module.config
    local pieces=self:FitPieces(entry,g.w,g.h,c.castBarWeight,c.castBarPadding,c.unit~="player",c.castBarWidth,c.castBarHeight)
    module.assetOK=true
    for name,piece in pairs(pieces) do
        local texture=module.textures[name]
        if layout or module.id~=id then
            -- Only our unprotected texture regions move on an identity change;
            -- the native bar and the decoration's frame anchor stay untouched.
            texture:ClearAllPoints();texture:SetPoint("TOPLEFT",module.frame,"TOPLEFT",piece.x,-piece.y)
            texture:SetSize(piece.w,piece.h)
        end
        texture:SetTexCoord(piece.u1,piece.u2,piece.v1,piece.v2)
        if texture:SetTexture(entry.cast)==false then module.assetOK=false end
    end
    module.id=id
end

function C:TickUnit(key)
    local config=J.ThemeManager:Read(key)
    local module=self.units[key]
    local combat=InCombatLockdown()
    -- Configuration changes are queued; native visibility is always respected.
    if combat and module and module.preferences then config=module.preferences
    elseif module then module.preferences=config end
    if not config.castBarShown then
        self.status[key]="off"
        if module then module.active=false;J.Core:SyncVisibility(module,nil) end
        return
    end
    local candidate,reason=J.AddOnAnchors:ResolveCastBar(key,config)
    local bar=candidate and candidate.frame
    local g=bar and geometry(bar)
    if not g then
        self.status[key]=reason or "Waiting for a horizontal cast bar with public geometry"
        if module then module.active=false;J.Core:SyncVisibility(module,nil) end
        return
    end
    g.artStrata,g.artLevel=self:Layering(bar,candidate.chrome,config,g,key,candidate.nativeRoot)
    if not module then
        if combat then J.Core.dirty=true;self.status[key]="Attachment queued until combat ends";return end
        module=self:Create(key)
        module.preferences=config
    end
    local needsLayout=changed(module,bar,g,config)
    if needsLayout and combat then
        J.Core.dirty=true;module.active=false;J.Core:SyncVisibility(module,nil)
        self.status[key]="Fitting queued until combat ends"
        return
    end
    if not combat then module.config=config end
    local present=J.Portraits:HasUnit(key)
    local id=present and self:Artwork(config) or module.id or "FACTION_NEUTRAL"
    if needsLayout then
        module.config=J.Core:Copy(config);module.geometry=g;module.bar=bar
        local f=module.frame
        f:SetScale(g.scale/g.parentScale);f:SetSize(g.w,g.h)
        f:ClearAllPoints();f:SetPoint("TOPLEFT",bar,"TOPLEFT",0,0)
        module.applied={shown=true,opacity=1}
        self:Paint(module,id,true)
    elseif module.id~=id then
        if combat and module.frame:IsProtected() then J.Core.dirty=true
        else self:Paint(module,id,false) end
    end
    -- Native cast FX can raise their level at cast start. Re-layer only our
    -- unprotected decoration, without rewriting anchors or hiding it in combat.
    local f=module.frame
    if f:GetFrameStrata()~=g.artStrata or f:GetFrameLevel()~=g.artLevel then
        if not combat or not f:IsProtected() then
            f:SetFrameStrata(g.artStrata);f:SetFrameLevel(g.artLevel)
        else J.Core.dirty=true end
    end
    module.active=true;module.source=candidate.source
    local shown=present and visibility(bar) or nil
    self.status[key]=(candidate.name or labels[candidate.source]).." - "..(module.assetOK and
        (shown and shown.visible and shown.alpha>0 and "attached; cast visible" or "attached; waiting for cast") or "artwork unavailable").." | "..g.artStrata.." / level "..g.artLevel
    J.Core:SyncVisibility(module,shown)
end

-- Strata cannot cover native trim through the artwork's transparent opening.
-- Replace only Blizzard's static rim/textbox while a usable skin is attached.
-- Reuse the reversible effect masks so native show/alpha/atlas updates cannot
-- bring the trim back mid-cast; no combat hooks or native visibility writes.
function C:SyncBlizzardChrome()
    if InCombatLockdown() then return end
    local wanted={}
    for _,module in pairs(self.units) do
        if module.active and module.assetOK and module.source=="BLIZZARD" and usable(module.bar) then
            for _,key in ipairs({"Border","TextBorder"}) do
                local region=module.bar[key]
                if usable(region) then wanted[region]="mask" end
            end
        end
    end
    self.chrome=self.chrome or {}
    J.BlizzardUnits:SyncEffectMasks(self.chrome,wanted)
end

function C:Tick()
    for _,key in ipairs(keys) do
        local ok=J.Core:Protect(key.." cast border",function() self:TickUnit(key) end)
        if not ok then self.status[key]="Attachment unavailable; see /jui status." end
        if not ok and self.units[key] then
            local module=self.units[key];module.active=false
            J.Core:Protect(key.." cast cleanup",function() J.Core:SyncVisibility(module,nil) end)
        end
    end
    J.Core:Protect("Blizzard cast trim",function() self:SyncBlizzardChrome() end)
end

-- Short visibility-only poll avoids leaving a decorative border behind when a
-- cast stops. No spell, duration, progress, interrupt or resource APIs are read.
function C:Sync()
    for key,module in pairs(self.units) do
        local ok=J.Core:Protect(key.." cast visibility",function()
            J.Core:SyncVisibility(module,module.active and J.Portraits:HasUnit(key) and visibility(module.bar) or nil)
        end)
        if not ok then
            module.active=false
            J.Core:Protect(key.." cast cleanup",function() J.Core:SyncVisibility(module,nil) end)
        end
    end
end
