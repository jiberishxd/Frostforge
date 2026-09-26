local test,near,count=...
local keys={"playerFrame","targetFrame","focusFrame"}
local titles={playerFrame="Player",targetFrame="Target",focusFrame="Focus"}
local function fixture(M,source,key)
    local title=titles[key]
    local root
    if source=="BLIZZARD" then root=_G[title.."Frame"]
    else
        local name=(source=="ELLESMERE" and "EllesmereUIUnitFrames_" or "ElvUF_")..title
        root=M.native(name,200,60,.9)
    end
    local bar=M.region(root,"Frame",180,16);bar.level=30;bar.strata="MEDIUM";bar.scale=.85
    bar.fill=M.region(bar,"Texture",180,16);bar.shown=false
    if source=="BLIZZARD" then
        if key=="playerFrame" then PlayerCastingBarFrame=bar else root.spellbar=bar end
    else root.Castbar=bar end
    return bar,root
end
local function enable(J,key,source)
    J.ProfileManager:Set(key,"castBarSource",source or "AUTO")
    J.ProfileManager:Set(key,"castBarShown",true)
end

for _,interface in ipairs({120100,16001}) do
    for _,source in ipairs({"BLIZZARD","ELLESMERE","ELVUI"}) do
        test("cast borders attach before the first cast on "..source.." client "..interface,function(M)
            local J=M.load({interface=interface})
            local bars={}
            for _,key in ipairs(keys) do bars[key]=fixture(M,source,key) end
            assert(not next(J.CastBars.units))
            for _,key in ipairs(keys) do
                enable(J,key,source)
                local c=J.CastBars.units[key];local bar=bars[key]
                assert(c.bar==bar and c.frame.parent==UIParent and not c.frame.mouse and not c.frame.keyboard)
                assert(not c.frame.shown and count(c.textures)==8)
                near(c.frame:GetEffectiveScale(),bar:GetEffectiveScale());near(c.frame.w,180);near(c.frame.h,16)
                assert(c.frame.level==31 and c.frame.strata=="MEDIUM")
                M.combat=true;bar.shown=true
                local writes=M.geometryWrites
                J.Core.driver.scripts.OnUpdate(J.Core.driver,.06)
                assert(c.frame.shown and M.geometryWrites==writes)
                bar.shown=false;J.Core.driver.scripts.OnUpdate(J.Core.driver,.06);assert(not c.frame.shown)
                M.combat=false
            end
            assert((M.appearanceWrites or 0)==0 and (M.nativeLayoutWrites or 0)==0 and not next(J.Core.notices))
        end)
    end
end

test("all 42 Bold cast identities have empty centers and fixed fitting",function(M)
    local J=M.load();local bar=fixture(M,"BLIZZARD","targetFrame");bar.shown=true
    enable(J,"targetFrame","BLIZZARD")
    local c=J.CastBars.units.targetFrame
    for id,entry in pairs(J.UnitSkinCatalog.entries) do
        for _,style in ipairs({"CAPPED"}) do
            J.ProfileManager:Set("targetFrame","castBarStyle",style)
            J.ProfileManager:Set("targetFrame","castBarArt",id)
            assert(c.id==id and c.frame.w==180 and c.frame.h==16)
            for _,texture in pairs(c.textures) do
                assert(texture.path==entry.cast and texture.w>0 and texture.h>0)
                local _,_,_,x,ny=texture:GetPoint();local y=-ny
                assert(x+texture.w<=0 or x>=180 or y+texture.h<=0 or y>=16,"Border overlaps native fill")
                local uv=texture.texCoord
                assert(uv[1]>uv[2],"Target crop not mirrored")
                for _,value in ipairs(uv) do assert(value>=0 and value<=1) end
            end
            for _,weight in ipairs({.5,2}) do
                for _,padding in ipairs({0,8}) do
                    local pieces=J.CastBars:Pieces(entry,8,4,weight,padding,false)
                    for _,p in pairs(pieces) do assert(p.w>0 and p.h>0 and (p.x+p.w<=0 or p.x>=8 or p.y+p.h<=0 or p.y>=4)) end
                end
            end
        end
    end
    assert((M.appearanceWrites or 0)==0 and (M.nativeLayoutWrites or 0)==0)
end)

