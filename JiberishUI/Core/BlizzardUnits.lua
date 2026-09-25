local _,J=...
local B={units={},status={}}
J.BlizzardUnits=B
J.Core.properties.blizzardPortraitHidden={boolean=true}
J.Core.properties.blizzardNameEnabled={boolean=true}
J.Core.properties.blizzardNameX={-300,300}
J.Core.properties.blizzardNameY={-300,300}
J.Core.properties.blizzardNameSize={6,40}
J.Core.properties.blizzardNameAlign={LEFT=true,CENTER=true,RIGHT=true}
J.Core.properties.blizzardNameOutline={KEEP=true,NONE=true,OUTLINE=true,THICKOUTLINE=true}

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

local function equal(a,b)
    if #a~=#b then return false end
    for i,v in ipairs(a) do if v~=b[i] then return false end end
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

local function samePoints(a,b)
    if #a~=#b then return false end
    for i,p in ipairs(a) do for j=1,5 do if p[j]~=b[i][j] then return false end end end
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
    if not samePoints(current.points,record.last.points) then record.original.points=current.points end
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

function B:TickUnit(key)
    local config=J.ThemeManager:Resolve(key)
    local state=self.units[key]
    if (not state or (not state.portrait and not state.name)) and not config.blizzardPortraitHidden and not config.blizzardNameEnabled then
        self.status[key]="Stock portrait and name unchanged."
        return
    end
    if InCombatLockdown() then
        J.Core.dirty=true
        self.status[key]="Stock portrait/name changes and restoration wait until combat ends."
        return
    end
    if not state then state={};self.units[key]=state end
    local root,portrait,name=self:Regions(key)
    local active=false
    if usable(root) then
        local shown,alpha=root:IsVisible(),root:GetEffectiveAlpha()
        active=J.Core:IsSafe(shown) and shown==true and J.Core:IsNumber(alpha) and alpha>0
    end
    local hide=config.blizzardPortraitHidden and active and usable(portrait)
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
    local customize=config.blizzardNameEnabled and active and usable(name)
    if state.name and (not customize or state.name.region~=name) then
        if self:RestoreName(state.name) then state.name=nil end
    end
    if customize and (not state.name or state.name.region==name) then
        local current=nameState(name)
        if current then
            local record=state.name or {region=name,original=current}
            state.name=record
            adoptChanges(record,current)
            local original=record.original
            local flags=config.blizzardNameOutline=="KEEP" and original.font[3]
                or config.blizzardNameOutline=="NONE" and "" or config.blizzardNameOutline
            local wanted={font={original.font[1],config.blizzardNameSize,flags},align=config.blizzardNameAlign,
                points=copyPoints(original.points,config.blizzardNameX,config.blizzardNameY)}
            if writeName(name,current,wanted) then record.last=wanted end
        end
    end
    local status={}
    if config.blizzardPortraitHidden then status[#status+1]=hide and state.portrait and "Stock portrait image hidden" or "Waiting for stock portrait" end
    if config.blizzardNameEnabled then status[#status+1]=customize and state.name and "Stock name customized" or "Waiting for stock name" end
    self.status[key]=#status>0 and table.concat(status,"; ") or "Stock portrait and name restored."
end

function B:Tick()
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
        local ok=J.Core:Protect(key.." stock appearance",function() self:TickUnit(key) end)
        if not ok then self.status[key]="Stock appearance unavailable; see /jui status." end
    end
end
