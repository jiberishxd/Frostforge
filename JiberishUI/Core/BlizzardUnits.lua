local _,J=...
local B={units={},status={},textGroups={"Name","Health","Power","Level","CastName","CastTime"},textProperties={}}
J.BlizzardUnits=B
-- Stable, user-facing class palette. Do not inherit another addon's overrides.
B.classColors={
    DEATHKNIGHT={196,31,59},DEMONHUNTER={163,48,201},DRUID={255,125,10},
    EVOKER={51,147,127},HUNTER={171,212,115},MAGE={105,204,240},
    MONK={0,255,186},PALADIN={245,140,186},PRIEST={255,255,255},
    ROGUE={255,245,105},SHAMAN={0,112,222},WARLOCK={148,130,201},WARRIOR={199,156,110},
}
for _,color in pairs(B.classColors) do
    for i=1,3 do color[i]=color[i]/255 end
    color[4]=1
end
J.Core.properties.blizzardPortraitHidden={boolean=true}
J.Core.properties.blizzardPortraitFrameHidden={boolean=true}
J.Core.properties.blizzardNameEnabled={boolean=true}
J.Core.properties.blizzardNameX={-300,300}
J.Core.properties.blizzardNameY={-300,300}
J.Core.properties.blizzardNameSize={6,40}
J.Core.properties.blizzardNameAlign={KEEP=true,LEFT=true,CENTER=true,RIGHT=true}
J.Core.properties.blizzardNameOutline={KEEP=true,NONE=true,OUTLINE=true,THICKOUTLINE=true}

