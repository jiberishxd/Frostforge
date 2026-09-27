local _, J = ...
local S = { selected="playerFrame", page="artwork", controls={}, menus={} }
J.SettingsUI = S

local names = {minimap="Minimap",playerFrame="Player",targetFrame="Target",focusFrame="Focus",actionHub="Action hub"}
local modes = {{"CLASS","Automatic class"},{"RACE","Automatic race"},{"FACTION","Automatic faction"},{"FIXED","Chosen artwork"}}
local strata = {
    {"BACKGROUND","Background"},{"LOW","Low"},{"MEDIUM","Medium"},{"HIGH","High"},
    {"DIALOG","Dialog"},{"FULLSCREEN","Fullscreen"},{"FULLSCREEN_DIALOG","Fullscreen dialog"},{"TOOLTIP","Tooltip"},
}
local automaticStrata={{"AUTO","Automatic"}}
for _,choice in ipairs(strata) do automaticStrata[#automaticStrata+1]=choice end
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
        frame.underlay:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-10)
        frame.underlay:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-10,10)
        frame.underlay:SetColorTexture(0.025,0.03,0.035,1)
    end
    frame:SetBackdrop({
        bgFile=slider and "Interface\\Buttons\\UI-SliderBar-Background" or J.Media.panelStone,
        edgeFile=slider and "Interface\\Buttons\\UI-SliderBar-Border" or
            (kind=="outer" and "Interface\\DialogFrame\\UI-DialogBox-Border" or "Interface\\Tooltips\\UI-Tooltip-Border"),
        tile=true,tileSize=slider and 8 or 128,edgeSize=slider and 8 or (kind=="outer" and 32 or 12),
        insets=kind=="outer" and {left=11,right=12,top=12,bottom=11} or {left=3,right=3,top=3,bottom=3},
    })
    frame:SetBackdropColor(0.48,0.54,0.62,1)
    frame:SetBackdropBorderColor(0.48,0.50,0.52,1)
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
    if font and font:find("Normal",1,true) then label:SetTextColor(0.68,0.86,0.96,1)
    else label:SetTextColor(0.88,0.93,0.97,1) end
    return label
end
local function button(parent,value,x,y,width,callback,card)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); b:SetSize(width,28)
    b:SetFrameLevel(parent:GetFrameLevel()+1)
    b:EnableMouse(true)
    local function nativeButton(path,layer,parent)
        local t=art(parent or b,path,layer)
        t:SetTexCoord(0,0.625,0,0.6875)
        -- Retain Blizzard's original sculpted bevel; remove the red before tinting.
        t:SetDesaturated(true);t:SetVertexColor(0.50,0.74,0.94,1)
        return t
    end
    if card then
        backdrop(b,"inset")
        b:SetBackdropColor(0.48,0.62,0.78,1)
        b.down=art(b,J.Media.panelStone,"BORDER")
        b.down:ClearAllPoints();b.down:SetPoint("TOPLEFT",b,"TOPLEFT",4,-4);b.down:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-4,4)
        b.down:SetVertexColor(0.28,0.40,0.55,1)
    else
        b.up=nativeButton("Interface\\Buttons\\UI-Panel-Button-Up")
        b.down=nativeButton("Interface\\Buttons\\UI-Panel-Button-Down","BORDER")
    end
    b.down:Hide()
    local function frostOutline(hover)
        local rim=CreateFrame("Frame",nil,b,"BackdropTemplate")
        rim:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1);rim:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1)
        rim:SetFrameLevel(b:GetFrameLevel()+1);rim:EnableMouse(false)
        -- Native fixed-size corners and tiled edges fit both short buttons and
        -- tall artwork cards without stretching a border image across them.
        rim:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
        if hover then rim:SetBackdropBorderColor(0.80,0.94,1,1)
        else rim:SetBackdropBorderColor(0.52,0.82,1,1) end
        if not card then
            rim.glow=nativeButton("Interface\\Buttons\\UI-Panel-Button-Highlight","BACKGROUND",rim)
            rim.glow:SetBlendMode("ADD");rim.glow:SetAlpha(hover and 0.42 or 0.34)
        end
        rim:Hide();return rim
    end
    b.selection=frostOutline(false)
    b.hover=frostOutline(true)
    b.caption=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    b.caption:SetPoint("CENTER",b,"CENTER",0,0);b.caption:SetText(value);b.caption:SetTextColor(1,1,1,1)
    b:SetScript("OnClick",callback)
    b:SetScript("OnEnter",function() b.hover:Show() end)
    b:SetScript("OnLeave",function() b.hover:Hide();b.down:Hide() end)
    b:SetScript("OnMouseDown",function() b.down:Show() end)
    b:SetScript("OnMouseUp",function() b.down:Hide() end)
    b:SetScript("OnHide",function() b.hover:Hide();b.down:Hide() end)
    return b
end
local function toggle(parent,value,x,y,width,callback)
    local b=button(parent,value,x,y,width,callback,true)
    local box=art(b,"Interface\\Buttons\\UI-CheckBox-Up","ARTWORK")
    box:ClearAllPoints();box:SetPoint("LEFT",b,"LEFT",0,0);box:SetSize(28,28)
    b.check=art(b,"Interface\\Buttons\\UI-CheckBox-Check","OVERLAY")
    b.check:ClearAllPoints();b.check:SetAllPoints(box)
    b.caption:ClearAllPoints();b.caption:SetPoint("LEFT",b,"LEFT",28,0)
    function b:SetChecked(checked)
        self.check:SetShown(checked);self.selection:SetShown(checked)
    end
    return b
end

function S:Set(property,value)
    self.message=nil
    local key=J.BlizzardUnits.sharedStyleProperties[property] and "playerFrame" or self.selected
    local ok,reason=J.ProfileManager:Set(key,property,value)
    if not ok then self.message=reason; self:Refresh() end
end

