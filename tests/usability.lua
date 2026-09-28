local test,near=...

for _,interface in ipairs({120100,16001}) do
    test("first launch wizard waits for the world and combat then finishes atomically on "..interface,function(M)
        local J=M.load({interface=interface});local W=J.Setup
        assert(W.pending and not W.frame and JiberishUIDB.setupVersion==0)
        local before=J.ProfileManager:Export()
        M.combat=true;M.event(J.Core,"PLAYER_ENTERING_WORLD");assert(not W.frame)
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        assert(W.frame:IsShown() and W.step==1 and not J.SettingsUI.frame)
        W.choices.RACE.scripts.OnClick();W.next.scripts.OnClick()
        W.toggles.frames.scripts.OnClick();W.toggles.casts.scripts.OnClick()
        W.next.scripts.OnClick();W.toggles.icon.scripts.OnClick()
        assert(J.ProfileManager:Export()==before and not J.Access:IconEnabled())
        M.combat=true;W.next.scripts.OnClick()
        assert(W.frame:IsShown() and J.ProfileManager:Export()==before)
        M.combat=false;W.next.scripts.OnClick()
        assert(not W.frame:IsShown() and JiberishUIDB.setupVersion==1 and J.SettingsUI.frame:IsShown())
        for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
            local c=J.ThemeManager:Resolve(key)
            assert(c.portraitMode=="RACE" and c.unitFrameShown and c.castBarShown)
        end
        assert(J.ThemeManager:Resolve("minimap").minimapMode=="RACE" and J.Access:IconEnabled())
        assert(not next(J.Core.notices))
    end)

    test("wizard skip reload and existing profiles do not nag or overwrite choices on "..interface,function(M)
        local J=M.load({interface=interface});M.event(J.Core,"PLAYER_ENTERING_WORLD")
        local before=J.ProfileManager:Export();J.Setup.choices.FACTION.scripts.OnClick();J.Setup.skip.scripts.OnClick()
        assert(J.ProfileManager:Export()==before and JiberishUIDB.setupVersion==1)
        local saved=JiberishUIDB
        J=M.load({interface=interface,db=saved});M.event(J.Core,"PLAYER_ENTERING_WORLD");assert(not J.Setup.frame)
        J=M.load({interface=interface,db={phase1={version=2,modules={playerFrame={width=172,height=140}}}}})
        M.event(J.Core,"PLAYER_ENTERING_WORLD");assert(not J.Setup.frame)
        J.SettingsUI:Open();J.SettingsUI:SetPage("guide");J.SettingsUI.setupButton.scripts.OnClick()
        assert(J.Setup.frame:IsShown());J.Setup.frame:Hide()
        assert(J.ThemeManager:Resolve("playerFrame").width==172 and J.ThemeManager:Resolve("playerFrame").height==140)
        assert(not next(J.Core.notices))
    end)
end

test("wizard resumes after interrupted first login and refuses profile changes",function(M)
    local J=M.load();assert(JiberishUIDB.setupVersion==0)
    J=M.load({db=JiberishUIDB});M.event(J.Core,"PLAYER_ENTERING_WORLD")
    local W=J.Setup;assert(W.frame:IsShown())
    W.step=3;W:Refresh();J.ProfileManager:SaveAs("Other",false)
    local before=J.ProfileManager:Export();W:Finish()
    assert(W.frame:IsShown() and J.ProfileManager:Export()==before and W.message.text:find("profile changed",1,true))
    W:Dismiss();M.combat=true;W:Open();assert(W.pending)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(W.frame:IsShown())
    UIParent.w,UIParent.h=800,500;W:Fit();assert(W.frame.scale<=468/480)
end)

test("wizard and access preferences preserve future saved-data formats",function(M)
    local db={phase1={version=50},access={version=50,minimapIcon=true}}
    local J=M.load({db=db});M.event(J.Core,"PLAYER_ENTERING_WORLD");J.Setup:Open()
    assert(not J.Setup.frame and not J.Access:SetIcon(false))
    assert(db.phase1.version==50 and db.access.minimapIcon and not db.setupVersion)
end)

