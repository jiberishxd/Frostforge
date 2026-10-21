local test=...
local ids={"SEASONAL_HARVEST_HOLLOW","SEASONAL_WITCHING_HOUR","SEASONAL_HALLOWS_END","SEASONAL_HOLLY_HEARTH","SEASONAL_WINTER_STARLIGHT","SEASONAL_WINTER_VEIL","SEASONAL_WINTER_VEIL_HORDE"}

for _,interface in ipairs({120100,16001}) do
    test("seasonal sets select all four matching components on client "..interface,function(M)
        local J=M.load({interface=interface});local P=J.ProfileManager
        P:Set("targetFrame","unitFrameShown",true)
        for _,id in ipairs(ids) do
            for _,catalog in ipairs({J.PortraitCatalog,J.HubCatalog,J.MinimapCatalog}) do
                assert(catalog.entries[id].group=="SEASONAL")
            end
            assert(P:Set("targetFrame","portrait",id));assert(P:Set("targetFrame","portraitMode","FIXED"))
            assert(P:Set("actionHub","hub",id));assert(P:Set("actionHub","hubMode","FIXED"))
            assert(P:Set("minimap","minimap",id));assert(P:Set("minimap","minimapMode","FIXED"))
            assert(J.Core.modules.targetFrame.portraitID==id and J.UnitSkins.units.targetFrame.health.id==id)
            assert(J.Core.modules.actionHub.hubID==id and J.Core.modules.minimap.minimapID==id)
            for _,texture in pairs(J.UnitSkins.units.targetFrame.health.trim.textures) do
                assert(texture.path==J.UnitSkinCatalog.entries[id].shell)
            end
            local entry=J.UnitSkinCatalog.entries[id]
            assert(entry.castInsets==J.UnitSkinCatalog.entries[entry.castTheme].castInsets)
        end
        -- A seasonal choice is explicit and never changes unrelated units.
        assert(J.Core.modules.playerFrame.portraitID=="CLASS_PALADIN")
        assert(J.Core.modules.focusFrame.portraitID=="CLASS_MAGE")
        assert(not next(J.Core.notices))
    end)
end

test("Seasonal galleries expose seven options with holiday and faction search",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open()
    local cases={
        {"targetFrame","portrait","picker","portraitButtons","portraitMode","portrait"},
        {"focusFrame","unit","unitPicker","unitButtons","portraitMode","portrait"},
        {"actionHub","hub","hubPicker","hubButtons","hubMode","hub"},
        {"minimap","minimap","minimapPicker","minimapButtons","minimapMode","minimap"},
    }
    for _,case in ipairs(cases) do
        S:Select(case[1]);S:ShowCollection(case[2],"SEASONAL");S[case[3]]:Show()
        assert(S[case[3]].result:GetText()=="7 designs")
        S[case[3]].search:SetText("Halloween")
        assert(S[case[3]].result:GetText()=="3 designs")
        assert(S[case[4]].SEASONAL_HARVEST_HOLLOW:IsVisible())
        assert(S[case[4]].SEASONAL_HALLOWS_END:IsVisible())
        assert(not S[case[4]].SEASONAL_HOLLY_HEARTH:IsVisible())
        S[case[3]].search:SetText("Christmas")
        assert(S[case[3]].result:GetText()=="4 designs")
        assert(S[case[4]].SEASONAL_WINTER_VEIL:IsVisible())
        assert(S[case[4]].SEASONAL_WINTER_VEIL_HORDE:IsVisible())
        S[case[3]].search:SetText("Hallow's End")
        assert(S[case[3]].result:GetText()=="1 designs")
        assert(S[case[4]].SEASONAL_HALLOWS_END:IsVisible())
        S[case[3]].search:SetText("Winter Veil")
        assert(S[case[3]].result:GetText()=="2 designs")
        S[case[3]].search:SetText("Alliance")
        assert(S[case[3]].result:GetText()=="1 designs")
        assert(S[case[4]].SEASONAL_WINTER_VEIL:IsVisible())
        assert(not S[case[4]].SEASONAL_WINTER_VEIL_HORDE:IsVisible())
        S[case[3]].search:SetText("Horde")
        assert(S[case[3]].result:GetText()=="1 designs")
        assert(not S[case[4]].SEASONAL_WINTER_VEIL:IsVisible())
        S[case[4]].SEASONAL_WINTER_VEIL_HORDE.scripts.OnClick()
        local config=J.ThemeManager:Resolve(case[1])
        assert(config[case[5]]=="FIXED" and config[case[6]]=="SEASONAL_WINTER_VEIL_HORDE")
        for _,button in pairs(S[case[4]]) do assert(button.image.path==nil) end
    end
    S:ShowCollection("cast","CLASS");S:ShowCollection("small","CLASS")
    assert(not S.castGroupButtons.SEASONAL and not S.smallGroupButtons.SEASONAL)
    assert(not S.castButtons.SEASONAL_HARVEST_HOLLOW and not S.smallButtons.SEASONAL_HARVEST_HOLLOW)
end)

test("seasonal selections survive backups and defer combat configuration changes",function(M)
    local J=M.load();local P=J.ProfileManager
    M.combat=true
    assert(P:Set("targetFrame","portrait","SEASONAL_HARVEST_HOLLOW"))
    assert(P:Set("targetFrame","portraitMode","FIXED"))
    assert(P:Set("actionHub","hub","SEASONAL_HOLLY_HEARTH"))
    assert(P:Set("actionHub","hubMode","FIXED"))
    assert(P:Set("minimap","minimap","SEASONAL_WITCHING_HOUR"))
    assert(P:Set("minimap","minimapMode","FIXED"))
    assert(J.Core.modules.targetFrame.portraitID=="CLASS_ROGUE")
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(J.Core.modules.targetFrame.portraitID=="SEASONAL_HARVEST_HOLLOW")
    assert(J.Core.modules.actionHub.hubID=="SEASONAL_HOLLY_HEARTH")
    assert(J.Core.modules.minimap.minimapID=="SEASONAL_WITCHING_HOUR")
    local backup=P:Export();P:Reset();assert(P:Import(backup))
    local nextJ=M.load({db=JiberishUIDB})
    assert(nextJ.Core.modules.targetFrame.portraitID=="SEASONAL_HARVEST_HOLLOW")
    assert(nextJ.Core.modules.actionHub.hubID=="SEASONAL_HOLLY_HEARTH")
    assert(nextJ.Core.modules.minimap.minimapID=="SEASONAL_WITCHING_HOUR")
    assert(not next(nextJ.Core.notices))
end)
