local _,J=...
local U,P,R=J.Util,J.Profiles,J.Renderer
local S={scope='global'}; J.SettingsUI=S
local function label(parent,text,x,y,width)
    local f=parent:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y); f:SetText(text); f:SetJustifyH('LEFT')
    if width then f:SetWidth(width) end
    return f
end
local function button(parent,text,x,y,width,click)
    local f=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
    f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y); f:SetSize(width or 130,24); f:SetText(text)
    f:SetScript('OnClick',click); return f
end
local function cycle(parent,x,y,width,get,choices,change)
    local f
    f=button(parent,'',x,y,width,function()
        local values=type(choices)=='function' and choices() or choices
        local current=get(); local index=0
        for i,v in ipairs(values) do if v[1]==current then index=i end end
        if #values>0 then change(values[index%#values+1][1]) end
    end)
    f.Refresh=function()
        local values=type(choices)=='function' and choices() or choices; local current=get()
        for _,v in ipairs(values) do if v[1]==current then f:SetText(v[2]); return end end
        f:SetText(tostring(current))
    end
    return f
end
function S:Value() return P:Resolve(self.scope) end
function S:ExportProfile()
    self:Dialog('Copy this export before reloading',P.Export(P:Current()))
end
function S:ImportProfile()
    self:Dialog('Paste a JUI1 export. Apply replaces the active profile.','',function(text)
        local value,err=P.Import(text);if not value then J:Print(err);return false end
        return P:Commit(value)
    end)
end
function S:UsesNativeShell()
    local groups={player=true,target=true,focus=true,pet=true,boss=true,targettarget=true,focustarget=true}
    return groups[self.scope] and not (J.Integrations and J.Integrations.providers[self.scope])
end
function S:Set(key,value)
    local ok,err=P:Set(self.scope,key,value)
    if not ok then J:Print(err) end
    self:Refresh()
end
function S:Color(key,token)
    local config=self:Value(); local value=token and (config.powerColors[token] or {0.2,0.45,1}) or config[key]
    local scope=self.scope
    local profileName=P:Name()
    local source=scope=='global' and P:Current().global or P:Current().groups[scope] or {}
    local previousOverride=U.Copy(source[key])
    if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then J:Print('Color picker unavailable.'); return end
    local function apply(rgb)
        if P:Name()~=profileName then return end
        if token then
            local profile=P:Current(); local source=scope=='global' and profile.global or profile.groups[scope] or {}
            local colors=U.Copy(source.powerColors or {}); colors[token]=rgb
            P:Set(scope,'powerColors',colors)
        else P:Set(scope,key,rgb) end
        self:Refresh()
    end
    -- The native picker previews changes; cancel restores the prior appearance.
    ColorPickerFrame:SetupColorPickerAndShow({r=value[1],g=value[2],b=value[3],hasOpacity=false,
        swatchFunc=function() local r,g,b=ColorPickerFrame:GetColorRGB(); apply({r,g,b}) end,
        cancelFunc=function() if P:Name()==profileName then P:Set(scope,key,previousOverride); self:Refresh() end end})
end
function S:Slider(parent,key,text,y,low,high,step)
    local caption=label(parent,text,200,y,200)
    local slider=CreateFrame('Slider',nil,parent)
    slider:SetPoint('TOPLEFT',parent,'TOPLEFT',420,y-2); slider:SetSize(250,16)
    slider:SetOrientation('HORIZONTAL'); slider:SetMinMaxValues(low,high); slider:SetValueStep(step); slider:SetObeyStepOnDrag(true)
    local track=slider:CreateTexture(nil,'BACKGROUND'); track:SetAllPoints(); track:SetColorTexture(0.1,0.12,0.16,1)
    slider:SetThumbTexture('Interface\\Buttons\\UI-SliderBar-Button-Horizontal')
    slider:SetScript('OnValueChanged',function(_,value)
        if not self.refreshing then self:Set(key,math.floor(value/step+0.5)*step) end
    end)
    self.controls[#self.controls+1]={Refresh=function()
        local fixed=self:UsesNativeShell() and (key=='thickness' or key=='inset' or key=='ornament')
        if slider.SetEnabled then slider:SetEnabled(not fixed) end
        caption:SetAlpha(fixed and 0.5 or 1)
        local maximum=high
        if key=='thickness' and self.scope~='global' then
            maximum=({party=5,partypet=5,raid=5,pet=5,targettarget=5,focustarget=5,actionbars=10,petbar=10,stancebar=10,vehiclebar=10,extrabar=10,flyout=10,totembar=10})[self.scope] or high
            if J.Integrations and J.Integrations.providers[self.scope] then maximum=3 end
        end
        slider:SetMinMaxValues(low,maximum)
        local value=U.Clamp(self:Value()[key],low,maximum); slider:SetValue(value)
        caption:SetText(fixed and (text..': native shape') or (text..string.format(': %.2g',value)))
    end}
