local _, J = ...
local S = { selected="playerFrame", page="artwork", controls={}, menus={} }
J.SettingsUI = S

local names = {minimap="Minimap",playerFrame="Player",targetFrame="Target",focusFrame="Focus",actionHub="Action hub"}
local modes = {{"CLASS","Automatic class"},{"RACE","Automatic race"},{"FACTION","Automatic faction"},{"FIXED","Chosen artwork"}}
local strata = {
    {"BACKGROUND","Background"},{"LOW","Low"},{"MEDIUM","Medium"},{"HIGH","High"},
    {"DIALOG","Dialog"},{"FULLSCREEN","Fullscreen"},{"FULLSCREEN_DIALOG","Fullscreen dialog"},{"TOOLTIP","Tooltip"},
}
local layers = {{"BACKGROUND","Background"},{"BORDER","Border"},{"ARTWORK","Artwork"},{"OVERLAY","Overlay"}}
local anchors = {{"FRAME","Follow selected frame"},{"SCREEN","Screen"}}
local portraitSources = {{"AUTO","Automatic (Blinkii first)"},{"BLINKII","Blinkii's Portraits"},
    {"MMT","mMediaTag & Tools"},
    {"ELVUI","ElvUI"},{"ELLESMERE","EllesmereUI"},{"BLIZZARD","Blizzard"}}
local hubSources = {{"AUTO","Automatic"},{"ELVUI","ElvUI"},{"ELLESMERE","EllesmereUI"},{"BLIZZARD","Blizzard"}}

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
    frame:SetBackdropColor(0.42,0.36,0.28,1)
    frame:SetBackdropBorderColor(0.62,0.48,0.27,1)
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
    if self.backupDialog then self.backupDialog:Hide();self.backupEdit:ClearFocus() end
    if self.resetDialog then self.resetDialog:Hide() end
end

local collectionSpecs={
    portrait={catalog="PortraitCatalog",property="portrait",mode="portraitMode",picker="picker",buttons="portraitButtons",groups="groupButtons",group="portraitGroup",page="portraitPage",label="portraitPageLabel",title="Unit artwork collection"},
    hub={catalog="HubCatalog",property="hub",mode="hubMode",picker="hubPicker",buttons="hubButtons",groups="hubGroupButtons",group="hubGroup",page="hubPage",label="hubPageLabel",title="Action hub collection"},
    minimap={catalog="MinimapCatalog",property="minimap",mode="minimapMode",picker="minimapPicker",buttons="minimapButtons",groups="minimapGroupButtons",group="minimapGroup",page="minimapPage",label="minimapPageLabel",title="Minimap collection"},
}

