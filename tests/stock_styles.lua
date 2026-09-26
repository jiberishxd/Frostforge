local test,near=...
local function equal(color,r,g,b) near(color[1],r);near(color[2],g);near(color[3],b) end
for _,interface in ipairs({120100,16001}) do
    test("stock class names health and dark mode are independent on "..interface,function(M)
        local J=M.load({interface=interface,stockStone=true})
        for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
            local token=key:gsub("Frame","");M.unitData[token].player=true
            local _,_,name=J.BlizzardUnits:Regions(key);local bars=J.Core.client:UnitBars(key)
            local class=RAID_CLASS_COLORS[M.unitData[token].class]
            J.ProfileManager:Set(key,"blizzardNameColor","CLASS")
            J.ProfileManager:Set(key,"blizzardHealthColor","CLASS")
            equal(name.color,class.r,class.g,class.b);equal(bars.health.barColor,class.r,class.g,class.b)
            assert(not bars.power.barColor and not J.ThemeManager:Resolve(key).blizzardNameEnabled)
            M.combat=true
            name:SetTextColor(1,1,0,1);bars.health:SetStatusBarColor(0,1,0,1)
            equal(name.color,class.r,class.g,class.b);equal(bars.health.barColor,class.r,class.g,class.b)
            M.unitData[token].class="MAGE";M.tick(J.Core)
            equal(name.color,.25,.78,.92);equal(bars.health.barColor,.25,.78,.92)
            J.ProfileManager:Set(key,"blizzardHealthColor","DARK")
            equal(bars.health.barColor,.25,.78,.92)
            M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
            equal(bars.health.barColor,.12,.12,.13);assert(bars.health.selectedTexture==J.Media.stone)
            assert(bars.power.fill.path==J.Media.stone and not bars.power.barColor)
            J.ProfileManager:Set(key,"blizzardNameColor","STOCK");J.ProfileManager:Set(key,"blizzardHealthColor","STOCK")
            equal(name.color,1,1,0);equal(bars.health.barColor,0,1,0)
        end
        assert(not next(J.Core.notices),next(J.Core.notices))
    end)
end

test("stock class colors guard NPCs forbidden frames and restricted class or color data",function(M)
    local J=M.load();local _,_,name=J.BlizzardUnits:Regions("targetFrame")
    local h=J.Core.client:UnitBars("targetFrame").health
    M.unitData.target.player=false
    J.ProfileManager:Set("targetFrame","blizzardNameColor","CLASS");J.ProfileManager:Set("targetFrame","blizzardHealthColor","CLASS")
    assert(not name.color and not h.barColor)
    M.unitData.target.player=true;M.tick(J.Core);equal(h.barColor,1,.96,.41)
    M.unitData.target.class=M.secret;h.barColor={M.secret,1,0,1};local writes=M.colorWrites;M.tick(J.Core)
    assert(M.colorWrites==writes+1,"Only safe name fallback should restore")
    h.forbidden=true;name.forbidden=true;M.tick(J.Core)
    h.forbidden=false;name.forbidden=false;h.barColor={0,1,0,1};M.unitData.target.class="MAGE";M.tick(J.Core)
    equal(h.barColor,.25,.78,.92)
    M.unitData.target.player=false;h:SetStatusBarColor(.7,.2,0,1);name:SetTextColor(1,.82,0,1)
    equal(h.barColor,.7,.2,0);equal(name.color,1,.82,0)
    assert(not next(J.Core.notices),next(J.Core.notices))
end)

test("pooled party and raid names follow their public unit and restore on release",function(M)
    local J=M.load();PartyFrame=M.native("PartyFrame",100,100)
    local function member(parent,token)
        local f=M.region(parent,"Frame",100,40);f.unit=token
        f.Name=M.region(f,"FontString",100,12);f.Name.stockPresentation=true
        f.HealthBar=M.region(f,"StatusBar",100,20);f.HealthBar.stockColor=true
        return f
    end
    M.unitData.party1={player=true,class="HUNTER"};M.unitData.raid1={player=true,class="MAGE"}
    local party=member(PartyFrame,"party1")
    local pool={[party]=true};PartyFrame.PartyMemberFramePool={EnumerateActive=function() return next,pool end}
    CompactRaidFrameContainer=M.native("CompactRaidFrameContainer",100,100)
    local raid=member(CompactRaidFrameContainer,"raid1");raid.name=raid.Name;raid.healthBar=raid.HealthBar
    CompactRaidFrameContainer.ApplyToFrames=function(_,_,callback) callback(raid) end
    J.ProfileManager:Set("playerFrame","blizzardPartyNameColor","CLASS")
    J.ProfileManager:Set("playerFrame","blizzardPartyHealthColor","CLASS")
    equal(party.Name.color,.67,.83,.45);equal(raid.name.color,.25,.78,.92)
    local hooks=M.hooks;party.unit="raid1";M.tick(J.Core);equal(party.HealthBar.barColor,.25,.78,.92)
    for i=1,5 do M.tick(J.Core) end;assert(M.hooks==hooks)
    pool[party]=nil;M.tick(J.Core);equal(party.Name.color,1,.82,0);equal(party.HealthBar.barColor,0,1,0)
    assert(not next(J.Core.notices),next(J.Core.notices))
end)

