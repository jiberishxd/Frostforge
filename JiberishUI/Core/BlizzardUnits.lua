local _,J=...
local B={units={},status={},textGroups={"Name","Health","Power","Level","CastName","CastTime"},textProperties={}}
J.BlizzardUnits=B
J.Core.properties.blizzardPortraitHidden={boolean=true}
J.Core.properties.blizzardPortraitFrameHidden={boolean=true}
J.Core.properties.blizzardNameEnabled={boolean=true}
J.Core.properties.blizzardNameX={-300,300}
J.Core.properties.blizzardNameY={-300,300}
J.Core.properties.blizzardNameSize={6,40}
J.Core.properties.blizzardNameAlign={KEEP=true,LEFT=true,CENTER=true,RIGHT=true}
J.Core.properties.blizzardNameOutline={KEEP=true,NONE=true,OUTLINE=true,THICKOUTLINE=true}

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
    local function add(region)
        if usable(region) and type(region.SetAlpha)=="function" then regions[region]=true end
    end
    -- Stock rim and bar border share one texture. Hide that texture only;
    -- never hide a container holding health, power, names or secure controls.
    for _,name in ipairs({"FrameTexture","VehicleFrameTexture","AlternatePowerFrameTexture","FrameFlash","Flash","BossPortraitFrameTexture"}) do add(field(container,name)) end
    for _,name in ipairs({"LevelBackgroundCircle","StatusTexture","PvpBackgroundCircle","PvpBackgroundIcon"}) do add(field(main,name)) end
    add(player and PlayerLevelText or field(main,"LevelText"))
    for _,name in ipairs({"HighLevelTexture","PlayerPortraitCornerIcon","PrestigePortrait","PrestigeBadge","PVPIcon","PvpIcon","PvpBackgroundCircle","PvpBackgroundIcon"}) do add(field(contextual,name)) end
    return regions
end

function B:SyncPortraitDecorations(state,wanted)
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
    local count=name:GetNumPoints()
    if not J.Core:IsNumber(count) or count<1 or count>8 then return end
    local points={}
    for i=1,count do
        local point,relative,relativePoint,x,y=name:GetPoint(i)
        if not J.Core:IsSafe(point) or not J.Core.properties.point[point]
            or not J.Core:IsSafe(relativePoint) or not J.Core.properties.point[relativePoint]
            or not J.Core:IsNumber(x) or not J.Core:IsNumber(y) then return end
        if relative==nil then relative=name:GetParent() end
        if not usable(relative) then return end
        points[i]={point,relative,relativePoint,x,y}
    end
    return {font={path,size,flags or ""},align=align,points=points}
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

function B:Tick()
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
        local ok=J.Core:Protect(key.." stock appearance",function() self:TickUnit(key) end)
        if not ok then self.status[key]="Stock appearance unavailable; see /jui status." end
    end
end
