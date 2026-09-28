-- Loaded by run.lua with its fresh-host test helper.
local test,near,count = ...

test("all class/race/faction choices map to independent artwork",function(M)
    local J=M.load()
    assert(count(J.PortraitCatalog.entries)==42)
    local paths={}
    for id,entry in pairs(J.PortraitCatalog.entries) do
        assert(not paths[entry.texture]); paths[entry.texture]=true
        assert(J.Core:ValidateProperty("portrait",id)==id)
    end
    assert(count(J.PortraitCatalog.classes)==13 and count(J.PortraitCatalog.factions)==3)
end)

test("every identity uses fixed Player and round Target Focus atlas fits",function(M)
    for _,interface in ipairs({120100,16001}) do
        local J=M.load({interface=interface})
        for id in pairs(J.PortraitCatalog.entries) do
            for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
                J.ProfileManager:Set(key,"portraitMode","FIXED")
                J.ProfileManager:Set(key,"portrait",id)
                local module=J.Core.modules[key]
                local uv=module.textures.main.texCoord
                near(uv[1],key=="playerFrame" and 0 or 1)
                near(uv[2],0.5);near(uv[3],0);near(uv[4],1)
                assert(module.frame.w==128 and module.frame.h==128)
                local c=J.ThemeManager:Resolve(key)
                near(c.x,key=="playerFrame" and -23 or 22)
                near(c.y,key=="playerFrame" and 11 or 12)
            end
        end
        assert(M.nativeWrites==0)
    end
end)

test("target and focus change classes safely during combat without geometry writes",function(M)
    local J=M.load()
    M.combat=true
    local writes=M.geometryWrites
    M.unitData.target.class="PALADIN"; M.event(J.Core,"PLAYER_TARGET_CHANGED")
    assert(J.Core.modules.targetFrame.portraitID=="CLASS_PALADIN")
    M.unitData.target.class="ROGUE"; M.event(J.Core,"PLAYER_TARGET_CHANGED")
    M.unitData.focus.class="WARLOCK"; M.event(J.Core,"PLAYER_FOCUS_CHANGED")
    assert(J.Core.modules.targetFrame.portraitID=="CLASS_ROGUE")
    assert(J.Core.modules.focusFrame.portraitID=="CLASS_WARLOCK")
    assert(J.Core.modules.playerFrame.portraitID=="CLASS_PALADIN" and M.geometryWrites==writes)
end)

test("restricted missing and NPC identity never leaves stale class artwork",function(M)
    local J=M.load()
    local target=J.Core.modules.targetFrame
    M.unitData.target.class=M.secret; M.tick(J.Core)
    assert(target.portraitID=="FACTION_NEUTRAL")
    M.unitData.target.class="MAGE"; M.tick(J.Core)
    assert(target.portraitID=="CLASS_MAGE")
    M.unitData.target.player=M.secret; M.tick(J.Core)
    assert(target.portraitID=="FACTION_NEUTRAL")
    M.unitData.target.player=false; M.unitData.target.class="WARRIOR"; M.tick(J.Core)
    assert(target.portraitID=="FACTION_NEUTRAL")
    M.unitData.target.player=true; UnitClass=function() error("unavailable") end; M.tick(J.Core)
    assert(target.portraitID=="FACTION_NEUTRAL" and not next(J.Core.notices))
end)

test("race faction and fixed modes are independent and secret-safe",function(M)
    local J=M.load()
    local target=J.Core.modules.targetFrame
    J.ProfileManager:Set("targetFrame","portraitMode","RACE")
    assert(target.portraitID=="RACE_HUMAN")
    M.unitData.target.race=M.secret; M.tick(J.Core)
    assert(target.portraitID=="FACTION_NEUTRAL")
    J.ProfileManager:Set("targetFrame","portraitMode","FACTION")
    assert(target.portraitID=="FACTION_ALLIANCE")
    M.unitData.target.faction=M.secret; M.tick(J.Core)
    assert(target.portraitID=="FACTION_NEUTRAL")
    J.ProfileManager:Set("targetFrame","portrait","CLASS_DRUID")
    J.ProfileManager:Set("targetFrame","portraitMode","FIXED")
    assert(target.portraitID=="CLASS_DRUID")
    assert(not J.ProfileManager:Set("minimap","portraitMode","CLASS"))
end)

test("client-protected portrait defers texture writes until combat ends",function(M)
    local J=M.load()
    local target=J.Core.modules.targetFrame
    target.frame.protected=true; M.combat=true
    local writes=M.writes
    M.unitData.target.class="MAGE"; M.event(J.Core,"PLAYER_TARGET_CHANGED")
    assert(target.portraitID=="CLASS_ROGUE" and M.writes==writes)
    M.combat=false; M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(target.portraitID=="CLASS_MAGE")
end)