B.styleProperties={blizzardNameColor=true,blizzardHealthColor=true}
B.sharedStyleProperties={blizzardPartyNameColor=true,blizzardPartyHealthColor=true,blizzardHealthTexture=true,blizzardPowerTexture=true}
J.Core.properties.blizzardNameColor={STOCK=true,CLASS=true}
J.Core.properties.blizzardHealthColor={STOCK=true,CLASS=true,DARK=true}
J.Core.properties.blizzardPartyNameColor=J.Core:Copy(J.Core.properties.blizzardNameColor)
J.Core.properties.blizzardPartyHealthColor=J.Core:Copy(J.Core.properties.blizzardHealthColor)
J.Core.properties.blizzardHealthTexture={AUTO=true,STOCK=true,STONE=true,SMOOTH=true}
J.Core.properties.blizzardPowerTexture=J.Core:Copy(J.Core.properties.blizzardHealthTexture)
for _,property in ipairs({"blizzardNameColor","blizzardHealthColor","blizzardPartyNameColor","blizzardPartyHealthColor","blizzardHealthTexture","blizzardPowerTexture"}) do
    J.Core.propertyOrder[#J.Core.propertyOrder+1]=property
end
for _,prefix in ipairs({"blizzardPower","blizzardPartyPower"}) do
    local properties=prefix=="blizzardPower" and B.styleProperties or B.sharedStyleProperties
    for suffix,rule in pairs({Color={STOCK=true,CLASS=true,CUSTOM=true},Shading={SOLID=true,GRADIENT=true},Custom={hex=true}}) do
        local property=prefix..suffix
        properties[property]=true;J.Core.properties[property]=rule
    end
    for _,suffix in ipairs({"Color","Shading","Custom"}) do J.Core.propertyOrder[#J.Core.propertyOrder+1]=prefix..suffix end
end

function B:HexColor(hex)
    if not J.Core:IsSafe(hex) or type(hex)~="string" or not hex:match("^%x%x%x%x%x%x$") then return end
    return {tonumber(hex:sub(1,2),16)/255,tonumber(hex:sub(3,4),16)/255,tonumber(hex:sub(5,6),16)/255,1}
end

B.placementProperties={blizzardAurasEnabled={boolean=true},blizzardAurasX={-600,600},blizzardAurasY={-600,600},
    blizzardCastPositionEnabled={boolean=true},blizzardCastPositionX={-600,600},blizzardCastPositionY={-600,600}}
for _,property in ipairs({"blizzardAurasEnabled","blizzardAurasX","blizzardAurasY","blizzardCastPositionEnabled","blizzardCastPositionX","blizzardCastPositionY"}) do
    J.Core.properties[property]=B.placementProperties[property]
    J.Core.propertyOrder[#J.Core.propertyOrder+1]=property
end

-- The original name keys stay compatible with existing character profiles.
for _,group in ipairs(B.textGroups) do
    local prefix="blizzard"..group
    local rules={Enabled={boolean=true},X={-300,300},Y={-300,300},Size={6,40},
        Align={KEEP=true,LEFT=true,CENTER=true,RIGHT=true},Outline={KEEP=true,NONE=true,OUTLINE=true,THICKOUTLINE=true}}
    for _,suffix in ipairs({"Enabled","X","Y","Size","Align","Outline"}) do
        local rule=rules[suffix]
        local property=prefix..suffix
        if not J.Core.properties[property] then
            J.Core.properties[property]=rule
            J.Core.propertyOrder[#J.Core.propertyOrder+1]=property
        end
        B.textProperties[property]=true
    end
end

local function usable(frame) return J.Core:IsUsableFrame(frame) end
local function field(frame,key)
    if not usable(frame) then return end
    local value=frame[key]
    if J.Core:IsSafe(value) then return value end
end

-- UnitFrame_Initialize exposes these same regions on both supported clients.
-- Resolve only Blizzard's roots; no third-party unit or name label is changed.
function B:Regions(key)
    local root=key=="playerFrame" and PlayerFrame or key=="targetFrame" and TargetFrame or FocusFrame
    if not usable(root) then return end
    local container=field(root,key=="playerFrame" and "PlayerFrameContainer" or "TargetFrameContainer")
    local portrait=field(container,key=="playerFrame" and "PlayerPortrait" or "Portrait")
    local name=field(root,"name")
    if not usable(name) then
        if key=="playerFrame" then name=PlayerName
        else
            local content=field(root,"TargetFrameContent")
            name=field(field(content,"TargetFrameContentMain"),"Name")
        end
    end
    return root,portrait,name
end

function B:TextRegions(key,root,name)
    local groups={}
    for _,group in ipairs(self.textGroups) do groups[group]={} end
    local function add(group,region)
        if usable(region) and type(region.GetFont)=="function" then groups[group][region]=true end
    end
    add("Name",name)
    local prefix=key=="playerFrame" and "PlayerFrame" or "TargetFrame"
    local main=field(field(root,prefix.."Content"),prefix.."ContentMain")
    add("Level",key=="playerFrame" and PlayerLevelText or field(main,"LevelText"))
    local bars=J.Core.client:UnitBars(key)
    for kind,group in pairs({health="Health",power="Power"}) do
        local bar=bars and bars[kind]
        for _,name in ipairs({"TextString","HealthBarText","ManaBarText","LeftText","RightText","DeadText","UnconsciousText"}) do
            add(group,field(bar,name))
        end
        -- Target health labels belong to the bar container in current XML.
        if kind=="health" then
            local container=field(main,"HealthBarsContainer")
            for _,name in ipairs({"HealthBarText","LeftText","RightText","DeadText","UnconsciousText"}) do add(group,field(container,name)) end
        end
    end
    -- Include idle player variants so text is ready before the first cast.
    for _,bar in ipairs(J.Core.client:CastBars(key) or {}) do
        add("CastName",field(bar,"Text"));add("CastTime",field(bar,"CastTimeText"))
    end
    return groups
end

function B:PortraitDecorations(key,root)
    local player=key=="playerFrame"
    local prefix=player and "PlayerFrame" or "TargetFrame"
    local container=field(root,prefix.."Container")
    local content=field(root,prefix.."Content")
    local main=field(content,prefix.."ContentMain")
    local contextual=field(content,prefix.."ContentContextual")
    local regions={}
    local function add(region,animated)
        if usable(region) and type(region.SetAlpha)=="function" then regions[region]=animated and "mask" or true end
    end
    -- Stock rim and bar border share one texture. Hide that texture only;
    -- never hide a container holding health, power, names or secure controls.
    for _,name in ipairs({"FrameTexture","VehicleFrameTexture","AlternatePowerFrameTexture","BossPortraitFrameTexture"}) do add(field(container,name)) end
    for _,name in ipairs({"FrameFlash","Flash"}) do add(field(container,name),true) end
    add(field(main,"StatusTexture"),true)
    for _,name in ipairs({"LevelBackgroundCircle","PvpBackgroundCircle","PvpBackgroundIcon","HitIndicator"}) do add(field(main,name)) end
    add(player and PlayerLevelText or field(main,"LevelText"))
    for _,name in ipairs({"HighLevelTexture","PlayerPortraitCornerIcon","PrestigePortrait","PrestigeBadge","PVPIcon","PvpIcon","PvpBackgroundCircle","PvpBackgroundIcon","AttackIcon","PlayerRestLoop"}) do add(field(contextual,name)) end
    return regions
end

-- Blizzard rewrites both alpha and vertex color on combat flashes. A separate
-- zero-alpha mask survives those animations and atlas swaps without hooks or
-- combat writes. Remove only our mask; preserve every native texture/mask.
function B:SyncEffectMasks(state,wanted)
    state.effectMasks=state.effectMasks or {}
    for region,record in pairs(state.effectMasks) do
        if record.active and wanted[region]~="mask" and usable(region) then
            region:RemoveMaskTexture(record.mask);record.active=false
        end
    end
    for region,mode in pairs(wanted) do
        if mode=="mask" and type(region.AddMaskTexture)=="function" and type(region.RemoveMaskTexture)=="function" then
            local record=state.effectMasks[region]
            local parent=region:GetParent()
            if not record and usable(parent) and type(parent.CreateMaskTexture)=="function" then
                local mask=parent:CreateMaskTexture(nil,"BACKGROUND")
                mask:SetColorTexture(0,0,0,0);mask:SetAllPoints(region)
                record={mask=mask};state.effectMasks[region]=record
            end
            if record and not record.active then region:AddMaskTexture(record.mask);record.active=true end
        end
    end
end

function B:SyncPortraitDecorations(state,wanted)
    self:SyncEffectMasks(state,wanted)
    state.decorations=state.decorations or {}
    for region,original in pairs(state.decorations) do
        if not wanted[region] and usable(region) then
            local alpha=region:GetAlpha()
            if J.Core:IsNumber(alpha) then
                if alpha==0 then region:SetAlpha(original) end
                state.decorations[region]=nil
            end
        end
    end
    for region in pairs(wanted) do
        local alpha=region:GetAlpha()
        if J.Core:IsNumber(alpha) then
            if state.decorations[region]==nil or alpha~=0 then state.decorations[region]=alpha end
            if alpha~=0 then region:SetAlpha(0) end
        end
    end
end

local function equal(a,b)
    if #a~=#b then return false end
    for i,v in ipairs(a) do
        if type(v)=="number" and type(b[i])=="number" then
            if math.abs(v-b[i])>.001 then return false end
        elseif v~=b[i] then return false end
    end
    return true
end

local function nameState(name)
    if not usable(name) or type(name.GetFont)~="function" then return end
    local path,size,flags=name:GetFont()
    local align=name:GetJustifyH()
    if not J.Core:IsSafe(path) or type(path)~="string" or not J.Core:IsNumber(size)
        or not J.Core:IsSafe(flags) or (flags~=nil and type(flags)~="string")
        or not J.Core:IsSafe(align) or not J.Core.properties.blizzardNameAlign[align] then return end
    local points=B:AnchorPoints(name)
    if not points then return end
    return {font={path,size,flags or ""},align=align,points=points}
end

function B:AnchorPoints(name)
    if not usable(name) or type(name.GetNumPoints)~="function" then return end
    local count=name:GetNumPoints()
    if not J.Core:IsNumber(count) or count<1 or count>8 then return end
    local points={}
    for i=1,count do
        local point,relative,relativePoint,x,y=name:GetPoint(i)
        if not J.Core:IsSafe(point) or not J.Core.properties.point[point]
            or not J.Core:IsSafe(relativePoint) or not J.Core.properties.point[relativePoint]
            or not J.Core:IsNumber(x) or not J.Core:IsNumber(y) then return end
        if not J.Core:IsSafe(relative) then return end
        if relative==nil then relative=name:GetParent() end
        if not usable(relative) then return end
        points[i]={point,relative,relativePoint,x,y}
    end
    return points
end

local function pointFor(points,anchor)
    for _,point in ipairs(points) do if point[1]==anchor then return point end end
end
local function samePoints(a,b)
    if #a~=#b then return false end
    for _,point in ipairs(a) do
        local other=pointFor(b,point[1])
        if not other or not equal(point,other) then return false end
    end
    return true
end

-- Copy point tuples without deep-copying native frame references.
local function copyPoints(points,dx,dy)
    local out={}
    for i,p in ipairs(points) do out[i]={p[1],p[2],p[3],p[4]+(dx or 0),p[5]+(dy or 0)} end
    return out
end

local function adoptChanges(record,current)
    if not record.last then return end
    if not equal(current.font,record.last.font) then record.original.font=current.font end
    if current.align~=record.last.align then record.original.align=current.align end
    if not samePoints(current.points,record.last.points) then
        local baseline={}
        for i,point in ipairs(current.points) do
            local previous=pointFor(record.last.points,point[1])
            local original=pointFor(record.original.points,point[1])
            -- Blizzard may replace just one anchor or coordinate. Preserve the
            -- native baseline for every coordinate that still matches our write.
            if previous and original and point[2]==previous[2] and point[3]==previous[3] then
                baseline[i]={point[1],point[2],point[3],
                    math.abs(point[4]-previous[4])<=.001 and original[4] or point[4],
                    math.abs(point[5]-previous[5])<=.001 and original[5] or point[5]}
            else baseline[i]={unpack(point)} end
        end
        record.original.points=baseline
    end
end

local function writeName(name,current,wanted)
    if not equal(current.font,wanted.font) then
        if name:SetFont(unpack(wanted.font))==false then return false end
    end
    if current.align~=wanted.align then name:SetJustifyH(wanted.align) end
    if not samePoints(current.points,wanted.points) then
        name:ClearAllPoints()
        for _,point in ipairs(wanted.points) do name:SetPoint(unpack(point)) end
    end
    return true
end

function B:RestoreName(record)
    local current=nameState(record.region)
    if not current then return false end
    adoptChanges(record,current)
    return writeName(record.region,current,record.original)
end

function B:ApplyText(record,current,config,group)
    adoptChanges(record,current)
    local prefix="blizzard"..group
    local original=record.original
    local outline=config[prefix.."Outline"]
    local flags=outline=="KEEP" and original.font[3] or outline=="NONE" and "" or outline
    local align=config[prefix.."Align"]
    local wanted={font={original.font[1],config[prefix.."Size"],flags},
        align=align=="KEEP" and original.align or align,
        points=copyPoints(original.points,config[prefix.."X"],config[prefix.."Y"])}
    -- Engine readback can quantize anchors or font sizes. Do not use desired
    -- floats as the next comparison baseline or mistake our own result for a
    -- fresh Blizzard layout. Repeated ticks then need no additional writes.
    local sameRequest=record.wanted and equal(record.wanted.font,wanted.font)
        and record.wanted.align==wanted.align and samePoints(record.wanted.points,wanted.points)
    local sameActual=record.last and equal(current.font,record.last.font)
        and current.align==record.last.align and samePoints(current.points,record.last.points)
    if sameRequest and sameActual then return end
    if writeName(record.region,current,wanted) then
        record.wanted=wanted
        record.last=nameState(record.region) or wanted
    end
end

function B:SyncText(state,groups,config,active)
    state.text=state.text or {}
    local wanted={}
    for _,group in ipairs(self.textGroups) do
        -- Player casts can be visible while the stock player frame is hidden.
        local enabled=config["blizzard"..group.."Enabled"] and (active or group=="CastName" or group=="CastTime")
        if enabled then for region in pairs(groups[group]) do wanted[region]=group end end
    end
    for region,record in pairs(state.text) do
        if not wanted[region] and self:RestoreName(record) then state.text[region]=nil end
    end
    for region,group in pairs(wanted) do
        local current=nameState(region)
        if current then
            local record=state.text[region] or {region=region,original=current}
            state.text[region]=record
            self:ApplyText(record,current,config,group)
        end
    end
    -- Preserve the existing name status reference for diagnostics.
    state.name=nil
    for region in pairs(groups.Name) do state.name=state.text[region] end
end

function B:TickUnit(key)
    local config=J.ThemeManager:Resolve(key)
    local state=self.units[key]
    local textEnabled=false
    for _,group in ipairs(self.textGroups) do if config["blizzard"..group.."Enabled"] then textEnabled=true end end
    if (not state or (not state.portrait and not next(state.text or {}) and not next(state.decorations or {})))
        and not config.blizzardPortraitHidden and not config.blizzardPortraitFrameHidden and not textEnabled then
        self.status[key]="Stock portrait and text unchanged."
        return
    end
    if InCombatLockdown() then
        J.Core.dirty=true
        self.status[key]="Stock portrait/text changes and restoration wait until combat ends."
        return
    end
    if not state then state={};self.units[key]=state end
    local root,portrait,name=self:Regions(key)
    local active=false
    if usable(root) then
        local shown,alpha=root:IsVisible(),root:GetEffectiveAlpha()
        active=J.Core:IsSafe(shown) and shown==true and J.Core:IsNumber(alpha) and alpha>0
    end
    local full=config.blizzardPortraitFrameHidden and config.unitFrameShown and active
    self:SyncPortraitDecorations(state,full and self:PortraitDecorations(key,root) or {})
    local hide=(config.blizzardPortraitHidden or full) and active and usable(portrait)
    if state.portrait and (not hide or state.portrait.region~=portrait) then
        local old=state.portrait
        if usable(old.region) then
            local alpha=old.region:GetAlpha()
            if J.Core:IsNumber(alpha) then
                if alpha==0 then old.region:SetAlpha(old.alpha) end
                state.portrait=nil
            end
        end
    end
    if hide and (not state.portrait or state.portrait.region==portrait) then
        local alpha=portrait:GetAlpha()
        if J.Core:IsNumber(alpha) then
            state.portrait=state.portrait or {region=portrait,alpha=alpha}
            if alpha~=0 then state.portrait.alpha=alpha;portrait:SetAlpha(0) end
        end
    end
    self:SyncText(state,self:TextRegions(key,root,name),config,active)
    local status={}
    if config.blizzardPortraitFrameHidden then status[#status+1]=full and "Stock portrait, shared border and level badge hidden" or "Full portrait removal needs Unit-frame art enabled" end
    if config.blizzardPortraitHidden then status[#status+1]=hide and state.portrait and "Stock portrait image hidden" or "Waiting for stock portrait" end
    local labels={Name="name",Health="health",Power="power",Level="level",CastName="cast name",CastTime="cast time"}
    local enabled={}
    for _,group in ipairs(self.textGroups) do
        if config["blizzard"..group.."Enabled"] then enabled[#enabled+1]=labels[group] end
    end
    if #enabled>0 then status[#status+1]="Text controls: "..table.concat(enabled,", ") end
    self.status[key]=#status>0 and table.concat(status,"; ") or "Stock portrait and text restored."
end

-- Prefer Blizzard's public accessor; the XML child path is a fallback for
-- clients that do not expose the mixin yet. Never inspect aura buttons/data.
function B:PlacementRegion(root,kind)
    if kind=="CastPosition" then return field(root,"spellbar") end
    local getter=field(root,"GetAuraContainer")
    if type(getter)=="function" then
        local ok,region=pcall(getter,root)
        if ok and usable(region) then return region end
    end
    return field(field(field(root,"TargetFrameContent"),"TargetFrameContentContextual"),"Auras")
end

function B:WatchAuraLayout(key,root)
    if not usable(root) or type(field(root,"AnchorAuraContainer"))~="function" then return end
    self.auraLayoutHooks=self.auraLayoutHooks or setmetatable({}, {__mode="k"})
    if self.auraLayoutHooks[root] then return end
    -- Apply after native layout, not only on our periodic scan: Blizzard's
    -- ApplyLayout callback runs after that scan and otherwise erases X/Y.
    hooksecurefunc(root,"AnchorAuraContainer",function()
        local current=key=="targetFrame" and TargetFrame or FocusFrame
        if not usable(current) or current~=root then return end
        self:TickPlacement(key,"Auras",true)
    end)
    self.auraLayoutHooks[root]=true
end

function B:ApplyPlacement(key,kind,nativeAnchor)
    self.placements=self.placements or {}
    local id=key..kind;local prefix="blizzard"..kind
    local config=J.ThemeManager:Resolve(key)
    local record=self.placements[id]
    if record and nativeAnchor then record.nativeAnchor=true end
    nativeAnchor=nativeAnchor or (record and record.nativeAnchor)
    local enabled=config[prefix.."Enabled"]
    if not record and not enabled then self.placementStatus[id]="Blizzard position (customization off).";return end
    if InCombatLockdown() then
        J.Core.dirty=true;self.placementStatus[id]="Saved; placement applies after combat.";return
    end
    local root=key=="targetFrame" and TargetFrame or FocusFrame
    if enabled and kind=="Auras" then self:WatchAuraLayout(key,root) end
    local region=self:PlacementRegion(root,kind)
    if record and (record.region~=region or not enabled) then
        local current=self:AnchorPoints(record.region)
        if not current then self.placementStatus[id]="Waiting to restore previous placement.";return end
        -- A native reanchor already restored its own baseline. Only undo ours.
        if not (nativeAnchor and record.region==region) and record.last and samePoints(current,record.last) then
            record.region:ClearAllPoints()
            for _,point in ipairs(record.original) do record.region:SetPoint(unpack(point)) end
        end
        self.placements[id]=nil;record=nil
    end
    if not enabled then self.placementStatus[id]="Blizzard position restored.";return end
    local current=self:AnchorPoints(region)
    if not current then self.placementStatus[id]="Waiting for readable Blizzard anchors.";return end
    if not record then record={region=region,original=current};self.placements[id]=record end
    -- A native callback supplies a fresh baseline even when its coordinates
    -- happen to equal our previous offset. Do not compound our own writes.
    if nativeAnchor or (record.last and not samePoints(current,record.last)) then record.original=current end
    local x,y=config[prefix.."X"],config[prefix.."Y"]
    local wanted=copyPoints(record.original,x,y)
    local unchanged=not nativeAnchor and record.last and samePoints(current,record.last) and record.x==x and record.y==y
    if not unchanged then
        if not samePoints(current,wanted) then
            region:ClearAllPoints()
            for _,point in ipairs(wanted) do region:SetPoint(unpack(point)) end
        end
        record.last=self:AnchorPoints(region) or wanted
        record.x,record.y=x,y
    end
    record.nativeAnchor=nil
    self.placementStatus[id]=string.format("Applied: X %g / Y %g",x,y)
end

function B:TickPlacement(key,kind,nativeAnchor)
    self.placementStatus=self.placementStatus or {}
    self.placementBusy=self.placementBusy or {}
    local id=key..kind
    if self.placementBusy[id] then return end
    self.placementBusy[id]=true
    local ok=J.Core:Protect(key.." stock "..kind,function() self:ApplyPlacement(key,kind,nativeAnchor) end)
    self.placementBusy[id]=nil
    if not ok then self.placementStatus[id]="Placement unavailable; see /jui status." end
end

function B:Tick()
    J.Core:Protect("stock colors",function() self:TickColors() end)
    for _,key in ipairs({"targetFrame","focusFrame"}) do
        for _,kind in ipairs({"Auras","CastPosition"}) do
            self:TickPlacement(key,kind)
        end
    end
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
        local ok=J.Core:Protect(key.." stock appearance",function() self:TickUnit(key) end)
        if not ok then self.status[key]="Stock appearance unavailable; see /jui status." end
    end
end

local function safeColor(...)
    local c={...};if J.Core:IsSafe(c[4]) and c[4]==nil then c[4]=1 end
    for i=1,4 do if not J.Core:IsNumber(c[i]) then return end end
    return c
end
local function sameColor(a,b)
    if not a or not b then return false end
    for i=1,4 do if math.abs(a[i]-b[i])>.0001 then return false end end
    return true
end
local function classColor(info)
    local token=info.unit
    if not token then
        token=field(info.root,"displayedUnit") or field(info.root,"unit") or field(info.root,"unitToken")
    end
    if not J.Core:IsSafe(token) or type(token)~="string" or type(UnitIsPlayer)~="function" or type(UnitClass)~="function" then return end
    local player=UnitIsPlayer(token)
    if not J.Core:IsSafe(player) or player~=true then return end
    local _,class=UnitClass(token)
    if not J.Core:IsSafe(class) or type(class)~="string" then return end
    return B.classColors[class]
end

local function resourceColor(record)
    local token=field(record.region,"powerToken")
    local color=type(token)=="string" and PowerBarColor and PowerBarColor[token]
    if not color then
        local index=field(record.region,"powerType")
        if J.Core:IsNumber(index) then color=PowerBarColor and PowerBarColor[index] end
    end
    if color then return safeColor(color.r,color.g,color.b,record.original and record.original[4] or 1) end
end

local function materialColor(record)
    local material=J.UnitSkins:StockFill(record.region)
    if not material or not material.original.atlas then return end
    -- Blizzard's modern atlases contain their green/blue/etc. pixels and use
    -- a white tint. Replacing them with neutral stone must supply those hues.
    -- Preserve native grey/disconnect overrides instead of painting over them.
    local c=record.original
    if not c or c[1]~=1 or c[2]~=1 or c[3]~=1 then return end
    if record.kind=="health" then return {0,1,0,c[4]} end
    if material.fillPath~=J.Media.stone and material.fillPath~="Interface\\Buttons\\WHITE8X8"
        and material.fillPath~="Interface\\TargetingFrame\\UI-StatusBar" then return end
    return resourceColor(record)
end

function B:RefreshColor(record)
    if record.writing or not record.active or not usable(record.region) or not usable(record.info.root) then return end
    local current=safeColor(record.region[record.get](record.region))
    -- Never compare restricted client colors or infer any combat value.
    if not current then return end
    if not sameColor(current,record.last) then record.original=current end
    local desired=record.mode=="DARK" and {.12,.12,.13,1}
        or record.mode=="CLASS" and classColor(record.info)
        or record.mode=="CUSTOM" and self:HexColor(record.custom)
    local material=record.kind~="name" and J.UnitSkins:StockFill(record.region)
    local texture=material and material.texture
    local gradient=(desired and record.kind=="health" and record.mode=="CLASS" or record.kind=="power" and record.shading=="GRADIENT")
        and usable(texture) and type(texture.SetGradient)=="function" and type(CreateColor)=="function"
    desired=desired or materialColor(record) or record.original
    local changed=not sameColor(desired,record.desired) or record.colorDirty
        or record.texture~=texture or record.textureRevision~=(material and material.revision)
        or record.gradientActive~=not not gradient
    if desired and ((gradient and (changed or not sameColor(current,record.last)))
        or (not gradient and (record.gradientActive or not sameColor(current,desired)))) then
        record.writing=true
        local ok=J.Core:Protect("stock color",function()
            record.region[record.set](record.region,unpack(desired))
            if gradient then
                texture:SetGradient("VERTICAL",CreateColor(desired[1]*.72,desired[2]*.72,desired[3]*.72,desired[4]),CreateColor(unpack(desired)))
            end
        end)
        record.writing=false
        if not ok then return end
    end
    record.last=safeColor(record.region[record.get](record.region))
    record.desired,record.gradientActive,record.colorDirty=desired,not not gradient,false
    record.texture,record.textureRevision=texture,material and material.revision
end

function B:TickColors()
    self.colors=self.colors or {}
    if InCombatLockdown() then
        -- Existing opt-in color records can follow public class identity in
        -- combat. Hooks/toggles, geometry and restoration still wait outside it.
        for _,record in pairs(self.colors) do self:RefreshColor(record) end
        return
    end
    local wanted={}
    local shared=J.ThemeManager:Resolve("playerFrame")
    local configs={playerFrame=shared,targetFrame=J.ThemeManager:Resolve("targetFrame"),focusFrame=J.ThemeManager:Resolve("focusFrame")}
    local enabled=next(J.UnitSkins.stockRecords or {})~=nil
        or shared.blizzardPartyNameColor~="STOCK" or shared.blizzardPartyHealthColor~="STOCK"
        or shared.blizzardPartyPowerColor~="STOCK" or shared.blizzardPartyPowerShading=="GRADIENT"
    for _,unit in pairs(J.UnitSkins.units) do
        enabled=enabled or (unit.health and unit.health.stock and unit.health.active)
            or (unit.power and unit.power.stock and unit.power.active)
    end
    for _,config in pairs(configs) do
        enabled=enabled or config.blizzardNameColor~="STOCK" or config.blizzardHealthColor~="STOCK"
            or config.blizzardPowerColor~="STOCK" or config.blizzardPowerShading=="GRADIENT"
    end
    local restoring=false
    for _,record in pairs(self.colors) do restoring=restoring or record.active end
    if not enabled and not restoring then return end
    local units=enabled and J.UnitSkins:StockUnits() or {}
    local function add(region,info,mode,kind)
        if mode and usable(region) and (mode~="STOCK" or (kind~="name" and J.UnitSkins:StockFill(region))) then
            wanted[region]={info=info,mode=mode,kind=kind}
        end
    end
    for _,info in pairs(units) do
        if info.key then
            local config=info.key=="party" and shared or configs[info.key]
            local mode=info.key=="party" and config.blizzardPartyNameColor or config.blizzardNameColor
            local name=field(info.root,"name") or field(info.root,"Name")
            add(name,info,mode,"name")
        end
    end
    for bar,info in pairs(J.UnitSkins:StockBars(units)) do
        local mode="STOCK"
        if info.kind=="health" and info.key then
            mode=info.key=="party" and shared.blizzardPartyHealthColor or configs[info.key].blizzardHealthColor
        end
        add(bar,info,mode,info.kind)
        if info.kind=="power" and info.key then
            local config=info.key=="party" and shared or configs[info.key]
            local prefix=info.key=="party" and "blizzardPartyPower" or "blizzardPower"
            if config[prefix.."Color"]~="STOCK" or config[prefix.."Shading"]=="GRADIENT" or wanted[bar] then
                wanted[bar]={info=info,kind="power",mode=config[prefix.."Color"],shading=config[prefix.."Shading"],custom=config[prefix.."Custom"]}
            end
        end
    end
    for region,record in pairs(self.colors) do
        if record.active and not wanted[region] and usable(region) then
            local current=safeColor(region[record.get](region))
            if current then
                record.active=false
                if sameColor(current,record.last) and record.original then region[record.set](region,unpack(record.original)) end
            end
        end
    end
    for region,options in pairs(wanted) do
        local record=self.colors[region]
        local get=options.kind~="name" and "GetStatusBarColor" or "GetTextColor"
        local set=options.kind~="name" and "SetStatusBarColor" or "SetTextColor"
        if type(region[get])=="function" and type(region[set])=="function" then
            local current=safeColor(region[get](region))
            if current then
                if not record then
                    record={region=region,get=get,set=set};self.colors[region]=record
                    local function changed()
                        if record.active and not record.writing then record.colorDirty=true;self:RefreshColor(record) end
                    end
                    hooksecurefunc(region,set,changed)
                    if options.kind=="name" then
                        for _,method in ipairs({"SetVertexColor","SetText"}) do
                            if type(region[method])=="function" then hooksecurefunc(region,method,changed) end
                        end
                    end
                end
                if not record.active then record.original=current;record.last=nil end
                record.info,record.mode,record.kind,record.active=options.info,options.mode,options.kind,true
                record.shading,record.custom=options.shading,options.custom
                self:RefreshColor(record)
            end
        end
    end
end