function S:HideMenus()
    if self.powerColorSession then
        local session=self.powerColorSession
        if session.picker:IsShown() then session.cancel();session.picker:Hide() end
        self.powerColorSession=nil
    end
    for _,control in pairs(self.controls) do if control.hex then control.edit:ClearFocus() end end
    if self.powerStyleDialog then self.powerStyleDialog:Hide() end
    if self.stockPlacementDialog then self.stockPlacementDialog:Hide() end
    if self.profileNameEdit then self.profileNameEdit:ClearFocus() end
    if self.websiteEdit then self.websiteEdit:ClearFocus() end
    for _,menu in ipairs(self.menus) do menu:Hide() end
    if self.picker then self.picker:Hide() end
    if self.hubPicker then self.hubPicker:Hide() end
    if self.minimapPicker then self.minimapPicker:Hide() end
    if self.castPicker then self.castPicker:Hide() end
    if self.backupDialog then self.backupDialog:Hide();self.backupEdit:ClearFocus() end
    if self.resetDialog then self.resetDialog:Hide() end
    if self.stockStyleDialog then self.stockStyleDialog:Hide() end
end

local collectionSpecs={
    cast={catalog="PortraitCatalog",property="castBarArt",picker="castPicker",buttons="castButtons",groups="castGroupButtons",group="castGroup",page="castPage",label="castPageLabel",title="Cast-bar border artwork"},
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
    p.hint:SetText("Applies to "..names[self.selected]..(kind=="cast" and " cast border only. Match unit artwork returns to automatic matching." or " only. Choosing a design switches to Chosen artwork."))
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
    p.search:SetTextInsets(8,8,0,0);p.search:SetMaxLetters(64);backdrop(p.search,"button");p.search:SetText("")
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
            p:Hide();self:Set(spec.property,choice);if spec.mode then self:Set(spec.mode,"FIXED") end
        end,true)
        b:SetHeight(118)
        b.image=b:CreateTexture(nil,"ARTWORK")
        b.image:SetSize(kind=="hub" and 156 or 78,kind=="hub" and 52 or 78)
        b.image:SetPoint("TOP",b,"TOP",0,kind=="hub" and -18 or -4)
        if kind=="portrait" or kind=="cast" then b.image:SetTexCoord(0,.5,0,1) end
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
    if self.page=="profiles" or self.page=="website" then self.page="artwork" end
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
        local show=not menu:IsShown();local stockOpen=self.stockStyleDialog and self.stockStyleDialog:IsShown()
        local powerOpen=self.powerStyleDialog and self.powerStyleDialog:IsShown()
        self:HideMenus();if stockOpen then self.stockStyleDialog:Show() end
        if powerOpen then self.powerStyleDialog:Show() end;menu:SetShown(show)
    end)
    text(control.button,"v",width-22,-8,16,"GameFontNormalSmall")
    menu:SetPoint("TOPLEFT",control.button,"BOTTOMLEFT",0,-2)
    menu:SetScript("OnShow",function() control.button.selection:Show() end)
    menu:SetScript("OnHide",function() control.button.selection:Hide() end)
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
    local caption=text(parent,label,x,y,230,"GameFontNormal")
    local edit=CreateFrame("EditBox",nil,parent,"BackdropTemplate")
    edit:SetPoint("TOPLEFT",parent,"TOPLEFT",x+238,y+4); edit:SetSize(80,24)
    edit:EnableMouse(true)
    edit:SetAutoFocus(false); edit:SetFontObject("GameFontHighlightSmall")
    edit:SetTextInsets(6,6,0,0); edit:SetMaxLetters(12); backdrop(edit,"button")
    local slider=CreateFrame("Slider",nil,parent,"BackdropTemplate")
    slider:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y-32); slider:SetSize(318,18)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(rule[1],rule[2])
    slider:SetValueStep(step); slider:SetObeyStepOnDrag(true); slider:EnableMouse(true)
    backdrop(slider,"slider")
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local control={edit=edit,slider=slider,step=step,label=caption}
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

local pageNames={artwork="Artwork",placement="Placement",fitting="Unit frame",cast="Cast bar",advanced="Advanced",blizzard="Blizzard",guide="Guide"}

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
    edit:SetTextInsets(10,10,0,0);edit:SetMaxLetters(8192);backdrop(edit,"button")
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

function S:ProfileAction(action)
    local ok,reason
    local name=self.profileNameEdit:GetText()
    if action=="use" then ok,reason=J.ProfileManager:UseProfile(self.profileChoice)
    elseif action=="rename" then ok,reason=J.ProfileManager:RenameProfile(name)
    else ok,reason=J.ProfileManager:SaveAs(name,action=="new") end
    if ok then
        self.profileChoice=J.ProfileManager.activeID
        self.profileNameEdit:ClearFocus();self.profileNameEdit:SetText("")
        self.message="Profile '"..J.ProfileManager:ProfileName().."' is assigned to this character. Changes save automatically."
    else self.message=reason end
    self:Refresh()
end

function S:CreateWebsitePage()
    local p=CreateFrame("Frame",nil,self.frame);self.pages.website=p
    p:SetPoint("TOPLEFT",self.frame,"TOPLEFT",218,-214);p:SetSize(666,400);p:SetFrameLevel(202)
    local logo=p:CreateTexture(nil,"ARTWORK")
    logo:SetPoint("TOP",p,"TOP",0,-2);logo:SetSize(154,154);logo:SetTexture(J.Media.logo)
    local heading=text(p,J.Brand.name,0,-174,666,"GameFontNormalLarge");heading:SetJustifyH("CENTER")
    local description=text(p,"Craft your interface. Make it your own.",0,-209,666);description:SetJustifyH("CENTER")
    local edit=CreateFrame("EditBox",nil,p,"BackdropTemplate");self.websiteEdit=edit
    edit:SetPoint("TOPLEFT",p,"TOPLEFT",123,-244);edit:SetSize(420,34)
    edit:EnableMouse(true);edit:SetAutoFocus(false);edit:SetFontObject("GameFontHighlight")
    edit:SetTextInsets(12,12,0,0);backdrop(edit,"button");edit:SetText(J.Brand.website)
    edit:SetScript("OnTextChanged",function()
        if edit:GetText()~=J.Brand.website then edit:SetText(J.Brand.website);edit:HighlightText() end
    end)
    edit:SetScript("OnEditFocusGained",function() edit:HighlightText() end)
    edit:SetScript("OnEscapePressed",function() edit:ClearFocus() end)
    edit:SetScript("OnEnterPressed",function() edit:ClearFocus() end)
    self.websiteCopyButton=button(p,"Select website link",223,-296,220,function()
        edit:SetFocus();edit:HighlightText()
    end)
    local hint=text(p,"Select the link, then press Ctrl+C (Command+C on Mac).\nPaste it into your browser to visit The Igloo.",0,-342,666)
    hint:SetJustifyH("CENTER")
