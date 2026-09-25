local test,near=...
local function unit(M,parent)
    local frame=M.region(parent,"Frame",100,40)
    for _,key in ipairs({"healthBar","powerBar"}) do
        local bar=M.region(frame,"Frame",100,16)
        bar.fill=M.region(bar,"Texture",100,16);bar.fill.fillTexture=true
        bar.fill.atlas="Stock-"..key;bar.fill.path="stock";bar.fill.texCoord={0,0,0,1,1,0,1,1}
        frame[key]=bar
    end
    return frame
end
for _,interface in ipairs({120100,16001}) do
    test("stock stone covers pooled party compact raid pets and all main bars on "..interface,function(M)
        PartyFrame=M.native("PartyFrame",100,100)
        local party=unit(M,PartyFrame);party.PetFrame=unit(M,party)
        PartyFrame.PartyMemberFramePool={EnumerateActive=function() return next,{[party]=true} end}
        CompactPartyFrame=M.native("CompactPartyFrame",100,100)
        local compact=unit(M,CompactPartyFrame);CompactPartyFrame.memberUnitFrames={compact}
        local pet=unit(M,CompactPartyFrame);CompactPartyFrame.petUnitFrames={pet}
        CompactRaidFrameContainer=M.native("CompactRaidFrameContainer",100,100)
        local raid=unit(M,CompactRaidFrameContainer);local mini=unit(M,CompactRaidFrameContainer)
        CompactRaidFrameContainer.ApplyToFrames=function(_,which,callback)
            assert(which=="all");callback(raid);callback(mini)
        end
        PetFrame=unit(M,UIParent);TargetFrameToT=unit(M,UIParent);FocusFrameToT=unit(M,UIParent)
        Boss1TargetFrame=unit(M,UIParent)
        local unrelated=unit(M,UIParent)
        local J=M.load({interface=interface,stockStone=true})
        for _,frame in ipairs({party,party.PetFrame,compact,pet,raid,mini,PetFrame,TargetFrameToT,FocusFrameToT,Boss1TargetFrame}) do
            for _,kind in ipairs({"healthBar","powerBar"}) do assert(frame[kind].fill.path==J.Media.stone) end
        end
        for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
            for _,bar in pairs(J.Core.client:UnitBars(key)) do assert(bar.fill.path==J.Media.stone) end
        end
        assert(unrelated.healthBar.fill.path=="stock" and not next(J.UnitSkins.units))
        local writes=M.appearanceWrites
        for i=1,5 do M.tick(J.Core) end
        assert(M.appearanceWrites==writes)
        J.ProfileManager:Set("playerFrame","blizzardStone",false)
        assert(party.healthBar.fill.atlas=="Stock-healthBar" and raid.powerBar.fill.atlas=="Stock-powerBar")
        assert(not next(J.UnitSkins.stockRecords) and not next(J.Core.notices))
    end)
end

test("stock stone hands texture ownership to and from full shells without stale restore",function(M)
    local J=M.load({stockStone=true});local bars=J.Core.client:UnitBars("playerFrame")
    local original=J.UnitSkins.stockRecords[bars.health].original
    J.ProfileManager:Set("playerFrame","unitFrameShown",true)
    assert(not J.UnitSkins.units.playerFrame.health.active and bars.power.fill.path==J.Media.stone)
    J.ProfileManager:Set("playerFrame","blizzardStone",false)
    assert(J.UnitSkins.units.playerFrame.health.active and not next(J.UnitSkins.stockRecords))
    J.ProfileManager:Set("playerFrame","blizzardStone",true)
    assert(not J.UnitSkins.units.playerFrame.health.active and bars.power.fill.path==J.Media.stone)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    assert(bars.health.fill.path==J.Media.stone)
    J.ProfileManager:Set("playerFrame","blizzardStone",false)
    assert(bars.health.fill.atlas==original.atlas)
end)

test("stock stone observes redraw and new raid bars without writes in combat",function(M)
    local J=M.load({stockStone=true});local h=J.Core.client:UnitBars("playerFrame").health
    M.combat=true;local writes=M.appearanceWrites
    CompactRaidFrameContainer=M.native("CompactRaidFrameContainer",100,100)
    local raid=unit(M,CompactRaidFrameContainer)
    CompactRaidFrameContainer.ApplyToFrames=function(_,_,callback) callback(raid) end
    M.tick(J.Core);assert(raid.healthBar.fill.path=="stock" and M.appearanceWrites==writes)
    J.ProfileManager:Set("playerFrame","blizzardStone",false)
    assert(h.fill.path==J.Media.stone)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(h.fill.atlas)
    J.ProfileManager:Set("playerFrame","blizzardStone",true)
    assert(raid.healthBar.fill.path==J.Media.stone)
    h.fill:SetAtlas("New-vehicle-atlas");M.tick(J.Core);assert(h.fill.path==J.Media.stone)
    J.ProfileManager:Set("playerFrame","blizzardStone",false);assert(h.fill.atlas=="New-vehicle-atlas")
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset("playerFrame");assert(J.ProfileManager:Import(backup))
    assert(not J.ThemeManager:Resolve("playerFrame").blizzardStone)
    assert(not J.ProfileManager:Set("targetFrame","blizzardStone",true))
end)
