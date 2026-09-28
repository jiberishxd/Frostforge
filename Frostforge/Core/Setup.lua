local _,J=...
local W={step=1}
J.Setup=W
local units={"playerFrame","targetFrame","focusFrame"}
local tips={
    BLIZZARD={"Blizzard UI", "1. Move your frames with Blizzard Edit Mode.\n\n2. In Frostforge, enable Portrait art and Unit-frame art separately.\n\n3. Use Placement for size; use the Blizzard tab for stock portraits, text and colors."},
    ELVUI={"ElvUI", "1. Portrait art: use Blinkii's Portraits or mMediaTag & Tools. Their circular portrait controls give Frostforge a closer fit.\n\n2. Unit-frame art: use ElvUI's own unit frames, with horizontal health and full-width power below.\n\n3. In Frostforge, pick your portrait addon as Portrait provider and ElvUI as Unit-frame provider, or keep Automatic."},
    ELLESMERE={"EllesmereUI", "1. Enable a separate portrait in Ellesmere for a portrait surround.\n\n2. Full shells fit horizontal health with power attached below, not detached power.\n\n3. Choose Frostforge Stone in Ellesmere's texture menu if you want matching fills."},
}
-- Actual captures, shown one at a time and released when the tour closes.
function W:Picture(body,path,x,y,w,h,uv)
    local t=body:CreateTexture(nil,"ARTWORK")
    t:SetPoint("TOPLEFT",body,"TOPLEFT",x,y);t:SetSize(w,h);t:SetTexCoord(unpack(uv))
    self.pictures[#self.pictures+1]={texture=t,page=body,path=path}
end

function W:Dismiss()
    self.pending=nil
    if J.ProfileManager.writable and (JiberishUIDB.setupVersion==nil or JiberishUIDB.setupVersion==0) then JiberishUIDB.setupVersion=1 end
    if self.frame then self.frame:Hide() end
end

function W:Fit()
    if not self.frame then return end
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    if J.Core:IsNumber(w) and J.Core:IsNumber(h) and w>32 and h>32 then
        self.frame:SetScale(math.min(1,(w-32)/760,(h-32)/640))
    end
end

function W:Create()
    if self.frame then return end
    local ui=J.SettingsUI.widgets
    local f=CreateFrame("Frame","JiberishUISetupFrame",UIParent,"BackdropTemplate")
    self.frame=f;f:Hide();f:SetSize(760,640);f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    f:SetFrameStrata("DIALOG");f:SetFrameLevel(240);f:EnableMouse(true);f:SetClampedToScreen(true);ui.backdrop(f,"outer")
    local logo=f:CreateTexture(nil,"ARTWORK");logo:SetPoint("TOPLEFT",f,"TOPLEFT",26,-20);logo:SetSize(64,64);logo:SetTexture(J.Media.logo)
    ui.text(f,"Welcome to Frostforge",108,-26,600,"GameFontNormalLarge")
    self.progress=ui.text(f,"",108,-56,600)
    self.pages={};self.choices={};self.toggles={};self.pictures={};self.providers={}
    for i=1,4 do
        local body=CreateFrame("Frame",nil,f);body:SetPoint("TOPLEFT",f,"TOPLEFT",32,-106);body:SetSize(696,446)
        body:SetFrameLevel(241);self.pages[i]=body
    end
    local a=self.pages[1]
    ui.text(a,"Your artwork, in game",0,0,696,"GameFontNormalLarge")
    self:Picture(a,J.Media.setupInGame,0,-42,696,391.6,{0,910/1024,0,1})
    a=self.pages[2]
    ui.text(a,"Quick tips for your interface",0,0,696,"GameFontNormalLarge")
    for i,key in ipairs({"BLIZZARD","ELVUI","ELLESMERE"}) do
        self.providers[key]=ui.button(a,tips[key][1],(i-1)*236,-40,224,function() self.provider=key;self:Refresh() end)
    end
    self:Picture(a,J.Media.setupSettings,0,-92,350,267,{0,1,0,390/512})
    self.providerTips=ui.text(a,"",376,-94,320)
    ui.text(a,"Tips only: choose providers in settings if Automatic picks the wrong frame.",376,-374,320,"GameFontNormalSmall")
    a=self.pages[3]
    ui.text(a,"Choose your starting look",0,0,696,"GameFontNormalLarge")
    for i,entry in ipairs({{"CLASS","Follow class"},{"RACE","Follow race"},{"FACTION","Follow faction"}}) do
        local mode=entry[1]
        self.choices[mode]=ui.button(a,entry[2],(i-1)*236,-40,224,function() self.draft.mode=mode;self:Refresh() end,true)
    end
    for i,entry in ipairs({{"portraits","Portrait surrounds"},{"frames","Full unit-frame artwork"},{"casts","Cast-bar borders"},{"minimap","Minimap artwork"},{"hub","Action-bar artwork"}}) do
        local key=entry[1]
        self.toggles[key]=ui.toggle(a,entry[2],0,-100-(i-1)*40,320,function() self.draft[key]=not self.draft[key];self:Refresh() end)
    end
    ui.text(a,"Automatic artwork follows each unit's identity. You can choose a fixed design later.",376,-108,320)
    ui.text(a,"Portrait, unit-frame and cast choices apply to Player, Target and Focus. Their providers stay as you have set them.",376,-186,320)
    ui.text(a,"You can adjust every component separately in settings.",376,-282,320,"GameFontNormal")
    a=self.pages[4]
    ui.text(a,"You're ready to forge your interface",0,0,696,"GameFontNormalLarge")
    ui.text(a,"Open settings from the AddOn Compartment or the Frostforge section in ElvUI. You can always use /frostforge too.",0,-42,696)
    self.toggles.icon=ui.toggle(a,"Show minimap settings icon",0,-108,696,function() self.draft.icon=not self.draft.icon;self:Refresh() end)
    self.toggles.round=ui.toggle(a,"Use a round minimap in ElvUI",0,-152,696,function() self.draft.round=not self.draft.round;self:Refresh() end)
    ui.text(a,"Round shape applies while minimap artwork is on. Turning the artwork off restores your previous ElvUI shape.",30,-198,646)
    self.summary=ui.text(a,"",0,-266,696,"GameFontNormal")
    ui.text(a,"More from Jiberish: The Igloo tab in settings • theigloo.io",0,-310,696)
    self.message=ui.text(f,"",32,-550,696)
    self.skip=ui.button(f,"Skip setup",32,-586,170,function() self:Dismiss() end)
    self.back=ui.button(f,"Back",382,-586,150,function() self.step=math.max(1,self.step-1);self:Refresh() end)
    self.next=ui.button(f,"Next",548,-586,180,function()
        if self.step<4 then self.step=self.step+1;self:Refresh() else self:Finish() end
    end)
    f:SetScript("OnHide",function()
        -- Loading screens/UIParent hides are not a completed or skipped tour.
        -- Escape defers it until next login; only Skip/Finish save completion.
        self.pending=f:IsShown() and true or nil
        for _,item in ipairs(self.pictures) do item.texture:SetTexture(nil) end
    end)
    f:SetScript("OnShow",function() self.pending=nil;if self.draft then self:Refresh() end end)
    f:RegisterEvent("UI_SCALE_CHANGED");f:RegisterEvent("DISPLAY_SIZE_CHANGED")
    f:SetScript("OnEvent",function() if not InCombatLockdown() then self:Fit() end end)
    UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,"JiberishUISetupFrame")
