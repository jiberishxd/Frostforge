local test,near=...
local function rgb(c,r,g,b) near(c[1],r);near(c[2],g);near(c[3],b) end
for _,interface in ipairs({120100,16001}) do
    test("fitted player power releases only its native clipping mask on "..interface,function(M)
        local J=M.load({interface=interface,stockStone=true})
        local b=J.Core.client:UnitBars("playerFrame").power
        local target=J.Core.client:UnitBars("targetFrame").power
        local mask=M.region(b,"MaskTexture",128,12);local other=M.region(b,"MaskTexture",500,500)
        b.ManaBarMask=mask;b.fill.masks={[mask]=true,[other]=true};target.ManaBarMask=mask;target.fill.masks={[mask]=true}
        local points=mask.points;local height=mask.h;local width=mask.w
        J.ProfileManager:Set("playerFrame","unitFrameShown",true)
        J.ProfileManager:Set("targetFrame","unitFrameShown",true)
        assert(not b.fill.masks[mask] and b.fill.masks[other] and target.fill.masks[mask])
        assert(mask.points==points and mask.h==height and mask.w==width)
        local writes=M.appearanceWrites;for i=1,5 do M.tick(J.Core) end;assert(M.appearanceWrites==writes)
        b.fill.masks[mask]=true;M.tick(J.Core);assert(not b.fill.masks[mask])
        M.combat=true;J.ProfileManager:Set("playerFrame","unitFrameShown",false)
        assert(not b.fill.masks[mask]);M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        assert(b.fill.masks[mask] and b.fill.masks[other] and not next(J.UnitSkins.powerMasks))
        J.ProfileManager:Set("playerFrame","unitFrameShown",true)
        b.fill.forbidden=true;J.ProfileManager:Set("playerFrame","unitFrameShown",false)
        assert(next(J.UnitSkins.powerMasks));b.fill.forbidden=false;M.tick(J.Core)
        assert(b.fill.masks[mask] and not next(J.UnitSkins.powerMasks) and not next(J.Core.notices))
    end)
end

test("stock power supports custom and class colors with independent gradients and full restoration",function(M)
    PowerBarColor={MANA={r=0,g=.35,b=1},RAGE={r=1,g=0,b=0}}
    local J=M.load({stockStone=true});local b=J.Core.client:UnitBars("playerFrame").power
    b.powerToken="MANA";b:SetStatusBarColor(1,1,1)
    J.ProfileManager:Set("playerFrame","blizzardPowerCustom","#ff8800")
    J.ProfileManager:Set("playerFrame","blizzardPowerColor","CUSTOM")
    rgb(b.barColor,1,136/255,0);assert(b.fill.path==J.Media.stone and not b.fill.gradient)
    J.ProfileManager:Set("playerFrame","blizzardPowerShading","GRADIENT")
    local g=b.fill.gradient;near(g.low.r,.72);near(g.high.g,136/255);assert(g.orientation=="VERTICAL")
    J.ProfileManager:Set("playerFrame","blizzardPowerTexture","STOCK")
    assert(b.fill.path=="Interface\\TargetingFrame\\UI-StatusBar" and b.fill.gradient)
    J.ProfileManager:Set("playerFrame","blizzardPowerColor","CLASS")
    rgb(b.barColor,245/255,140/255,186/255)
    M.combat=true;M.unitData.player.class="DEATHKNIGHT";b:SetStatusBarColor(1,1,1)
    rgb(b.barColor,196/255,31/255,59/255);assert(b.fill.gradient)
    local writes=M.colorWrites;for i=1,5 do M.tick(J.Core) end;assert(M.colorWrites==writes)
    M.combat=false;J.ProfileManager:Set("playerFrame","blizzardPowerColor","STOCK")
    rgb(b.barColor,0,.35,1);assert(b.fill.gradient)
    M.combat=true;b.powerToken="RAGE";b:SetStatusBarColor(1,1,1);rgb(b.barColor,1,0,0)
    b:SetStatusBarColor(.4,.4,.4);rgb(b.barColor,.4,.4,.4)
    b:SetStatusBarColor(1,1,1);M.combat=false
    J.ProfileManager:Set("playerFrame","blizzardPowerShading","SOLID")
    assert(not b.fill.gradient and b.fill.atlas=="Native-PlayerFrame-Mana");rgb(b.barColor,1,1,1)
    assert(not next(J.Core.notices));PowerBarColor=nil
end)