end

function S:CreateProfilesPage()
    local p=CreateFrame("Frame",nil,self.frame);self.pages.profiles=p
    p:SetPoint("TOPLEFT",self.frame,"TOPLEFT",218,-214);p:SetSize(666,400);p:SetFrameLevel(202)
    text(p,"SAVED PROFILES",0,0,310,"GameFontNormal")
    self.profileRows={}
    for i=1,5 do
        local row=button(p,"",0,-32-(i-1)*50,318,function()
            self.profileChoice=self.profileRows[i].profileID;self.message=nil;self:Refresh()
        end,true)
        row:SetHeight(44);row.caption:SetWidth(282);row.caption:SetJustifyH("LEFT")
        self.profileRows[i]=row
    end
    self.profilesPrevious=button(p,"Previous",0,-294,92,function()
        self.profilePage=(self.profilePage or 1)-1;self:Refresh()
    end)
    self.profilePageLabel=text(p,"",102,-302,100)
    self.profilesNext=button(p,"Next",226,-294,92,function()
        self.profilePage=(self.profilePage or 1)+1;self:Refresh()
    end)
    self.useProfileButton=button(p,"Use selected for this character",0,-350,318,function() self:ProfileAction("use") end)
    self.activeProfileLabel=text(p,"",346,0,318,"GameFontNormalSmall")
    text(p,"Artwork, fitting, providers and all Frostforge controls save into the active profile as you change them.",346,-52,318)
    text(p,"Profile name",346,-112,318,"GameFontNormalSmall")
    local edit=CreateFrame("EditBox",nil,p,"BackdropTemplate");self.profileNameEdit=edit
    edit:SetPoint("TOPLEFT",p,"TOPLEFT",346,-134);edit:SetSize(318,30)
    edit:EnableMouse(true);edit:SetAutoFocus(false);edit:SetFontObject("GameFontHighlightSmall")
    edit:SetTextInsets(8,8,0,0);edit:SetMaxLetters(64);backdrop(edit,"button");edit:SetText("")
    edit:SetScript("OnEscapePressed",function() edit:ClearFocus() end)
    edit:SetScript("OnEnterPressed",function() self:ProfileAction("copy") end)
    self.saveProfileButton=button(p,"Save as new profile",346,-184,318,function() self:ProfileAction("copy") end)
    self.newProfileButton=button(p,"New profile from defaults",346,-226,318,function() self:ProfileAction("new") end)
    self.renameProfileButton=button(p,"Rename active profile",346,-268,318,function() self:ProfileAction("rename") end)
    text(p,"A new character starts with its own automatic setup. Selecting the same profile on two characters shares future edits. Save as new to keep them separate.",346,-316,318)
end

