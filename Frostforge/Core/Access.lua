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

function A:StyleGameMenuButton(anchor)
    local b=self.gameMenuButton
    local font=b:GetFontString()
    local source=anchor:GetFontString()
    if font and source then
        local path,size,flags=source:GetFont()
        if path and J.Core:IsNumber(size) then font:SetFont(path,size,flags) end
    end
    local euiSkin=type(EllesmereUI)=="table" and C_AddOns and C_AddOns.IsAddOnLoaded
        and C_AddOns.IsAddOnLoaded("EllesmereUIBlizzardSkin")
        and (not EllesmereUIDB or EllesmereUIDB.reskinGameMenu~=false)
    if euiSkin then
        if not b.inset then
            for _,region in ipairs({b:GetRegions()}) do
                if region~=font then region:SetAlpha(0) end
            end
            local inset=CreateFrame("Frame",nil,b,"BackdropTemplate")
            inset:SetPoint("TOPLEFT",b,"TOPLEFT",2,-2)
            inset:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2)
            inset:SetFrameLevel(b:GetFrameLevel());inset:EnableMouse(false)
            inset:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
                edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
            inset:SetBackdropBorderColor(0.25,0.25,0.25,1)
            b.inset=inset
            local highlight=b:CreateTexture(nil,"HIGHLIGHT")
            highlight:SetAllPoints(inset);highlight:SetColorTexture(1,1,1,0.1)
        end
        local color=EllesmereUIDB and EllesmereUIDB.popupMenuButtonBackgroundColor
            or {r=0.1,g=0.1,b=0.1,a=0.8}
        b.inset:SetBackdropColor(color.r,color.g,color.b,color.a==nil and 0.8 or color.a)
        if type(EllesmereUI._applyBlizzardConfiguredBorder)=="function" then
            EllesmereUI._applyBlizzardConfiguredBorder(b.inset,"popupMenuButton",1)
        end
    elseif not b.elvuiSkinned then
        local E=type(ElvUI)=="table" and ElvUI[1]
        local config=type(E)=="table" and E.private and E.private.skins and E.private.skins.blizzard
        local skins=config and config.enable and config.misc and E.GetModule and E:GetModule("Skins",true)
        if skins and type(skins.HandleButton)=="function" then
            skins:HandleButton(b);b.elvuiSkinned=true
        end
    end
end

function A:LayoutGameMenu(menu,nativeLayout)
    if menu~=self.gameMenu or not J.Core:IsUsableFrame(menu) then return end
    -- Each native Layout pass restores its own row positions and height first.
    -- A deferred/late registration may apply once to the already-open menu.
    if nativeLayout then self.gameMenuLaidOut=nil end
    local b=self.gameMenuButton
    if InCombatLockdown() then
        if not b:IsProtected() then b:Hide() end
        return
    end
    if self.gameMenuLaidOut or not menu:IsShown() then return end
    local anchor,exit,options
    for row in menu.buttonPool:EnumerateActive() do
        if J.Core:IsUsableFrame(row) then
            local label=row:GetText()
            if label==ADDONS then anchor=row
            elseif label==EXIT_GAME then exit=row
            elseif label==GAMEMENU_OPTIONS then options=row end
        end
    end
    anchor=anchor or exit or options
    if not anchor or not J.Core:IsNumber(anchor.layoutIndex) then b:Hide();return end
    local width,height=anchor:GetWidth(),anchor:GetHeight()
    if not J.Core:IsNumber(width) or width<=0 or not J.Core:IsNumber(height) or height<=0 then return end
    -- SetText creates the native template's font string lazily. Initialize it
    -- before styling; inline color survives the template's hover font changes.
    b:SetText("|cff4da6ff"..J.Brand.shortName.."|r")
    -- Optional provider styling must not prevent the row from being laid out.
    J.Core:Protect("game menu style",function() self:StyleGameMenuButton(anchor) end)
    b:SetSize(width,height)
    b:ClearAllPoints();b:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,0)
    -- Move only geometry, just as ElvUI/Ellesmere do for their own menu rows.
    -- Never acquire pooled buttons, write layout indices, rebuild the menu,
    -- replace native scripts, or call the protected Logout/Quit callbacks.
    for row in menu.buttonPool:EnumerateActive() do
        if J.Core:IsUsableFrame(row) and J.Core:IsNumber(row.layoutIndex)
            and row.layoutIndex>anchor.layoutIndex then
            local point,relative,relativePoint,x,y=row:GetPoint(1)
            -- Native rows use one menu-relative anchor. A row chained to a
            -- shifted row already moves with it, so must not be shifted twice.
            if point and relative==menu and J.Core:IsNumber(x) and J.Core:IsNumber(y) then
                row:ClearAllPoints();row:SetPoint(point,relative,relativePoint,x,y-height)
            end
        end
    end
    menu:SetHeight(menu:GetHeight()+height)
    b:Show();self.gameMenuLaidOut=true
end

function A:RegisterGameMenu()
    local menu=GameMenuFrame
    if not J.Core:IsUsableFrame(menu) or InCombatLockdown() then return end
    if self.gameMenu==menu then self:LayoutGameMenu(menu);return end
    if type(menu.Layout)~="function" or type(hooksecurefunc)~="function"
        or not menu.buttonPool or type(menu.buttonPool.EnumerateActive)~="function" then return end
    if self.gameMenuButton then self.gameMenuButton:Hide() end
    local b=CreateFrame("Button",nil,menu,"MainMenuFrameButtonTemplate")
    b:Hide()
    b:SetScript("OnClick",function()
        if InCombatLockdown() then
            J.Core:Print("Open Frostforge from the Game Menu after combat.");return
        end
        HideUIPanel(menu)
        self:Open()
    end)
    self.gameMenu,self.gameMenuButton,self.gameMenuLaidOut=menu,b,nil
    hooksecurefunc(menu,"Layout",function(frame)
        J.Core:Protect("game menu layout",function() self:LayoutGameMenu(frame,true) end)
    end)
    self:LayoutGameMenu(menu)
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
    self:RegisterGameMenu();self:RegisterCompartment();self:RegisterElvUI()
    local enabled=self:IconEnabled()
    if enabled and not self.icon then self:CreateIcon() end
    if self.icon then
        self:PositionIcon()
        if self.icon:IsShown()~=enabled then self.icon:SetShown(enabled) end
    end
end
