local test,near=...
local function npc(M,unit,affiliation,guid)
    M.unitData[unit]={player=false,controlled=false,class="WARRIOR",race="Human",faction="Neutral",guid=guid or "Creature-0-1-0-0-9000001-1"}
    M.tooltips=M.tooltips or {}
    M.tooltips[unit]={lines={{type=2,leftText="NPC name"},{type=0,leftText="Level 60"},{type=0,leftText=affiliation}}}
    C_TooltipInfo={GetUnit=function(u,hideStatus)
        assert(hideStatus==true);M.tooltipReads=(M.tooltipReads or 0)+1
        return M.tooltips[u]
    end}
end

for _,interface in ipairs({120100,16001}) do
    test("city NPCs share existing portrait and shell artwork on client "..interface,function(M)
        npc(M,"target","Undercity");npc(M,"focus","Stormwind")
        local J=M.load({interface=interface})
        for _,city in ipairs(J.NPCCities) do
            npc(M,"target",city.name,"Creature-0-1-0-0-"..city.factionID.."-1")
            M.tick(J.Core)
            assert(J.Core.modules.targetFrame.portraitID==city.artwork)
            J.ProfileManager:Set("targetFrame","unitFrameShown",true)
            assert(J.UnitSkins.units.targetFrame.health.id==city.artwork)
            J.ProfileManager:Set("targetFrame","shown",false)
            assert(not J.Core.modules.targetFrame.frame.shown and J.UnitSkins.units.targetFrame.health.trim.frame.shown)
            J.ProfileManager:Set("targetFrame","shown",true)
        end
        assert(J.Core.modules.focusFrame.portraitID=="RACE_HUMAN")
        assert(J.Core.modules.playerFrame.portraitID=="CLASS_PALADIN")
        assert(not next(J.Core.notices))
    end)
end

test("city affiliation outranks NPC race in automatic modes but fixed choices win",function(M)
    npc(M,"target","Undercity");local J=M.load()
    for _,mode in ipairs({"CLASS","RACE","FACTION"}) do
        J.ProfileManager:Set("targetFrame","portraitMode",mode)
        assert(J.Core.modules.targetFrame.portraitID=="RACE_SCOURGE")
    end
    J.ProfileManager:Set("targetFrame","portrait","CLASS_MAGE")
    J.ProfileManager:Set("targetFrame","portraitMode","FIXED")
    assert(J.Core.modules.targetFrame.portraitID=="CLASS_MAGE")
    assert(not next(J.Core.notices))
end)

test("city affiliation names use modern and legacy client localization",function(M)
    npc(M,"target","|cffaaaaaaFossoyeuse|r")
    C_Reputation={GetFactionDataByID=function(id) return id==68 and {name="Fossoyeuse"} or nil end}
    local J=M.load();assert(J.Core.modules.targetFrame.portraitID=="RACE_SCOURGE")
    C_Reputation=nil;GetFactionInfoByID=function(id) if id==72 then return "Sturmwind" end end
    M.time=31;npc(M,"target","  Sturmwind  ","Creature-0-1-0-0-68-2");M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="RACE_HUMAN")
    assert(not next(J.Core.notices))
end)

test("players pets vehicles and controlled NPCs do not inherit city art",function(M)
    npc(M,"target","Undercity");M.unitData.target.player=true;M.unitData.target.class="ROGUE"
    local J=M.load();assert(J.Core.modules.targetFrame.portraitID=="CLASS_ROGUE")
    assert(not M.tooltipReads)
    M.unitData.target.player=false
    for _,guid in ipairs({"Player-1-123","Pet-0-1-0-0-5624-1","Vehicle-0-1-0-0-5624-1"}) do
        M.unitData.target.guid=guid;M.tick(J.Core)
        assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    end
    M.unitData.target.guid="Creature-0-1-0-0-5624-1";M.unitData.target.controlled=true;M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL" and not M.tooltipReads)
    assert(not next(J.Core.notices))
end)

test("unknown NPC affiliations stay neutral without guessing from name or zone",function(M)
    npc(M,"target","Argent Dawn");local J=M.load()
    assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    M.tooltips.target.lines={{type=2,leftText="Undercity"},{type=17,leftText="Stormwind"},{type=0,leftText="Ironforge Expedition"}}
    M.time=1;M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    assert(not next(J.Core.notices))
end)

test("city tooltip cache is bounded and invalidates on target identity changes",function(M)
    npc(M,"target","Undercity");local J=M.load();J.ProfileManager:Set("targetFrame","unitFrameShown",true)
    local reads=M.tooltipReads
    for i=1,10 do M.tick(J.Core) end
    assert(M.tooltipReads==reads)
    npc(M,"target","Stormwind","Creature-0-1-0-0-68-2");M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="RACE_HUMAN" and M.tooltipReads==reads+1)
    M.time=.51;M.tooltips.target.lines[3].leftText="Orgrimmar";M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="RACE_ORC")
    assert(not next(J.Core.notices))
end)

test("secret or unavailable NPC metadata never leaks or retains stale artwork",function(M)
    npc(M,"target","Undercity");local J=M.load()
    assert(J.Core.modules.targetFrame.portraitID=="RACE_SCOURGE")
    M.unitData.target.guid=M.secret;M.tick(J.Core);assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    M.unitData.target.guid="Creature-0-1-0-0-9000001-1"
    for _,data in ipairs({M.secret,{lines=M.secret},{lines={{},M.secret}},{lines={{},{type=0,leftText=M.secret}}},{lines={{},{type=M.secret,leftText="Undercity"}}}}) do
        M.tooltips.target=data;M.time=(M.time or 0)+1;M.tick(J.Core)
        assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    end
    C_TooltipInfo.GetUnit=function() error("Unavailable") end
    M.time=M.time+1;M.tick(J.Core);assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    C_TooltipInfo=nil;M.time=M.time+1;M.tick(J.Core)
    assert(not next(J.Core.notices))
end)

test("city portrait changes respect protected combat artwork and defer native fills",function(M)
    npc(M,"target","Undercity");local J=M.load();J.ProfileManager:Set("targetFrame","unitFrameShown",true)
    local portrait=J.Core.modules.targetFrame;portrait.frame.protected=true
    M.combat=true;local writes=M.appearanceWrites;local layout=M.nativeLayoutWrites
    npc(M,"target","Stormwind","Creature-0-1-0-0-68-2");M.event(J.Core,"PLAYER_TARGET_CHANGED")
    assert(portrait.portraitID=="RACE_SCOURGE" and writes==M.appearanceWrites and layout==M.nativeLayoutWrites)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(portrait.portraitID=="RACE_HUMAN" and J.UnitSkins.units.targetFrame.health.id=="RACE_HUMAN")
    assert(not next(J.Core.notices))
end)

test("known city guards keep city art when affiliation tooltips are absent",function(M)
    npc(M,"target",nil);C_TooltipInfo=nil
    local J=M.load()
    for id,art in pairs(J.NPCCityGuards) do
        M.unitData.target.guid="Creature-0-1-0-0-"..id.."-1";M.tick(J.Core)
        assert(J.Core.modules.targetFrame.portraitID==art)
    end
    M.unitData.target.guid="Creature-malformed-5624";M.tick(J.Core)
    assert(J.Core.modules.targetFrame.portraitID=="FACTION_NEUTRAL")
    assert(not next(J.Core.notices))
end)
