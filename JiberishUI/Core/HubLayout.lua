local _,J=...
local U=J.Util
-- Only explicitly named Blizzard containers may be docked. Buttons retain their
-- parents, secure attributes, bindings, paging, visibility and internal layout.
local L={records={}};J.HubLayout=L
function L.Geometry(config)
    local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
    if not U.Number(sw) or not U.Number(sh) or sw<=0 or sh<=0 then return end
    local w,h=math.min(config.hubWidth,sw),math.min(config.hubHeight,sh)
    local x=U.Clamp((sw-w)/2+config.hubX,0,sw-w)
    local y=U.Clamp(config.hubY,0,sh-h)
    return x,y,w,h,x+w/2-sw/2
end
function L.Editing()
    local shown=EditModeManagerFrame and EditModeManagerFrame:IsShown()
    return U.Safe(shown) and shown==true
end
local function snapshot(frame)
    local scale=frame:GetScale();local points={}
    if not U.Number(scale) or scale<=0 then return end
    local count=frame:GetNumPoints()
    if not U.Number(count) or count<1 or count>8 then return end
    for i=1,count do
        local point,relative,relativePoint,x,y=frame:GetPoint(i)
        if not U.Safe(point) or not U.Safe(relative) or not U.Safe(relativePoint) or not U.Number(x) or not U.Number(y) then return end
        points[#points+1]={point,relative,relativePoint,x,y}
    end
    return {scale=scale,points=points}
end
function L:Remember(frame)
    local r=self.records[frame]
    if not r then
        r={frame=frame};self.records[frame]=r
        for _,method in ipairs({'SetPoint','SetScale'}) do
            hooksecurefunc(frame,method,function()
                if r.busy or not r.docked then return end
                local latest=snapshot(frame)
                if latest then
                    -- Scale updates must not replace saved native anchors with
                    -- our dock anchor, and vice versa.
                    if method=='SetScale' then r.native.scale=latest.scale else r.native.points=latest.points end
                end
                r.dirty=true
            end)
        end
    end
    if not r.docked then r.native=snapshot(frame) end
    return r.native and r or nil
end
function L:Release(except)
    if U.Combat() then return end
    for frame,r in pairs(self.records) do
        if r.docked and not (except and except[frame]) then
            r.busy=true
            frame:SetScale(r.native.scale);frame:ClearAllPoints()
            for _,point in ipairs(r.native.points) do frame:SetPoint(unpack(point)) end
            r.busy=false;r.docked=false;r.last=nil
        end
    end
end
function L:Dock(frame,x,y,multiplier,used)
    if not frame or not frame.GetScale or (frame.IsForbidden and frame:IsForbidden()) then return end
    local shown=frame:IsShown();if not U.Safe(shown) or not shown then return end
    local r=self:Remember(frame);if not r then return end
    local parent=frame:GetParent();local ps=parent and parent:GetEffectiveScale() or UIParent:GetEffectiveScale()
    local us=UIParent:GetEffectiveScale()
    if not U.Number(ps) or ps<=0 or not U.Number(us) or us<=0 then return end
    -- UI controls are offsets in UIParent units, independent of the native scale.
    local scale=r.native.scale*multiplier;local conversion=us/(ps*scale)
    if r.dirty or not r.last or r.last[1]~=x or r.last[2]~=y or r.last[3]~=scale then
        r.busy=true;frame:SetScale(scale);frame:ClearAllPoints()
        frame:SetPoint('BOTTOM',UIParent,'BOTTOM',x*conversion,y*conversion)
        r.busy=false;r.last={x,y,scale};r.dirty=false
    end
    r.docked=true;used[frame]=true
    local h=frame:GetHeight()
    return U.Number(h) and h*ps*scale/us or 0
end
function L:Apply(config)
    if U.Combat() then return end
    local provider=J.Integrations and J.Integrations.providers.actionbars
    if not config or not config.enabled or config.actionMode~='hub' or not config.hubDock or provider or
        J.conflicts.actionbars or self.Editing() then self:Release();return end
    local _,baseY,_,_,center=self.Geometry(config);if not center then self:Release();return end
    local used={};local y=baseY+config.hubActionsY
    for i,name in ipairs({'MainActionBar','MultiBarBottomLeft','MultiBarBottomRight'}) do
        local key='hubBar'..i
        local height=self:Dock(_G[name],center+config.hubActionsX+(config[key..'X'] or 0),y+(config[key..'Y'] or 0),
            config.hubActionsScale*(config[key..'Scale'] or 1),used)
        if height then y=y+height+config.hubRowGap end
    end
    if config.hubMicro then self:Dock(MicroMenuContainer or MicroMenu,center+config.hubMicroX,baseY+config.hubMicroY,config.hubMicroScale,used) end
    if config.hubBags then self:Dock(BagsBar,center+config.hubBagsX,baseY+config.hubBagsY,config.hubBagsScale,used) end
    self:Release(used)
end