end
function S:Dialog(title,text,accept)
    if not self.dialog then
        local f=CreateFrame('Frame',nil,UIParent,'BackdropTemplate'); self.dialog=f
        f:SetSize(680,440); f:SetPoint('CENTER'); f:SetFrameStrata('DIALOG'); f:EnableMouse(true)
        f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
        f:SetBackdropColor(0.06,0.07,0.09,1)
        f.title=label(f,'',20,-20,630)
        local scroll=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate'); scroll:SetPoint('TOPLEFT',20,-55); scroll:SetSize(615,310)
        local edit=CreateFrame('EditBox',nil,scroll); edit:SetMultiLine(true); edit:SetFontObject(ChatFontNormal); edit:SetWidth(610); edit:SetAutoFocus(false); edit:SetMaxLetters(262144)
        edit:SetScript('OnEscapePressed',function() f:Hide() end); scroll:SetScrollChild(edit); f.edit=edit
        f.accept=button(f,'Apply',20,-395,130,function() if f.action and f.action(edit:GetText()) then f:Hide(); self:Refresh() end end)
        button(f,'Close',520,-395,130,function() f:Hide() end)
    end
    local f=self.dialog; f.title:SetText(title); f.edit:SetText(text or ''); f.action=accept; f.accept:SetShown(accept~=nil)
    f:Show(); f.edit:SetFocus(); f.edit:HighlightText()
end
function S:BrowseSkins()
    if not self.browser then
        local f=CreateFrame('Frame',nil,UIParent,'BackdropTemplate'); self.browser=f
        f:SetSize(720,510); f:SetPoint('CENTER'); f:SetFrameStrata('DIALOG'); f:EnableMouse(true)
        f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
        f:SetBackdropColor(0.055,0.065,0.085,1)
        f.heading=label(f,'Choose a border style',20,-18,610)
        f.category='all'; f.page=1; f.cards={}
        for i,entry in ipairs(J.SkinCategories) do
            local category=entry[1]
            button(f,entry[2],20+(i-1)*137,-45,130,function() f.category=category; f.page=1; self:RefreshBrowser() end)
        end
        label(f,'Search',20,-91,70)
        f.search=CreateFrame('EditBox',nil,f,'InputBoxTemplate'); f.search:SetSize(400,24); f.search:SetPoint('TOPLEFT',90,-82)
        f.search:SetAutoFocus(false); f.search:SetMaxLetters(80)
        f.search:SetScript('OnTextChanged',function() f.page=1; self:RefreshBrowser() end)
        f.search:SetScript('OnEscapePressed',function() f:Hide() end)
        f.position=label(f,'',515,-88,185)
        for i=1,6 do
            local col=(i-1)%2; local row=math.floor((i-1)/2)
            local card=CreateFrame('Button',nil,f); card:SetSize(325,98); card:SetPoint('TOPLEFT',24+col*351,-122-row*105)
            card.background=card:CreateTexture(nil,'BACKGROUND'); card.background:SetAllPoints(); card.background:SetColorTexture(0.08,0.1,0.13,1)
            card.title=label(card,'',10,-9,300); card.detail=label(card,'',10,-30,300)
            local sample=CreateFrame('Frame',nil,card); sample:SetPoint('TOPLEFT',17,-65); sample:SetSize(230,18)
            local fill=sample:CreateTexture(nil,'BACKGROUND'); fill:SetAllPoints(); fill:SetColorTexture(0.06,0.09,0.12,1)
            card.border=R.Create(sample,sample,'compact')
            card:SetScript('OnClick',function()
                if card.skin then self.scope=f.scope; self:Set('skin',card.skin); f:Hide() end
            end)
            f.cards[i]=card
        end
        button(f,'Previous',20,-450,110,function() f.page=math.max(1,f.page-1); self:RefreshBrowser() end)
        button(f,'Next',140,-450,110,function() f.page=f.page+1; self:RefreshBrowser() end)
        button(f,'Close',580,-450,110,function() f:Hide() end)
        f.note=label(f,'Skin defaults shown. Your saved overrides still apply. Related styles share material artwork.',20,-484,670)
    end
    local f=self.browser; f.scope=self.scope
    f.heading:SetText('Choose a border style — '..(self.scope=='global' and 'Global' or J.GroupLabels[self.scope]))
    f:Show(); self:RefreshBrowser()