test("cast theme matching follows identity and selections independently of other toggles",function(M)
    local J=M.load();local bar=fixture(M,"BLIZZARD","targetFrame");bar.shown=true
    J.ProfileManager:Set("targetFrame","shown",false);enable(J,"targetFrame")
    local c=J.CastBars.units.targetFrame
    assert(c.id=="CLASS_ROGUE" and c.frame.shown and not J.UnitSkins.units.targetFrame)
    J.ProfileManager:Set("targetFrame","portraitMode","FIXED");J.ProfileManager:Set("targetFrame","portrait","RACE_DWARF")
    assert(c.id=="RACE_DWARF")
    M.combat=true;M.tick(J.Core);assert(c.id=="RACE_DWARF","Matching selection reverted in combat")
    M.combat=false;J.ProfileManager:Set("targetFrame","portraitMode","CLASS")
    M.combat=true;M.unitData.target.class="SHAMAN";local writes=M.geometryWrites;M.tick(J.Core)
    assert(c.id=="CLASS_SHAMAN" and M.geometryWrites==writes)
    c.frame.protected=true;M.unitData.target.class="MAGE";M.tick(J.Core);assert(c.id=="CLASS_SHAMAN")
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(c.id=="CLASS_MAGE")
    J.ProfileManager:Set("targetFrame","castBarArt","RACE_SCOURGE")
    M.unitData.target.class="PALADIN";M.tick(J.Core);assert(c.id=="RACE_SCOURGE")
    J.ProfileManager:Set("targetFrame","castBarShown",false);assert(not c.frame.shown)
    J.ProfileManager:Set("targetFrame","shown",true);assert(not c.frame.shown and J.Core.modules.targetFrame.frame.shown)
end)

