local test,near=...
for _,interface in ipairs({120100,16001}) do
    test("Frostforge branding and website navigation preserve profiles on client "..interface,function(M)
        local J=M.load({interface=interface});local S=J.SettingsUI;S:Open()
        local before=J.ProfileManager:Export()
        assert(S.crest.path==J.Media.logo and S.crest.texCoord[2]==1)
        assert(SLASH_JIBERISHFANTASY4=="/frostforge" and SLASH_JIBERISHFANTASY2=="/jui")
        S.websiteButton.scripts.OnClick()
        assert(S.pages.website:IsVisible() and not S.pages.artwork:IsVisible())
        assert(not S.resetButton:IsVisible() and not S.pageButtons.artwork:IsVisible())
        assert(S.websiteButton.selection:IsVisible() and not S.tabs.playerFrame.selection:IsVisible())
        S.websiteCopyButton.scripts.OnClick()
        assert(S.websiteEdit:HasFocus() and S.websiteEdit:GetText()=="https://theigloo.io")
        S.websiteEdit:SetText("accidental edit")
        assert(S.websiteEdit:GetText()==J.Brand.website)
        S.websiteEdit.scripts.OnEscapePressed();assert(not S.websiteEdit:HasFocus())
        S.websiteCopyButton.scripts.OnClick();S:SetPage("profiles")
        assert(not S.websiteEdit:HasFocus() and not S.pages.website:IsVisible() and S.pages.profiles:IsVisible())
        S:SetPage("website");S:Select("targetFrame")
        assert(S.page=="artwork" and S.pageButtons.artwork:IsVisible() and S.crest.path==J.Media.logo)
        S:Select("minimap");assert(S.crest.path==J.Media.logo)
        S:SetPage("website");S.websiteCopyButton.scripts.OnClick();S.frame:Hide()
        assert(not S.websiteEdit:HasFocus() and J.ProfileManager:Export()==before)
        assert(not next(J.Core.notices))
    end)
end

test("frosted stone buttons keep white labels and reset hover and pressed states",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open()
    local b=S.pageButtons.artwork
    assert(b.up.desaturated and b.up.color[3]>b.up.color[1])
    assert(b.caption.color[1]==1 and b.caption.color[2]==1 and b.caption.color[3]==1)
    b.scripts.OnEnter();b.scripts.OnMouseDown();assert(b.hover.shown and b.down.shown)
    b.scripts.OnMouseUp();assert(not b.down.shown and b.hover.shown)
    b.scripts.OnMouseDown();b.scripts.OnLeave();assert(not b.down.shown and not b.hover.shown)
    b.scripts.OnEnter();b.scripts.OnMouseDown();b:Hide();assert(not b.down.shown and not b.hover.shown)
    for _,o in ipairs(M.objects) do
        if o.path and o.path:find("UI-Panel-Button-",1,true) then
            assert(o.desaturated and o.color[3]>o.color[1])
        end
    end
end)

test("chosen buttons keep their frost outline after hover and follow actual settings",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open()
    local active=S.pageButtons.artwork
    active.scripts.OnEnter();active.scripts.OnLeave()
    assert(active.selection:IsShown() and not active.hover:IsShown())
    S.pageButtons.placement.scripts.OnClick()
    assert(not active.selection:IsShown() and S.pageButtons.placement.selection:IsShown())
    S:SetPage("artwork")
    local toggle=S.showButton
    assert(toggle.selection:IsShown() and toggle.check:IsShown())
    toggle.scripts.OnClick();toggle.scripts.OnEnter();toggle.scripts.OnLeave()
    assert(not toggle.selection:IsShown() and not toggle.check:IsShown())
    toggle.scripts.OnClick()
    assert(toggle.selection:IsShown() and toggle.check:IsShown())
    local dropdown=S.controls.portraitMode
    dropdown.button.scripts.OnClick()
    assert(dropdown.button.selection:IsShown() and dropdown.options.CLASS.selection:IsVisible())
    dropdown.options.FIXED.scripts.OnClick()
    assert(not dropdown.button.selection:IsShown())
    dropdown.button.scripts.OnClick()
    assert(dropdown.options.FIXED.selection:IsVisible() and not dropdown.options.CLASS.selection:IsShown())
    S:HideMenus();assert(not dropdown.button.selection:IsShown())
    S.frame:Hide();S:Open()
    assert(toggle.selection:IsVisible() and not toggle.hover:IsShown())
    assert(not next(J.Core.notices))
end)

for _,interface in ipairs({120100,16001}) do
    test("settings pages isolate advanced controls and preserve unsaved input on client "..interface,function(M)
        local J=M.load({interface=interface});local S=J.SettingsUI;S:Open()
        local original=J.ProfileManager:Export()
        assert(S.showButton:IsVisible() and not S.controls.width.edit:IsVisible() and not S.debugButton:IsVisible())
        S.pageButtons.placement.scripts.OnClick()
        assert(S.controls.portraitSize.edit:IsVisible() and not S.controls.width.edit:IsVisible() and not S.showButton:IsVisible())
        local edit=S.controls.portraitSize.edit;edit:SetFocus();edit:SetText("222")
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
        S:Select(case[1]);S:ShowCollection(case[2],"RACE",3)
        local p=S[case[3]];p:Show()
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
