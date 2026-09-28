local addonName,J=...
local A={}
J.Access=A

function A:Preferences()
    if not J.ProfileManager.writable or type(JiberishUIDB)~="table" then return end
    local saved=JiberishUIDB.access
    if saved==nil then
        saved={version=1,minimapIcon=false,angle=225};JiberishUIDB.access=saved
    end
    if type(saved)=="table" and saved.version==1 then return saved end
end

function A:IconEnabled()
    local p=self:Preferences()
    return p and p.minimapIcon==true or false
end

function A:SetIcon(value)
    local p=self:Preferences()
    if not p then return false end
    p.minimapIcon=value==true
    self:Tick()
    return true
end

function A:Open()
    J.Core:Protect("open settings",function() J.SettingsUI:Open() end)
end

function A:RegisterCompartment()
    local compartment=AddonCompartmentFrame
    if self.compartment==compartment or not J.Core:IsUsableFrame(compartment)
        or type(compartment.RegisterAddon)~="function" then return end
    compartment:RegisterAddon({text=J.Brand.name,icon=J.Media.logo,notCheckable=true,
        func=function() self:Open() end})
    self.compartment=compartment
end

function A:RegisterElvUI()
    local E=type(ElvUI)=="table" and ElvUI[1]
    local EP=type(E)=="table" and E.Libs and E.Libs.EP
    if self.elvui==E or type(EP)~="table" or type(EP.RegisterPlugin)~="function" then return end
    EP:RegisterPlugin(addonName,function()
        if type(E.Options)~="table" or type(E.Options.args)~="table" then return end
        E.Options.args.frostforge={type="group",name=J.Brand.name,order=100,args={
            description={type="description",name="Matching portrait, unit-frame, cast-bar and minimap artwork.",order=1},
            open={type="execute",name="Open Frostforge settings",order=2,func=function() self:Open() end},
            setup={type="execute",name="Run quick setup",order=3,func=function() J.Setup:Open() end},
        }}
    end)
    self.elvui=E
end

function A:PositionIcon()
    local b,p=self.icon,self:Preferences()
    if not b or not p or InCombatLockdown() then return end
    local map=b:GetParent()
    if not J.Core:IsUsableFrame(map) then return end
    local w,h=map:GetWidth(),map:GetHeight()
    if not J.Core:IsNumber(w) or not J.Core:IsNumber(h) then return end
    local angle=J.Core:IsNumber(p.angle) and p.angle or 225
    local radius=math.min(w,h)/2+10
    local x,y=math.cos(angle*math.pi/180)*radius,math.sin(angle*math.pi/180)*radius
    if b.x~=x or b.y~=y then b:ClearAllPoints();b:SetPoint("CENTER",map,"CENTER",x,y);b.x,b.y=x,y end
    local art=J.Core.modules.minimap.frame
    if art then
        local strata,level=art:GetFrameStrata(),art:GetFrameLevel()+5
        if b:GetFrameStrata()~=strata then b:SetFrameStrata(strata) end
        if b:GetFrameLevel()~=level then b:SetFrameLevel(level) end
    end
end

function A:CreateIcon()
    local map=Minimap
    if not J.Core:IsUsableFrame(map) or InCombatLockdown() then return end
    -- This optional launcher is interactive; the minimap artwork stays input-free.
    local b=CreateFrame("Button","JiberishUISettingsButton",map)
    self.icon=b;b:SetSize(32,32);b:EnableMouse(true)
    local texture=b:CreateTexture(nil,"ARTWORK");texture:SetAllPoints(b);texture:SetTexture(J.Media.logo)
    b:SetScript("OnMouseDown",function() b.dragged=nil end)
    b:SetScript("OnClick",function() if not b.dragged then self:Open() end;b.dragged=nil end)
    b:SetScript("OnEnter",function()
        if GameTooltip and GameTooltip.SetOwner then
            GameTooltip:SetOwner(b,"ANCHOR_LEFT");GameTooltip:SetText(J.Brand.name)
            GameTooltip:AddLine("Click to open settings. Drag to move.",1,1,1);GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart",function() if not InCombatLockdown() then b.dragging=true;b.dragged=true end end)
    b:SetScript("OnDragStop",function() b.dragging=nil end)
    b:SetScript("OnUpdate",function()
        if not b.dragging then return end
        if InCombatLockdown() then b.dragging=nil;return end
        local x,y=GetCursorPosition();local cx,cy=map:GetCenter();local scale=map:GetEffectiveScale()
        if J.Core:IsNumber(x) and J.Core:IsNumber(y) and J.Core:IsNumber(cx) and J.Core:IsNumber(cy) and J.Core:IsNumber(scale) and scale>0 then
            local p=self:Preferences()
            if p then p.angle=math.atan2(y/scale-cy,x/scale-cx)*180/math.pi;self:PositionIcon() end
        end
    end)
    b:SetScript("OnHide",function() b.dragging=nil;if GameTooltip then GameTooltip:Hide() end end)
end

function A:Tick()
    if InCombatLockdown() then return end
    self:RegisterCompartment();self:RegisterElvUI()
    local enabled=self:IconEnabled()
    if enabled and not self.icon then self:CreateIcon() end
    if self.icon then
        self:PositionIcon()
        if self.icon:IsShown()~=enabled then self.icon:SetShown(enabled) end
    end
end
