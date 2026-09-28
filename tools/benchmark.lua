-- Offline comparison, NOT WoW's CPU profiler or graphics-memory accounting.
-- Usage: lua tools/benchmark.lua [addon directory] [iterations]
local directory=arg[1] or "Frostforge"
local iterations=tonumber(arg[2]) or 1000
local M=dofile("tests/mock_wow.lua")
local J=M.load({addonDirectory=directory,stockStone=true})
M.event(J.Core,"PLAYER_ENTERING_WORLD");J.Setup:Dismiss()
for _,key in ipairs({"playerFrame","targetFrame"}) do J.ProfileManager:Set(key,"unitFrameShown",true) end
local function measure(name,run)
    for i=1,10 do run(i) end
    collectgarbage("collect")
    local base=collectgarbage("count")
    collectgarbage("stop") -- benchmark only, so transient allocations can be measured
    local start=os.clock()
    for i=1,iterations do run(i) end
    local seconds,allocated=os.clock()-start,collectgarbage("count")-base
    collectgarbage("restart");collectgarbage("collect")
    print(string.format("%s,%d,%.6f,%.2f,%.2f",name,iterations,seconds,allocated,collectgarbage("count")-base))
    assert(not next(J.Core.notices),next(J.Core.notices))
end
print("workload,iterations,seconds,temporary_KiB,retained_KiB")
measure("idle two shells",function() M.tick(J.Core) end)
local health=J.Core.client:UnitBars("playerFrame").health
measure("native fill animation",function() health.fill:SetTexCoord(0,.5,0,1);M.tick(J.Core) end)
M.combat=true
measure("combat target switches",function(i)
    M.unitData.target.player=i%2==0;M.unitData.target.class="DRUID"
    M.event(J.Core,"PLAYER_TARGET_CHANGED")
end)
M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
collectgarbage("collect")
local base,objects=collectgarbage("count"),#M.objects
J.SettingsUI:Open();collectgarbage("collect")
print(string.format("settings open,objects=%d,retained_KiB=%.2f",#M.objects-objects,collectgarbage("count")-base))
