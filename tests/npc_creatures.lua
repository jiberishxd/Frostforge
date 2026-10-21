local test=...
local function npc(M,unit,typeID,name)
    M.unitData[unit]={player=false,controlled=false,class="WARRIOR",faction="Neutral",
        creatureTypeID=typeID,creatureType=name,guid="Creature-0-1-0-0-9000001-1"}
end

for _,interface in ipairs({120100,16001}) do
    test("all ten NPC creature types select paired artwork on client "..interface,function(M)
        npc(M,"target",1,"Beast");npc(M,"focus",3,"Demon")
        local J=M.load({interface=interface})
        J.ProfileManager:Set("targetFrame","unitFrameShown",true)
        local seen={}
        for typeID,id in pairs(J.PortraitCatalog.creatures) do
            M.unitData.target.creatureTypeID=typeID;M.event(J.Core,"PLAYER_TARGET_CHANGED")
            assert(J.Core.modules.targetFrame.portraitID==id)
            local skin=J.UnitSkins.units.targetFrame
            assert(skin.health.id==id and skin.power.id==id)
            for _,texture in pairs(skin.health.trim.textures) do assert(texture.path==J.UnitSkinCatalog.entries[id].shell) end
            assert(J.PortraitCatalog.entries[id].group=="CREATURE")
            assert(not seen[J.PortraitCatalog.entries[id].texture]);seen[J.PortraitCatalog.entries[id].texture]=true
        end
        assert(J.Core.modules.focusFrame.portraitID=="CREATURE_DEMON")
        assert(J.Core.modules.playerFrame.portraitID=="CLASS_PALADIN")
        assert(not next(J.Core.notices))
    end)

    test("creature combat swaps repaint both decorations without refitting on client "..interface,function(M)
        npc(M,"target",1,"Beast");local J=M.load({interface=interface})
        J.ProfileManager:Set("targetFrame","unitFrameShown",true)
        local geometry,appearance,objects=M.geometryWrites,M.appearanceWrites,#M.objects
        M.combat=true
        for _,typeID in ipairs({3,6,9,14,1}) do
            M.unitData.target.creatureTypeID=typeID;M.event(J.Core,"PLAYER_TARGET_CHANGED")
            local id=J.PortraitCatalog.creatures[typeID]
            assert(J.Core.modules.targetFrame.portraitID==id and J.UnitSkins.units.targetFrame.health.id==id)
        end
        assert(M.geometryWrites==geometry and M.appearanceWrites==appearance and #M.objects==objects)
        local writes=M.writes
        for i=1,10 do M.tick(J.Core) end
        assert(M.writes==writes and not next(J.Core.notices))
    end)
end

test("fixed and city art outrank creatures while players and controlled pets retain behavior",function(M)
    npc(M,"target",6,"Undead");local J=M.load()
    for _,mode in ipairs({"CLASS","RACE","FACTION"}) do
        J.ProfileManager:Set("targetFrame","portraitMode",mode)
        assert(J.Core.modules.targetFrame.portraitID=="CREATURE_UNDEAD")
    end
    M.unitData.target.guid="Creature-0-1-0-0-68-1";M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="RACE_HUMAN")
    J.ProfileManager:Set("targetFrame","portrait","CREATURE_MECHANICAL")
    J.ProfileManager:Set("targetFrame","portraitMode","FIXED")
    assert(J.Core.modules.targetFrame.portraitID=="CREATURE_MECHANICAL")
    J.ProfileManager:Set("targetFrame","portraitMode","CLASS")
    M.unitData.target.player=true;M.unitData.target.class="MAGE";M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="CLASS_MAGE")
    npc(M,"target",1,"Beast");M.unitData.target.controlled=true;M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    M.unitData.target.controlled=M.secret;M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
end)

test("numeric creature IDs work in any locale and legacy labels use client localization",function(M)
    npc(M,"target",1,"Wildtier");local J=M.load()
    assert(J.Core.modules.targetFrame.portraitID=="CREATURE_BEAST")
    M.unitData.target.creatureTypeID=nil
    C_CreatureInfo={GetCreatureTypeInfo=function(id) if id==1 then return {name="Wildtier"} end end}
    M.tick(J.Core);assert(J.Core.modules.targetFrame.portraitID=="CREATURE_BEAST")
    M.unitData.target.creatureType="Demon";M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="CREATURE_DEMON")
    M.unitData.target.creatureType="Unknown";M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
end)

test("unavailable unknown and restricted creature data clear stale art safely",function(M)
    npc(M,"target",1,"Beast");local J=M.load()
    for _,values in ipairs({{M.secret,"Beast"},{1,M.secret},{999,"Beast"},{0,"Beast"},{false,"Unknown"}}) do
        M.unitData.target.creatureTypeID=values[1];M.unitData.target.creatureType=values[2]
        M.tick(J.Core);assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    end
    UnitCreatureType=function() error("unavailable") end;M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    UnitCreatureType=nil;M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL" and not next(J.Core.notices))
end)

test("creature choices and opt-out survive backups while unsupported components reject them",function(M)
    npc(M,"target",1,"Beast");local J=M.load();local P=J.ProfileManager
    assert(P:Set("targetFrame","npcArtwork",false))
    assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    assert(not P:Set("minimap","npcArtwork",true) and not P:Set("actionHub","npcArtwork",true))
    assert(not P:Set("targetFrame","portrait","CREATURE_FAKE"))
    P:Set("focusFrame","portrait","CREATURE_DRAGONKIN");P:Set("focusFrame","portraitMode","FIXED")
    local backup=P:Export();assert(backup:find("npcArtwork=false",1,true))
    P:Reset();assert(J.Core.modules.targetFrame.portraitID=="CREATURE_BEAST")
    assert(P:Import(backup))
    assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    assert(J.Core.modules.focusFrame.portraitID=="CREATURE_DRAGONKIN")
    local nextJ=M.load({db=JiberishUIDB})
    assert(nextJ.ThemeManager:Resolve("targetFrame").npcArtwork==false)
end)

test("creature gallery selects fixed art and matching toggle stays scoped to the selected unit",function(M)
    npc(M,"target",1,"Beast");local J=M.load();local S=J.SettingsUI;S:Open();S:Select("targetFrame")
    assert(S.npcArtworkToggle:IsVisible() and not S.modeHelp:IsVisible())
    S.npcArtworkToggle.scripts.OnClick();assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    assert(J.ThemeManager:Resolve("focusFrame").npcArtwork)
    S.portraitButton.scripts.OnClick();S:ShowPortraitGroup("CREATURE")
    assert(S.picker.result:GetText()=="10 designs" and S.portraitButtons.CREATURE_BEAST:IsVisible())
    S.portraitButtons.CREATURE_ABERRATION.scripts.OnClick()
    assert(J.Core.modules.targetFrame.portraitID=="CREATURE_ABERRATION")
    S.unitBrowse.scripts.OnClick();S:ShowCollection("unit","CREATURE")
    assert(S.unitButtons.CREATURE_BEAST.image.path==J.UnitSkinCatalog.entries.CREATURE_BEAST.shell)
    S.unitButtons.CREATURE_BEAST.scripts.OnClick()
    assert(J.Core.modules.targetFrame.portraitID=="CREATURE_BEAST")
    S:Select("minimap");assert(not S.npcArtworkToggle:IsVisible() and S.modeHelp:IsVisible())
    S:Select("playerFrame");assert(not S.npcArtworkToggle:IsVisible())
    assert(not next(J.Core.notices))
end)
