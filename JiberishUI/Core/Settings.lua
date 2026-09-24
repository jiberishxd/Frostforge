local _, J = ...
local S = { selected="playerFrame", controls={}, menus={} }
J.SettingsUI = S

local names = {minimap="Minimap",playerFrame="Player",targetFrame="Target",focusFrame="Focus",actionHub="Action hub"}
local modes = {{"CLASS","Automatic class"},{"RACE","Automatic race"},{"FACTION","Automatic faction"},{"FIXED","Chosen artwork"}}
local strata = {
    {"BACKGROUND","Background"},{"LOW","Low"},{"MEDIUM","Medium"},{"HIGH","High"},
    {"DIALOG","Dialog"},{"FULLSCREEN","Fullscreen"},{"FULLSCREEN_DIALOG","Fullscreen dialog"},{"TOOLTIP","Tooltip"},
}
local layers = {{"BACKGROUND","Background"},{"BORDER","Border"},{"ARTWORK","Artwork"},{"OVERLAY","Overlay"}}
local anchors = {{"FRAME","Follow native frame"},{"SCREEN","Screen"}}

local function backdrop(frame,kind)
    local slider=kind=="slider"
    if kind=="outer" and not frame.underlay then
        frame.underlay=frame:CreateTexture(nil,"BACKGROUND",nil,-8)
        frame.underlay:SetPoint("TOPLEFT",frame,"TOPLEFT",11,-12)
        frame.underlay:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-12,11)
        frame.underlay:SetColorTexture(0.06,0.045,0.025,1)
    end
    frame:SetBackdrop({
        bgFile=slider and "Interface\\Buttons\\UI-SliderBar-Background" or "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile=slider and "Interface\\Buttons\\UI-SliderBar-Border" or
            (kind=="outer" and "Interface\\DialogFrame\\UI-DialogBox-Border" or "Interface\\Tooltips\\UI-Tooltip-Border"),
        tile=true,tileSize=slider and 8 or 32,edgeSize=slider and 8 or (kind=="outer" and 32 or 16),
        insets=kind=="outer" and {left=11,right=12,top=12,bottom=11} or {left=4,right=4,top=4,bottom=4},
    })
    frame:SetBackdropColor(0.72,0.63,0.48,1)
    frame:SetBackdropBorderColor(0.72,0.58,0.34,1)
end
local function panel(parent,x,y,width,height)
    local p=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    p:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);p:SetSize(width,height)
    p:SetFrameLevel(parent:GetFrameLevel());p:EnableMouse(false);backdrop(p,"inset")
    return p
end
local function art(parent,path,layer)
    local t=parent:CreateTexture(nil,layer or "BACKGROUND")
    t:SetAllPoints(parent);t:SetTexture(path)
    return t
end
local function text(parent,value,x,y,width,font)
    local label=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    label:SetWidth(width); label:SetJustifyH("LEFT"); label:SetText(value)
    return label
end
local function button(parent,value,x,y,width,callback,card)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); b:SetSize(width,28)
    b:EnableMouse(true)
    if card then backdrop(b,"inset")
    else
        b.up=art(b,"Interface\\Buttons\\UI-Panel-Button-Up")
        b.down=art(b,"Interface\\Buttons\\UI-Panel-Button-Down","BORDER");b.down:Hide()
        b.up:SetTexCoord(0,0.625,0,0.6875);b.down:SetTexCoord(0,0.625,0,0.6875)
    end
    b.hover=art(b,"Interface\\Buttons\\UI-Panel-Button-Highlight","HIGHLIGHT")
    b.hover:SetTexCoord(0,0.625,0,0.6875);b.hover:SetBlendMode("ADD");b.hover:Hide()
    b.caption=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    b.caption:SetPoint("CENTER",b,"CENTER",0,0); b.caption:SetText(value)
    b:SetScript("OnClick",callback)
    b:SetScript("OnEnter",function() b.hover:Show() end)
    b:SetScript("OnLeave",function() b.hover:Hide();if b.down then b.down:Hide() end end)
    b:SetScript("OnMouseDown",function() if b.down then b.down:Show() end end)
    b:SetScript("OnMouseUp",function() if b.down then b.down:Hide() end end)
    b:SetScript("OnHide",function() b.hover:Hide();if b.down then b.down:Hide() end end)
    b.selection=art(b,"Interface\\Buttons\\UI-Panel-Button-Highlight","BORDER")
    b.selection:SetTexCoord(0,0.625,0,0.6875);b.selection:SetBlendMode("ADD");b.selection:SetAlpha(0.45);b.selection:Hide()
    return b
