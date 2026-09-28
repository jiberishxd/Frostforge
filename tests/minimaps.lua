local test,near,count = ...

test("minimap opening follows native size and effective scale on both clients",function(M)
    for _,interface in ipairs({120100,16001}) do
        local J=M.load({interface=interface})
        local map=J.Core.modules.minimap
        for _,diameter in ipairs({140,198,256,320}) do
            for _,scale in ipairs({0.64,0.8,1}) do
                UIParent.scale=scale;Minimap.scale=1.2
                Minimap.w,Minimap.h=diameter,diameter
                M.tick(J.Core)
                near(map.frame.w,340*diameter/198)
                near(map.frame.h,map.frame.w)
                near(map.frame:GetEffectiveScale(),Minimap:GetEffectiveScale())
                assert(map.frame.points[1][2]==Minimap)
                near(map.frame.points[1][4],0);near(map.frame.points[1][5],0)
                -- The shared aperture matches native diameter within a pixel.
                assert(math.abs(map.frame.w*298/512-diameter)<0.2)
            end
        end
        J.ProfileManager:Set("minimap","width",400)
        J.ProfileManager:Set("minimap","x",12)
        J.ProfileManager:Set("minimap","scale",1.5)
        near(map.frame.w,400*320/198)
        near(map.frame.points[1][4],8)
        near(map.frame:GetEffectiveScale(),Minimap:GetEffectiveScale()*1.5)
    end
end)

test("minimap preserves saved adjustments and hides with unavailable native anchor",function(M)
    local J=M.load({db={phase1={version=2,modules={minimap={width=300,x=7,y=-9}}}}})
    local map=J.Core.modules.minimap
    assert(map.frame.w==300 and map.applied.x==7 and map.applied.y==-9)
    Minimap.shown=false;M.tick(J.Core);assert(not map.frame.shown)
    Minimap.shown=true;M.tick(J.Core);assert(map.frame.shown)
    Minimap.forbidden=true;M.tick(J.Core);assert(not map.frame.shown)
    Minimap=nil;M.tick(J.Core);assert(not map.frame.shown)
end)

test("42 minimaps share geometry while selecting independently of portraits",function(M)
    local J=M.load();local minimap=J.Core.modules.minimap
    assert(count(J.MinimapCatalog.entries)==42 and minimap.minimapID=="CLASS_PALADIN")
    local before={}
    for name,t in pairs(minimap.textures) do before[name]={t.w,t.h,t.points[1][4],t.points[1][5]} end
    for id,entry in pairs(J.MinimapCatalog.entries) do
        assert(J.ProfileManager:Set("minimap","minimap",id))
        assert(J.ProfileManager:Set("minimap","minimapMode","FIXED"))
        assert(minimap.minimapID==id)
        for name,t in pairs(minimap.textures) do
            assert(t.path==entry.texture)
            near(t.w,before[name][1]);near(t.h,before[name][2])
            near(t.points[1][4],before[name][3]);near(t.points[1][5],before[name][4])
        end
        assert(J.Core.modules.playerFrame.portraitID=="CLASS_PALADIN")
    end
end)

test("automatic minimap identity uses only player with guarded fallback",function(M)
    local J=M.load();local minimap=J.Core.modules.minimap
    M.unitData.target.class="WARRIOR";M.tick(J.Core);assert(minimap.minimapID=="CLASS_PALADIN")
    M.unitData.player.class="MAGE";M.tick(J.Core);assert(minimap.minimapID=="CLASS_MAGE")
    M.unitData.player.class=M.secret;M.tick(J.Core);assert(minimap.minimapID=="FACTION_NEUTRAL")
    J.ProfileManager:Set("minimap","minimapMode","RACE")
    assert(minimap.minimapID=="RACE_SCOURGE")
    J.ProfileManager:Set("minimap","minimapMode","FACTION")
    assert(minimap.minimapID=="FACTION_HORDE")
    M.unitData.player.faction=M.secret;M.tick(J.Core);assert(minimap.minimapID=="FACTION_NEUTRAL")
    assert(not next(J.Core.notices))
end)

test("minimap configuration and client-protected texture refresh defer in combat",function(M)
    local J=M.load();local minimap=J.Core.modules.minimap
    J.ProfileManager:Set("playerFrame","portraitMode","FIXED")
    J.ProfileManager:Set("actionHub","hubMode","FIXED")
    minimap.frame.protected=true;M.combat=true
    local writes=M.writes
    M.unitData.player.class="MAGE";M.tick(J.Core)
    assert(minimap.minimapID=="CLASS_PALADIN" and M.writes==writes)
    J.ProfileManager:Set("minimap","minimapMode","FIXED")
    J.ProfileManager:Set("minimap","minimap","RACE_SCOURGE")
    J.ProfileManager:Set("minimap","minimap","CLASS_HUNTER")
    assert(minimap.minimapID=="CLASS_PALADIN")
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(minimap.minimapID=="CLASS_HUNTER" and not J.Core.dirty)
end)

test("minimap profile export import is bounded atomic and module scoped",function(M)
    local J=M.load()
    J.ProfileManager:Set("minimap","minimapMode","FIXED")
    J.ProfileManager:Set("minimap","minimap","RACE_SCOURGE")
    local backup=J.ProfileManager:Export();assert(backup:find("minimap.minimap=RACE_SCOURGE",1,true))
    assert(J.ProfileManager:Import(backup));assert(J.Core.modules.minimap.minimapID=="RACE_SCOURGE")
    assert(not J.ProfileManager:Set("playerFrame","minimap","CLASS_MAGE"))
    local profile=J.ProfileManager.current
    for _,bad in ipairs({"JF2;paladin_ret;playerFrame.minimap=CLASS_MAGE","JF2;paladin_ret;minimap.minimap=UNKNOWN","JF2;paladin_ret;minimap.minimapMode=TARGET"}) do
        assert(not J.ProfileManager:Import(bad));assert(J.ProfileManager.current==profile)
    end
    local nextJ=M.load({db=JiberishUIDB});assert(nextJ.Core.modules.minimap.minimapID=="RACE_SCOURGE")
end)

test("minimap gallery pages have opaque backing and only load visible thumbnails",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:Select("minimap")
    assert(S.minimapButton.shown and S.controls.minimapMode.button.shown and not S.portraitButton.shown)
    assert(not S.minimapPicker and not S.picker)
    S.minimapButton.scripts.OnClick();S:ShowMinimapGroup("RACE",1)
    assert(S.minimapPicker.underlay and S.frame.underlay)
    local countVisible=0
    for _,b in pairs(S.minimapButtons) do
        if b.shown then countVisible=countVisible+1;assert(b.image.path) else assert(b.image.path==nil) end
    end
    assert(countVisible==12)
    local frames,textures=#M.frames,M.textures
    S:ShowMinimapGroup("RACE",3)
    countVisible=0;for _,b in pairs(S.minimapButtons) do if b.shown then countVisible=countVisible+1 end end
    assert(countVisible==2 and S.minimapPageLabel.text=="Page 3 / 3")
    S:ShowMinimapGroup("CLASS",9);assert(S.minimapPage==2)
    S.minimapButtons.RACE_SCOURGE.scripts.OnClick()
    assert(J.Core.modules.minimap.minimapID=="RACE_SCOURGE" and not S.minimapPicker.shown)
    for _,b in pairs(S.minimapButtons) do assert(b.image.path==nil) end
    S.minimapButton.scripts.OnClick();assert(#M.frames==frames and M.textures==textures)
    assert(J.Core.modules.playerFrame.portraitID=="CLASS_PALADIN")
end)