test("Focus waits for a usable native root and follows visibility and scale",function(M)
    for _,interface in ipairs({120100,16001}) do
        local root=FocusFrame; FocusFrame=nil
        local J=M.load({interface=interface}); assert(not J.Core.modules.focusFrame.frame)
        FocusFrame=root; FocusFrame.forbidden=true; M.tick(J.Core)
        assert(not J.Core.modules.focusFrame.frame)
        FocusFrame.forbidden=false; M.tick(J.Core)
        local focus=J.Core.modules.focusFrame
        near(focus.frame:GetEffectiveScale(),FocusFrame:GetEffectiveScale())
        FocusFrame.shown=false; M.event(J.Core,"PLAYER_FOCUS_CHANGED")
        assert(not focus.frame.shown)
        FocusFrame.shown=true; FocusFrame.scale=0.5; M.tick(J.Core)
        assert(focus.frame.shown); near(focus.frame:GetEffectiveScale(),FocusFrame:GetEffectiveScale())
    end
end)

test("old shell profiles convert once and new portrait backups round trip",function(M)
    local J=M.load({db={phase1={version=1,theme="paladin_ret",modules={
        playerFrame={width=360,height=170,x=-46,y=16,strata="BACKGROUND"},actionHub={y=-24}}}}})
    local p=J.ProfileManager.current
    assert(p.version==2 and p.modules.playerFrame.width==128 and p.modules.playerFrame.x==-23)
    assert(p.modules.playerFrame.y==11 and p.modules.actionHub.y==-24)
    J.ProfileManager:Set("focusFrame","portraitMode","RACE")
    J.ProfileManager:Set("playerFrame","width",140)
    local backup=J.ProfileManager:Export(); assert(backup:match("^JF2;"))
    assert(J.ProfileManager:Import(backup))
    assert(J.Core.modules.playerFrame.frame.w==140 and J.Core.modules.focusFrame.portraitID=="RACE_GNOME")
    local nextJ=M.load({db=JiberishUIDB})
    assert(nextJ.Core.modules.playerFrame.frame.w==140)
end)

test("portrait gallery selects fixed art without mutating other modules",function(M)
    local J=M.load(); local S=J.SettingsUI; S:Open()
    S.tabs.focusFrame.scripts.OnClick();S.portraitButton.scripts.OnClick()
    assert(S.portraitButtons.CLASS_PALADIN.image.texCoord[1]==0.5)
    assert(S.portraitButtons.CLASS_PALADIN.image.texCoord[2]==1)
    S:ShowPortraitGroup("RACE",2)
    assert(S.portraitButtons.RACE_NIGHTELF.shown and not S.portraitButtons.CLASS_ROGUE.shown)
    S.portraitButtons.RACE_NIGHTELF.scripts.OnClick()
    assert(J.Core.modules.focusFrame.portraitID=="RACE_NIGHTELF")
    assert(J.Core.modules.targetFrame.portraitID=="CLASS_ROGUE")
    S.controls.portraitMode.options.CLASS.scripts.OnClick()
    assert(J.Core.modules.focusFrame.portraitID=="CLASS_MAGE")
    S.tabs.actionHub.scripts.OnClick()
    assert(not S.portraitButton.shown and not S.controls.portraitMode.button.shown)
end)

test("classic options toggle states and collection tabs reflect saved settings",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open()
    assert(S.frame.template=="BackdropTemplate" and S.frame.backdrop.edgeFile:find("DialogBox"))
    assert(S.showButton.check:IsShown() and not S.debugButton.check:IsShown())
    S.showButton.scripts.OnClick();assert(not S.showButton.check:IsShown())
    assert(not J.ThemeManager:Resolve("playerFrame").shown)
    S.debugButton.scripts.OnClick();assert(S.debugButton.check:IsShown())
    S:Select("focusFrame");assert(S.showButton.check:IsShown())
    assert(S.tabs.focusFrame.selection:IsShown() and not S.tabs.playerFrame.selection:IsShown())
    S:ShowPortraitGroup("RACE")
    assert(S.groupButtons.RACE.selection:IsShown() and not S.groupButtons.CLASS.selection:IsShown())
    S.portraitButtons.CLASS_MAGE.scripts.OnClick()
    assert(S.portraitButtons.CLASS_MAGE.selection:IsShown())
    assert(S.crest.path==J.Media.logo)
    assert(M.nativeWrites==0)
end)

test("hidden missing and forbidden native portraits never show decorative backgrounds",function(M)
    local J=M.load()
    local portrait=TargetFrame.TargetFrameContainer.Portrait
    portrait.shown=false; M.tick(J.Core)
    assert(not J.Core.modules.targetFrame.frame.shown)
    portrait.shown=true; M.tick(J.Core)
    assert(J.Core.modules.targetFrame.frame.shown)
    portrait.forbidden=true; M.tick(J.Core)
    assert(not J.Core.modules.targetFrame.frame.shown and not next(J.Core.notices))
    TargetFrame.TargetFrameContainer.Portrait=nil; M.tick(J.Core)
    assert(not J.Core.modules.targetFrame.frame.shown and not next(J.Core.notices))
end)