end
local function toggle(parent,value,x,y,width,callback)
    local b=button(parent,value,x,y,width,callback,true)
    local box=art(b,"Interface\\Buttons\\UI-CheckBox-Up","ARTWORK")
    box:ClearAllPoints();box:SetPoint("LEFT",b,"LEFT",0,0);box:SetSize(28,28)
    b.check=art(b,"Interface\\Buttons\\UI-CheckBox-Check","OVERLAY")
    b.check:ClearAllPoints();b.check:SetAllPoints(box)
    b.caption:ClearAllPoints();b.caption:SetPoint("LEFT",b,"LEFT",28,0)
    return b
end

function S:Set(property,value)
    self.message=nil
    local ok,reason=J.ProfileManager:Set(self.selected,property,value)
    if not ok then self.message=reason; self:Refresh() end
end

function S:HideMenus()
    for _,menu in ipairs(self.menus) do menu:Hide() end
    if self.picker then self.picker:Hide() end
    if self.hubPicker then self.hubPicker:Hide() end
    if self.minimapPicker then self.minimapPicker:Hide() end
end

function S:ShowHubGroup(group,page)
    self.hubGroup=group
    local visible={}
    for id,b in pairs(self.hubButtons) do
        b:Hide()
        b.image:SetTexture(nil)
        if J.HubCatalog.entries[id].group==group then visible[#visible+1]=id end
    end
    table.sort(visible,function(a,b) return J.HubCatalog.entries[a].label<J.HubCatalog.entries[b].label end)
    local pages=math.max(1,math.ceil(#visible/12))
    self.hubPage=math.max(1,math.min(pages,page or 1))
    for key,b in pairs(self.hubGroupButtons) do b.selection:SetShown(key==group) end
    for slot=1,12 do
        local id=visible[(self.hubPage-1)*12+slot]
        if id then
            local b=self.hubButtons[id]
            b.image:SetTexture(J.HubCatalog.entries[id].texture)
            b:ClearAllPoints();b:SetPoint("TOPLEFT",self.hubPicker,"TOPLEFT",18+((slot-1)%3)*228,-84-math.floor((slot-1)/3)*112)
            b:Show()
        end
    end
    self.hubPageLabel:SetText("Page "..self.hubPage.." / "..pages)
end

function S:CreateHubPicker()
    local p=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");self.hubPicker=p
    p:SetSize(720,584);p:SetPoint("CENTER",self.frame,"CENTER",0,0)
    p:SetFrameStrata("DIALOG");p:SetFrameLevel(220);p:EnableMouse(true);p:SetClampedToScreen(true)
    backdrop(p,"outer");text(p,"Action hub collection",20,-18,600,"GameFontNormalLarge")
    button(p,"X",680,-8,28,function() p:Hide() end)
    self.hubGroupButtons={}
    for i,entry in ipairs({{"CLASS","Classes"},{"RACE","Races"},{"FACTION","Factions"}}) do
        local group=entry[1]
        self.hubGroupButtons[group]=button(p,entry[2],18+(i-1)*228,-44,216,function() self:ShowHubGroup(group) end)
    end
    self.hubButtons={}
    for id,entry in pairs(J.HubCatalog.entries) do
        local choice=id
        local b=button(p,"",0,0,216,function()
            p:Hide();self:Set("hub",choice);self:Set("hubMode","FIXED")
        end,true)
        b:SetHeight(104)
        local image=b:CreateTexture(nil,"ARTWORK");image:SetSize(204,68)
        image:SetPoint("TOP",b,"TOP",0,-4);b.image=image
        text(b,entry.label,8,-78,200)
        self.hubButtons[id]=b
    end
    button(p,"Previous",18,-542,140,function() self:ShowHubGroup(self.hubGroup,self.hubPage-1) end)
    button(p,"Next",562,-542,140,function() self:ShowHubGroup(self.hubGroup,self.hubPage+1) end)
    self.hubPageLabel=text(p,"",294,-550,140)
    p:SetScript("OnHide",function()
        for _,b in pairs(self.hubButtons) do b.image:SetTexture(nil) end
    end)
    self:ShowHubGroup("CLASS");p:Hide()
end

function S:ShowMinimapGroup(group,page)
    self.minimapGroup=group
    local visible={}
    for id,b in pairs(self.minimapButtons) do
        b:Hide()
        b.image:SetTexture(nil)
        if J.MinimapCatalog.entries[id].group==group then visible[#visible+1]=id end
    end
    table.sort(visible,function(a,b) return J.MinimapCatalog.entries[a].label<J.MinimapCatalog.entries[b].label end)
    local pages=math.max(1,math.ceil(#visible/12))
    self.minimapPage=math.max(1,math.min(pages,page or 1))
    for key,b in pairs(self.minimapGroupButtons) do b.selection:SetShown(key==group) end
    for slot=1,12 do
        local id=visible[(self.minimapPage-1)*12+slot]
        if id then
            local b=self.minimapButtons[id]
            b.image:SetTexture(J.MinimapCatalog.entries[id].texture)
            b:ClearAllPoints();b:SetPoint("TOPLEFT",self.minimapPicker,"TOPLEFT",18+((slot-1)%3)*228,-84-math.floor((slot-1)/3)*112)
            b:Show()
        end
    end
    self.minimapPageLabel:SetText("Page "..self.minimapPage.." / "..pages)
end

function S:CreateMinimapPicker()
    local p=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");self.minimapPicker=p
    p:SetSize(720,584);p:SetPoint("CENTER",self.frame,"CENTER",0,0)
    p:SetFrameStrata("DIALOG");p:SetFrameLevel(220);p:EnableMouse(true);p:SetClampedToScreen(true)
    backdrop(p,"outer");text(p,"Minimap collection",20,-18,600,"GameFontNormalLarge")
    button(p,"X",680,-8,28,function() p:Hide() end)
    self.minimapGroupButtons={}
    for i,entry in ipairs({{"CLASS","Classes"},{"RACE","Races"},{"FACTION","Factions"}}) do
        local group=entry[1]
        self.minimapGroupButtons[group]=button(p,entry[2],18+(i-1)*228,-44,216,function() self:ShowMinimapGroup(group) end)
    end
    self.minimapButtons={}
    for id,entry in pairs(J.MinimapCatalog.entries) do
        local choice=id
        local b=button(p,"",0,0,216,function()
            p:Hide();self:Set("minimap",choice);self:Set("minimapMode","FIXED")
        end,true)
        b:SetHeight(104)
        local image=b:CreateTexture(nil,"ARTWORK");image:SetSize(72,72)
        image:SetPoint("TOP",b,"TOP",0,-4);b.image=image
        text(b,entry.label,8,-78,200)
        self.minimapButtons[id]=b
    end
    button(p,"Previous",18,-542,140,function() self:ShowMinimapGroup(self.minimapGroup,self.minimapPage-1) end)
    button(p,"Next",562,-542,140,function() self:ShowMinimapGroup(self.minimapGroup,self.minimapPage+1) end)
    self.minimapPageLabel=text(p,"",294,-550,140)
    p:SetScript("OnHide",function()
        for _,b in pairs(self.minimapButtons) do b.image:SetTexture(nil) end
    end)
    self:ShowMinimapGroup("CLASS");p:Hide()
end

function S:ShowPortraitGroup(group)
    self.portraitGroup=group
    for key,b in pairs(self.groupButtons) do b.selection:SetShown(key==group) end
    local visible={}
    for id,b in pairs(self.portraitButtons) do
        b:Hide()
        if J.PortraitCatalog.entries[id].group == group then visible[#visible+1]=id end
    end
    table.sort(visible,function(a,b) return J.PortraitCatalog.entries[a].label < J.PortraitCatalog.entries[b].label end)
    for i,id in ipairs(visible) do
        local b=self.portraitButtons[id]
        b:ClearAllPoints(); b:SetPoint("TOPLEFT",self.picker,"TOPLEFT",12+((i-1)%6)*95,-82-math.floor((i-1)/6)*93)
        b:Show()
    end
end

function S:CreatePortraitPicker()
    local p=CreateFrame("Frame",nil,self.frame,"BackdropTemplate"); self.picker=p
    p:SetSize(594,564); p:SetPoint("CENTER",self.frame,"CENTER",0,0)
    p:SetFrameStrata("DIALOG"); p:SetFrameLevel(220); p:EnableMouse(true); p:SetClampedToScreen(true)
    backdrop(p,"outer"); text(p,"Portrait collection",20,-18,460,"GameFontNormalLarge")
    button(p,"X",554,-8,28,function() p:Hide() end)
    self.groupButtons={}
    for i,entry in ipairs({{"CLASS","Classes"},{"RACE","Races"},{"FACTION","Factions"}}) do
        local group=entry[1]
        self.groupButtons[group]=button(p,entry[2],12+(i-1)*190,-42,180,function() self:ShowPortraitGroup(group) end)
    end
    self.portraitButtons={}
    for id,entry in pairs(J.PortraitCatalog.entries) do
        local choice=id
        local b=button(p,"",0,0,88,function()
            p:Hide(); self:Set("portrait",choice); self:Set("portraitMode","FIXED")
        end,true)
        b:SetHeight(88)
        local art=b:CreateTexture(nil,"ARTWORK"); art:SetSize(66,66); art:SetPoint("TOP",b,"TOP",0,-2); art:SetTexture(entry.texture)
        art:SetTexCoord(0,0.5,0,1);b.image=art
        text(b,entry.label,2,-69,84)
        self.portraitButtons[id]=b
    end
    self:ShowPortraitGroup("CLASS"); p:Hide()
end

function S:Select(key)
    self:HideMenus()
    for _,control in pairs(self.controls) do
        if control.edit then control.edit:ClearFocus() end
    end
    self.selected=key; self.message=nil; self:Refresh()
end

function S:Dropdown(property,label,choices,x,y)
    local control={choices=choices,label=text(self.frame,label,x,y,276,"GameFontNormal")}
    local menu=CreateFrame("Frame",nil,self.frame,"BackdropTemplate")
    menu:SetSize(276,#choices*29+8); menu:SetFrameStrata("TOOLTIP"); menu:SetFrameLevel(200)
    menu:EnableMouse(true); menu:SetClampedToScreen(true); backdrop(menu,"inset")
    menu:Hide(); self.menus[#self.menus+1]=menu
    control.button=button(self.frame,"",x,y-20,276,function()
        local show=not menu:IsShown(); self:HideMenus(); menu:SetShown(show)
    end)
    text(control.button,"v",254,-8,16,"GameFontNormalSmall")
    menu:SetPoint("TOPLEFT",control.button,"BOTTOMLEFT",0,-2)
    control.options={}
    for i,entry in ipairs(choices) do
        local choice=entry
        control.options[choice[1]]=button(menu,choice[2],4,-4-(i-1)*29,268,function()
            menu:Hide(); self:Set(property,choice[1])
        end)
    end
    self.controls[property]=control
end

function S:Number(property,label,x,y,step)
    local rule=J.Core.properties[property]
    text(self.frame,label,x,y,185,"GameFontNormal")
    local edit=CreateFrame("EditBox",nil,self.frame,"BackdropTemplate")
    edit:SetPoint("TOPLEFT",self.frame,"TOPLEFT",x+196,y+4); edit:SetSize(80,24)
    edit:EnableMouse(true)
    edit:SetAutoFocus(false); edit:SetFontObject("GameFontHighlightSmall")
    edit:SetTextInsets(6,6,0,0); edit:SetMaxLetters(12); backdrop(edit,"inset")
    local slider=CreateFrame("Slider",nil,self.frame,"BackdropTemplate")
    slider:SetPoint("TOPLEFT",self.frame,"TOPLEFT",x,y-28); slider:SetSize(276,18)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(rule[1],rule[2])
    slider:SetValueStep(step); slider:SetObeyStepOnDrag(true); slider:EnableMouse(true)
    backdrop(slider,"slider")
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local control={edit=edit,slider=slider,step=step}
    self.controls[property]=control
    slider:SetScript("OnValueChanged",function(_,value)
        if self.refreshing then return end
        edit:ClearFocus()
        local rounded=math.floor(value/step+0.5)*step
        rounded=math.max(rule[1],math.min(rule[2],rounded))
        self:Set(property,rounded)
    end)
    edit:SetScript("OnEditFocusGained",function() edit:HighlightText() end)
    edit:SetScript("OnEnterPressed",function()
        local value=edit:GetText()
        edit:ClearFocus(); self:Set(property,value)
    end)
    edit:SetScript("OnEscapePressed",function() edit:ClearFocus(); self:Refresh() end)
    edit:SetScript("OnEditFocusLost",function() self:Refresh() end)
end

function S:StopDrag()
    if not self.dragging then return end
    self.dragging=false; self.frame:StopMovingOrSizing()
    if not J.Core:IsUsableFrame(UIParent) then return end
    local x,y=self.frame:GetCenter()
    local px,py=UIParent:GetCenter()
    if J.Core:IsNumber(x) and J.Core:IsNumber(y) and J.Core:IsNumber(px) and J.Core:IsNumber(py) then
        J.ProfileManager:SetWindowPosition(x-px,y-py)
    end
end

function S:Center()
    self:StopDrag()
    self.frame:ClearAllPoints(); self.frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
    J.ProfileManager:SetWindowPosition(0,0)
end

function S:Create()
    if self.frame then return end
    assert(not InCombatLockdown(),"First options attachment deferred during combat")
    local f=CreateFrame("Frame","JiberishUIOptionsFrame",UIParent,"BackdropTemplate")
    self.frame=f
    f:Hide(); f:SetSize(640,748); f:SetFrameStrata("DIALOG"); f:SetFrameLevel(200)
    f:EnableMouse(true); f:SetMovable(true); f:SetClampedToScreen(true)
    local pos=J.ProfileManager.current.window or {x=0,y=0}
    f:SetPoint("CENTER",UIParent,"CENTER",pos.x,pos.y)
    backdrop(f,"outer")
    panel(f,16,-122,608,498)
    panel(f,16,-650,608,78)

    local title=CreateFrame("Frame",nil,f); self.titleBar=title
    title:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); title:SetSize(590,74)
    title:EnableMouse(true); title:RegisterForDrag("LeftButton")
    self.crest=title:CreateTexture(nil,"ARTWORK")
    self.crest:SetPoint("TOPLEFT",title,"TOPLEFT",18,-4);self.crest:SetSize(82,82)
    self.crest:SetTexCoord(0,0.5,0,1)
    text(title,"JiberishUI",104,-20,430,"GameFontNormalLarge")
    text(title,"Fantasy artwork for your adventures",104,-43,430,"GameFontHighlightSmall")
    title:SetScript("OnDragStart",function()
        if not InCombatLockdown() or not f:IsProtected() then self.dragging=true; f:StartMoving() end
    end)
    title:SetScript("OnDragStop",function() self:StopDrag() end)
    button(f,"X",592,-16,28,function() f:Hide() end)
    f:SetScript("OnHide",function()
        self:StopDrag(); self:HideMenus()
        for _,control in pairs(self.controls) do if control.edit then control.edit:ClearFocus() end end
    end)
    UISpecialFrames=UISpecialFrames or {}
    local registered=false
    for _,name in ipairs(UISpecialFrames) do if name=="JiberishUIOptionsFrame" then registered=true end end
    if not registered then table.insert(UISpecialFrames,"JiberishUIOptionsFrame") end

    self.tabs={}
    for i,key in ipairs({"playerFrame","targetFrame","focusFrame","minimap","actionHub"}) do
        local selected=key
        self.tabs[key]=button(f,names[key],24+(i-1)*120,-82,112,function() self:Select(selected) end)
    end
    self.heading=text(f,"",32,-136,420,"GameFontNormal")
    self.showButton=toggle(f,"Show artwork",468,-128,140,function()
        self:Set("shown",not J.ThemeManager:Resolve(self.selected).shown)
    end)
    self:Number("width","Width",24,-176,1); self:Number("height","Height",340,-176,1)
    self:Number("x","X offset",24,-252,1); self:Number("y","Y offset",340,-252,1)
    self:Number("scale","Artwork scale",24,-328,0.01); self:Number("opacity","Opacity",340,-328,0.01)
    self:Dropdown("strata","Frame strata",strata,24,-406)
    self:Number("level","Frame level (within strata)",340,-406,1)
    self:Dropdown("anchor","Anchor",anchors,24,-480)
    self:Dropdown("layer","Texture draw layer",layers,340,-480)
    self:Dropdown("portraitMode","Portrait selection",modes,24,-554)
    self.portraitCaption=text(f,"Portrait artwork",340,-554,276,"GameFontNormal")
    self.portraitButton=button(f,"Browse artwork",340,-574,276,function()
        self:HideMenus(); self.picker:Show()
    end)
    self:CreatePortraitPicker()
    self:Dropdown("hubMode","Hub selection",modes,24,-554)
    self.hubCaption=text(f,"Hub artwork",340,-554,276,"GameFontNormal")
    self.hubButton=button(f,"Browse hubs",340,-574,276,function()
        self:HideMenus();self:ShowHubGroup(self.hubGroup or "CLASS",self.hubPage);self.hubPicker:Show()
    end)
    self:CreateHubPicker()
    self:Dropdown("minimapMode","Minimap selection",modes,24,-554)
    self.minimapCaption=text(f,"Minimap artwork",340,-554,276,"GameFontNormal")
    self.minimapButton=button(f,"Browse minimaps",340,-574,276,function()
        self:HideMenus();self:ShowMinimapGroup(self.minimapGroup or "CLASS",self.minimapPage);self.minimapPicker:Show()
    end)
    self:CreateMinimapPicker()
    self.debugButton=toggle(f,"Debug bounds",24,-664,148,function() J.Core:Command("debug") end)
    button(f,"Reset this component",184,-664,188,function()
        self.message=nil
        local ok,reason=J.ProfileManager:Reset(self.selected)
        if not ok then self.message=reason; self:Refresh() end
    end)
    button(f,"Center window",384,-664,148,function() self:Center() end)
    self.status=text(f,"",28,-705,584)
end

function S:Refresh()
    if not self.frame or not self.frame:IsShown() or self.refreshing then return end
    self.refreshing=true
    local config=J.ThemeManager:Resolve(self.selected)
    self.heading:SetText(names[self.selected] .. " artwork")
    local unit=J.Portraits:IsUnitKey(self.selected)
    local minimap=self.selected=="minimap"
    self.controls.minimapMode.button:SetShown(minimap);self.controls.minimapMode.label:SetShown(minimap)
    self.minimapCaption:SetShown(minimap);self.minimapButton:SetShown(minimap)
    if minimap then
        local id=J.Minimaps:Resolve(config)
        self.minimapButton.caption:SetText(J.MinimapCatalog.entries[id].label.." - Browse")
    end
    local hub=self.selected=="actionHub"
    self.controls.hubMode.button:SetShown(hub);self.controls.hubMode.label:SetShown(hub)
    self.hubCaption:SetShown(hub);self.hubButton:SetShown(hub)
    if hub then
        local id=J.Hubs:Resolve(config)
        self.hubButton.caption:SetText(J.HubCatalog.entries[id].label.." - Browse")
    end
    self.controls.portraitMode.button:SetShown(unit)
    self.portraitCaption:SetShown(unit); self.portraitButton:SetShown(unit)
    self.controls.portraitMode.label:SetShown(unit)
    if unit then
        local id=J.Portraits:Resolve(config)
        local entry=J.PortraitCatalog.entries[id]
        self.portraitButton.caption:SetText((entry and entry.label or "Portrait") .. " - Browse")
        self.crest:SetTexture(entry.texture)
    else
        self.crest:SetTexture(J.PortraitCatalog.entries.CLASS_PALADIN.texture)
    end
    self.showButton.check:SetShown(config.shown)
    self.debugButton.check:SetShown(J.ProfileManager.current.debug)
    for key,b in pairs(self.tabs) do
        b.selection:SetShown(key==self.selected)
        b.caption:SetText((key==self.selected and "|cffffe5a0" or "|cffffd100")..names[key].."|r")
    end
    for id,b in pairs(self.portraitButtons) do
        local u1,u2=J.Portraits:TexCoords(config.unit or "player")
        b.image:SetTexCoord(u1,u2,0,1)
        b.selection:SetShown(unit and config.portraitMode=="FIXED" and config.portrait==id)
    end
    for id,b in pairs(self.hubButtons) do
        b.selection:SetShown(hub and config.hubMode=="FIXED" and config.hub==id)
    end
    for id,b in pairs(self.minimapButtons) do
        b.selection:SetShown(minimap and config.minimapMode=="FIXED" and config.minimap==id)
    end
    for property,control in pairs(self.controls) do
        if control.slider then
            control.slider:SetValue(config[property])
            if not control.edit:HasFocus() then
                local value=string.format("%.2f",config[property]):gsub("%.?0+$","")
                control.edit:SetText(value)
            end
        else
            for _,choice in ipairs(control.choices) do
                if choice[1]==config[property] then control.button.caption:SetText(choice[2]) end
            end
        end
    end
    local message=self.message
    if not J.ProfileManager.writable then message=J.ProfileManager.notice end
    if not message then
        message=InCombatLockdown() and J.Core.dirty and "Changes saved; artwork updates after combat."
            or "Drag the title bar to move this window. Enter applies typed values. Higher strata can cover other UI."
    end
    self.status:SetText(message)
    self.refreshing=false
end

function S:Open()
    if not self.frame and InCombatLockdown() then
        self.pendingOpen=true; J.Core:Print("Options will open after combat."); return
    end
    self.pendingOpen=nil
    self:Create(); self.frame:Show(); self:Refresh()
end

function S:Toggle()
    if self.pendingOpen then self.pendingOpen=nil; J.Core:Print("Options opening canceled.")
    elseif self.frame and self.frame:IsShown() then self.frame:Hide()
    else self:Open() end
end