test("power modes apply without shells and do not recolor health or other unit scopes",function(M)
    local J=M.load();local p=J.Core.client:UnitBars("playerFrame");local t=J.Core.client:UnitBars("targetFrame")
    local old=p.power.barColor
    J.ProfileManager:Set("targetFrame","blizzardPowerColor","CUSTOM")
    J.ProfileManager:Set("targetFrame","blizzardPowerCustom","CC0033")
    rgb(t.power.barColor,.8,0,.2);assert(p.power.barColor==old and not t.health.barColor)
    assert(t.power.selectedTexture=="Interface\\TargetingFrame\\UI-StatusBar")
    J.ProfileManager:Set("targetFrame","unitFrameShown",true);M.tick(J.Core)
    assert(t.power.selectedTexture=="Interface\\TargetingFrame\\UI-StatusBar")
    M.unitData.target.player=false
    J.ProfileManager:Set("targetFrame","blizzardPowerColor","CLASS")
    assert(not M.unitData.target.player);rgb(t.power.barColor,0,1,0) -- fixture's native color
    assert(not next(J.Core.notices))
end)

test("party power uses its own profile controls and restores pooled bars",function(M)
    local J=M.load();PartyFrame=M.native("PartyFrame",100,100)
    local f=M.region(PartyFrame,"Frame",100,40);f.unit="party1";M.unitData.party1={player=true,class="MAGE"}
    f.ManaBar=M.region(f,"StatusBar",100,8);f.ManaBar.fill=M.region(f.ManaBar,"Texture",100,8)
    f.ManaBar.fill.fillTexture=true;f.ManaBar.fill.path="party-power";f.ManaBar.barColor={0,0,1,1};f.ManaBar.stockColor=true
    local pool={[f]=true};PartyFrame.PartyMemberFramePool={EnumerateActive=function() return next,pool end}
    J.ProfileManager:Set("playerFrame","blizzardPartyPowerColor","CUSTOM")
    J.ProfileManager:Set("playerFrame","blizzardPartyPowerCustom","33CCFF")
    J.ProfileManager:Set("playerFrame","blizzardPartyPowerShading","GRADIENT")
    rgb(f.ManaBar.barColor,.2,.8,1);assert(f.ManaBar.fill.gradient)
    pool[f]=nil;M.tick(J.Core);rgb(f.ManaBar.barColor,0,0,1)
    assert(not f.ManaBar.fill.gradient and f.ManaBar.fill.path=="party-power" and not next(J.Core.notices))
end)

test("power controls validate hex values scope edits and round-trip profiles",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:Select("targetFrame");S:SetPage("blizzard")
    S.stockStyleButton.scripts.OnClick();S.powerStyleButton.scripts.OnClick();assert(S.powerStyleDialog:IsShown())
    local edit=S.controls.blizzardPowerCustom.edit;edit:SetText("#aa00ff");edit.scripts.OnEnterPressed()
    assert(J.ThemeManager:Resolve("targetFrame").blizzardPowerCustom=="AA00FF")
    assert(J.ThemeManager:Resolve("targetFrame").blizzardPowerColor=="CUSTOM")
    S.controls.blizzardPowerShading.button.scripts.OnClick();assert(S.powerStyleDialog:IsShown())
    S.controls.blizzardPowerShading.options.GRADIENT.scripts.OnClick()
    S.powerScopeButtons.party.scripts.OnClick();assert(S.powerPanels.party:IsShown() and not S.powerPanels.unit:IsShown())
    S:ColorValue("blizzardPartyPower","112233");assert(J.ThemeManager:Resolve("playerFrame").blizzardPartyPowerCustom=="112233")
    for _,v in ipairs({"bad","1234567","FFGG00",M.secret}) do assert(not J.ProfileManager:Set("targetFrame","blizzardPowerCustom",v)) end
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset();assert(J.ProfileManager:Import(backup))
    assert(J.ThemeManager:Resolve("targetFrame").blizzardPowerShading=="GRADIENT")
    assert(not J.ProfileManager:Set("actionHub","blizzardPowerColor","CUSTOM"))
    S:Select("playerFrame");assert(not S.powerStyleDialog:IsShown() and not next(J.Core.notices))
end)

test("native color picker cancel and profile switches cannot leak power edits",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:Select("targetFrame")
    local picker=CreateFrame("Frame",nil,UIParent);ColorPickerFrame=picker
    function picker:SetupColorPickerAndShow(options) self.options=options;self:Show() end
    function picker:GetColorRGB() return .1,.4,.8 end
    S:ChoosePowerColor("blizzardPower");picker.options.swatchFunc()
    assert(J.ThemeManager:Resolve("targetFrame").blizzardPowerCustom=="1A66CC")
    picker.options.cancelFunc();assert(J.ThemeManager:Resolve("targetFrame").blizzardPowerColor=="STOCK")
    S:ChoosePowerColor("blizzardPower");picker.options.swatchFunc();S:Select("focusFrame")
    assert(not picker:IsShown() and J.ThemeManager:Resolve("targetFrame").blizzardPowerColor=="STOCK")
    S:ChoosePowerColor("blizzardPower");local callback=picker.options.swatchFunc
    J.ProfileManager:SaveAs("New power profile",false);callback()
    assert(J.ThemeManager:Resolve("focusFrame").blizzardPowerColor=="STOCK")
    ColorPickerFrame=nil;assert(not next(J.Core.notices))
end)
