local test=...

test("steady artwork updates bound transient allocations without accumulating frames",function(M)
    local J=M.load({stockStone=true});M.event(J.Core,"PLAYER_ENTERING_WORLD");J.Setup:Dismiss()
    for _,key in ipairs({"playerFrame","targetFrame"}) do J.ProfileManager:Set(key,"unitFrameShown",true) end
    for i=1,10 do M.tick(J.Core) end
    local objects,textures=#M.objects,M.textures
    collectgarbage("collect");local base=collectgarbage("count");collectgarbage("stop")
    for i=1,200 do M.tick(J.Core) end
    local allocated=collectgarbage("count")-base
    collectgarbage("restart");collectgarbage("collect")
    assert(allocated<200*90,"Repeated settings copies increased idle allocation")
    assert(collectgarbage("count")-base<64,"Idle passes retain growing state")
    assert(#M.objects==objects and M.textures==textures)
    assert(not J.ThemeManager.readPass and not next(J.Core.notices))
end)

test("read-only pass settings never leak layout mutations or survive profile changes",function(M)
    local J=M.load();local T=J.ThemeManager
    T.readPass={};local r=T:Read("playerFrame");assert(T:Read("playerFrame")==r)
    local copy=T:Resolve("playerFrame");copy.width=999
    assert(T:Read("playerFrame").width~=999)
    T.readPass=nil
    assert(J.ProfileManager:Set("playerFrame","width",170));assert(T:Read("playerFrame").width==170)
    J.ProfileManager:SaveAs("Performance",false)
    assert(J.ProfileManager:Set("playerFrame","width",180));assert(T:Read("playerFrame").width==180)
    assert(not T.readPass and not next(J.Core.notices))
end)

test("settings defer artwork browsers and release thumbnails when closed",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open()
    assert(not S.picker and not S.hubPicker and not S.minimapPicker and not S.castPicker and not S.unitPicker)
    S.portraitButton.scripts.OnClick();assert(S.picker:IsShown())
    assert(not S.hubPicker and not S.minimapPicker and not S.castPicker and not S.unitPicker)
    local objects=#M.objects
    S:HideMenus()
    for _,b in pairs(S.portraitButtons) do assert(not b.image.path) end
    S.portraitButton.scripts.OnClick();assert(#M.objects==objects)
    assert(not next(J.Core.notices))
end)

test("native fill animation does not repaint or refit unrelated artwork",function(M)
    local J=M.load({stockStone=true});local C=J.Core;local bar=C.client:UnitBars("playerFrame").health
    M.tick(C)
    local layouts=0;local apply=C.Apply
    C.Apply=function(self,...) layouts=layouts+1;return apply(self,...) end
    bar.fill:SetTexCoord(0,.5,0,1)
    local writes=M.appearanceWrites
    M.tick(C)
    assert(layouts==0 and M.appearanceWrites==writes,"Live UVs must remain under the StatusBar's control")
    bar.fill:SetAtlas("Native-Changed-Health")
    M.tick(C)
    assert(layouts==0 and bar.fill.path==J.Media.stone,"Real asset changes still restore the chosen material")
    J.ProfileManager:Set("playerFrame","blizzardStone",false)
    assert(bar.fill.atlas=="Native-Changed-Health")
    assert(not next(C.notices))
end)

test("target changes still refresh the visible settings artwork preview",function(M)
    local J=M.load();J.SettingsUI:Open();J.SettingsUI:Select("targetFrame")
    M.unitData.target.class="DRUID";M.event(J.Core,"PLAYER_TARGET_CHANGED")
    assert(J.SettingsUI.themePreview.path==J.PortraitCatalog.entries.CLASS_DRUID.texture)
    assert(not next(J.Core.notices))
end)
