local test=...

test("stone and its legacy alias register once with optional SharedMedia and no skin enabled",function(M)
    local calls,media=0,{}
    local library={Register=function(_,kind,name,path)
        calls=calls+1;assert(kind=="statusbar");media[name]=path;return true
    end}
    LibStub=setmetatable({}, {__call=function(_,name,silent)
        assert(name=="LibSharedMedia-3.0" and silent);return library
    end})
    local J=M.load()
    assert(media["Frostforge Stone"]==media["JiberishUI Stone"])
    assert(media["JiberishUI Stone"]==J.UnitSkinCatalog.entries.CLASS_PALADIN.health)
    assert(not next(J.UnitSkins.units) and not M.appearanceWrites)
    for i=1,10 do M.event(J.Core,"ADDON_LOADED","OtherAddon") end
    assert(calls==2 and not next(J.Core.notices))
end)

test("SharedMedia may arrive late or be absent without affecting artwork",function(M)
    local J=M.load();assert(not J.Media.sharedLibrary)
    LibStub=function() error("Not ready") end
    M.event(J.Core,"ADDON_LOADED","OtherAddon")
    assert(not next(J.Core.notices))
    local calls=0
    local library={Register=function(_,kind,name,path) calls=calls+1;return true end}
    LibStub=function() return library end
    M.event(J.Core,"ADDON_LOADED","LibSharedMedia-3.0")
    assert(calls==2 and J.Media.sharedLibrary==library)
end)

test("provider fill mode keeps Blizzard shell and restores native materials",function(M)
    local J=M.load();local h=J.Core.client:UnitBars("playerFrame").health
    local atlas=h.fill.atlas
    J.ProfileManager:Set("playerFrame","unitFrameShown",true)
    assert(J.UnitSkins.units.playerFrame.health.active)
    J.SettingsUI:Open();J.SettingsUI:SetPage("advanced")
    J.SettingsUI.controls.unitFrameFill.options.PROVIDER.scripts.OnClick()
    local record=J.UnitSkins.units.playerFrame.health
    assert(record.trim.frame.shown and not record.active and h.fill.atlas==atlas)
    local writes=M.appearanceWrites
    for i=1,10 do M.tick(J.Core) end
    assert(writes==M.appearanceWrites)
    assert(not J.ProfileManager:Set("actionHub","unitFrameFill","PROVIDER"))
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset();J.ProfileManager:Import(backup)
    assert(J.ThemeManager:Resolve("playerFrame").unitFrameFill=="PROVIDER")
    assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown and h.fill.atlas==atlas)
end)