test("cast border appearance restores without touching providers and reuses owned frames",function(M)
    local J=M.load();local bar=fixture(M,"ELVUI","playerFrame");bar.shown=true
    enable(J,"playerFrame","ELVUI");local c=J.CastBars.units.playerFrame
    local frames,textures=#M.frames,M.textures;local writes=M.geometryWrites
    for i=1,5 do M.tick(J.Core) end
    assert(M.geometryWrites==writes)
    J.ProfileManager:Set("playerFrame","castBarShown",false);assert(not c.frame.shown)
    enable(J,"playerFrame","ELVUI");assert(J.CastBars.units.playerFrame==c and c.frame.shown)
    assert(#M.frames==frames and M.textures==textures and (M.appearanceWrites or 0)==0)
    bar.alpha=.4;J.CastBars:Sync();near(c.frame.alpha,bar:GetEffectiveAlpha())
    bar:GetParent().shown=false;J.CastBars:Sync();assert(not c.frame.shown)
end)

test("cast configuration and attachment defer in combat and recover after native replacement",function(M)
    local J=M.load();local bar=fixture(M,"ELLESMERE","playerFrame");bar.shown=true
    M.combat=true;enable(J,"playerFrame","ELLESMERE");assert(not J.CastBars.units.playerFrame)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");local c=J.CastBars.units.playerFrame
    M.combat=true;local writes=M.geometryWrites
    J.ProfileManager:Set("playerFrame","castBarWeight",2);J.ProfileManager:Set("playerFrame","castBarStyle","SLIM")
    assert(c.config.castBarWeight==1 and c.config.castBarStyle=="CAPPED" and M.geometryWrites==writes)
    bar.w=210;M.tick(J.Core);assert(not c.frame.shown and c.frame.w==180 and M.geometryWrites==writes)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(c.frame.shown and c.frame.w==210 and c.config.castBarStyle=="CAPPED" and c.config.castBarWeight==2)
    local replacement=fixture(M,"ELLESMERE","playerFrame");replacement.shown=true
    M.tick(J.Core);assert(c.bar==replacement and c.frame.shown)
    M.combat=true;c.frame.protected=true;J.ProfileManager:Set("playerFrame","castBarShown",false)
    assert(c.frame.shown)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(not c.frame.shown)
end)

test("cast providers handle missing hidden forbidden and secret metadata without native writes",function(M)
    local J=M.load();enable(J,"focusFrame","ELVUI");assert(not J.CastBars.units.focusFrame)
    local bar,root=fixture(M,"ELVUI","focusFrame");bar.shown=true;M.tick(J.Core)
    local c=J.CastBars.units.focusFrame;assert(c.frame.shown)
    bar.orientation="VERTICAL";M.tick(J.Core);assert(not c.frame.shown)
    bar.orientation="HORIZONTAL";bar.secretScale=true;M.tick(J.Core);assert(not c.frame.shown)
    bar.secretScale=false;bar.forbidden=true;M.tick(J.Core);assert(not c.frame.shown)
    bar.forbidden=false;root.forbidden=true;M.tick(J.Core);assert(not c.frame.shown)
    root.forbidden=false;bar.secretAlpha=true;M.tick(J.Core);assert(not c.frame.shown)
    bar.secretAlpha=false;M.tick(J.Core);assert(c.frame.shown and not next(J.Core.notices))
    J.ProfileManager:Set("focusFrame","castBarSource","BLIZZARD");assert(not c.frame.shown)
end)

test("automatic cast discovery chooses visible casts and respects explicit providers",function(M)
    local J=M.load();local eui=fixture(M,"ELLESMERE","targetFrame");local elv=fixture(M,"ELVUI","targetFrame")
    local blizz=fixture(M,"BLIZZARD","targetFrame");elv.shown=true
    enable(J,"targetFrame");assert(J.CastBars.units.targetFrame.bar==elv)
    elv.shown=false;eui.shown=true;M.tick(J.Core);assert(J.CastBars.units.targetFrame.bar==eui)
    J.ProfileManager:Set("targetFrame","castBarSource","ELVUI");assert(J.CastBars.units.targetFrame.bar==elv and not J.CastBars.units.targetFrame.frame.shown)
    blizz.shown=true;M.tick(J.Core);assert(J.CastBars.units.targetFrame.bar==elv)
end)

test("Forever resolves active gamepad cast bar and Retail keeps its own candidates",function(M)
    local J=M.load({interface=16001});local normal=fixture(M,"BLIZZARD","playerFrame")
    GamepadPlayerCastingBarFrame=M.region(UIParent,"Frame",220,18);GamepadPlayerCastingBarFrame.level=10
    GamepadPlayerCastingBarFrame.shown=true
    enable(J,"playerFrame","BLIZZARD");assert(J.CastBars.units.playerFrame.bar==GamepadPlayerCastingBarFrame)
    GamepadPlayerCastingBarFrame.shown=false;normal.shown=true;M.tick(J.Core);assert(J.CastBars.units.playerFrame.bar==normal)
    assert(#J.Core.clients.retail:CastBars("playerFrame")==1)
end)

test("cast options keep artwork choices scoped and persist in validated backups",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:SetPage("cast")
    assert(S.castToggle:IsVisible() and not S.controls.castBarStyle and S.controls.castBarSource.button:IsVisible() and not S.styleButton:IsVisible())
    S.castToggle.scripts.OnClick()
    S.castBrowse.scripts.OnClick();S.castButtons.CLASS_MAGE.scripts.OnClick()
    local c=J.ThemeManager:Resolve("playerFrame")
    assert(c.castBarShown and c.castBarStyle=="CAPPED" and c.castBarArt=="CLASS_MAGE")
    assert(c.portrait=="CLASS_PALADIN" and c.portraitMode=="CLASS" and not c.unitFrameShown)
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset("playerFrame");assert(J.ProfileManager:Import(backup))
    assert(J.ThemeManager:Resolve("playerFrame").castBarArt=="CLASS_MAGE")
    assert(not J.ThemeManager:Resolve("targetFrame").castBarShown)
    S.castMatch.scripts.OnClick();assert(J.ThemeManager:Resolve("playerFrame").castBarArt=="MATCH")
    S:Select("minimap");assert(S.page=="placement" and not S.pageButtons.cast:IsVisible())
    assert(not J.ProfileManager:Set("minimap","castBarShown",true))
    assert(not J.ProfileManager:Set("playerFrame","castBarWeight",3))
    assert(not J.ProfileManager:Set("playerFrame","castBarPadding",-1))
    assert(not J.ProfileManager:Set("playerFrame","castBarArt","UNKNOWN"))
    assert(not J.ProfileManager:Set("playerFrame","castBarSource","BLINKII"))
end)

test("automatic idle discovery avoids inactive providers before combat starts",function(M)
    local J=M.load();local eui,root=fixture(M,"ELLESMERE","playerFrame")
    local elv=fixture(M,"ELVUI","playerFrame");root.shown=false
    enable(J,"playerFrame");local c=J.CastBars.units.playerFrame
    assert(c.bar==elv and not c.frame.shown)
    M.combat=true;elv.shown=true;J.CastBars:Sync();assert(c.frame.shown)
    M.combat=false;elv.shown=false;root.shown=true
    J.ProfileManager:Set("playerFrame","unitFrameSource","ELLESMERE")
    assert(c.bar==eui and not c.frame.shown)
end)

test("unexpected native read failures hide stale cast borders and recover",function(M)
    local J=M.load();local bar=fixture(M,"BLIZZARD","playerFrame");bar.shown=true
    enable(J,"playerFrame","BLIZZARD");local c=J.CastBars.units.playerFrame
    local read=bar.GetEffectiveAlpha
    bar.GetEffectiveAlpha=function() error("Restricted alpha read") end
    J.CastBars:Sync();assert(not c.frame.shown and not c.active)
    bar.GetEffectiveAlpha=read;M.tick(J.Core);assert(c.frame.shown and c.active)
    local writes=M.geometryWrites
    for i=1,20 do J.Core.driver.scripts.OnUpdate(J.Core.driver,.06) end
    assert(M.geometryWrites==writes)
end)

test("disabled or unavailable cast preferences cannot resurrect old borders in combat",function(M)
    local J=M.load();local bar=fixture(M,"BLIZZARD","playerFrame");bar.shown=true
    enable(J,"playerFrame","BLIZZARD");local c=J.CastBars.units.playerFrame
    J.ProfileManager:Set("playerFrame","castBarShown",false)
    M.combat=true;M.tick(J.Core);assert(not c.frame.shown)
    J.ProfileManager:Set("playerFrame","castBarShown",true);M.tick(J.Core);assert(not c.frame.shown)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(c.frame.shown)
    J.ProfileManager:Set("playerFrame","castBarSource","ELVUI");assert(not c.frame.shown)
    M.combat=true;M.tick(J.Core);assert(not c.frame.shown and c.bar==bar)
    M.combat=false;local elv=fixture(M,"ELVUI","playerFrame");elv.shown=true
    M.tick(J.Core);assert(c.bar==elv and c.frame.shown)
end)

test("cast width and height resize only centered artwork and persist independently",function(M)
    local J=M.load();local bar=fixture(M,"ELLESMERE","playerFrame");bar.shown=true
    enable(J,"playerFrame","ELLESMERE");local c=J.CastBars.units.playerFrame
    J.ProfileManager:Set("playerFrame","castBarWidth",125)
    J.ProfileManager:Set("playerFrame","castBarHeight",150)
    local _,_,_,x,ny=c.textures['12']:GetPoint()
    near(x,(180-225)/2-1);near(c.textures['12'].w,227)
    local _,_,_,_,bottomY=c.textures['32']:GetPoint()
    near(-bottomY,(16-24)/2+24+1)
    assert(c.frame.w==180 and c.frame.h==16 and bar.w==180 and bar.h==16)
    assert(J.ThemeManager:Resolve("targetFrame").castBarWidth==100)
    assert(J.ThemeManager:Resolve("focusFrame").castBarHeight==100)
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset("playerFrame");assert(J.ProfileManager:Import(backup))
    assert(J.ThemeManager:Resolve("playerFrame").castBarWidth==125)
    assert(J.ThemeManager:Resolve("playerFrame").castBarHeight==150)
    assert(not J.ProfileManager:Set("playerFrame","castBarWidth",49))
    assert(not J.ProfileManager:Set("playerFrame","castBarHeight",151))
    assert(not J.ProfileManager:Set("actionHub","castBarWidth",110))
    assert(not J.ProfileManager:Set("minimap","castBarHeight",110))
    local S=J.SettingsUI;S:Open();S:SetPage("cast")
    assert(S.controls.castBarWidth.edit:IsVisible() and S.controls.castBarHeight.edit:IsVisible())
    S.castReset.scripts.OnClick();assert(c.config.castBarWidth==100 and c.config.castBarHeight==100)
    assert((M.appearanceWrites or 0)==0 and (M.nativeLayoutWrites or 0)==0)
end)

test("cast fitting changes wait for combat and retain full corner silhouettes",function(M)
    local J=M.load();local bar=fixture(M,"BLIZZARD","focusFrame");bar.shown=true
    enable(J,"focusFrame","BLIZZARD");local c=J.CastBars.units.focusFrame
    M.combat=true;local writes=M.geometryWrites
    J.ProfileManager:Set("focusFrame","castBarWidth",150);J.ProfileManager:Set("focusFrame","castBarHeight",75)
    assert(c.config.castBarWidth==100 and c.config.castBarHeight==100 and M.geometryWrites==writes)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(c.config.castBarWidth==150 and c.config.castBarHeight==75)
    local entry=J.UnitSkinCatalog.entries.CLASS_DRUID
    for _,w in ipairs({50,100,150}) do for _,h in ipairs({50,100,150}) do
        for _,p in pairs(J.CastBars:FitPieces(entry,180,16,1,1,false,w,h)) do
            assert(p.w>0 and p.h>0)
        end
        local p=J.CastBars:FitPieces(entry,180,16,1,1,false,w,h)['11']
        near(p.w/48,p.h/48)
        assert(p.u1==0 and p.v1==0,"Outer art was cropped")
    end end
    assert((M.nativeLayoutWrites or 0)==0)
end)

test("retired cast styles migrate to Bold without losing fitting or artwork",function(M)
    local J=M.load({db={phase1={version=2,theme="paladin_ret",modules={
        playerFrame={castBarStyle="SLIM",castBarWidth=123,castBarHeight=84,castBarShown=true,castBarArt="CLASS_MAGE"},
        targetFrame={castBarStyle="CARVED",castBarWeight=.8},focusFrame={castBarStyle="CAPPED"},
    }}}})
    for _,key in ipairs(keys) do assert(J.ThemeManager:Resolve(key).castBarStyle=="CAPPED") end
    local player=J.ThemeManager:Resolve("playerFrame")
    assert(player.castBarWidth==123 and player.castBarHeight==84 and player.castBarShown and player.castBarArt=="CLASS_MAGE")
    assert(J.ThemeManager:Resolve("targetFrame").castBarWeight==.8)
    local backup=J.ProfileManager:Export()
    assert(not backup:find("SLIM",1,true) and not backup:find("CARVED",1,true))
    for _,style in ipairs({"SLIM","CARVED","CAPPED"}) do
        assert(J.ProfileManager:Import("JF2;paladin_ret;playerFrame.castBarStyle="..style..";playerFrame.castBarWidth=115"))
        player=J.ThemeManager:Resolve("playerFrame")
        assert(player.castBarStyle=="CAPPED" and player.castBarWidth==115)
    end
    local corner=J.CastBars:Pieces(nil,180,16,1,1,false)['11']
    near(corner.w,30);near(corner.h,30) -- The previous Bold geometry.
end)

for _,interface in ipairs({120100,16001}) do
    test("Ellesmere Resource Bars main cast attaches while idle on "..interface,function(M)
        local J=M.load({interface=interface});local mini=fixture(M,"ELLESMERE","playerFrame")
        local host=M.native("ERB_CastBarFrame",230,20,.8);host.shown=false;host.alpha=.7
        local clip=M.region(host,"Frame",210,20);clip.clipsChildren=true
        local bar=M.region(clip,"Frame",210,20);bar.level=17;bar.strata="MEDIUM";host._bar=bar
        local chrome=M.region(host,"Frame",230,20);chrome.level=20;chrome.strata="MEDIUM";host._border=chrome
        enable(J,"playerFrame","ELLESMERE");local c=J.CastBars.units.playerFrame
        assert(c.bar==bar and not c.frame.shown and c.frame.parent==UIParent and c.frame.level==21)
        near(c.frame.w,210);near(c.frame.h,20)
        M.combat=true;host.shown=true;local writes=M.geometryWrites;J.CastBars:Sync()
        assert(c.frame.shown and M.geometryWrites==writes);near(c.frame.alpha,.7)
        host.alpha=0;J.CastBars:Sync();assert(not c.frame.shown)
        host.alpha=.5;J.CastBars:Sync();assert(c.frame.shown);near(c.frame.alpha,.5)
        M.combat=false;host.shown=false;mini.shown=true;M.tick(J.Core)
        assert(c.bar==mini and c.frame.shown)
        mini.shown=false;ERB_CastBarFrame=nil;M.tick(J.Core);assert(c.bar==mini and not c.frame.shown)
        assert(not next(J.Core.notices))
    end)
end

test("Ellesmere target and focus aura-layout casts attach above their style art",function(M)
    local J=M.load({interface=16001})
    for _,key in ipairs({"targetFrame","focusFrame"}) do
        local bar=fixture(M,"ELLESMERE",key);bar.layoutAspect=true
        bar._blizzArtFr=M.region(bar,"Frame",180,16);bar._blizzArtFr.level=33;bar._blizzArtFr.strata="MEDIUM"
        enable(J,key,"ELLESMERE");local c=J.CastBars.units[key]
        assert(c and c.bar==bar and c.frame.template=="DisableUntrustedLayoutScriptsTemplate" and c.frame.level==34)
        M.combat=true;bar.shown=true;J.CastBars:Sync();assert(c.frame.shown)
        M.combat=false
    end
    assert(not next(J.Core.notices))
end)

test("cast layout template absence keeps ordinary native bars compatible",function(M)
    M.noLayoutTemplate=true;local J=M.load();local bar=fixture(M,"BLIZZARD","playerFrame");bar.shown=true
    enable(J,"playerFrame","BLIZZARD");assert(J.CastBars.units.playerFrame.frame.shown)
    assert(not J.CastBars.units.playerFrame.frame.template and not next(J.Core.notices))
end)

test("portrait shell and cast strata are independent and survive backups",function(M)
    local J=M.load();local bar=fixture(M,"BLIZZARD","playerFrame");bar.shown=true
    enable(J,"playerFrame","BLIZZARD");J.ProfileManager:Set("playerFrame","unitFrameShown",true)
    J.ProfileManager:Set("playerFrame","strata","HIGH")
    J.ProfileManager:Set("playerFrame","unitFrameStrata","MEDIUM")
    J.ProfileManager:Set("playerFrame","castBarStrata","DIALOG")
    local cast=J.CastBars.units.playerFrame;local shell=J.UnitSkins.units.playerFrame.health.trim
    assert(J.Core.modules.playerFrame.frame.strata=="HIGH" and shell.frame.strata=="MEDIUM" and not shell.rim)
    assert(cast.frame.strata=="DIALOG")
    J.ProfileManager:Set("playerFrame","strata","LOW")
    assert(shell.frame.strata=="MEDIUM" and cast.frame.strata=="DIALOG")
    local backup=J.ProfileManager:Export();assert(J.ProfileManager:Import(backup))
    assert(J.ThemeManager:Resolve("playerFrame").castBarStrata=="DIALOG")
    assert(J.ThemeManager:Resolve("targetFrame").castBarStrata=="AUTO")
    M.combat=true;J.ProfileManager:Set("playerFrame","castBarStrata","LOW");assert(cast.frame.strata=="DIALOG")
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(cast.frame.strata=="LOW")
    J.ProfileManager:Set("playerFrame","castBarStrata","AUTO");assert(cast.frame.strata==bar.strata)
    assert(not J.ProfileManager:Set("actionHub","castBarStrata","HIGH"))
    assert(not J.ProfileManager:Set("playerFrame","unitFrameStrata","INVALID"))
end)

test("automatic cast layering clears child chrome and saves an independent level",function(M)
    local J=M.load({interface=16001});local bar=fixture(M,"BLIZZARD","playerFrame")
    local chrome=M.region(bar,"Frame",180,16);chrome.level=80;chrome.strata="HIGH"
    local border=M.region(chrome,"Frame",180,16);border.level=87;border.strata="HIGH"
    bar.GetChildren=function() return chrome end
    chrome.GetChildren=function() return border end
    enable(J,"playerFrame","BLIZZARD")
    local cast=J.CastBars.units.playerFrame
    assert(cast.frame.strata=="HIGH" and cast.frame.level==88)
    J.ProfileManager:Set("playerFrame","castBarLevel",8)
    assert(cast.frame.level==95)
    J.ProfileManager:Set("playerFrame","castBarStrata","DIALOG")
    assert(cast.frame.strata=="DIALOG")
    local exported=J.ProfileManager:Export()
    assert(J.ProfileManager:Import(exported))
    assert(J.ThemeManager:Resolve("playerFrame").castBarLevel==8)
    assert(J.ThemeManager:Resolve("targetFrame").castBarLevel==1)
    M.combat=true;J.ProfileManager:Set("playerFrame","castBarLevel",12)
    assert(cast.config.castBarLevel==8)
    M.combat=false;M.tick(J.Core);assert(cast.config.castBarLevel==12)
    assert(not J.ProfileManager:Set("actionHub","castBarLevel",12))
    chrome.forbidden=true
    J.ProfileManager:Set("playerFrame","castBarStrata","AUTO")
    assert(cast.frame.strata==bar.strata)
end)