test("portrait size is linked scoped atomic and queues both dimensions in combat",function(M)
    local J=M.load({db={phase1={version=2,modules={playerFrame={width=175,height=140}}}}})
    local S=J.SettingsUI;S:Open();S:SetPage("placement")
    assert(S.controls.portraitSize.slider:IsVisible() and not S.controls.width.slider:IsVisible())
    assert(J.ThemeManager:Resolve("playerFrame").height==140)
    S.controls.portraitSize.slider:SetValue(192)
    local c=J.ThemeManager:Resolve("playerFrame");assert(c.width==192 and c.height==192)
    assert(J.ThemeManager:Resolve("targetFrame").width==128)
    S.sizeAdvanced.scripts.OnClick();assert(S.controls.width.slider:IsVisible() and S.controls.height.slider:IsVisible())
    assert(not S.controls.portraitSize.slider:IsVisible())
    S.controls.height.slider:SetValue(180);assert(J.ThemeManager:Resolve("playerFrame").width==192)
    S.sizeAdvanced.scripts.OnClick();M.combat=true
    S.controls.portraitSize.edit:SetText("220");S.controls.portraitSize.edit.scripts.OnEnterPressed()
    c=J.ThemeManager:Resolve("playerFrame");assert(c.width==220 and c.height==220)
    assert(J.Core.modules.playerFrame.frame.w==192 and J.Core.modules.playerFrame.frame.h==180)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(J.Core.modules.playerFrame.frame.w==220 and J.Core.modules.playerFrame.frame.h==220)
    local before=J.ProfileManager:Export();S:Set("portraitSize","invalid");assert(J.ProfileManager:Export()==before)
    assert(not J.ProfileManager:SetMany({{"playerFrame","width",200},{"playerFrame","height","bad"}}))
    assert(J.ProfileManager:Export()==before)
    assert(J.ProfileManager:Import(before));assert(J.ThemeManager:Resolve("playerFrame").height==220)
    S:Select("minimap");assert(S.controls.width.slider:IsVisible() and S.controls.height.slider:IsVisible() and not S.sizeAdvanced:IsVisible())
    assert(not next(J.Core.notices))
end)

test("settings use quiet panels and retain frosted native buttons",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open()
    assert(S.frame.backdrop.bgFile=="Interface\\Buttons\\WHITE8X8")
    assert(S.frame.backdropColor[1]<.1 and S.frame.backdrop.edgeFile:find("Dialog",1,true))
    assert(S.pageButtons.artwork.up.path:find("UI-Panel-Button-Up",1,true))
    for _,o in ipairs(M.objects) do
        assert(not o.backdrop or o.backdrop.bgFile~=J.Media.panelStone)
        assert(o.path~=J.Media.panelStone)
    end
end)

local function elv(M,circle)
    local map={Initialized=true,db={circle=circle,size=198}}
    local E={db={general={minimap=map.db}},private={general={minimap={enable=true}}},data={keys={profile="Default"}}}
    function E:GetModule(name) if name=="Minimap" then return map end end
    function map:SetMinimapMask(square)
        assert(not M.combat and not Minimap.forbidden)
        self.mask=square and "SQUARE" or "ROUND";M.shapeWrites=(M.shapeWrites or 0)+1
    end
    function map:UpdateSettings() assert(not M.combat);M.shapeUpdates=(M.shapeUpdates or 0)+1 end
    ElvUI={E};return E,map
end

for _,interface in ipairs({120100,16001}) do
    test("ElvUI round minimap is reversible through reload and profile changes on "..interface,function(M)
        local E,map=elv(M,false);local J=M.load({interface=interface})
        assert(map.db.circle and map.mask=="ROUND" and JiberishUIDB.minimapShapeRestore.Default==false)
        local writes=M.shapeWrites;for i=1,4 do M.tick(J.Core) end;assert(M.shapeWrites==writes)
        J=M.load({interface=interface,db=JiberishUIDB})
        assert(J.Minimaps.round.original==false)
        J.ProfileManager:Set("minimap","shown",false)
        assert(not map.db.circle and map.mask=="SQUARE" and JiberishUIDB.minimapShapeRestore.Default==nil)
        J.ProfileManager:Set("minimap","shown",true)
        local old=map.db
        E.db.general.minimap={circle=true,size=220};map.db=E.db.general.minimap;E.data.keys.profile="Round profile"
        M.tick(J.Core);assert(not old.circle and map.db.circle and J.Minimaps.round.original==true)
        J.ProfileManager:Set("minimap","minimapRound",false);assert(map.db.circle and map.mask=="ROUND")
        local before=J.ProfileManager:Export();assert(J.ProfileManager:Import(before))
        assert(not J.ThemeManager:Resolve("minimap").minimapRound)
        assert(not J.ProfileManager:Set("playerFrame","minimapRound",true))
        assert(not next(J.Core.notices))
    end)

    test("round minimap defers combat disabled providers and forbidden maps on "..interface,function(M)
        local E,map=elv(M,false);map.Initialized=false
        local J=M.load({interface=interface});assert(not map.db.circle and not M.shapeWrites)
        map.Initialized=true;M.combat=true;M.tick(J.Core);assert(not map.db.circle)
        M.combat=false;Minimap.forbidden=true;M.tick(J.Core);assert(not map.db.circle)
        Minimap.forbidden=false;M.tick(J.Core);assert(map.db.circle)
        M.combat=true;J.ProfileManager:Set("minimap","shown",false);assert(map.db.circle)
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(not map.db.circle)
        E.private.general.minimap.enable=false;J.ProfileManager:Set("minimap","shown",true);assert(not map.db.circle)
        assert(not next(J.Core.notices))
    end)
