local test,near=...
for _,interface in ipairs({120100,16001}) do
    test("settings pages isolate advanced controls and preserve unsaved input on client "..interface,function(M)
        local J=M.load({interface=interface});local S=J.SettingsUI;S:Open()
        local original=J.ProfileManager:Export()
        assert(S.showButton:IsVisible() and not S.controls.width.edit:IsVisible() and not S.debugButton:IsVisible())
        S.pageButtons.placement.scripts.OnClick()
        assert(S.controls.width.edit:IsVisible() and not S.showButton:IsVisible())
        local edit=S.controls.width.edit;edit:SetFocus();edit:SetText("222")
        S:SetPage("advanced")
        assert(not edit:HasFocus() and edit:GetText()=="128" and J.ProfileManager:Export()==original)
        S.controls.strata.button.scripts.OnClick();assert(S.menus[1]:IsVisible())
        S:Select("minimap");assert(not S.menus[1]:IsVisible())
        S:SetPage("artwork")
        assert(S.minimapButton:IsVisible() and not S.styleButton:IsVisible() and not S.controls.portraitSource.button:IsVisible())
        local frames,textures,fonts=#M.frames,M.textures,M.fonts
        for i=1,5 do for _,page in ipairs({"artwork","placement","advanced","guide"}) do S:SetPage(page) end end
        assert(#M.frames==frames and M.textures==textures and M.fonts==fonts)
        assert(not next(J.Core.notices))
    end)
end

test("settings window fits short screens and preserves scaled drag positions",function(M)
    local J=M.load();local S=J.SettingsUI
    UIParent.w,UIParent.h=1024,600;S:Open()
    near(S.frame.scale,568/700)
    assert(S.frame.w*S.frame.scale<=UIParent.w-32 and S.frame.h*S.frame.scale<=UIParent.h-32)
    local scale=S.frame.scale
    S.titleBar.scripts.OnDragStart();S.frame.center={(512+40)/scale,(300-20)/scale};S.titleBar.scripts.OnDragStop()
    near(J.ProfileManager.current.window.x,40);near(J.ProfileManager.current.window.y,-20)
    S.frame:Hide();S:Open();near(S.frame.points[1][4],40/scale)
    UIParent.w,UIParent.h=1920,1080;S.frame.scripts.OnEvent(S.frame,"UI_SCALE_CHANGED")
    near(S.frame.scale,1);near(S.frame.points[1][4],40);near(S.frame.points[1][5],-20)
    S:Center();near(J.ProfileManager.current.window.x,0)
end)

test("settings backups round trip and reject invalid input without partial writes",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:SetPage("guide")
    J.ProfileManager:Set("playerFrame","x",-80);J.ProfileManager:Set("targetFrame","unitFrameShown",true)
    S:ShowBackup("export");local backup=S.backupEdit:GetText()
    assert(backup==J.ProfileManager:Export() and S.backupDialog:IsVisible() and S.backupEdit:HasFocus() and not S.restoreButton.shown)
    S.backupEdit.scripts.OnEscapePressed();assert(not S.backupDialog.shown and not S.backupEdit:HasFocus())
    J.ProfileManager:Set("playerFrame","x",12)
    local current=J.ProfileManager.current
    S:ShowBackup("import");S.backupEdit:SetText("not a backup");S.restoreButton.scripts.OnClick()
    assert(J.ProfileManager.current==current and S.backupDialog.shown and S.backupResult.text:find("Invalid",1,true))
    S.backupEdit:SetText(backup);S.restoreButton.scripts.OnClick()
    assert(not S.backupDialog.shown and not S.backupEdit:HasFocus())
    assert(J.ThemeManager:Resolve("playerFrame").x==-80 and J.ThemeManager:Resolve("targetFrame").unitFrameShown)
    assert(S.status.text:find("Backup restored",1,true))
end)

test("reset confirmation changes only its selected component and is canceled on navigation",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open()
    J.ProfileManager:Set("playerFrame","x",-80);J.ProfileManager:Set("targetFrame","x",60)
    S.resetButton.scripts.OnClick();assert(S.resetDialog.shown and J.ThemeManager:Resolve("playerFrame").x==-80)
    S:Select("targetFrame");assert(not S.resetDialog.shown)
    S.resetButton.scripts.OnClick();S.resetConfirm.scripts.OnClick()
    assert(not S.resetDialog.shown and J.ThemeManager:Resolve("playerFrame").x==-80)
    assert(J.ThemeManager:Resolve("targetFrame").x==J.ThemeManager.registry.paladin_ret.targetFrame.x)
end)

test("all artwork collections search literal names and keep pagination and selection scoped",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open()
    for _,case in ipairs({{"playerFrame","portrait","picker","portraitButtons"},{"actionHub","hub","hubPicker","hubButtons"},{"minimap","minimap","minimapPicker","minimapButtons"}}) do
        S:Select(case[1]);local p=S[case[3]]
        S:ShowCollection(case[2],"RACE",3);p:Show()
        p.search:SetText("  night elf  ")
        assert(S[case[4]].RACE_NIGHTELF:IsVisible())
        local visible=0
        for _,b in pairs(S[case[4]]) do if b:IsVisible() then visible=visible+1 else assert(not b.image.path) end end
        assert(visible==1 and not p.empty.shown)
        p.search:SetText("[%") -- Lua patterns must never be evaluated.
        assert(p.empty.shown and p.result.text=="0 designs")
        S:ShowCollection(case[2],"CLASS",1);assert(p.search:GetText()=="")
        p.search:SetText("priest");S[case[4]].CLASS_PRIEST.scripts.OnClick()
        assert(not p.shown)
        local c=J.ThemeManager:Resolve(case[1]);assert(c[case[2].."Mode"]=="FIXED" and c[case[2]]=="CLASS_PRIEST")
        for _,b in pairs(S[case[4]]) do assert(not b.image.path) end
    end
    assert(not next(J.Core.notices))
end)

test("settings backups respect read-only profiles and combat queuing",function(M)
    local J=M.load({db={phase1={version=99}}});local S=J.SettingsUI;S:Open();S:ShowBackup("import")
    S.backupEdit:SetText("JF2;paladin_ret;playerFrame.x=10");S.restoreButton.scripts.OnClick()
    assert(not J.ProfileManager.writable and S.backupDialog.shown and JiberishUIDB.phase1.version==99)
    J=M.load();S=J.SettingsUI;S:Open();M.combat=true
    local before=J.Core.modules.playerFrame.applied.x
    S:ShowBackup("import");S.backupEdit:SetText("JF2;paladin_ret;playerFrame.x=10");S.restoreButton.scripts.OnClick()
    assert(J.Core.dirty and J.Core.modules.playerFrame.applied.x==before)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(J.Core.modules.playerFrame.applied.x==10)
end)

test("cast page exposes both strata and its separate level",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:SetPage("cast")
    assert(S.controls.castBarStrata.button:IsVisible())
    assert(S.controls.castBarLevel.edit:IsVisible())
    S:SetPage("advanced");assert(not S.controls.castBarLevel.edit:IsVisible())
    S:Select("actionHub");assert(not S.controls.castBarLevel.edit:IsVisible())
end)
