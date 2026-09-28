local _,J=...
local W={step=1}
J.Setup=W
local units={"playerFrame","targetFrame","focusFrame"}

function W:Dismiss()
    self.pending=nil
    if J.ProfileManager.writable then JiberishUIDB.setupVersion=1 end
    if self.frame then self.frame:Hide() end
end

function W:Fit()
    if not self.frame then return end
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    if J.Core:IsNumber(w) and J.Core:IsNumber(h) and w>32 and h>32 then
        self.frame:SetScale(math.min(1,(w-32)/680,(h-32)/480))
    end
end

function W:Create()
    if self.frame then return end
    local ui=J.SettingsUI.widgets
    local f=CreateFrame("Frame","JiberishUISetupFrame",UIParent,"BackdropTemplate")
    self.frame=f;f:Hide();f:SetSize(680,480);f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    f:SetFrameStrata("DIALOG");f:SetFrameLevel(240);f:EnableMouse(true);f:SetClampedToScreen(true);ui.backdrop(f,"outer")
    local logo=f:CreateTexture(nil,"ARTWORK");logo:SetPoint("TOPLEFT",f,"TOPLEFT",26,-20);logo:SetSize(64,64);logo:SetTexture(J.Media.logo)
    ui.text(f,"Welcome to Frostforge",108,-26,520,"GameFontNormalLarge")
    self.progress=ui.text(f,"",108,-56,520)
    self.pages={};self.choices={};self.toggles={}
    for i=1,3 do
        local body=CreateFrame("Frame",nil,f);body:SetPoint("TOPLEFT",f,"TOPLEFT",32,-106);body:SetSize(616,280)
        body:SetFrameLevel(241);self.pages[i]=body
    end
    local a=self.pages[1]
    ui.text(a,"Choose your artwork theme",0,0,616,"GameFontNormalLarge")
    ui.text(a,"Automatic themes follow your character and each unit. You can browse individual designs later.",0,-36,616)
    for i,entry in ipairs({{"CLASS","Class","Materials and symbols for each class."},{"RACE","Race","Artwork inspired by each race."},{"FACTION","Faction","Alliance, Horde or Neutral."}}) do
        local mode=entry[1]
        self.choices[mode]=ui.button(a,entry[2],0,-88-(i-1)*56,170,function() self.draft.mode=mode;self:Refresh() end,true)
        ui.text(a,entry[3],192,-96-(i-1)*56,410)
    end
    a=self.pages[2]
    ui.text(a,"Choose your decorations",0,0,616,"GameFontNormalLarge")
    ui.text(a,"These choices apply to Player, Target and Focus together. Fine-tune each one later in settings.",0,-36,616)
    for i,entry in ipairs({{"portraits","Portrait surrounds"},{"frames","Full unit-frame artwork"},{"casts","Cast-bar borders"},{"minimap","Minimap artwork"},{"hub","Action-bar artwork"}}) do
        local key=entry[1]
        self.toggles[key]=ui.toggle(a,entry[2],0,-80-(i-1)*34,300,function() self.draft[key]=not self.draft[key];self:Refresh() end)
    end
    ui.text(a,"Uses your current frame providers. Your bars, buttons and game controls keep working as usual.",326,-86,280)
    ui.text(a,"Nothing is applied until you finish.",326,-168,280,"GameFontNormal")
    a=self.pages[3]
    ui.text(a,"Make it easy to find",0,0,616,"GameFontNormalLarge")
    ui.text(a,"Open settings from the AddOn Compartment or the Frostforge section in ElvUI. You can always use /frostforge too.",0,-36,616)
    self.toggles.icon=ui.toggle(a,"Show minimap settings icon",0,-92,616,function() self.draft.icon=not self.draft.icon;self:Refresh() end)
    self.toggles.round=ui.toggle(a,"Use a round minimap in ElvUI",0,-132,616,function() self.draft.round=not self.draft.round;self:Refresh() end)
    ui.text(a,"Round shape applies while minimap artwork is on. Turning the artwork off restores your previous ElvUI shape.",30,-174,580)
    self.summary=ui.text(a,"",0,-226,616,"GameFontNormal")
    self.message=ui.text(f,"",32,-386,616)
    self.skip=ui.button(f,"Skip setup",32,-426,170,function() self:Dismiss() end)
    self.back=ui.button(f,"Back",302,-426,150,function() self.step=math.max(1,self.step-1);self:Refresh() end)
    self.next=ui.button(f,"Next",468,-426,180,function()
        if self.step<3 then self.step=self.step+1;self:Refresh() else self:Finish() end
    end)
    f:SetScript("OnHide",function()
        self.pending=nil
        if J.ProfileManager.writable then JiberishUIDB.setupVersion=1 end
    end)
    f:RegisterEvent("UI_SCALE_CHANGED");f:RegisterEvent("DISPLAY_SIZE_CHANGED")
    f:SetScript("OnEvent",function() if not InCombatLockdown() then self:Fit() end end)
    UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,"JiberishUISetupFrame")
end

function W:Refresh()
    for i,page in ipairs(self.pages) do page:SetShown(self.step==i) end
    self.progress:SetText("Quick setup  |  Step "..self.step.." of 3")
    for key,b in pairs(self.choices) do b.selection:SetShown(self.draft.mode==key) end
    for key,b in pairs(self.toggles) do b:SetChecked(self.draft[key]) end
    self.back:SetShown(self.step>1);self.next.caption:SetText(self.step==3 and "Finish & open settings" or "Next")
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
    if self.pending and (J.Core.worldReady or self.manual) and not InCombatLockdown() then self:Open() end
end