end

function W:Refresh()
    for i,page in ipairs(self.pages) do page:SetShown(self.step==i) end
    self.progress:SetText("Quick setup  |  Step "..self.step.." of 4")
    for key,b in pairs(self.choices) do b.selection:SetShown(self.draft.mode==key) end
    for key,b in pairs(self.toggles) do b:SetChecked(self.draft[key]) end
    self.back:SetShown(self.step>1);self.next.caption:SetText(self.step==4 and "Finish & open settings" or "Next")
    for key,b in pairs(self.providers) do b.selection:SetShown(self.provider==key) end
    self.providerTips:SetText(tips[self.provider or "BLIZZARD"][2])
    for _,item in ipairs(self.pictures) do item.texture:SetTexture(item.page==self.pages[self.step] and item.path or nil) end
    self.summary:SetText("You can run this wizard again from Guide → Run quick setup.")
end

function W:Open()
    if not J.ProfileManager.writable then J.Core:Print(J.ProfileManager.notice);return end
    if InCombatLockdown() then self.pending=true;self.manual=true;J.Core:Print("Quick setup will open after combat.");return end
    self.pending=nil;self.manual=nil
    local p=J.ThemeManager:Resolve("playerFrame")
    local m=J.ThemeManager:Resolve("minimap")
    self.draft={mode=p.portraitMode=="FIXED" and "CLASS" or p.portraitMode,
        portraits=p.shown,frames=p.unitFrameShown,casts=p.castBarShown,minimap=m.shown,
        hub=J.ThemeManager:Resolve("actionHub").shown,round=m.minimapRound,icon=J.Access:IconEnabled()}
    self.profile=J.ProfileManager.activeID;self.step=1
    local anchor=J.Core.modules.playerFrame.snapshot
    self.provider=anchor and tips[anchor.source] and anchor.source or "BLIZZARD"
    self:Create();self.message:SetText("");self:Fit();self:Refresh();self.frame:Show()
end

function W:Finish()
    if InCombatLockdown() then self.message:SetText("Finish setup after combat ends.");return end
    if self.profile~=J.ProfileManager.activeID then self.message:SetText("Your profile changed. Close and reopen setup to continue.");return end
    local d,changes=self.draft,{}
    for _,key in ipairs(units) do
        for _,item in ipairs({{"shown",d.portraits},{"unitFrameShown",d.frames},{"castBarShown",d.casts},{"portraitMode",d.mode}}) do
            changes[#changes+1]={key,item[1],item[2]}
        end
    end
    for _,item in ipairs({{"minimap","shown",d.minimap},{"minimap","minimapMode",d.mode},{"minimap","minimapRound",d.round},
        {"actionHub","shown",d.hub},{"actionHub","hubMode",d.mode}}) do changes[#changes+1]=item end
    local ok,reason=J.ProfileManager:SetMany(changes)
    if not ok then self.message:SetText(reason);return end
    J.Access:SetIcon(d.icon);self:Dismiss();J.SettingsUI:Open()
end

function W:Tick()
    if not self.pending or InCombatLockdown() or not UIParent:IsVisible() then return end
    local ready=J.Core.worldReady or self.manual or (IsLoggedIn and IsLoggedIn())
    if not ready then return end
    if self.frame and self.frame:IsShown() and self.draft then
        self.pending=nil;self:Refresh() -- resume an inherited hide at the same step
    else self:Open() end
end