end

test("minimap artwork clears native layers including old background settings",function(M)
    Minimap.strata="MEDIUM";Minimap.level=50
    Minimap.backdrop=M.region(Minimap,"Frame",198,198);Minimap.backdrop.strata="HIGH";Minimap.backdrop.level=55
    local J=M.load();local art=J.Core.modules.minimap.frame
    assert(art.strata=="HIGH" and art.level==56 and art.fixedStrata and art.fixedLevel and not art.mouse)
    local before=M.geometryWrites;M.combat=true;Minimap.backdrop.level=70;M.tick(J.Core)
    assert(art.level==71 and M.geometryWrites==before)
    art.protected=true;Minimap.backdrop.level=80;M.tick(J.Core);assert(art.level==71)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(art.level==81)
    Minimap.shown=false;M.tick(J.Core);assert(not art:IsShown())
    assert(not next(J.Core.notices))
end)

test("round minimap retries an interrupted provider refresh",function(M)
    local E,map=elv(M,false);local update=map.UpdateSettings;local fail=true
    map.UpdateSettings=function(self) if fail then error("temporary provider failure") end;update(self) end
    local J=M.load();assert(J.Minimaps.round.pending and map.db.circle)
    fail=false;M.tick(J.Core);assert(not J.Minimaps.round.pending and map.mask=="ROUND")
    J.ProfileManager:Set("minimap","shown",false);assert(not map.db.circle and map.mask=="SQUARE")
end)

test("compartment and ElvUI launchers register once and open after combat",function(M)
    local J=M.load();local E={Options={args={}},Libs={EP={}}};ElvUI={E}
    function E.Libs.EP:RegisterPlugin(name,callback)
        assert(name=="Frostforge");self.calls=(self.calls or 0)+1;self.callback=callback
    end
    AddonCompartmentFrame=M.native("AddonCompartmentFrame",32,32)
    function AddonCompartmentFrame:RegisterAddon(info) self.calls=(self.calls or 0)+1;self.info=info end
    for i=1,4 do M.tick(J.Core) end
    assert(AddonCompartmentFrame.calls==1 and E.Libs.EP.calls==1)
    E.Libs.EP.callback();assert(E.Options.args.frostforge.args.open.name=="Open Frostforge settings")
    M.combat=true;AddonCompartmentFrame.info.func();assert(J.SettingsUI.pendingOpen and not J.SettingsUI.frame)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(J.SettingsUI.frame:IsShown())
    J.SettingsUI.frame:Hide();E.Options.args.frostforge.args.open.func();assert(J.SettingsUI.frame:IsShown())
    E.Options.args.frostforge.args.setup.func();assert(J.Setup.frame:IsShown())
    assert(not next(J.Core.notices))
end)

test("reload restoration retries until ElvUI finishes updating",function(M)
    local E,map=elv(M,false);local J=M.load();local saved=JiberishUIDB
    J.ProfileManager.current.modules.minimap={shown=false}
    local update=map.UpdateSettings;local fail=true
    map.UpdateSettings=function(self) if fail then error("temporary provider failure") end;update(self) end
    J=M.load({db=saved})
    assert(not map.db.circle and JiberishUIDB.minimapShapeRestore.Default==false)
    fail=false;M.tick(J.Core)
    assert(map.mask=="SQUARE" and JiberishUIDB.minimapShapeRestore.Default==nil)
end)

test("optional minimap launcher persists drags hides with map and reuses its button",function(M)
    local J=M.load();assert(not J.Access:IconEnabled() and not J.Access.icon)
    J.Access:SetIcon(true);local b=J.Access.icon;assert(b:IsVisible() and b.parent==Minimap)
    b.scripts.OnClick();assert(J.SettingsUI.frame:IsShown())
    GetCursorPosition=function() return 100,200 end
    b.scripts.OnDragStart();b.scripts.OnUpdate();b.scripts.OnDragStop()
    local angle=JiberishUIDB.access.angle;assert(angle~=225)
    J.SettingsUI.frame:Hide();b.scripts.OnMouseDown();b.scripts.OnClick()
    assert(J.SettingsUI.frame:IsShown(),"first new click after dragging opens settings")
    Minimap.shown=false;assert(not b:IsVisible());Minimap.shown=true
    M.combat=true;J.Access:SetIcon(false);assert(b:IsShown())
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(not b:IsShown())
    local textures=M.textures;J.Access:SetIcon(true);assert(J.Access.icon==b and M.textures==textures)
    local saved=JiberishUIDB;J=M.load({db=saved});assert(J.Access:IconEnabled() and JiberishUIDB.access.angle==angle)
    assert(not next(J.Core.notices))
end)
