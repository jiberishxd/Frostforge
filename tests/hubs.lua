local test,near,count = ...

test("42 hubs share geometry while selecting independently of portraits",function(M)
    local J=M.load();local hub=J.Core.modules.actionHub
    assert(count(J.HubCatalog.entries)==42 and hub.hubID=="CLASS_PALADIN")
    local before={}
    for name,t in pairs(hub.textures) do before[name]={t.w,t.h,t.points[1][4],t.points[1][5]} end
    for id,entry in pairs(J.HubCatalog.entries) do
        assert(J.ProfileManager:Set("actionHub","hub",id))
        assert(J.ProfileManager:Set("actionHub","hubMode","FIXED"))
        assert(hub.hubID==id)
        for name,t in pairs(hub.textures) do
            assert(t.path==entry.texture)
            near(t.w,before[name][1]);near(t.h,before[name][2])
            near(t.points[1][4],before[name][3]);near(t.points[1][5],before[name][4])
        end
        assert(J.Core.modules.playerFrame.portraitID=="CLASS_PALADIN")
    end
end)

test("automatic hub identity uses only player with guarded fallback",function(M)
    local J=M.load();local hub=J.Core.modules.actionHub
    M.unitData.target.class="WARRIOR";M.tick(J.Core);assert(hub.hubID=="CLASS_PALADIN")
    M.unitData.player.class="MAGE";M.tick(J.Core);assert(hub.hubID=="CLASS_MAGE")
    M.unitData.player.class=M.secret;M.tick(J.Core);assert(hub.hubID=="FACTION_NEUTRAL")
    J.ProfileManager:Set("actionHub","hubMode","RACE")
    assert(hub.hubID=="RACE_SCOURGE")
    J.ProfileManager:Set("actionHub","hubMode","FACTION")
    assert(hub.hubID=="FACTION_HORDE")
    M.unitData.player.faction=M.secret;M.tick(J.Core);assert(hub.hubID=="FACTION_NEUTRAL")
    assert(not next(J.Core.notices))
end)

test("hub configuration and client-protected texture refresh defer in combat",function(M)
    local J=M.load();local hub=J.Core.modules.actionHub
    J.ProfileManager:Set("playerFrame","portraitMode","FIXED")
    hub.frame.protected=true;M.combat=true
    local writes=M.writes
    M.unitData.player.class="MAGE";M.tick(J.Core)
    assert(hub.hubID=="CLASS_PALADIN" and M.writes==writes)
    J.ProfileManager:Set("actionHub","hubMode","FIXED")
    J.ProfileManager:Set("actionHub","hub","RACE_SCOURGE")
    J.ProfileManager:Set("actionHub","hub","CLASS_HUNTER")
    assert(hub.hubID=="CLASS_PALADIN")
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(hub.hubID=="CLASS_HUNTER" and not J.Core.dirty)
end)

test("hub profile export import is bounded atomic and module scoped",function(M)
    local J=M.load()
    J.ProfileManager:Set("actionHub","hubMode","FIXED")
    J.ProfileManager:Set("actionHub","hub","RACE_SCOURGE")
    local backup=J.ProfileManager:Export();assert(backup:find("actionHub.hub=RACE_SCOURGE",1,true))
    assert(J.ProfileManager:Import(backup));assert(J.Core.modules.actionHub.hubID=="RACE_SCOURGE")
    assert(not J.ProfileManager:Set("playerFrame","hub","CLASS_MAGE"))
    local profile=J.ProfileManager.current
    for _,bad in ipairs({"JF2;paladin_ret;playerFrame.hub=CLASS_MAGE","JF2;paladin_ret;actionHub.hub=UNKNOWN","JF2;paladin_ret;actionHub.hubMode=TARGET"}) do
        assert(not J.ProfileManager:Import(bad));assert(J.ProfileManager.current==profile)
    end
    local nextJ=M.load({db=JiberishUIDB});assert(nextJ.Core.modules.actionHub.hubID=="RACE_SCOURGE")
end)

test("hub gallery pages have opaque backing and only load visible thumbnails",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:Select("actionHub")
    assert(S.hubButton.shown and S.controls.hubMode.button.shown and not S.portraitButton.shown)
    assert(S.hubPicker.underlay and S.picker.underlay and S.frame.underlay)
    S.hubButton.scripts.OnClick();S:ShowHubGroup("RACE",1)
    local countVisible=0
    for _,b in pairs(S.hubButtons) do
        if b.shown then countVisible=countVisible+1;assert(b.image.path) else assert(b.image.path==nil) end
    end
    assert(countVisible==12)
    local frames,textures=#M.frames,M.textures
    S:ShowHubGroup("RACE",3)
    countVisible=0;for _,b in pairs(S.hubButtons) do if b.shown then countVisible=countVisible+1 end end
    assert(countVisible==2 and S.hubPageLabel.text=="Page 3 / 3")
    S:ShowHubGroup("CLASS",9);assert(S.hubPage==2)
    S.hubButtons.RACE_SCOURGE.scripts.OnClick()
    assert(J.Core.modules.actionHub.hubID=="RACE_SCOURGE" and not S.hubPicker.shown)
    for _,b in pairs(S.hubButtons) do assert(b.image.path==nil) end
    S.hubButton.scripts.OnClick();assert(#M.frames==frames and M.textures==textures)
    assert(J.Core.modules.playerFrame.portraitID=="CLASS_PALADIN")
end)
