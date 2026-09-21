local passed = 0
local function near(a,b) assert(math.abs(a-b)<0.00001,tostring(a).." ~= "..tostring(b)) end
local function test(name,fn)
    local M=dofile("tests/mock_wow.lua")
    local ok,message=pcall(fn,M)
    assert(ok,name..": "..tostring(message))
    assert(M.nativeWrites==0,name..": mutated native UI")
    passed=passed+1
    print("PASS "..name)
end
local function count(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
local function expectFour(J,M)
    assert(count(J.Core.owned)==4)
    assert(count(J.Core.modules)==4 and count(J.ThemeManager.registry)==1)
    for _,key in ipairs(J.Core.order) do
        local m=J.Core.modules[key]
        assert(m.frame.parent==UIParent and m.frame.mouse==false and m.frame.keyboard==false and m.frame.wheel==false)
        assert(m.texture.parent==m.frame and m.crest.parent==m.frame)
        assert(m.frame.strata=="BACKGROUND" and m.texture.layer=="BACKGROUND")
        assert(m.status=="attached")
    end
    assert(not next(J.Core.notices))
end

test("Retail creates exactly four independent decorative roots",function(M)
    local J=M.load()
    assert(J.Core.client.id=="retail")
    expectFour(J,M)
    assert(M.textures==24 and M.fonts==4)
    assert(J.Core.driver.mouse==false and #J.Core.driver.regions==0)
end)
test("Forever takes its own compatibility path",function(M)
    local J=M.load({interface=16001,flavor="forever"})
    assert(J.Core.client.id=="forever")
    expectFour(J,M)
    assert(J.Core.clients.retail.Resolve~=J.Core.clients.forever.Resolve)
end)
test("wrong-client package never attaches artwork",function(M)
    local J=M.load({interface=16001,flavor="retail"})
    assert(not J.Core.client and count(J.Core.owned)==0)
end)
test("unsupported interface never attaches artwork",function(M)
    local J=M.load({interface=110207})
    assert(not J.Core.client and count(J.Core.owned)==0)
end)
test("late Blizzard addon loads attach only available anchors",function(M)
    local target=TargetFrame; TargetFrame=nil
    local J=M.load()
    assert(count(J.Core.owned)==3 and not J.Core.modules.targetFrame.frame)
    TargetFrame=target
    M.event(J.Core,"ADDON_LOADED","Blizzard_UnitFrame")
    expectFour(J,M)
end)
test("forbidden Retail root is rejected before geometry reads",function(M)
    TargetFrame.forbidden=true
    local J=M.load()
    assert(not J.Core.modules.targetFrame.frame)
    assert(J.Core.modules.targetFrame.status:find("Forbidden"))
    assert(not next(J.Core.notices))
    TargetFrame.forbidden=false
    M.tick(J.Core)
    expectFour(J,M)
end)
test("existing artwork hides when its anchor becomes forbidden",function(M)
    local J=M.load()
    PlayerFrame.forbidden=true
    M.tick(J.Core)
    assert(not J.Core.modules.playerFrame.frame.shown and not next(J.Core.notices))
end)
test("Forever also rejects forbidden roots",function(M)
    Minimap.forbidden=true
    local J=M.load({interface=16001})
    assert(not J.Core.modules.minimap.frame and not next(J.Core.notices))
end)
test("restricted and invalid geometry stays native",function(M)
    PlayerFrame.secretScale=true
    TargetFrame.w=0
    MainActionBar.secretAlpha=true
    local J=M.load()
    assert(count(J.Core.owned)==1 and not next(J.Core.notices))
end)
test("source effective scale is inherited exactly once",function(M)
    local J=M.load()
    local frame=J.Core.modules.playerFrame.frame
    near(frame:GetEffectiveScale(),0.832)
    assert(J.ProfileManager:Set("playerFrame","scale",1.5))
    near(frame:GetEffectiveScale(),0.832*1.5)
    near(frame.w,270)
end)
test("decoration scale does not move requested X/Y offsets",function(M)
    local J=M.load()
    J.ProfileManager:Set("playerFrame","x",30)
    J.ProfileManager:Set("playerFrame","y",-12)
    J.ProfileManager:Set("playerFrame","scale",2)
    local frame=J.Core.modules.playerFrame.frame
    local point,relative,relativePoint,x,y=frame:GetPoint()
    assert(point=="CENTER" and relative==PlayerFrame and relativePoint=="CENTER")
    near(x*frame:GetEffectiveScale(),30*PlayerFrame:GetEffectiveScale())
    near(y*frame:GetEffectiveScale(),-12*PlayerFrame:GetEffectiveScale())
end)
test("1080p/1440p/4K scale changes preserve relative anchors",function(M)
    local J=M.load()
    for _,size in ipairs({{1920,1080,0.64},{2560,1440,0.83},{3840,2160,0.5}}) do
        UIParent.w,UIParent.h,UIParent.scale=unpack(size)
        PlayerFrame.scale=1.12
        M.event(J.Core,"UI_SCALE_CHANGED")
        local frame=J.Core.modules.playerFrame.frame
        assert(frame.points[1][2]==PlayerFrame)
        near(frame:GetEffectiveScale(),UIParent.scale*PlayerFrame.scale)
    end
end)
test("Edit Mode updates only artwork geometry",function(M)
    local J=M.load()
    PlayerFrame.w,PlayerFrame.scale=270,1.8
    M.event(J.Core,"EDIT_MODE_LAYOUTS_UPDATED")
    near(J.Core.modules.playerFrame.frame:GetEffectiveScale(),1.8*UIParent.scale)
    assert(#PlayerFrame.points==0)
end)
test("all required properties apply independently",function(M)
    local J=M.load()
    for property,value in pairs({width=400,height=190,x=-40,y=24,scale=0.7,strata="LOW",layer="BORDER",
        point="TOP",relativePoint="BOTTOM",opacity=0.5}) do
        assert(J.ProfileManager:Set("playerFrame",property,value))
    end
    local frame=J.Core.modules.playerFrame.frame
    assert(frame.w==400 and frame.h==190 and frame.strata=="LOW")
    assert(frame.points[1][1]=="TOP" and frame.points[1][3]=="BOTTOM")
    assert(J.Core.modules.playerFrame.texture.layer=="BORDER")
    assert(J.Core.modules.targetFrame.frame.w==270)
    near(frame.alpha,0.5)
end)
test("combat stores only the latest requested configuration",function(M)
    local J=M.load()
    local frame=J.Core.modules.actionHub.frame
    M.combat=true
    local writes=M.geometryWrites
    J.ProfileManager:Set("actionHub","width",700)
    J.ProfileManager:Set("actionHub","width",800)
    J.ProfileManager:Set("actionHub","x",25)
    assert(frame.w==660 and M.geometryWrites==writes)
    M.combat=false
    M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(frame.w==800 and frame.points[1][4]==25 and not J.Core.dirty)
end)
test("login in combat creates no decorative anchors until regen",function(M)
    M.combat=true
    local J=M.load()
    assert(count(J.Core.owned)==0 and M.textures==0)
    M.combat=false
    M.event(J.Core,"PLAYER_REGEN_ENABLED")
    expectFour(J,M)
end)
test("anchor replacement during combat cannot leave art on the old root",function(M)
    local J=M.load()
    local old=J.Core.modules.targetFrame.frame
    M.combat=true
    M.native("TargetFrame",240,110)
    M.tick(J.Core)
    assert(not old.shown)
    M.combat=false
    M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(old.points[1][2]==TargetFrame and old.shown)
end)
test("safe visibility follows target and vehicle main-bar visibility",function(M)
    local J=M.load()
    M.combat=true
    TargetFrame.shown=false; MainActionBar.shown=false
    M.event(J.Core,"PLAYER_TARGET_CHANGED")
    assert(not J.Core.modules.targetFrame.frame.shown and not J.Core.modules.actionHub.frame.shown)
    TargetFrame.shown=true; MainActionBar.shown=true
    M.tick(J.Core)
    assert(J.Core.modules.targetFrame.frame.shown and J.Core.modules.actionHub.frame.shown)
end)
test("client-protected artwork defers even visibility changes",function(M)
    local J=M.load()
    local frame=J.Core.modules.playerFrame.frame
    frame.protected=true
    M.combat=true
    PlayerFrame.shown=false
    J.ProfileManager:Set("playerFrame","width",300)
    assert(frame.shown and frame.w==270 and not next(J.Core.notices))
    M.combat=false
    M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(not frame.shown and frame.w==300)
end)
test("individual hide/show and reset never change native frames",function(M)
    local J=M.load()
    J.Core:Command("hide minimap")
    assert(not J.Core.modules.minimap.frame.shown and Minimap.shown)
    J.Core:Command("show minimap")
    assert(J.Core.modules.minimap.frame.shown)
    J.Core:Command("set minimap width 350")
    J.Core:Command("reset minimap")
    assert(J.Core.modules.minimap.frame.w==240)
end)
test("debug displays bounds and every required diagnostic field",function(M)
    local J=M.load()
    J.Core:Command("debug on")
    for _,key in ipairs(J.Core.order) do
        local module=J.Core.modules[key]
        assert(module.debugLabel.shown)
        for _,edge in ipairs(module.outline) do assert(edge.shown and #edge.points==2) end
        for _,word in ipairs({key,"Anchor","X/Y","BACKGROUND","Interface","scale"," x "}) do
            assert(module.debugLabel.text:find(word,1,true),word)
        end
    end
    J.Core:Command("debug off")
    for _,module in pairs(J.Core.modules) do assert(not module.debugLabel.shown and not module.outline[1].shown) end
end)
test("debug can outline disabled and invisible components without artwork",function(M)
    TargetFrame.shown=false
    local J=M.load()
    J.Core:Command("hide minimap")
    J.Core:Command("debug on")
    for _,key in ipairs({"targetFrame","minimap"}) do
        local module=J.Core.modules[key]
        assert(module.frame.shown and module.outline[1].shown and not module.texture.shown)
    end
end)
test("debug changes during combat are deferred",function(M)
    local J=M.load()
    M.combat=true
    J.Core:Command("debug on")
    assert(not J.Core.modules.playerFrame.outline[1].shown)
    M.combat=false
    M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(J.Core.modules.playerFrame.outline[1].shown)
end)
test("idle polling and repeated reloadtheme reuse all objects",function(M)
    local J=M.load()
    local textures,fonts,frames,writes=M.textures,M.fonts,#M.frames,M.writes
    for i=1,20 do M.tick(J.Core) end
    assert(M.writes==writes,"idle polling should read only")
    for i=1,10 do J.Core:Command("reloadtheme") end
    assert(M.textures==textures and M.fonts==fonts and #M.frames==frames)
    expectFour(J,M)
end)
test("missing artwork keeps native presentation and supports retry",function(M)
    M.missingTexture=true
    local J=M.load()
    assert(not J.Core.modules.playerFrame.frame.shown and PlayerFrame.shown)
    M.missingTexture=false
    J.Core:Command("reloadtheme")
    assert(J.Core.modules.playerFrame.frame.shown)
end)
test("native fading is mirrored by artwork without modifying the anchor",function(M)
    local J=M.load()
    MainActionBar.alpha=0.4
    M.tick(J.Core)
    near(J.Core.modules.actionHub.frame.alpha,0.4*0.85)
    MainActionBar.alpha=0
    M.tick(J.Core)
    assert(not J.Core.modules.actionHub.frame.shown)
end)
test("theme defaults remain immutable when overrides change",function(M)
    local J=M.load()
    assert(J.ProfileManager:Set("playerFrame","width",350))
    assert(J.ThemeManager.registry.paladin_ret.playerFrame.width==270)
    assert(J.ThemeManager:Load("paladin_ret"))
    assert(J.Core.modules.playerFrame.frame.w==350)
    assert(not J.ThemeManager:Load("warlock"))
    local bad=J.Core:Copy(J.ThemeManager.registry.paladin_ret); bad.callback=function() end
    assert(not pcall(function() J.ThemeManager:Register("bad",bad) end))
end)
test("profile settings survive simulated reload on both client paths",function(M)
    for _,interface in ipairs({120100,16001}) do
        local J=M.load({interface=interface})
        J.Core:Command("set playerFrame width 345")
        J.Core:Command("set actionHub x -42")
        local db=JiberishUIDB
        local nextJ=M.load({interface=interface,db=db})
        assert(nextJ.Core.modules.playerFrame.frame.w==345)
        assert(nextJ.Core.modules.actionHub.applied.x==-42)
        assert(nextJ.ProfileManager.notice=="Phase 1 settings loaded.")
    end
end)
test("legacy profiles are preserved without applying their renderer settings",function(M)
    local legacy={profiles={Default={global={skin="warlock",hubDock=true}}},characters={["Test-Realm"]="Default"},version=1}
    local oldProfiles=legacy.profiles
    local J=M.load({db=legacy})
    assert(legacy.profiles==oldProfiles and legacy.profiles.Default.global.hubDock==true)
    assert(J.ProfileManager.current.theme=="paladin_ret" and legacy.phase1)
end)
test("invalid saved properties cannot reach renderer APIs",function(M)
    local J=M.load({db={phase1={version=1,theme="unknown",modules={playerFrame={width=0,scale=math.huge,layer="BAD",shown=false}}}}})
    local config=J.ThemeManager:Resolve("playerFrame")
    assert(config.width==270 and config.scale==1 and config.layer=="BACKGROUND" and config.shown==false)
end)
test("future or unknown saved database formats are preserved",function(M)
    local db={phase1={version=99,theme="later"}}
    local J=M.load({db=db})
    assert(not J.ProfileManager.writable and db.phase1.version==99)
    assert(not J.ProfileManager:Reset())
    J=M.load({db="future-format"})
    assert(JiberishUIDB=="future-format" and not J.ProfileManager.writable)
end)
test("Phase 1 export/import round trip is atomic",function(M)
    local J=M.load()
    J.ProfileManager:Set("actionHub","x",-12.5)
    J.ProfileManager:Set("targetFrame","shown",false)
    local backup=J.ProfileManager:Export()
    J.ProfileManager:Reset()
    assert(J.ProfileManager:Import(backup))
    assert(J.ThemeManager:Resolve("actionHub").x==-12.5)
    assert(not J.ThemeManager:Resolve("targetFrame").shown)
    local old=J.ProfileManager.current
    for _,invalid in ipairs({"", "return {}","JF1;warlock","JF1;paladin_ret;actionHub.scale=0",
        "JF1;paladin_ret;actionHub.x=2;actionHub.x=3","JF1;paladin_ret;evil.width=1",
        "JF1;paladin_ret;playerFrame.width=400;targetFrame.x=oops","JF1;paladin_ret;"}) do
        assert(not J.ProfileManager:Import(invalid),invalid)
        assert(J.ProfileManager.current==old)
    end
end)
test("invalid commands do not corrupt the profile",function(M)
    local J=M.load()
    for _,cmd in ipairs({"set","set playerFrame width -1","set playerFrame layer INVALID","hide nope","debug perhaps","theme warlock"}) do
        J.Core:Command(cmd)
    end
    assert(J.Core.modules.playerFrame.frame.w==270 and not J.ProfileManager.current.debug)
    assert(not next(J.Core.notices))
end)
test("startup is idempotent and slash aliases share one dispatcher",function(M)
    local J=M.load()
    local frames=#M.frames
    M.event(J.Core,"PLAYER_LOGIN")
    M.event(J.Core,"ADDON_LOADED","JiberishUI")
    assert(#M.frames==frames)
    assert(SLASH_JIBERISHFANTASY1=="/jf" and SLASH_JIBERISHFANTASY2=="/jui")
    SlashCmdList.JIBERISHFANTASY("theme paladin_ret")
    assert(J.ProfileManager.current.theme=="paladin_ret")
end)
print(string.format("%d Phase 1 tests passed; no native-frame writes. In-game testing is still required.",passed))
