local _, J = ...
local U=J.Util
local C={}; J.Colors=C
local function query(fn,...)
    if type(fn)~='function' then return nil end
    local ok,a,b,c,d,e=pcall(fn,...)
    if not ok or not U.Safe(a) or not U.Safe(b) or not U.Safe(c) or not U.Safe(d) or not U.Safe(e) then return nil end
    return a,b,c,d,e
end
function C.Unit(frame)
    local unit=frame.displayedUnit
    if not U.Safe(unit) then return nil end
    if type(unit)~='string' then unit=frame.unit end
    if not U.Safe(unit) or type(unit)~='string' then return nil end
    return unit
end
function C.Resolve(owner,kind,config)
    local mode=config[kind..'Mode']; if mode=='native' then return nil end
    local unit=C.Unit(owner)
    if not unit then return nil end
    local connected=query(UnitIsConnected,unit)
    local dead=query(UnitIsDeadOrGhost,unit)
    if connected~=true or dead~=false then return nil end
    if UnitIsTapDenied then local tapped=query(UnitIsTapDenied,unit); if tapped~=false then return nil end end
    if kind=='health' then
        local threat=owner.displayThreatHealthBarColor
        if not U.Safe(threat) or threat then return nil end
        if mode=='custom' then return config.healthColor end
        local player=query(UnitIsPlayer,unit)
        if player==true then
            local _,class=query(UnitClass,unit)
            local rgb=class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
            if rgb and U.Number(rgb.r) and U.Number(rgb.g) and U.Number(rgb.b) then return {rgb.r,rgb.g,rgb.b} end
        elseif player==false then
            local r,g,b=query(UnitSelectionColor,unit)
            if U.Number(r) and U.Number(g) and U.Number(b) then return {r,g,b} end
        end
    elseif mode=='custom' then return config.powerColor
    else
        local _,token=query(UnitPowerType,unit)
        if type(token)=='string' then
            if config.powerColors[token] then return config.powerColors[token] end
            local rgb=PowerBarColor and PowerBarColor[token]
            if rgb and U.Number(rgb.r) and U.Number(rgb.g) and U.Number(rgb.b) then return {rgb.r,rgb.g,rgb.b} end
        end
    end
end
local function captureTexture(record)
    local texture=record.bar:GetStatusBarTexture()
    if not texture then return end
    local atlas=texture.GetAtlas and texture:GetAtlas()
    local path=texture:GetTexture()
    if U.Safe(atlas) and U.Safe(path) then record.nativeTexture=atlas or path else record.nativeTexture=nil end
    local coords={texture:GetTexCoord()}; local valid=true
    for _,v in ipairs(coords) do if not U.Number(v) then valid=false end end
    if valid then record.nativeCoords=coords end
end
function C.Attach(owner,bar,kind,mask,configGetter)
    if not bar or not bar.GetStatusBarTexture then return nil end
    if C.qualified==nil then
        if U.Combat() then return nil end
        C.probe=CreateFrame('Frame'); C.probe:Hide()
        local texture=C.probe:CreateTexture(nil,'BACKGROUND')
        local loaded=texture:SetTexture(J.Neutral)
        local path=texture:GetTexture()
        C.qualified=loaded~=false and U.Safe(path) and path~=nil
        if not C.qualified and J.Failure then J:Failure('neutral-fill','Neutral artwork is missing. Native bar fills retained; repair the addon and reload.') end
    end
    if not C.qualified then return nil end
    local record={owner=owner,bar=bar,kind=kind,mask=mask,getConfig=configGetter}
    captureTexture(record)
    local r,g,b,a=bar:GetStatusBarColor()
    if U.Number(r) and U.Number(g) and U.Number(b) then record.nativeColor={r,g,b,U.Number(a) and a or 1} end
    local texture=bar:GetStatusBarTexture()
    local function afterTexture()
        if record.busy then return end
        record.lastColor=nil
        captureTexture(record); C.RefreshSafely(record)
    end
    hooksecurefunc(bar,'SetStatusBarTexture',afterTexture)
    if texture and texture.SetAtlas then hooksecurefunc(texture,'SetAtlas',afterTexture) end
    hooksecurefunc(bar,'SetStatusBarColor',function(_,red,green,blue,alpha)
        if record.busy then return end
        record.lastColor=nil
        if U.Number(red) and U.Number(green) and U.Number(blue) then
            record.nativeColor={red,green,blue,U.Number(alpha) and alpha or 1}
        else record.nativeColor=nil end
        C.RefreshSafely(record)
    end)
    return record
end
function C.Apply(record,override)
    if record.busy or record.failed then return end
    local config=override or record.getConfig()
    if not config then return end
    local color=C.Resolve(record.owner,record.kind,config)
    local texture=record.bar:GetStatusBarTexture()
    if not texture or not record.nativeTexture then return end
    record.busy=true
    if color then
        -- Add the native shape mask before swapping a shaped atlas for a neutral fill.
        if record.mask and not record.maskApplied and not U.Combat() then
            local found=false
            if texture.GetNumMaskTextures then
                for i=1,texture:GetNumMaskTextures() do if texture:GetMaskTexture(i)==record.mask then found=true end end
            end
            if not found then texture:AddMaskTexture(record.mask); record.maskAdded=true end
            record.maskApplied=true
        end
        if record.mask and not record.maskApplied then record.busy=false; return end
        local current=texture:GetTexture()
        if not U.Safe(current) or current~=J.Neutral then
            record.bar:SetStatusBarTexture(J.Neutral)
            texture:SetTexCoord(0,1,0,1)
        end
        local old=record.lastColor
        if not old or old[1]~=color[1] or old[2]~=color[2] or old[3]~=color[3] then
            record.bar:SetStatusBarColor(color[1],color[2],color[3],1)
            record.lastColor={color[1],color[2],color[3]}
        end
        record.custom=true
    elseif record.custom then
        record.bar:SetStatusBarTexture(record.nativeTexture)
        if record.nativeCoords then texture:SetTexCoord(unpack(record.nativeCoords)) end
        if record.nativeColor then record.bar:SetStatusBarColor(unpack(record.nativeColor)) end
        record.custom=false
        record.lastColor=nil
    end
    if not color and record.maskApplied and not U.Combat() then
        if record.maskAdded then texture:RemoveMaskTexture(record.mask) end
        record.maskApplied=false; record.maskAdded=false
    end
    record.busy=false
end
function C.RefreshSafely(record)
    local ok=pcall(C.Apply,record)
    if not ok then
        record.busy=false; record.failed=true
        if J.Failure then J:Failure('color-'..record.kind,'Color update failed. Further color changes stopped; reload to restore native artwork.') end
    end
end