end
function S:RefreshBrowser()
    local f=self.browser; if not f then return end
    local ids=J:FindSkins(f.category,f.search:GetText())
    local pages=math.max(1,math.ceil(#ids/6)); f.page=U.Clamp(f.page,1,pages)
    f.position:SetText(string.format('%d styles • %d / %d',#ids,f.page,pages))
    local active=P:Resolve(f.scope or self.scope).skin
    for i,card in ipairs(f.cards) do
        local id=ids[(f.page-1)*6+i]; card.skin=id; card:SetShown(id~=nil)
        if id then
            local skin=J.Skins[id]; card.title:SetText((id==active and '|cff86bfff' or '')..skin.label..(id==active and '  • Selected|r' or ''))
            card.detail:SetText(skin.description)
            local config=U.Copy(skin.defaults); config.skin=id; config.thickness=3; config.ornament=0
            R.Apply(card.border,config)
        end
    end
end
function S:Refresh()
    if not self.panel or not J.ready then return end
    self.refreshing=true
    for _,control in ipairs(self.controls) do control:Refresh() end
    local config=self:Value()
    self.scopeLabel:SetText(self.scope=='global' and 'Global appearance' or J.GroupLabels[self.scope]..' overrides')
    self.status:SetText(U.Combat() and 'Preview shows saved choices. Live changes wait until combat ends.' or (next(J.reloadGroups) and 'Module disabling is saved. Reload UI to restore Blizzard appearance.' or J:LiveStatus(self.scope)))
    self.enabled:SetChecked(config.enabled)
    self.inherit:SetShown(self.scope~='global')
    R.Apply(self.previewBorder,config)
    local hc=config.healthMode=='native' and {0.1,0.8,0.2} or config.healthMode=='class' and {0.96,0.55,0.73} or config.healthColor
    local pc=config.powerMode=='custom' and config.powerColor or config.powerColors.MANA or {0.2,0.45,1}
    self.previewHealth:SetStatusBarColor(unpack(hc)); self.previewPower:SetStatusBarColor(unpack(pc))
    self.profileLabel:SetText('Active profile: '..P:Name())
    self.refreshing=false
end
function S:Create()
    if self.panel then return end
    local panel=CreateFrame('Frame'); self.panel=panel; panel.name='JiberishUI'; self.controls={}
    label(panel,'JiberishUI — Border library',16,-16,650)
    label(panel,'Alpha: live validation pending. Settings are stored separately in each game client.',16,-38,700)
    local appearance=CreateFrame('Frame',nil,panel); appearance:SetAllPoints(); self.appearance=appearance
    local profiles=CreateFrame('Frame',nil,panel); profiles:SetAllPoints(); profiles:Hide(); self.profiles=profiles
    button(panel,'Appearance',16,-65,130,function() appearance:Show(); profiles:Hide(); self:Refresh() end)
    button(panel,'Profiles',152,-65,130,function() appearance:Hide(); profiles:Show(); self:Refresh() end)
    button(panel,'Diagnostics',288,-65,130,function() self:Dialog('Diagnostics — no unit data',J:Diagnostics()) end)
    button(panel,'Reload UI',564,-65,120,function() if U.Combat() then J:Print('Reload after combat.'); else ReloadUI() end end)
    local groups={'global'}; for _,group in ipairs(J.Groups) do groups[#groups+1]=group end
    for i,group in ipairs(groups) do
        local scope=group
        button(appearance,group=='global' and 'Global' or J.GroupLabels[group],16,-104-(i-1)*23,170,function() self.scope=scope; self:Refresh() end)
    end
    self.scopeLabel=label(appearance,'',200,-106,450)
    local theme=button(appearance,'Browse styles',200,-130,440,function() self:BrowseSkins() end)
    self.controls[#self.controls+1]={Refresh=function() theme:SetText(J.Skins[self:Value().skin].label..' — Browse styles') end}
    self.enabled=CreateFrame('CheckButton',nil,appearance,'UICheckButtonTemplate'); self.enabled:SetPoint('TOPLEFT',196,-160)
    self.enabled:SetScript('OnClick',function(box) self:Set('enabled',box:GetChecked() and true or false) end)
    label(appearance,'Enable this group (disabling requires reload)',232,-170,430)
    self:Slider(appearance,'thickness','Border thickness',-204,2,12,0.5)
    self:Slider(appearance,'inset','Border inset',-237,-8,12,0.5)
    self:Slider(appearance,'opacity','Border opacity',-270,0,1,0.05)
    self:Slider(appearance,'ornament','Ornament scale',-303,0,1,0.05)
    button(appearance,'Border tint',200,-332,130,function() self:Color('tint') end)
    self.inherit=button(appearance,'Use global settings',420,-332,200,function() P:ClearGroup(self.scope); self:Refresh() end)
    label(appearance,'Health',200,-373,80)
    self.controls[#self.controls+1]=cycle(appearance,285,-365,180,function() return self:Value().healthMode end,{{'native','Blizzard colors'},{'custom','Fixed color'},{'class','Class / reaction'}},function(value) self:Set('healthMode',value) end)
    button(appearance,'Health color',480,-365,160,function() self:Color('healthColor') end)
    label(appearance,'Power',200,-405,80)
    self.controls[#self.controls+1]=cycle(appearance,285,-397,180,function() return self:Value().powerMode end,{{'native','Blizzard colors'},{'custom','Fixed color'},{'type','Power type'}},function(value) self:Set('powerMode',value) end)
    button(appearance,'Power color',480,-397,160,function() self:Color('powerColor') end)
    self.powerToken='MANA'
    self.controls[#self.controls+1]=cycle(appearance,200,-431,265,function() return self.powerToken end,{{'MANA','Mana'},{'RAGE','Rage'},{'FOCUS','Focus'},{'ENERGY','Energy'},{'RUNIC_POWER','Runic power'},{'LUNAR_POWER','Astral power'},{'MAELSTROM','Maelstrom'},{'INSANITY','Insanity'},{'FURY','Fury'},{'PAIN','Pain'}},function(value) self.powerToken=value; self:Refresh() end)
    button(appearance,'Type color',480,-431,160,function() self:Color('powerColors',self.powerToken) end)
    local preview=CreateFrame('Frame',nil,appearance); preview:SetPoint('TOPLEFT',appearance,'TOPLEFT',220,-485); preview:SetSize(220,42)
    local health=CreateFrame('StatusBar',nil,preview); health:SetPoint('TOPLEFT'); health:SetSize(220,28); health:SetStatusBarTexture(J.Neutral); health:SetMinMaxValues(0,100); health:SetValue(75)
    local power=CreateFrame('StatusBar',nil,preview); power:SetPoint('TOPLEFT',0,-30); power:SetSize(220,10); power:SetStatusBarTexture(J.Neutral); power:SetMinMaxValues(0,100); power:SetValue(40)
    self.previewHealth,self.previewPower=health,power; self.previewBorder=R.Create(preview,preview,'compact')
    label(appearance,'Material preview\nLive shape follows your UI.\nBlizzard portrait borders use native width.',475,-485,210)
    self.status=label(panel,'',16,-555,680)
    self.profileLabel=label(profiles,'',24,-115,630)
    self.controls[#self.controls+1]=cycle(profiles,24,-148,285,function() return P:Name() end,function()
        local choices={}; for name,value in pairs(P.db.profiles) do if P.Validate(value) then choices[#choices+1]={name,name} end end
        table.sort(choices,function(a,b) return a[1]<b[1] end); return choices
    end,function(value) P:Select(value); self:Refresh() end)
    label(profiles,'Click to select the next named profile.',326,-155,340)
    button(profiles,'Copy to new profile',24,-188,220,function() self:Dialog('Name the new profile','',function(name)
        local ok,err=P:Copy(name); if not ok then J:Print(err) end; return ok
    end) end)
    button(profiles,'Export profile',24,-228,220,function() self:ExportProfile() end)
    button(profiles,'Import into active profile',24,-268,220,function() self:ImportProfile() end)
    button(profiles,'Reset active profile',24,-308,220,function() self:Dialog('Reset active profile? Apply restores Human defaults.','',function() return P:Reset() end) end)
    label(profiles,'Profile selection is saved per character. Export/import transfers appearance choices between clients.\n\nForever build 69913: settings loss is reported after /reload, logout, or restart. Use /jui export before reloading and /jui import to restore. Keep an export until client persistence is verified.',24,-370,620)
    panel:SetScript('OnShow',function() self:Refresh() end)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        self.category=Settings.RegisterCanvasLayoutCategory(panel,'JiberishUI'); Settings.RegisterAddOnCategory(self.category)
    end
end
function S:Open()
    if self.category and Settings.OpenToCategory then Settings.OpenToCategory(self.category:GetID())
    else J:Print('Native Settings integration is unavailable on this client.'); end
end