test("stock health and power texture selections update the actual StatusBar and restore",function(M)
    local J=M.load({stockStone=true});local b=J.Core.client:UnitBars("playerFrame")
    assert(b.health.selectedTexture==J.Media.stone and b.power.selectedTexture==J.Media.stone)
    J.ProfileManager:Set("playerFrame","blizzardHealthTexture","SMOOTH")
    J.ProfileManager:Set("playerFrame","blizzardPowerTexture","STOCK")
    assert(b.health.selectedTexture=="Interface\\Buttons\\WHITE8X8" and b.power.fill.atlas=="Native-PlayerFrame-Mana")
    b.health.fill:SetTexCoord(.1,.9,.1,.9);M.tick(J.Core)
    J.ProfileManager:Set("playerFrame","blizzardHealthTexture","STOCK")
    assert(b.health.fill.atlas=="Native-PlayerFrame-Health","Smooth UV redraw captured custom fill as original")
    J.ProfileManager:Set("playerFrame","unitFrameShown",true)
    assert(b.health.fill.atlas=="Native-PlayerFrame-Health" and b.power.fill.atlas=="Native-PlayerFrame-Mana")
    J.ProfileManager:Set("playerFrame","blizzardHealthColor","DARK");assert(b.health.selectedTexture==J.Media.stone)
    J.ProfileManager:Set("playerFrame","blizzardHealthColor","STOCK");assert(b.health.fill.atlas=="Native-PlayerFrame-Health")
    M.combat=true;local writes=M.appearanceWrites
    J.ProfileManager:Set("playerFrame","blizzardPowerTexture","STONE");assert(M.appearanceWrites==writes)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(b.power.selectedTexture==J.Media.stone)
    assert(not next(J.Core.notices),next(J.Core.notices))
end)

test("stock color and texture dialog selects scopes and survives profile backup",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:Select("targetFrame");S:SetPage("blizzard")
    S.stockStyleButton.scripts.OnClick();assert(S.stockStyleDialog:IsShown())
    for property,value in pairs({blizzardNameColor="CLASS",blizzardHealthColor="DARK",blizzardPartyNameColor="CLASS",blizzardPartyHealthColor="CLASS",blizzardHealthTexture="STONE",blizzardPowerTexture="SMOOTH"}) do
        S.controls[property].button.scripts.OnClick();assert(S.stockStyleDialog:IsShown())
        S.controls[property].options[value].scripts.OnClick()
        local key=J.BlizzardUnits.sharedStyleProperties[property] and "playerFrame" or "targetFrame"
        assert(J.ThemeManager:Resolve(key)[property]==value)
    end
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset();assert(J.ProfileManager:Import(backup))
    assert(J.ThemeManager:Resolve("targetFrame").blizzardHealthColor=="DARK")
    assert(J.ThemeManager:Resolve("playerFrame").blizzardPowerTexture=="SMOOTH")
    assert(not J.ProfileManager:Set("targetFrame","blizzardHealthTexture","STONE"))
    assert(not J.ProfileManager:Set("actionHub","blizzardHealthColor","DARK"))
    S:Select("actionHub");assert(not S.stockStyleDialog:IsShown())
    assert(not next(J.Core.notices),next(J.Core.notices))
end)

test("both stock adapters prefer initialized live bars over outdated XML paths",function(M)
    local J=M.load()
    local old=J.Core.clients.retail:UnitBars("playerFrame")
    local h=M.region(PlayerFrame,"StatusBar",124,20);h.fill=M.region(h,"Texture",124,20);h.fill.fillTexture=true
    h.fill.path="Live-Health";h.fill.texCoord={0,1,0,1}
    local p=M.region(PlayerFrame,"StatusBar",124,10);p.fill=M.region(p,"Texture",124,10);p.fill.fillTexture=true
    p.fill.path="Live-Power";p.fill.texCoord={0,1,0,1}
    PlayerFrame.healthbar=h;PlayerFrame.manabar=p
    for _,client in pairs(J.Core.clients) do
        local bars=client:UnitBars("playerFrame");assert(bars.health==h and bars.power==p)
    end
    J.ProfileManager:Set("playerFrame","blizzardHealthTexture","STONE")
    assert(h.selectedTexture==J.Media.stone and old.health.fill.path~="Interface\\AddOns\\JiberishUI\\Media\\UnitFrames\\class_paladin-health.tga")
    assert(not next(J.Core.notices),next(J.Core.notices))
end)