function S:RefreshProfiles()
    self.heading:SetText("Profiles  |  This character")
    self.pageHint:SetText("Your character's assignment loads automatically when you log in.")
    self.activeProfileLabel:SetText("ACTIVE PROFILE\n"..J.ProfileManager:ProfileName())
    local list=J.ProfileManager:ProfileList()
    local pages=math.max(1,math.ceil(#list/5))
    self.profilePage=math.max(1,math.min(pages,self.profilePage or 1))
    self.profileChoice=self.profileChoice or J.ProfileManager.activeID
    for i,row in ipairs(self.profileRows) do
        local entry=list[(self.profilePage-1)*5+i]
        row:SetShown(entry~=nil);row.profileID=entry and entry.id
        if entry then row.caption:SetText(entry.name);row.selection:SetShown(entry.id==self.profileChoice) end
    end
    self.profilePageLabel:SetText(self.profilePage.." / "..pages)
    self.profilesPrevious:SetAlpha(self.profilePage>1 and 1 or .45)
    self.profilesNext:SetAlpha(self.profilePage<pages and 1 or .45)
    self.status:SetText(not J.ProfileManager.writable and J.ProfileManager.notice or self.message
        or "Profiles change only Frostforge. Your other addons keep their own profiles.")
end

function S:ColorValue(prefix,value,key)
    local hex=J.Core:ValidateProperty(prefix.."Custom",value)
    if not hex then self.message="Enter a six-digit color, for example 0070DE.";self:Refresh();return end
    self.message=nil
    key=key or (J.BlizzardUnits.sharedStyleProperties[prefix.."Custom"] and "playerFrame" or self.selected)
    J.ProfileManager:Set(key,prefix.."Custom",hex)
    J.ProfileManager:Set(key,prefix.."Color","CUSTOM")
end

function S:ChoosePowerColor(prefix)
    local picker=ColorPickerFrame
    if not picker or type(picker.SetupColorPickerAndShow)~="function" then
        self.message="Enter the custom color as six hex digits.";self:Refresh();return
    end
    local key=J.BlizzardUnits.sharedStyleProperties[prefix.."Custom"] and "playerFrame" or self.selected
    local profile=J.ProfileManager.current
    local config=J.ThemeManager:Resolve(key)
    local color=J.BlizzardUnits:HexColor(config[prefix.."Custom"])
    local session={};self.powerColorSession=session
    local function current() return self.powerColorSession==session and J.ProfileManager.current==profile end
    local function cancel()
        if not current() then return end
        self.powerColorSession=nil
        J.ProfileManager:Set(key,prefix.."Custom",config[prefix.."Custom"])
        J.ProfileManager:Set(key,prefix.."Color",config[prefix.."Color"])
    end
    session.cancel=cancel;session.picker=picker
    picker:SetupColorPickerAndShow({r=color[1],g=color[2],b=color[3],hasOpacity=false,
        swatchFunc=function()
            if not current() then return end
            local r,g,b=picker:GetColorRGB()
            if not J.Core:IsNumber(r) or not J.Core:IsNumber(g) or not J.Core:IsNumber(b) then return end
            local function byte(v) return math.floor(math.max(0,math.min(1,v))*255+.5) end
            self:ColorValue(prefix,string.format("%02X%02X%02X",byte(r),byte(g),byte(b)),key)
        end,cancelFunc=cancel})
    if type(picker.Raise)=="function" then picker:Raise() end
end

function S:CreatePowerStyleDialog()
    local dialog=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");self.powerStyleDialog=dialog
    dialog:SetSize(728,490);dialog:SetPoint("CENTER",self.frame,"CENTER",0,0)
    dialog:SetFrameStrata("DIALOG");dialog:SetFrameLevel(230);dialog:EnableMouse(true);backdrop(dialog,"outer")
    self.powerStyleTitle=text(dialog,"Blizzard power colors",24,-24,676,"GameFontNormalLarge")
    text(dialog,"Choose the resource color and shading independently. Saved with your Frostforge profile.",24,-62,676)
    self.powerScope="unit";self.powerScopeButtons={};self.powerPanels={}
    for i,scope in ipairs({"unit","party"}) do
        local prefix=scope=="unit" and "blizzardPower" or "blizzardPartyPower"
        self.powerScopeButtons[scope]=button(dialog,scope=="unit" and "This unit" or "Party & raid",24+(i-1)*350,-100,318,function()
            self:HideMenus();self.powerScope=scope;dialog:Show();self:Refresh()
        end,true)
        local body=CreateFrame("Frame",nil,dialog);body:SetPoint("TOPLEFT",dialog,"TOPLEFT",24,-156);body:SetSize(676,220)
        self.powerPanels[scope]=body
        self:Dropdown(prefix.."Color","Power color",{{"STOCK","Native resource color"},{"CLASS","Class color (players)"},{"CUSTOM","Custom color"}},0,0,body)
        self:Dropdown(prefix.."Shading","Shading",{{"SOLID","Solid"},{"GRADIENT","Gradient"}},350,0,body)
        text(body,"Custom color",0,-88,250,"GameFontNormal")
        local swatch=body:CreateTexture(nil,"ARTWORK");swatch:SetPoint("TOPLEFT",body,"TOPLEFT",0,-114);swatch:SetSize(44,28)
        local edit=CreateFrame("EditBox",nil,body,"BackdropTemplate")
        edit:SetPoint("TOPLEFT",body,"TOPLEFT",54,-114);edit:SetSize(112,28);edit:SetAutoFocus(false)
        edit:SetFontObject("GameFontHighlightSmall");edit:SetTextInsets(8,8,0,0);edit:SetMaxLetters(7);edit:EnableMouse(true);backdrop(edit,"button")
        self.controls[prefix.."Custom"]={edit=edit,swatch=swatch,hex=true}
        edit:SetScript("OnEnterPressed",function() local value=edit:GetText();edit:ClearFocus();self:ColorValue(prefix,value) end)
        edit:SetScript("OnEscapePressed",function() edit:ClearFocus();self:Refresh() end)
        edit:SetScript("OnEditFocusGained",function() edit:HighlightText() end)
        edit:SetScript("OnEditFocusLost",function() self:Refresh() end)
        button(body,"Choose color",182,-114,136,function() self:ChoosePowerColor(prefix) end)
        text(body,"Type six hex digits and press Enter, or use the color picker. Choosing a color enables Custom.",350,-90,318)
        text(body,"Gradient runs from a darker shade at the bottom to the chosen color at the top. Native follows mana, rage, energy and other resources.",0,-176,676)
    end
    text(dialog,"Blizzard frames only. Uses your selected power texture; custom colors and gradients replace pre-colored stock fills with a neutral texture. Changes apply after combat.",24,-382,676)
    button(dialog,"Back",24,-440,150,function() self:HideMenus();self.stockStyleDialog:Show() end)
    button(dialog,"Done",542,-440,150,function() self:HideMenus() end)
    dialog:Hide()
end

function S:CreateStockPlacementDialog()
    local dialog=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");self.stockPlacementDialog=dialog
    dialog:SetSize(728,410);dialog:SetPoint("CENTER",self.frame,"CENTER",0,0)
    dialog:SetFrameStrata("DIALOG");dialog:SetFrameLevel(230);dialog:EnableMouse(true);backdrop(dialog,"outer")
    self.stockPlacementTitle=text(dialog,"Blizzard placement",24,-24,676,"GameFontNormalLarge")
    self.stockPlacementPanels={};self.stockPlacementToggles={}
    self.stockPlacementStatus=text(dialog,"",374,-80,318)
    for _,kind in ipairs({"Auras","CastPosition"}) do
        local prefix="blizzard"..kind
        local body=CreateFrame("Frame",nil,dialog);body:SetPoint("TOPLEFT",dialog,"TOPLEFT",24,-80);body:SetSize(676,250)
        self.stockPlacementPanels[kind]=body
        self.stockPlacementToggles[kind]=toggle(body,"Customize position",0,0,318,function() self:Set(prefix.."Enabled",not J.ThemeManager:Resolve(self.selected)[prefix.."Enabled"]) end)
        self:Number(prefix.."X","Horizontal offset",0,-60,1,body)
        self:Number(prefix.."Y","Vertical offset",350,-60,1,body)
        text(body,kind=="Auras" and "Moves Blizzard's combined buff/debuff group together. Positive X moves right; positive Y moves up. Native aura order, tooltips and visibility stay unchanged." or "Moves the native Blizzard cast bar and its Frostforge border together. Offsets follow Blizzard's normal anchor, including its aura placement. Enable the border and choose Blizzard on the Cast bar page.",0,-144,676)
        text(body,"Changes and restoration apply outside combat. Turn off Customize position to restore Blizzard placement.",0,-211,676)
        button(body,"Reset position",0,-266,200,function() self:Set(prefix.."Enabled",false);self:Set(prefix.."X",0);self:Set(prefix.."Y",0) end)
    end
    button(dialog,"Done",542,-346,150,function() self:HideMenus() end)
    dialog:Hide()
end

function S:Create()
    if self.frame then return end
    assert(not InCombatLockdown(),"First options attachment deferred during combat")
    local f=CreateFrame("Frame","JiberishUIOptionsFrame",UIParent,"BackdropTemplate")
    self.frame=f
    f:Hide();f:SetSize(920,700);f:SetFrameStrata("DIALOG");f:SetFrameLevel(200)
    f:EnableMouse(true);f:SetMovable(true);f:SetClampedToScreen(true)
    backdrop(f,"outer")
    panel(f,20,-98,174,538);panel(f,200,-98,700,538);panel(f,20,-640,880,40)
    local rule=f:CreateTexture(nil,"ARTWORK");rule:SetColorTexture(.38,.64,.81,.75)
    rule:SetPoint("TOPLEFT",f,"TOPLEFT",218,-152);rule:SetSize(666,1)

    local title=CreateFrame("Frame",nil,f);self.titleBar=title
    title:SetPoint("TOPLEFT",f,"TOPLEFT",0,0);title:SetSize(850,94)
    title:EnableMouse(true);title:RegisterForDrag("LeftButton")
    self.crest=title:CreateTexture(nil,"ARTWORK")
    self.crest:SetPoint("TOPLEFT",title,"TOPLEFT",26,-14);self.crest:SetSize(76,76);self.crest:SetTexCoord(0,1,0,1);self.crest:SetTexture(J.Media.logo)
    text(title,J.Brand.name,112,-28,440,"GameFontNormalLarge")
    text(title,"Craft your interface. Keep the spirit of Warcraft.",112,-54,510)
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
    text(f,"Choose a component to shape its artwork.",32,-424,140)
    self.profilesButton=button(f,"Profiles",28,-470,154,function() self:SetPage("profiles") end,true)
    self.websiteButton=button(f,"The Igloo",28,-508,154,function() self:SetPage("website") end,true)
    self.resetButton=button(f,"Reset component",28,-552,154,function()
        self:HideMenus();self.resetKey=self.selected
        self.resetTitle:SetText("Reset "..names[self.selected].." artwork?");self.resetDialog:Show()
    end)
    button(f,"Center window",28,-592,154,function() self:Center() end)

    self.pages={};self.pageButtons={}
    for i,key in ipairs({"artwork","placement","fitting","cast","blizzard","advanced","guide"}) do
        local page=key
        self.pageButtons[key]=button(f,pageNames[key],218+(i-1)*112,-114,104,function() self:SetPage(page) end)
        local body=CreateFrame("Frame",nil,f);body:SetPoint("TOPLEFT",f,"TOPLEFT",218,-214);body:SetSize(666,400)
        body:SetFrameLevel(202);self.pages[key]=body
    end
    self:CreateProfilesPage()
    self:CreateWebsitePage()
    self.heading=text(f,"",220,-165,650,"GameFontNormalLarge")
    self.pageHint=text(f,"",220,-192,652)
    local a=self.pages.advanced
    self:Dropdown("strata","Portrait art strata",strata,0,-14,a)
    self:Number("level","Level within strata",346,-14,1,a)
    self:Dropdown("unitFrameStrata","Unit-frame art strata",automaticStrata,0,-108,a)
    self:Dropdown("layer","Texture draw layer",layers,346,-202,a)
    self:Dropdown("unitFrameFill","Health & power textures",{{"AUTO","Automatic (respect UI addon)"},{"PROVIDER","Keep provider textures"},{"JIBERISH","Use Frostforge fills"}},346,-108,a)
    self.debugButton=toggle(a,"Show fitting bounds",0,-350,318,function() J.Core:Command("debug") end)
    text(a,"Strata controls which artwork draws in front. Each decoration has its own setting. Higher strata may cover names. Choose Frostforge Stone in your UI addon to share the stone texture across its bars.",0,-286,666)
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
    self:Number("unitFrameX","Artwork horizontal offset",0,-108,.5,a)
    self:Number("unitFrameY","Artwork vertical offset",346,-108,.5,a)
    panel(a,0,-196,666,106)
    text(a,"FIT THE FRAME, KEEP YOUR BARS",18,-214,626,"GameFontNormal")
    text(a,"The original artwork sits over the bars. Reduce width to bring its side edges inward; adjust height and offsets for your fit. 100% slightly overlaps both sides. No extra borders are added. Portrait fitting stays on Placement.",18,-244,626)
    button(a,"Reset unit-frame fitting",0,-332,318,function()
        self:Set("unitFrameWidth",100);self:Set("unitFrameHeight",100);self:Set("unitFrameX",0);self:Set("unitFrameY",0)
    end)
    text(a,"Fitting changes apply after combat. Native bar values, colors and texture choices stay with your UI addon.",0,-378,666)

    a=self.pages.cast
    self.castToggle=toggle(a,"Cast-bar border",0,0,318,function() self:Set("castBarShown",not J.ThemeManager:Resolve(self.selected).castBarShown) end)
    text(a,"Native cast values, timing and text stay with your provider.",346,0,318)
    self:Dropdown("castBarSource","Cast-bar provider",hubSources,0,-50,a)
    self:Dropdown("castBarStrata","Cast-border strata",automaticStrata,346,-50,a)
    self:Number("castBarLevel","Level above nearby artwork",346,-110,1,a)
    text(a,"Border artwork",0,-114,318,"GameFontNormal")
    self.castMatch=button(a,"Match unit artwork",0,-136,318,function() self:Set("castBarArt","MATCH") end)
    self.castBrowse=button(a,"Choose border artwork",0,-174,318,function()
        self:HideMenus();self:ShowCollection("cast",self.castGroup or "CLASS",self.castPage);self.castPicker:Show()
    end)
    self:Number("castBarWeight","Border weight",0,-218,.05,a)
    self:Number("castBarPadding","Space around the bar",346,-218,.5,a)
    self:Number("castBarWidth","Border width (%)",0,-284,1,a)
    self:Number("castBarHeight","Border height (%)",346,-284,1,a)
    self.castReset=button(a,"Reset border fitting",0,-346,220,function()
        self:Set("castBarWidth",100);self:Set("castBarHeight",100)
        self:Set("castBarWeight",1);self:Set("castBarPadding",1)
    end)
    self.castStatus=text(a,"",242,-346,424)
    text(a,"Strata and level control this border only. Automatic clears nearby frame artwork. Width and height fit the native bar. Changes apply after combat.",0,-392,666)
    self:CreateCollection("cast")

    a=self.pages.blizzard
    self.nativePortraitToggle=toggle(a,"Hide Blizzard portrait image",0,0,318,function() self:Set("blizzardPortraitHidden",not J.ThemeManager:Resolve(self.selected).blizzardPortraitHidden) end)
    self.nativePortraitFrameToggle=toggle(a,"Hide full Blizzard portrait",346,0,318,function() self:Set("blizzardPortraitFrameHidden",not J.ThemeManager:Resolve(self.selected).blizzardPortraitFrameHidden) end)
    self.textGroup=self.textGroup or "Name"
    self.textPanels={};self.textButtons={};self.textToggles={}
    local textLabels={Name="Name",Health="Health",Power="Power",Level="Level",CastName="Cast name",CastTime="Cast time"}
    for i,group in ipairs(J.BlizzardUnits.textGroups) do
        local selected=group
        self.textButtons[group]=button(a,textLabels[group],(i-1)*112,-50,104,function()
            self:HideMenus();self.textGroup=selected;self:Refresh()
        end,true)
        local body=CreateFrame("Frame",nil,a);body:SetPoint("TOPLEFT",a,"TOPLEFT",0,-94);body:SetSize(666,246)
        self.textPanels[group]=body
        local prefix="blizzard"..group
        self.textToggles[group]=toggle(body,"Customize "..textLabels[group]:lower(),0,0,318,function()
            self:Set(prefix.."Enabled",not J.ThemeManager:Resolve(self.selected)[prefix.."Enabled"])
        end)
        text(body,"Offsets use the original Blizzard position. Hidden labels stay hidden.",346,0,318)
        self:Number(prefix.."X","Horizontal offset",0,-50,1,body)
        self:Number(prefix.."Y","Vertical offset",346,-50,1,body)
        self:Number(prefix.."Size","Font size",0,-122,1,body)
        self:Dropdown(prefix.."Align","Alignment",{{"KEEP","Keep Blizzard alignment"},{"LEFT","Left"},{"CENTER","Center"},{"RIGHT","Right"}},346,-122,body)
        self:Dropdown(prefix.."Outline","Outline",{{"KEEP","Keep Blizzard outline"},{"NONE","None"},{"OUTLINE","Outline"},{"THICKOUTLINE","Thick outline"}},0,-196,body)
        button(body,"Reset "..textLabels[group]:lower(),346,-218,318,function()
            for _,suffix in ipairs({"Enabled","X","Y","Size","Align","Outline"}) do
                self:Set(prefix..suffix,J.ThemeManager.registry[J.ProfileManager.current.theme][self.selected][prefix..suffix])
            end
        end)
    end
    self.nativeNameToggle=self.textToggles.Name
    self.nativeReset=button(a,"Restore portrait & text",502,-352,164,function()
        self:Set("blizzardPortraitHidden",false);self:Set("blizzardPortraitFrameHidden",false)
        for _,group in ipairs(J.BlizzardUnits.textGroups) do
            local prefix="blizzard"..group
            for _,suffix in ipairs({"Enabled","X","Y","Size","Align","Outline"}) do
                self:Set(prefix..suffix,J.ThemeManager.registry[J.ProfileManager.current.theme][self.selected][prefix..suffix])
            end
        end
    end)
    self.stockStyleButton=button(a,"Colors & textures",0,-352,156,function()
        self:HideMenus();self.stockStyleDialog:Show();self:Refresh()
    end)
    self.stockAurasButton=button(a,"Buffs & debuffs...",166,-352,156,function()
        self:HideMenus();self.stockPlacementKind="Auras";self.stockPlacementDialog:Show();self:Refresh()
    end)
    self.stockCastPositionButton=button(a,"Cast-bar position...",332,-352,160,function()
        self:HideMenus();self.stockPlacementKind="CastPosition";self.stockPlacementDialog:Show();self:Refresh()
    end)
    self.nativeStatus=text(a,"",0,-394,666)
    local dialog=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");self.stockStyleDialog=dialog
    dialog:SetSize(728,490);dialog:SetPoint("CENTER",self.frame,"CENTER",0,0)
    dialog:SetFrameStrata("DIALOG");dialog:SetFrameLevel(230);dialog:EnableMouse(true);backdrop(dialog,"outer")
    self.stockStyleTitle=text(dialog,"Blizzard colors & textures",24,-24,676,"GameFontNormalLarge")
    text(dialog,"Names and health are independent. Party & raid and texture choices are shared across stock frames.",24,-60,676)
    local nameColors={{"STOCK","Blizzard color"},{"CLASS","Class color (players)"}}
    local healthColors={{"STOCK","Blizzard color"},{"CLASS","Class gradient (players)"},{"DARK","Dark stone"}}
    local textures={{"AUTO","Automatic (stone default)"},{"STONE","Frostforge Stone"},{"SMOOTH","Smooth"},{"STOCK","Blizzard texture"}}
    self:Dropdown("blizzardNameColor","This unit: name color",nameColors,24,-108,dialog)
    self:Dropdown("blizzardHealthColor","This unit: health color",healthColors,374,-108,dialog)
    self:Dropdown("blizzardPartyNameColor","Party & raid: name color",nameColors,24,-186,dialog)
    self:Dropdown("blizzardPartyHealthColor","Party & raid: health color",healthColors,374,-186,dialog)
    self:Dropdown("blizzardHealthTexture","Stock health texture",textures,24,-264,dialog)
    self:Dropdown("blizzardPowerTexture","Stock power texture",textures,374,-264,dialog)
    self.stockStoneToggle=toggle(dialog,"Stone for Automatic texture",24,-334,318,function()
        J.ProfileManager:Set("playerFrame","blizzardStone",not J.ThemeManager:Resolve("playerFrame").blizzardStone);self:Refresh()
    end)
    text(dialog,"Class gradients shade the selected texture; Blizzard texture uses a neutral fill for class colors. Dark stone is charcoal. Use Power colors for resource tints and gradients. Changes apply after combat.",24,-380,676)
    self.powerStyleButton=button(dialog,"Power colors...",24,-440,180,function()
        self:HideMenus();self.powerStyleDialog:Show();self:Refresh()
    end)
    button(dialog,"Done",542,-440,150,function() self:HideMenus() end)
    dialog:Hide()
    self:CreatePowerStyleDialog();self:CreateStockPlacementDialog()

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
    self:Dropdown("unitFrameSource","Unit-frame provider",{{"AUTO","Automatic"},{"BLIZZARD","Blizzard"},{"ELVUI","ElvUI"},{"ELLESMERE","EllesmereUI"}},346,-236,a)
    self.sourceStatus=text(a,"",0,-304,666)
    self.providerHelp=text(a,"",0,-354,666)
    self:CreatePortraitPicker();self:CreateHubPicker();self:CreateMinimapPicker()

    a=self.pages.guide
    panel(a,0,0,666,180)
    text(a,"FIRST STEPS",18,-18,626,"GameFontNormal")
    text(a,"1. Choose Player, Target, Focus, Minimap or Action hub on the left.\n\n2. On Artwork, turn on the decorations you want. Portrait and unit-frame art can be used separately or together.\n\n3. Keep Automatic class, or browse the collection for a fixed design.\n\n4. Keep providers on Automatic, or select your UI addon. Advanced lets you keep its bar textures or use Frostforge fills.",18,-46,626)
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
    local profiles=self.page=="profiles"
    self.pages.profiles:SetShown(profiles);self.profilesButton.selection:SetShown(profiles)
    local website=self.page=="website"
    self.pages.website:SetShown(website);self.websiteButton.selection:SetShown(website)
    self.resetButton:SetShown(not profiles and not website)
    if profiles or website then
        for key,page in pairs(self.pages) do if key~=self.page then page:Hide() end end
        for _,b in pairs(self.pageButtons) do b:Hide() end
        for _,b in pairs(self.tabs) do b.selection:Hide() end
        if profiles then self:RefreshProfiles()
        else
            self.heading:SetText("The Igloo  |  Jiberish's home")
            self.pageHint:SetText("Find more from Jiberish at The Igloo.")
            self.status:SetText("Copy the website address and paste it into your browser.")
        end
        self.refreshing=false;return
    end
    for _,b in pairs(self.pageButtons) do b:Show() end
    local config=J.ThemeManager:Resolve(self.selected)
    local unit=J.Portraits:IsUnitKey(self.selected)
    local minimap=self.selected=="minimap"
    local hub=self.selected=="actionHub"
    local module=J.Core.modules[self.selected]
    local headings={artwork="Artwork",placement="Placement & size",fitting="Unit-frame fitting",cast="Cast-bar border",advanced="Textures, layers & diagnostics",blizzard="Stock portrait & text",guide="Getting started"}
    if not unit and (self.page=="fitting" or self.page=="cast" or self.page=="blizzard") then self.page="placement" end
    self.heading:SetText(names[self.selected].."  |  "..headings[self.page])
    local hints={artwork=unit and "Choose your portrait surround and full-frame artwork independently." or "Choose a matching theme, then follow your existing UI.",
        placement=unit and "These controls fit the portrait surround. Use Unit frame to fit the shell around the bars." or "Fit the decoration around your existing minimap or action bars.",
        fitting="Enable Unit-frame art on Artwork; then fit its size and position.",
        cast="A matching border, independent of portraits and full unit-frame shells.",
        blizzard="Optional controls for stock Blizzard Player, Target and Focus only.",
        advanced="Choose who controls bar textures, then fine-tune layering.",guide="A few simple steps, plus tools to keep your settings safe."}
    self.pageHint:SetText(hints[self.page])
    for key,page in pairs(self.pages) do
        page:SetShown(key==self.page)
        if self.pageButtons[key] then self.pageButtons[key].selection:SetShown(key==self.page) end
    end
    local visiblePages=unit and {"artwork","placement","fitting","cast","blizzard","advanced","guide"} or {"artwork","placement","advanced","guide"}
    self.pageButtons.fitting:SetShown(unit);self.pageButtons.cast:SetShown(unit);self.pageButtons.blizzard:SetShown(unit)
    for i,key in ipairs(visiblePages) do
        local b=self.pageButtons[key];local step=unit and 96 or 168
        b:ClearAllPoints();b:SetPoint("TOPLEFT",self.frame,"TOPLEFT",218+(i-1)*step,-114);b:SetWidth(step-8)
    end
    self.styleButton:SetShown(unit);self.styleHelp:SetShown(unit)
    self.controls.unitFrameSource.button:SetShown(unit);self.controls.unitFrameSource.label:SetShown(unit)
    self.controls.unitFrameFill.button:SetShown(unit);self.controls.unitFrameFill.label:SetShown(unit)
    for _,property in ipairs({"unitFrameStrata","castBarStrata"}) do
        self.controls[property].button:SetShown(unit);self.controls[property].label:SetShown(unit)
    end
    for _,part in ipairs({"edit","slider","label"}) do self.controls.castBarLevel[part]:SetShown(unit) end
    self.controls.strata.label:SetText(unit and "Portrait art strata" or "Artwork strata")
    if unit then
        self.stockStoneToggle:SetChecked(J.ThemeManager:Resolve("playerFrame").blizzardStone)
        self.powerStyleTitle:SetText("Blizzard power colors — "..names[self.selected])
        for scope,body in pairs(self.powerPanels) do
            body:SetShown(scope==self.powerScope);self.powerScopeButtons[scope].selection:SetShown(scope==self.powerScope)
        end
        local movable=self.selected=="targetFrame" or self.selected=="focusFrame"
        self.stockAurasButton:SetShown(movable);self.stockCastPositionButton:SetShown(movable)
        for kind,body in pairs(self.stockPlacementPanels) do
            body:SetShown(kind==self.stockPlacementKind)
            self.stockPlacementToggles[kind]:SetChecked(config["blizzard"..kind.."Enabled"]==true)
        end
        self.stockPlacementTitle:SetText(names[self.selected]..(self.stockPlacementKind=="Auras" and " buffs & debuffs" or " Blizzard cast bar"))
        self.stockPlacementStatus:SetText((J.BlizzardUnits.placementStatus or {})[self.selected..(self.stockPlacementKind or "Auras")] or "Enable Customize position to move this group.")
        self.stockStyleTitle:SetText("Blizzard colors & textures — "..names[self.selected])
        self.nativePortraitToggle:SetChecked(config.blizzardPortraitHidden)
        self.nativePortraitFrameToggle:SetChecked(config.blizzardPortraitFrameHidden)
        for _,group in ipairs(J.BlizzardUnits.textGroups) do
            self.textPanels[group]:SetShown(group==self.textGroup)
            self.textButtons[group].selection:SetShown(group==self.textGroup)
            self.textToggles[group]:SetChecked(config["blizzard"..group.."Enabled"])
        end
        self.nativeStatus:SetText(J.BlizzardUnits.status[self.selected] or "Stock settings unchanged. Changes and restoration apply outside combat.")
        self.styleButton:SetChecked(config.unitFrameShown)
        self.castToggle:SetChecked(config.castBarShown)
        self.castMatch.selection:SetShown(config.castBarArt=="MATCH")
        local castID=J.CastBars:Artwork(config)
        self.castBrowse.caption:SetText(J.PortraitCatalog.entries[castID].label.." - Browse")
        self.castStatus:SetText((config.castBarArt=="MATCH" and "Matching unit artwork: " or "Chosen border artwork: ")..J.PortraitCatalog.entries[castID].label.."\n"..(J.CastBars.status[self.selected] or "Waiting for cast-bar provider"))
        for choice,b in pairs(self.castButtons) do b.selection:SetShown(config.castBarArt==choice) end
    end
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
        self.sourceStatus:SetText("|cff9edfffPortrait:|r "..portrait.."\n|cff9edfffUnit frame:|r "..frame)
        self.providerHelp:SetText("Full-frame artwork supports Blizzard, ElvUI and Ellesmere. Use horizontal health with full-width power attached below. Hidden power retains a complete shell with a dark empty opening.")
        self.placementHelp:SetText("Offsets move only the decoration. Use your UI addon's settings to move the portrait or health bars themselves.")
        self.guideHelp:SetText("|cff9edfffArtwork missing?|r Target a unit first, check each artwork toggle, and choose the matching provider. Enable portraits in that provider too. Hidden or inside-health portraits may not support a surround.\n\n|cff9edfffWrong NPC theme?|r Known city affiliations use matching race art. Unknown NPCs use the normal fallback. Choose a fixed design to override it.")
    else
        id=minimap and J.Minimaps:Resolve(config) or J.Hubs:Resolve(config)
        entry=minimap and J.MinimapCatalog.entries[id] or J.HubCatalog.entries[id]
        mode=minimap and config.minimapMode or config.hubMode
        local b=minimap and self.minimapButton or self.hubButton;b.caption:SetText(entry.label.."  -  Browse")
        self.sourceStatus:SetText("|cff9edfffArtwork:|r "..(not config.shown and "off" or module.snapshot and ("following "..module.snapshot.name) or module.status or "waiting for frame"))
        self.providerHelp:SetText(minimap and "The map, buttons and labels stay native. Leave room near screen edges for tall crests." or "Choose the addon that owns your main action bar. Buttons, bags and menus stay functional and keep their existing positions.")
        self.placementHelp:SetText("Follow selected frame keeps artwork attached. Screen anchors the decoration to the display. Neither option moves native controls.")
        self.guideHelp:SetText(minimap and "|cff9edfffMinimap fitting|r\nAutomatic modes follow your character. Width, height and scale adjust the surround only. Move the native map with its owning UI; leave room for crests at the screen edge." or "|cff9edfffAction hub fitting|r\nAutomatic modes follow your character, not your target. Pick the addon that owns the main bar, then adjust width and offsets around your layout. The hub never moves buttons or changes keybindings.")
    end
    self.themePreview:SetTexture(entry.texture)
    self.themePreview:ClearAllPoints();self.themePreview:SetPoint("CENTER",self.pages.artwork,"TOPLEFT",65,-149)
    self.themePreview:SetSize(104,hub and 52 or 104)
    if unit then local u1,u2=J.Portraits:TexCoords(config.unit);self.themePreview:SetTexCoord(u1,u2,0,1)
    else self.themePreview:SetTexCoord(0,1,0,1) end
    self.modeHelp:SetText(mode=="FIXED" and "Your chosen design stays fixed. Select an automatic mode to follow the unit again."
        or unit and "Follows this unit. Known city NPCs use matching race art. Browse chooses a fixed design."
        or "Follows your character's identity. Browse chooses a fixed design.")
    self.showButton:SetChecked(config.shown)
    self.debugButton:SetChecked(J.ProfileManager.current.debug)
    for key,b in pairs(self.tabs) do
        b.selection:SetShown(key==self.selected)
        b.caption:SetText(names[key])
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
        elseif control.hex then
            local value=J.BlizzardUnits.sharedStyleProperties[property] and J.ThemeManager:Resolve("playerFrame")[property] or config[property]
            local color=J.BlizzardUnits:HexColor(value)
            if color then
                if not control.edit:HasFocus() then control.edit:SetText(value) end
                control.swatch:SetColorTexture(unpack(color))
            end
        elseif control.choices then
            local value=J.BlizzardUnits.sharedStyleProperties[property] and J.ThemeManager:Resolve("playerFrame")[property] or config[property]
            for _,choice in ipairs(control.choices) do
                if choice[1]==value then control.button.caption:SetText(choice[2]) end
                control.options[choice[1]].selection:SetShown(choice[1]==value)
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