function S:ShowCollection(kind,group,page)
    local spec=collectionSpecs[kind];local p=self[spec.picker]
    if self[spec.group]~=group then
        p.updatingSearch=true;p.search:SetText("");p.updatingSearch=nil
    end
    self[spec.group]=group
    local query=(p.search:GetText() or ""):lower():match("^%s*(.-)%s*$")
    local visible={}
    for id,b in pairs(self[spec.buttons]) do
        b:Hide();b.image:SetTexture(nil)
        local entry=J[spec.catalog].entries[id]
        if entry.group==group and entry.label:lower():find(query,1,true) then visible[#visible+1]=id end
    end
    table.sort(visible,function(a,b) return J[spec.catalog].entries[a].label<J[spec.catalog].entries[b].label end)
    local pages=math.max(1,math.ceil(#visible/12))
    self[spec.page]=math.max(1,math.min(pages,page or 1))
    for key,b in pairs(self[spec.groups]) do b.selection:SetShown(key==group) end
    for slot=1,12 do
        local id=visible[(self[spec.page]-1)*12+slot]
        if id then
            local b=self[spec.buttons][id];b.image:SetTexture(J[spec.catalog].entries[id].texture)
            b:ClearAllPoints();b:SetPoint("TOPLEFT",p,"TOPLEFT",24+((slot-1)%4)*182,-156-math.floor((slot-1)/4)*126)
            b:Show()
        end
    end
    self[spec.label]:SetText("Page "..self[spec.page].." / "..pages)
    p.result:SetText(#visible.." designs")
    p.empty:SetShown(#visible==0)
    p.previous:SetAlpha(self[spec.page]>1 and 1 or .45)
    p.next:SetAlpha(self[spec.page]<pages and 1 or .45)
    p.hint:SetText("Applies to "..names[self.selected].." only. Choosing a design switches to Chosen artwork.")
end

function S:CreateCollection(kind)
    local spec=collectionSpecs[kind]
    local p=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");self[spec.picker]=p
    p:SetSize(768,608);p:SetPoint("CENTER",self.frame,"CENTER",0,0)
    p:SetFrameStrata("DIALOG");p:SetFrameLevel(220);p:EnableMouse(true);p:SetClampedToScreen(true)
    backdrop(p,"outer");text(p,spec.title,24,-22,650,"GameFontNormalLarge")
    button(p,"X",714,-18,28,function() p:Hide() end)
    self[spec.groups]={}
    for i,entry in ipairs({{"CLASS","Classes"},{"RACE","Races"},{"FACTION","Factions"}}) do
        local group=entry[1]
        self[spec.groups][group]=button(p,entry[2],24+(i-1)*244,-64,232,function() self:ShowCollection(kind,group) end)
    end
    text(p,"Find artwork",24,-115,90,"GameFontNormalSmall")
    p.search=CreateFrame("EditBox",nil,p,"BackdropTemplate")
    p.search:SetPoint("TOPLEFT",p,"TOPLEFT",118,-106);p.search:SetSize(408,30)
    p.search:EnableMouse(true);p.search:SetAutoFocus(false);p.search:SetFontObject("GameFontHighlightSmall")
    p.search:SetTextInsets(8,8,0,0);p.search:SetMaxLetters(64);backdrop(p.search,"inset");p.search:SetText("")
    p.search:SetScript("OnTextChanged",function() if not p.updatingSearch then self:ShowCollection(kind,self[spec.group] or "CLASS",1) end end)
    p.search:SetScript("OnEscapePressed",function() p.search:ClearFocus();p:Hide() end)
    p.search:SetScript("OnEnterPressed",function() p.search:ClearFocus() end)
    button(p,"Clear",538,-107,76,function() p.search:SetText("");self:ShowCollection(kind,self[spec.group],1) end)
    p.result=text(p,"",634,-115,100)
    p.empty=text(p,"No matching artwork in this collection. Try another name or category.",24,-170,716)
    self[spec.buttons]={}
    for id,entry in pairs(J[spec.catalog].entries) do
        local choice=id
        local b=button(p,"",0,0,168,function()
            p:Hide();self:Set(spec.property,choice);self:Set(spec.mode,"FIXED")
        end,true)
        b:SetHeight(118)
        b.image=b:CreateTexture(nil,"ARTWORK")
        b.image:SetSize(kind=="hub" and 156 or 78,kind=="hub" and 52 or 78)
        b.image:SetPoint("TOP",b,"TOP",0,kind=="hub" and -18 or -4)
        if kind=="portrait" then b.image:SetTexCoord(0,.5,0,1) end
        local caption=text(b,entry.label,6,-86,156);caption:SetJustifyH("CENTER")
        self[spec.buttons][id]=b
    end
    p.hint=text(p,"",24,-536,716)
    p.previous=button(p,"Previous",24,-566,144,function() self:ShowCollection(kind,self[spec.group],self[spec.page]-1) end)
    p.next=button(p,"Next",596,-566,144,function() self:ShowCollection(kind,self[spec.group],self[spec.page]+1) end)
    self[spec.label]=text(p,"",320,-574,140)
    p:SetScript("OnHide",function()
        p.search:ClearFocus()
        for _,b in pairs(self[spec.buttons]) do b.image:SetTexture(nil) end
    end)
    self:ShowCollection(kind,"CLASS");p:Hide()
end

function S:ShowPortraitGroup(group,page) self:ShowCollection("portrait",group,page) end
function S:ShowHubGroup(group,page) self:ShowCollection("hub",group,page) end
function S:ShowMinimapGroup(group,page) self:ShowCollection("minimap",group,page) end
function S:CreatePortraitPicker() self:CreateCollection("portrait") end
function S:CreateHubPicker() self:CreateCollection("hub") end
function S:CreateMinimapPicker() self:CreateCollection("minimap") end

function S:Select(key)
    self:HideMenus()
    for _,control in pairs(self.controls) do
        if control.edit then control.edit:ClearFocus() end
    end
    self.selected=key; self.message=nil; self:Refresh()
end

function S:Dropdown(property,label,choices,x,y,parent,width)
    parent=parent or self.frame; width=width or 318
    local control={choices=choices,label=text(parent,label,x,y,width,"GameFontNormal")}
    local menu=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    menu:SetSize(width,#choices*29+8); menu:SetFrameStrata("TOOLTIP"); menu:SetFrameLevel(200)
    menu:EnableMouse(true); menu:SetClampedToScreen(true); backdrop(menu,"inset")
    menu:Hide(); self.menus[#self.menus+1]=menu
    control.button=button(parent,"",x,y-22,width,function()
        local show=not menu:IsShown(); self:HideMenus(); menu:SetShown(show)
    end)
    text(control.button,"v",width-22,-8,16,"GameFontNormalSmall")
    menu:SetPoint("TOPLEFT",control.button,"BOTTOMLEFT",0,-2)
    control.options={}
    for i,entry in ipairs(choices) do
        local choice=entry
        control.options[choice[1]]=button(menu,choice[2],4,-4-(i-1)*29,width-8,function()
            menu:Hide(); self:Set(property,choice[1])
        end)
    end
    self.controls[property]=control
end

function S:Number(property,label,x,y,step,parent)
    parent=parent or self.frame
    local rule=J.Core.properties[property]
    text(parent,label,x,y,230,"GameFontNormal")
    local edit=CreateFrame("EditBox",nil,parent,"BackdropTemplate")
    edit:SetPoint("TOPLEFT",parent,"TOPLEFT",x+238,y+4); edit:SetSize(80,24)
    edit:EnableMouse(true)
    edit:SetAutoFocus(false); edit:SetFontObject("GameFontHighlightSmall")
    edit:SetTextInsets(6,6,0,0); edit:SetMaxLetters(12); backdrop(edit,"inset")
    local slider=CreateFrame("Slider",nil,parent,"BackdropTemplate")
    slider:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y-32); slider:SetSize(318,18)
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
        local scale=self.frame:GetScale()
        J.ProfileManager:SetWindowPosition(x*scale-px,y*scale-py)
    end
end

function S:Center()
    self:StopDrag()
    self.frame:ClearAllPoints(); self.frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
    J.ProfileManager:SetWindowPosition(0,0)
end

local pageNames={artwork="Artwork",placement="Placement",fitting="Unit frame",advanced="Advanced",guide="Guide & backups"}

function S:SetPage(page)
    if not self.pages[page] then return end
    self:HideMenus()
    for _,control in pairs(self.controls) do if control.edit then control.edit:ClearFocus() end end
    self.page=page;self.message=nil;self:Refresh()
end

function S:FitWindow()
    if not self.frame or not J.Core:IsUsableFrame(UIParent) then return end
    if InCombatLockdown() and self.frame:IsProtected() then return end
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    if not J.Core:IsNumber(w) or not J.Core:IsNumber(h) or w<=32 or h<=32 then return end
    local scale=math.min(1,(w-32)/920,(h-32)/700)
    self:StopDrag()
    self.frame:SetScale(scale)
    local pos=J.ProfileManager.current.window or {x=0,y=0}
    self.frame:ClearAllPoints();self.frame:SetPoint("CENTER",UIParent,"CENTER",pos.x/scale,pos.y/scale)
end

function S:ShowBackup(mode)
    self:HideMenus();self.backupMode=mode
    local export=mode=="export"
    self.backupTitle:SetText(export and "Save your artwork settings" or "Restore artwork settings")
    self.backupHelp:SetText(export and "Select the backup text and copy it with Ctrl+C (Command+C on Mac). Keep it somewhere safe. This includes artwork choices and fitting for every component."
        or "Paste a JF1 or JF2 backup below. Restore replaces artwork settings for all five components. It does not change settings in Blizzard or another UI addon.")
    self.backupEdit:SetText(export and J.ProfileManager:Export() or "")
    self.backupResult:SetText(export and "Select all: Ctrl+A / Command+A. Close when copied." or "Your current settings are kept if the backup is invalid.")
    self.restoreButton:SetShown(not export)
    self.backupDialog:Show();self.backupEdit:SetFocus();self.backupEdit:HighlightText()
end

function S:CreateDialogs()
    local p=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");self.backupDialog=p
    p:SetSize(680,260);p:SetPoint("CENTER",self.frame,"CENTER",0,0)
    p:SetFrameStrata("DIALOG");p:SetFrameLevel(230);p:EnableMouse(true);backdrop(p,"outer")
    self.backupTitle=text(p,"",24,-24,610,"GameFontNormalLarge")
    self.backupHelp=text(p,"",24,-62,628)
    local edit=CreateFrame("EditBox",nil,p,"BackdropTemplate");self.backupEdit=edit
    edit:SetPoint("TOPLEFT",p,"TOPLEFT",24,-116);edit:SetSize(628,36)
    edit:EnableMouse(true);edit:SetAutoFocus(false);edit:SetFontObject("GameFontHighlightSmall")
    edit:SetTextInsets(10,10,0,0);edit:SetMaxLetters(8192);backdrop(edit,"inset")
    edit:SetScript("OnEscapePressed",function() edit:ClearFocus();self.backupDialog:Hide() end)
    self.backupResult=text(p,"",24,-164,628)
    self.restoreButton=button(p,"Restore all artwork settings",24,-208,280,function()
        local ok,reason=J.ProfileManager:Import(edit:GetText())
        if ok then edit:ClearFocus();self.backupDialog:Hide();self.message="Backup restored for all five components.";self:Refresh()
        else self.backupResult:SetText("|cffffa36a"..reason.."|r") end
    end)
    button(p,"Close",510,-208,142,function() edit:ClearFocus();self.backupDialog:Hide() end)
    self.backupDialog:Hide()
    p=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");self.resetDialog=p
    p:SetSize(500,204);p:SetPoint("CENTER",self.frame,"CENTER",0,0)
    p:SetFrameStrata("DIALOG");p:SetFrameLevel(230);p:EnableMouse(true);backdrop(p,"outer")
    self.resetTitle=text(p,"",24,-26,448,"GameFontNormalLarge")
    text(p,"Restore this component's artwork, visibility, provider and fitting to their defaults. Your other components keep their settings.",24,-66,448)
    self.resetConfirm=button(p,"Restore defaults",24,-148,216,function()
        p:Hide();self.message=nil
        local ok,reason=J.ProfileManager:Reset(self.resetKey)
        self.message=ok and (names[self.resetKey].." defaults restored.") or reason;self:Refresh()
    end)
    button(p,"Cancel",260,-148,216,function() p:Hide() end);p:Hide()
end

function S:Create()
    if self.frame then return end
    assert(not InCombatLockdown(),"First options attachment deferred during combat")
    local f=CreateFrame("Frame","JiberishUIOptionsFrame",UIParent,"BackdropTemplate")
    self.frame=f
    f:Hide();f:SetSize(920,700);f:SetFrameStrata("DIALOG");f:SetFrameLevel(200)
    f:EnableMouse(true);f:SetMovable(true);f:SetClampedToScreen(true)
    backdrop(f,"outer")
    panel(f,16,-98,178,538);panel(f,200,-98,704,538);panel(f,16,-640,888,44)
    local rule=f:CreateTexture(nil,"ARTWORK");rule:SetColorTexture(.51,.37,.17,.75)
    rule:SetPoint("TOPLEFT",f,"TOPLEFT",218,-152);rule:SetSize(666,1)

    local title=CreateFrame("Frame",nil,f);self.titleBar=title
    title:SetPoint("TOPLEFT",f,"TOPLEFT",0,0);title:SetSize(850,94)
    title:EnableMouse(true);title:RegisterForDrag("LeftButton")
    self.crest=title:CreateTexture(nil,"ARTWORK")
    self.crest:SetPoint("TOPLEFT",title,"TOPLEFT",22,-6);self.crest:SetSize(82,82);self.crest:SetTexCoord(0,0.5,0,1)
    text(title,"JiberishUI",112,-24,440,"GameFontNormalLarge")
    text(title,"Craft your interface. Keep the spirit of Warcraft.",112,-50,510)
    text(title,"v"..J.Core.version,772,-29,72,"GameFontNormalSmall")
    title:SetScript("OnDragStart",function()
        if not InCombatLockdown() or not f:IsProtected() then self.dragging=true;f:StartMoving() end
    end)
    title:SetScript("OnDragStop",function() self:StopDrag() end)
    button(f,"X",868,-22,28,function() f:Hide() end)
    f:SetScript("OnHide",function()
        self:StopDrag();self:HideMenus()
        for _,control in pairs(self.controls) do if control.edit then control.edit:ClearFocus() end end
    end)
    f:RegisterEvent("UI_SCALE_CHANGED");f:RegisterEvent("DISPLAY_SIZE_CHANGED")
    f:SetScript("OnEvent",function() self:FitWindow() end)
    UISpecialFrames=UISpecialFrames or {}
    local registered=false
    for _,name in ipairs(UISpecialFrames) do if name=="JiberishUIOptionsFrame" then registered=true end end
    if not registered then table.insert(UISpecialFrames,"JiberishUIOptionsFrame") end

    text(f,"YOUR INTERFACE",30,-118,146,"GameFontNormalSmall")
    self.tabs={}
    for i,key in ipairs({"playerFrame","targetFrame","focusFrame","minimap","actionHub"}) do
        local selected=key
        local b=button(f,names[key],28,-148-(i-1)*54,154,function() self:Select(selected) end,true)
        b:SetHeight(44);self.tabs[key]=b
    end
    text(f,"Choose a component, then shape its artwork.",32,-438,140)
    text(f,"Changes save as you go. No Apply button needed.",32,-488,140)
    self.resetButton=button(f,"Reset component",28,-552,154,function()
        self:HideMenus();self.resetKey=self.selected
        self.resetTitle:SetText("Reset "..names[self.selected].." artwork?");self.resetDialog:Show()
    end)
    button(f,"Center window",28,-592,154,function() self:Center() end)

    self.pages={};self.pageButtons={}
    for i,key in ipairs({"artwork","placement","fitting","advanced","guide"}) do
        local page=key
        self.pageButtons[key]=button(f,pageNames[key],218+(i-1)*134,-114,126,function() self:SetPage(page) end)
        local body=CreateFrame("Frame",nil,f);body:SetPoint("TOPLEFT",f,"TOPLEFT",218,-214);body:SetSize(666,400)
        body:SetFrameLevel(202);self.pages[key]=body
    end
    self.heading=text(f,"",220,-165,650,"GameFontNormalLarge")
    self.pageHint=text(f,"",220,-192,652)
    local a=self.pages.advanced
    self:Dropdown("strata","Frame strata",strata,0,-14,a)
    self:Number("level","Level within strata",346,-14,1,a)
    self:Dropdown("layer","Texture draw layer",layers,0,-108,a)
    self:Dropdown("unitFrameFill","Health & power textures",{{"AUTO","Automatic (respect UI addon)"},{"PROVIDER","Keep provider textures"},{"JIBERISH","Use JiberishUI fills"}},346,-108,a)
    self.debugButton=toggle(a,"Show fitting bounds",0,-350,318,function() J.Core:Command("debug") end)
    panel(a,0,-200,666,124)
    text(a,"TEXTURES & LAYERING",18,-218,626,"GameFontNormal")
    text(a,"Choose JiberishUI Stone in EllesmereUI or ElvUI texture menus to use our stone on any of their bars. Automatic keeps Ellesmere textures and uses our fills on Blizzard frames. Higher layers can cover names and controls.",18,-248,626)
    self.diagnosticsButton=button(a,"Print support details to chat",346,-350,318,function() J.Core:Command("status");self.message="Support details printed to chat. Include them with your screenshot.";self:Refresh() end)

    a=self.pages.placement
    self:Number("width","Width",0,-14,1,a);self:Number("height","Height",346,-14,1,a)
    self:Number("x","Horizontal offset",0,-104,1,a);self:Number("y","Vertical offset",346,-104,1,a)
    self:Number("scale","Artwork scale",0,-194,.01,a);self:Number("opacity","Opacity",346,-194,.01,a)
    self:Dropdown("anchor","Anchor",anchors,0,-292,a)
    self.placementHelp=text(a,"",346,-292,318)
    text(a,"Drag a slider or type a value and press Enter. Escape cancels an unfinished edit.",0,-370,660)

    a=self.pages.fitting
    self:Number("unitFrameWidth","Artwork width (%)",0,-14,1,a)
    self:Number("unitFrameHeight","Artwork height (%)",346,-14,1,a)
    self:Number("unitFrameInset","Inset edge depth",0,-108,.1,a)
    text(a,"A small painted lip and inner shadow make the health and power fills sit inside the frame.",346,-108,318)
    panel(a,0,-196,666,106)
    text(a,"FIT THE FRAME, KEEP YOUR BARS",18,-214,626,"GameFontNormal")
    text(a,"100% follows the current bars. Width and height resize only this unit's artwork around the bar stack. Inset depth controls the inner edge; set it to 0 to remove it. Portrait fitting stays on Placement.",18,-244,626)
    button(a,"Reset unit-frame fitting",0,-332,318,function()
        self:Set("unitFrameWidth",100);self:Set("unitFrameHeight",100);self:Set("unitFrameInset",1.5)
    end)
    text(a,"Fitting changes apply after combat. Native bar values, colors and texture choices stay with your UI addon.",0,-378,666)

    a=self.pages.artwork
    self.showButton=toggle(a,"Portrait art",0,0,318,function() self:Set("shown",not J.ThemeManager:Resolve(self.selected).shown) end)
    self.styleButton=toggle(a,"Unit-frame art",346,0,318,function() self:Set("unitFrameShown",not J.ThemeManager:Resolve(self.selected).unitFrameShown) end)
    self.showHelp=text(a,"",30,-38,286)
    self.styleHelp=text(a,"Separate shell around health and power.",376,-38,288)
    panel(a,0,-84,130,130);panel(a,138,-84,528,130)
    self.themePreview=a:CreateTexture(nil,"ARTWORK");self.themePreview:SetPoint("TOPLEFT",a,"TOPLEFT",13,-97);self.themePreview:SetSize(104,104)
    self:Dropdown("portraitMode","Choose automatically",modes,154,-102,a,244)
    self:Dropdown("hubMode","Choose automatically",modes,154,-102,a,244)
    self:Dropdown("minimapMode","Choose automatically",modes,154,-102,a,244)
    self.portraitCaption=text(a,"Artwork collection",414,-102,236,"GameFontNormal")
    self.portraitButton=button(a,"Browse artwork",414,-124,236,function() self:HideMenus();self:ShowPortraitGroup(self.portraitGroup or "CLASS",self.portraitPage);self.picker:Show() end)
    self.hubCaption=text(a,"Artwork collection",414,-102,236,"GameFontNormal")
    self.hubButton=button(a,"Browse artwork",414,-124,236,function() self:HideMenus();self:ShowHubGroup(self.hubGroup or "CLASS",self.hubPage);self.hubPicker:Show() end)
    self.minimapCaption=text(a,"Artwork collection",414,-102,236,"GameFontNormal")
    self.minimapButton=button(a,"Browse artwork",414,-124,236,function() self:HideMenus();self:ShowMinimapGroup(self.minimapGroup or "CLASS",self.minimapPage);self.minimapPicker:Show() end)
    self.modeHelp=text(a,"",154,-166,496)
    self:Dropdown("portraitSource","Portrait provider",portraitSources,0,-236,a)
    self:Dropdown("hubSource","Action bar provider",hubSources,0,-236,a)
    self:Dropdown("unitFrameSource","Unit-frame provider",{{"AUTO","Automatic"},{"BLIZZARD","Blizzard"},{"ELLESMERE","EllesmereUI"}},346,-236,a)
    self.sourceStatus=text(a,"",0,-304,666)
    self.providerHelp=text(a,"",0,-354,666)
    self:CreatePortraitPicker();self:CreateHubPicker();self:CreateMinimapPicker()

    a=self.pages.guide
    panel(a,0,0,666,180)
    text(a,"FIRST STEPS",18,-18,626,"GameFontNormal")
    text(a,"1. Choose Player, Target, Focus, Minimap or Action hub on the left.\n\n2. On Artwork, turn on the decorations you want. Portrait and unit-frame art can be used separately or together.\n\n3. Keep Automatic class, or browse the collection for a fixed design.\n\n4. Keep providers on Automatic, or select your UI addon. Advanced lets you keep its bar textures or use JiberishUI fills.",18,-46,626)
    self.guideHelp=text(a,"",0,-198,666)
    button(a,"Copy settings backup",0,-326,318,function() self:ShowBackup("export") end)
    button(a,"Restore from backup",346,-326,318,function() self:ShowBackup("import") end)
    text(a,"Back up before making broad changes or reinstalling. Backups cover all five components.",0,-370,666)
    self:CreateDialogs()
    self.status=text(f,"",30,-655,858)
    self:FitWindow()
end

function S:Refresh()
    if not self.frame or not self.frame:IsShown() or self.refreshing then return end
    self.refreshing=true
    local config=J.ThemeManager:Resolve(self.selected)
    local unit=J.Portraits:IsUnitKey(self.selected)
    local minimap=self.selected=="minimap"
    local hub=self.selected=="actionHub"
    local module=J.Core.modules[self.selected]
    local headings={artwork="Artwork",placement="Placement & size",fitting="Unit-frame fitting",advanced="Textures, layers & diagnostics",guide="Getting started"}
    if not unit and self.page=="fitting" then self.page="placement" end
    self.heading:SetText(names[self.selected].."  |  "..headings[self.page])
    local hints={artwork=unit and "Choose your portrait surround and full-frame artwork independently." or "Choose a matching theme, then follow your existing UI.",
        placement=unit and "These controls fit the portrait surround. Use Unit frame to fit the shell around the bars." or "Fit the decoration around your existing minimap or action bars.",
        fitting="Enable Unit-frame art on Artwork; then fit its size and inset.",
        advanced="Choose who controls bar textures, then fine-tune layering.",guide="A few simple steps, plus tools to keep your settings safe."}
    self.pageHint:SetText(hints[self.page])
    for key,page in pairs(self.pages) do page:SetShown(key==self.page);self.pageButtons[key].selection:SetShown(key==self.page) end
    local visiblePages=unit and {"artwork","placement","fitting","advanced","guide"} or {"artwork","placement","advanced","guide"}
    self.pageButtons.fitting:SetShown(unit)
    for i,key in ipairs(visiblePages) do
        local b=self.pageButtons[key];local step=unit and 134 or 168
        b:ClearAllPoints();b:SetPoint("TOPLEFT",self.frame,"TOPLEFT",218+(i-1)*step,-114);b:SetWidth(step-8)
    end
    self.styleButton:SetShown(unit);self.styleHelp:SetShown(unit)
    self.controls.unitFrameSource.button:SetShown(unit);self.controls.unitFrameSource.label:SetShown(unit)
    self.controls.unitFrameFill.button:SetShown(unit);self.controls.unitFrameFill.label:SetShown(unit)
    if unit then self.styleButton.check:SetShown(config.unitFrameShown) end
    self.showButton.caption:SetText(unit and "Portrait art" or "Show artwork")
    self.showHelp:SetText(unit and "Decorative surround for the unit portrait." or minimap and "Decorative border around the native minimap." or "Decorative endcaps and rail for the action bars.")
    self.controls.minimapMode.button:SetShown(minimap);self.controls.minimapMode.label:SetShown(minimap)
    self.minimapCaption:SetShown(minimap);self.minimapButton:SetShown(minimap)
    self.controls.portraitSource.button:SetShown(unit);self.controls.portraitSource.label:SetShown(unit)
    self.controls.hubSource.button:SetShown(hub);self.controls.hubSource.label:SetShown(hub)
    self.controls.hubMode.button:SetShown(hub);self.controls.hubMode.label:SetShown(hub)
    self.hubCaption:SetShown(hub);self.hubButton:SetShown(hub)
    self.controls.portraitMode.button:SetShown(unit);self.controls.portraitMode.label:SetShown(unit)
    self.portraitCaption:SetShown(unit);self.portraitButton:SetShown(unit)
    local id,entry,mode
    if unit then
        id=J.Portraits:Resolve(config);entry=J.PortraitCatalog.entries[id];mode=config.portraitMode
        self.portraitButton.caption:SetText(entry.label.."  -  Browse")
        local sources={BLIZZARD="Blizzard",BLINKII="Blinkii's Portraits",MMT="mMediaTag & Tools",ELVUI="ElvUI",ELLESMERE="EllesmereUI"}
        local portrait=not config.shown and "off" or module.snapshot and ((sources[module.snapshot.source] or module.snapshot.source)..(module.nativeVisible and " - ready" or " - portrait hidden")) or "waiting for a visible portrait"
        if config.shown and module.assetOK==false then portrait="artwork could not be loaded" end
        local frame=not config.unitFrameShown and "off - enable Unit-frame art above" or J.UnitSkins.summary[self.selected] or "waiting for bars"
        self.sourceStatus:SetText("|cffffd38aPortrait:|r "..portrait.."\n|cffffd38aUnit frame:|r "..frame)
        self.providerHelp:SetText("Ellesmere full frames need horizontal health with attached power below. ElvUI supports portrait art; full-frame styling supports Blizzard and Ellesmere.")
        self.placementHelp:SetText("Offsets move only the decoration. Use your UI addon's settings to move the portrait or health bars themselves.")
        self.guideHelp:SetText("|cffffd38aArtwork missing?|r Target a unit first, check each artwork toggle, and choose the matching provider. Enable portraits in that provider too. Hidden or inside-health portraits may not support a surround.\n\n|cffffd38aWrong NPC theme?|r Known city affiliations use matching race art. Unknown NPCs use the normal fallback. Choose a fixed design to override it.")
    else
        id=minimap and J.Minimaps:Resolve(config) or J.Hubs:Resolve(config)
        entry=minimap and J.MinimapCatalog.entries[id] or J.HubCatalog.entries[id]
        mode=minimap and config.minimapMode or config.hubMode
        local b=minimap and self.minimapButton or self.hubButton;b.caption:SetText(entry.label.."  -  Browse")
        self.sourceStatus:SetText("|cffffd38aArtwork:|r "..(not config.shown and "off" or module.snapshot and ("following "..module.snapshot.name) or module.status or "waiting for frame"))
        self.providerHelp:SetText(minimap and "The map, buttons and labels stay native. Leave room near screen edges for tall crests." or "Choose the addon that owns your main action bar. Buttons, bags and menus stay functional and keep their existing positions.")
        self.placementHelp:SetText("Follow selected frame keeps artwork attached. Screen anchors the decoration to the display. Neither option moves native controls.")
        self.guideHelp:SetText(minimap and "|cffffd38aMinimap fitting|r\nAutomatic modes follow your character. Width, height and scale adjust the surround only. Move the native map with its owning UI; leave room for crests at the screen edge." or "|cffffd38aAction hub fitting|r\nAutomatic modes follow your character, not your target. Pick the addon that owns the main bar, then adjust width and offsets around your layout. The hub never moves buttons or changes keybindings.")
    end
    self.themePreview:SetTexture(entry.texture)
    self.themePreview:ClearAllPoints();self.themePreview:SetPoint("CENTER",self.pages.artwork,"TOPLEFT",65,-149)
    self.themePreview:SetSize(104,hub and 52 or 104)
    if unit then local u1,u2=J.Portraits:TexCoords(config.unit);self.themePreview:SetTexCoord(u1,u2,0,1)
    else self.themePreview:SetTexCoord(0,1,0,1) end
    self.crest:SetTexture((J.PortraitCatalog.entries[id] or J.PortraitCatalog.entries.CLASS_PALADIN).texture)
    self.modeHelp:SetText(mode=="FIXED" and "Your chosen design stays fixed. Select an automatic mode to follow the unit again."
        or unit and "Follows this unit. Known city NPCs use matching race art. Browse chooses a fixed design."
        or "Follows your character's identity. Browse chooses a fixed design.")
    self.showButton.check:SetShown(config.shown)
    self.debugButton.check:SetShown(J.ProfileManager.current.debug)
    for key,b in pairs(self.tabs) do
        b.selection:SetShown(key==self.selected)
        b.caption:SetText((key==self.selected and "|cffffe5a0" or "|cffffd100")..names[key].."|r")
    end
    for choice,b in pairs(self.portraitButtons) do
        local u1,u2=J.Portraits:TexCoords(config.unit or "player")
        b.image:SetTexCoord(u1,u2,0,1)
        b.selection:SetShown(unit and config.portraitMode=="FIXED" and config.portrait==choice)
    end
    for choice,b in pairs(self.hubButtons) do b.selection:SetShown(hub and config.hubMode=="FIXED" and config.hub==choice) end
    for choice,b in pairs(self.minimapButtons) do b.selection:SetShown(minimap and config.minimapMode=="FIXED" and config.minimap==choice) end
    for property,control in pairs(self.controls) do
        if control.slider and config[property]~=nil then
            control.slider:SetValue(config[property])
            if not control.edit:HasFocus() then control.edit:SetText(string.format("%.2f",config[property]):gsub("%.?0+$","")) end
        elseif control.choices then
            for _,choice in ipairs(control.choices) do
                if choice[1]==config[property] then control.button.caption:SetText(choice[2]) end
            end
        end
    end
    local message=self.message
    if not J.ProfileManager.writable then message=J.ProfileManager.notice end
    if not message then message=InCombatLockdown() and J.Core.dirty and "Changes saved; artwork updates after combat."
        or "Settings save automatically. Drag the title bar to move this window. Escape closes it." end
    self.status:SetText(message)
    self.refreshing=false
end

function S:Open()
    if not self.frame and InCombatLockdown() then
        self.pendingOpen=true; J.Core:Print("Options will open after combat."); return
    end
    self.pendingOpen=nil
    self:Create(); self:FitWindow(); self.frame:Show(); self:Refresh()
end

function S:Toggle()
    if self.pendingOpen then self.pendingOpen=nil; J.Core:Print("Options opening canceled.")
    elseif self.frame and self.frame:IsShown() then self.frame:Hide()
    else self:Open() end
end
