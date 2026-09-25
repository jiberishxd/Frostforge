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
local function expectFive(J,M)
    assert(count(J.Core.owned)==5)
    assert(count(J.Core.modules)==5 and count(J.ThemeManager.registry)==1)
    for _,key in ipairs(J.Core.order) do
        local m=J.Core.modules[key]
        assert(m.frame.parent==UIParent and m.frame.mouse==false and m.frame.keyboard==false and m.frame.wheel==false)
        assert(m.crest==nil and m.frame.strata=="BACKGROUND")
        for _,texture in pairs(m.textures) do
            assert(texture.parent==m.frame and texture.layer=="BACKGROUND")
        end
        assert(m.status=="attached")
    end
    assert(not next(J.Core.notices))
end

test("Retail creates exactly five independent decorative roots",function(M)
    local J=M.load()
    assert(J.Core.client.id=="retail")
    expectFive(J,M)
    assert(M.textures==29 and M.fonts==5)
    assert(J.Core.driver.mouse==false and #J.Core.driver.regions==0)
end)
test("Forever takes its own compatibility path",function(M)
    local J=M.load({interface=16001,flavor="forever"})
    assert(J.Core.client.id=="forever")
    expectFive(J,M)
    assert(J.Core.clients.retail.Resolve~=J.Core.clients.forever.Resolve)
end)
test("portraits have one texture, no bar rails, and independent class artwork",function(M)
    local J=M.load()
    local player,target,focus=J.Core.modules.playerFrame,J.Core.modules.targetFrame,J.Core.modules.focusFrame
    assert(player.portraitID=="CLASS_PALADIN" and target.portraitID=="CLASS_ROGUE" and focus.portraitID=="CLASS_MAGE")
    for _,m in ipairs({player,target,focus}) do
        assert(count(m.textures)==1 and m.textures.main and not m.textures.rails and not m.textures.endcap)
        assert(m.frame.w==128 and m.frame.h==128)
    end
    assert(player.frame.points[1][2]==PlayerFrame and target.frame.points[1][2]==TargetFrame and focus.frame.points[1][2]==FocusFrame)
    assert(player.textures.main.texCoord[1]==0 and target.textures.main.texCoord[1]==1 and focus.textures.main.texCoord[1]==1)
    for i=1,3 do J.Core:Command("reloadtheme") end
    assert(M.textures==29 and M.fonts==5)
end)
test("screen hub stays independent of native placement but follows native visibility",function(M)
    local J=M.load()
    local hub=J.Core.modules.actionHub
    local point,relative,relativePoint=hub.frame:GetPoint()
    assert(point=="BOTTOM" and relative==UIParent and relativePoint=="BOTTOM")
    near(hub.frame:GetEffectiveScale(),MainActionBar:GetEffectiveScale())
    assert(hub.debugLabel.text:find("Anchor UIParent",1,true))
    assert(hub.debugLabel.text:find("Visibility/scale: MainActionBar",1,true))
    J.Core:Command("set actionHub anchor FRAME")
    assert(hub.frame.points[1][2]==MainActionBar)
    J.Core:Command("reset actionHub")
    assert(hub.frame.points[1][2]==UIParent)
    MainActionBar.shown=false
    M.tick(J.Core)
    assert(not hub.frame.shown)
end)
test("portrait size controls resize only the owned portrait texture",function(M)
    local J=M.load()
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
        J.ProfileManager:Set(key,"width",150); J.ProfileManager:Set(key,"height",160)
        local m=J.Core.modules[key]
        assert(count(m.textures)==1 and m.textures.main.w==150 and m.textures.main.h==160)
        assert(m.textures.main.points[1][4]==0 and m.textures.main.points[1][5]==0)
    end
end)
test("hub width does not inflate wings or the sun crest",function(M)
    local J=M.load()
    local hub=J.Core.modules.actionHub
    local wingWidth,wingHeight=hub.textures.leftWing.w,hub.textures.leftWing.h
    local sunWidth,railWidth=hub.textures.sun.w,hub.textures.leftRail.w
    J.ProfileManager:Set("actionHub","width",1800)
    near(hub.textures.leftWing.w,wingWidth); near(hub.textures.leftWing.h,wingHeight)
    near(hub.textures.sun.w,sunWidth); near(hub.textures.leftRail.w,railWidth+160)
    near(hub.textures.rightWing.points[1][4]+hub.textures.rightWing.w,1800)
end)
test("all hub pieces preserve hanging ornament through resizing",function(M)
    local J=M.load()
    for _,size in ipairs({{600,80},{1480,240},{2048,480}}) do
        J.ProfileManager:Set("actionHub","width",size[1])
        J.ProfileManager:Set("actionHub","height",size[2])
        local config=J.ThemeManager:Resolve("actionHub")
        local top,height
        for name,piece in pairs(config.pieces) do
            local x,y,w,h=J.Core:PieceGeometry(config,piece)
            local texture=J.Core.modules.actionHub.textures[name]
            assert(texture.texCoord[3]==0 and texture.texCoord[4]==1,
                "Vertical cropping removes draped artwork")
            if top then near(y,top);near(h,height) else top,height=y,h end
        end
    end
end)
test("piece geometry remains finite and inside artwork bounds at control limits",function(M)
    local J=M.load()
    for _,key in ipairs(J.Core.order) do
        for _,size in ipairs({{16,2048},{2048,16},{300,150}}) do
            local config=J.ThemeManager:Resolve(key)
            config.width,config.height=size[1],size[2]
            for _,piece in pairs(config.pieces or {main=false}) do
                local x,y,w,h=J.Core:PieceGeometry(config,piece)
                assert(w>0 and h>0 and x>=-0.01 and y>=-0.01)
                assert(x+w<=config.width+0.01 and y+h<=config.height+0.01)
            end
        end
    end
end)
test("unsafe piece geometry is rejected at theme registration",function(M)
    local J=M.load()
    for _,changes in ipairs({{u2=1.1},{height=-1},{leftOffset=1000},{order=8},{v1=0/0}}) do
        local theme=J.Core:Copy(J.ThemeManager.registry.paladin_ret)
        for k,v in pairs(changes) do theme.actionHub.pieces.leftWing[k]=v end
        assert(not pcall(function() J.ThemeManager:Register("invalid",theme) end))
    end
end)
test("anchor choices persist and defer safely through combat",function(M)
    local J=M.load()
    local hub=J.Core.modules.actionHub
    M.combat=true
    local writes=M.geometryWrites
    J.Core:Command("set actionHub anchor FRAME")
    assert(hub.frame.points[1][2]==UIParent and M.geometryWrites==writes)
    M.combat=false
    M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(hub.frame.points[1][2]==MainActionBar)
    local saved=J.ProfileManager:Export()
    assert(saved:find("actionHub.anchor=FRAME",1,true))
    J.Core:Command("reset")
    assert(J.ProfileManager:Import(saved))
    assert(hub.frame.points[1][2]==MainActionBar)
    assert(not J.ProfileManager:Set("actionHub","anchor","TargetFrame"))
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
    assert(count(J.Core.owned)==4 and not J.Core.modules.targetFrame.frame)
    TargetFrame=target
    M.event(J.Core,"ADDON_LOADED","Blizzard_UnitFrame")
    expectFive(J,M)
end)
test("forbidden Retail root is rejected before geometry reads",function(M)
    TargetFrame.forbidden=true
    local J=M.load()
    assert(not J.Core.modules.targetFrame.frame)
    assert(J.Core.modules.targetFrame.status:find("Forbidden"))
    assert(not next(J.Core.notices))
    TargetFrame.forbidden=false
    M.tick(J.Core)
    expectFive(J,M)
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
    assert(count(J.Core.owned)==2 and not next(J.Core.notices))
end)
test("source effective scale is inherited exactly once",function(M)
    local J=M.load()
    local frame=J.Core.modules.playerFrame.frame
    near(frame:GetEffectiveScale(),0.832)
    assert(J.ProfileManager:Set("playerFrame","scale",1.5))
    near(frame:GetEffectiveScale(),0.832*1.5)
    near(frame.w,128)
end)
test("decoration scale does not move requested X/Y offsets",function(M)
    local J=M.load()
    J.ProfileManager:Set("playerFrame","x",30)
    J.ProfileManager:Set("playerFrame","y",-12)
    J.ProfileManager:Set("playerFrame","scale",2)
    local frame=J.Core.modules.playerFrame.frame
    local point,relative,relativePoint,x,y=frame:GetPoint()
    assert(point=="LEFT" and relative==PlayerFrame and relativePoint=="LEFT")
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
    for _,texture in pairs(J.Core.modules.playerFrame.textures) do assert(texture.layer=="BORDER") end
    assert(J.Core.modules.targetFrame.frame.w==128)
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
    assert(frame.w==1480 and M.geometryWrites==writes)
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
    expectFive(J,M)
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
    assert(frame.shown and frame.w==128 and not next(J.Core.notices))
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
    assert(J.Core.modules.minimap.frame.w==340)
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
        assert(module.frame.shown and module.outline[1].shown)
        for _,texture in pairs(module.textures) do assert(not texture.shown) end
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
test("debug labels use separate positions and follow target visibility",function(M)
    TargetFrame.shown=false
    local J=M.load()
    J.Core:Command("debug on")
    local player=J.Core.modules.playerFrame
    local target=J.Core.modules.targetFrame
    local map=J.Core.modules.minimap
    assert(player.debugLabel.points[1][3]=="TOPLEFT")
    assert(target.debugLabel.points[1][3]=="BOTTOMLEFT")
    assert(map.debugLabel.points[1][3]=="TOPLEFT" and map.debugLabel.points[1][4]<0)
    assert(target.debugLabel.text:find("native anchor hidden; debug outline only",1,true))
    TargetFrame.shown=true
    M.tick(J.Core)
    assert(target.debugLabel.text:find("artwork visible",1,true))
    J.Core:Command("hide targetFrame")
    assert(target.debugLabel.text:find("component hidden; debug outline only",1,true))
end)
test("idle polling and repeated reloadtheme reuse all objects",function(M)
    local J=M.load()
    local textures,fonts,frames,writes=M.textures,M.fonts,#M.frames,M.writes
    for i=1,20 do M.tick(J.Core) end
    assert(M.writes==writes,"idle polling should read only")
    for i=1,10 do J.Core:Command("reloadtheme") end
    assert(M.textures==textures and M.fonts==fonts and #M.frames==frames)
    expectFive(J,M)
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
    near(J.Core.modules.actionHub.frame.alpha,0.4)
    MainActionBar.alpha=0
    M.tick(J.Core)
    assert(not J.Core.modules.actionHub.frame.shown)
end)
test("theme defaults remain immutable when overrides change",function(M)
    local J=M.load()
    assert(J.ProfileManager:Set("playerFrame","width",350))
    assert(J.ThemeManager.registry.paladin_ret.playerFrame.width==128)
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
    assert(config.width==128 and config.scale==1 and config.layer=="BACKGROUND" and config.shown==false)
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
    assert(J.Core.modules.playerFrame.frame.w==128 and not J.ProfileManager.current.debug)
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
test("jui opens one movable window without enabling mouse on artwork",function(M)
    local J=M.load()
    assert(not J.SettingsUI.frame)
    local before=J.ProfileManager:Export()
    SlashCmdList.JIBERISHFANTASY("")
    local S=J.SettingsUI
    assert(S.frame==JiberishUIOptionsFrame and S.frame.parent==UIParent)
    assert(S.frame.shown and S.frame.movable and S.frame.clamped and S.frame.mouse)
    assert(S.titleBar.dragButtons[1]=="LeftButton")
    assert(#UISpecialFrames==1 and UISpecialFrames[1]=="JiberishUIOptionsFrame")
    assert(S.controls.level.edit:GetText()=="0" and S.controls.scale.edit:GetText()=="1")
    local frames,textures,fonts=#M.frames,M.textures,M.fonts
    SlashCmdList.JIBERISHFANTASY(""); assert(not S.frame.shown)
    for i=1,10 do
        S:Open()
        for _,key in ipairs(J.Core.order) do S:Select(key) end
        S.frame:Hide()
    end
    assert(#M.frames==frames and M.textures==textures and M.fonts==fonts)
    assert(J.ProfileManager:Export()==before)
    expectFive(J,M)
end)
test("window dragging saves only its own position and restores on both clients",function(M)
    for _,interface in ipairs({120100,16001}) do
        local J=M.load({interface=interface})
        local S=J.SettingsUI; S:Open()
        local original=J.ProfileManager:Export()
        S.titleBar.scripts.OnDragStart()
        assert(S.frame.moving)
        S.frame.center={1100,470}
        -- Closing while dragging must stop motion and save the final position too.
        S.frame:Hide()
        assert(not S.frame.moving and not S.dragging)
        assert(J.ProfileManager.current.window.x==140 and J.ProfileManager.current.window.y==-70)
        assert(J.ProfileManager:Export()==original)
        J=M.load({interface=interface,db=JiberishUIDB})
        S=J.SettingsUI; S:Open()
        assert(S.frame.points[1][4]==140 and S.frame.points[1][5]==-70)
        S:Center()
        assert(S.frame.points[1][4]==0 and S.frame.points[1][5]==0)
        assert(J.ProfileManager.current.window.x==0 and J.ProfileManager.current.window.y==0)
        assert(not next(J.Core.notices))
    end
end)
test("options strata and level change only the selected artwork",function(M)
    local J=M.load(); local S=J.SettingsUI; S:Open()
    S.tabs.targetFrame.scripts.OnClick()
    S.controls.strata.button.scripts.OnClick()
    assert(S.menus[1].shown)
    S.controls.strata.options.HIGH.scripts.OnClick()
    S.controls.level.slider:SetValue(23)
    S.controls.layer.options.OVERLAY.scripts.OnClick()
    local target=J.Core.modules.targetFrame
    assert(target.frame.strata=="HIGH" and target.frame.level==23)
    for _,texture in pairs(target.textures) do assert(texture.layer=="OVERLAY") end
    assert(not S.menus[1].shown)
    assert(J.Core.modules.playerFrame.frame.strata=="BACKGROUND" and J.Core.modules.playerFrame.frame.level==0)
    assert(target.debugLabel:GetText():find("HIGH / level 23 / OVERLAY",1,true))
    local backup=J.ProfileManager:Export()
    assert(backup:find("targetFrame.level=23",1,true))
    J.ProfileManager:Reset(); assert(J.ProfileManager:Import(backup))
    J=M.load({db=JiberishUIDB})
    assert(J.Core.modules.targetFrame.frame.strata=="HIGH" and J.Core.modules.targetFrame.frame.level==23)
    assert(not next(J.Core.notices))
end)
test("typed options validate on Enter and unfinished edits never cross components",function(M)
    local J=M.load(); local S=J.SettingsUI; S:Open()
    local edit=S.controls.level.edit
    for _,value in ipairs({"-1","129","2.5","nope"}) do
        edit:SetFocus(); edit:SetText(value); edit.scripts.OnEnterPressed()
        assert(J.Core.modules.playerFrame.frame.level==0 and edit:GetText()=="0")
        assert(S.message)
    end
    edit:SetFocus(); edit:SetText("32"); edit.scripts.OnEnterPressed()
    assert(J.Core.modules.playerFrame.frame.level==32 and not S.message)
    edit:SetFocus(); edit:SetText("50"); S:Select("targetFrame")
    assert(J.Core.modules.targetFrame.frame.level==0 and edit:GetText()=="0")
    assert(J.Core.modules.playerFrame.frame.level==32)
    edit:SetFocus(); edit:SetText("70"); edit.scripts.OnEscapePressed()
    assert(J.Core.modules.targetFrame.frame.level==0 and not edit:HasFocus())
    S.controls.x.slider:SetValue(-40)
    assert(J.Core.modules.targetFrame.applied.x==-40)
    assert(not next(J.Core.notices))
end)
test("options combat edits queue the latest layering until regen",function(M)
    local J=M.load(); local S=J.SettingsUI; S:Open()
    local frame=J.Core.modules.playerFrame.frame
    M.combat=true
    S.controls.strata.options.LOW.scripts.OnClick()
    S.controls.strata.options.HIGH.scripts.OnClick()
    S.controls.level.slider:SetValue(42)
    assert(frame.strata=="BACKGROUND" and frame.level==0 and J.Core.dirty)
    assert(S.controls.strata.button.caption:GetText()=="High")
    assert(S.status:GetText():find("after combat",1,true))
    -- The settings window is independent; artwork still waits for combat exit.
    S.titleBar.scripts.OnDragStart(); S.titleBar.scripts.OnDragStop()
    assert(frame.strata=="BACKGROUND")
    M.combat=false; M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(frame.strata=="HIGH" and frame.level==42 and not J.Core.dirty)
    assert(not S.status:GetText():find("after combat",1,true))
    assert(not next(J.Core.notices))
end)
test("first options attachment waits for combat and its pending open can be canceled",function(M)
    local J=M.load(); local S=J.SettingsUI
    local frames,textures=#M.frames,M.textures
    M.combat=true
    J.Core:Command("")
    assert(S.pendingOpen and not S.frame and #M.frames==frames and M.textures==textures)
    J.Core:Command(""); assert(not S.pendingOpen)
    M.combat=false; M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(not S.frame)
    M.combat=true; J.Core:Command("options")
    M.combat=false; M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(S.frame.shown and not S.pendingOpen)
    expectFive(J,M)
end)
test("window metadata and frame levels reject invalid saved and imported values",function(M)
    local J=M.load({db={phase1={version=1,window={x=math.huge,y=0},modules={playerFrame={level=0.5}}}}})
    assert(not J.ProfileManager.current.window and J.Core.modules.playerFrame.frame.level==0)
    assert(not J.ProfileManager:SetWindowPosition(0/0,0))
    assert(not J.ProfileManager:SetWindowPosition(10001,0))
    assert(J.ProfileManager:SetWindowPosition(20,-15))
    local profile=J.ProfileManager.current
    for _,value in ipairs({"-1","129","1.5"}) do
        assert(not J.ProfileManager:Import("JF1;paladin_ret;playerFrame.level="..value))
        assert(J.ProfileManager.current==profile)
    end
    assert(J.ProfileManager:Import("JF1;paladin_ret;playerFrame.level=128"))
    assert(J.ProfileManager.current.window.x==20 and J.ProfileManager.current.window.y==-15)
    assert(J.Core.modules.playerFrame.frame.level==128)
end)
test("options preserve newer read-only profiles while remaining usable",function(M)
    local source={version=99,window={x=25,y=75}}
    local J=M.load({db={phase1=source}}); local S=J.SettingsUI; S:Open()
    S.controls.strata.options.HIGH.scripts.OnClick()
    S.controls.level.slider:SetValue(20)
    S.titleBar.scripts.OnDragStart(); S.frame.center={1000,500}; S.titleBar.scripts.OnDragStop()
    assert(JiberishUIDB.phase1==source and source.window.x==25 and not source.modules)
    assert(J.Core.modules.playerFrame.frame.strata=="BACKGROUND" and J.Core.modules.playerFrame.frame.level==0)
    assert(S.status:GetText()==J.ProfileManager.notice)
    assert(not next(J.Core.notices))
end)
test("reported Forever fit profile reproduces geometry without changing native frames",function(M)
    local J=M.load({interface=16001,flavor="forever"})
    local file=assert(io.open("artwork/paladin-ret-review/reported-fit-profile.txt"))
    local backup=file:read("*a"):gsub("%s+$",""); file:close()
    assert(J.ProfileManager:Import(backup))
    local player,hub=J.Core.modules.playerFrame,J.Core.modules.actionHub
    local defaults=J.ThemeManager.registry.paladin_ret.playerFrame
    assert(player.applied.width==defaults.width and player.applied.height==defaults.height)
    assert(player.applied.x==defaults.x and player.applied.y==defaults.y)
    assert(player.frame.strata=="BACKGROUND" and player.frame.level==128)
    for _,texture in pairs(player.textures) do assert(texture.layer=="ARTWORK") end
    assert(hub.applied.strata=="HIGH" and hub.applied.scale==1.5 and hub.applied.y==-24)
    assert(not hub.applied.shown and not hub.frame.shown)
    J.Core:Command("reloadtheme")
    assert(player.frame.level==128 and not hub.frame.shown)
    assert(not next(J.Core.notices))
end)
assert(loadfile("tests/portraits.lua"))(test,near,count)
assert(loadfile("tests/hubs.lua"))(test,near,count)
assert(loadfile("tests/minimaps.lua"))(test,near,count)
assert(loadfile("tests/compatibility.lua"))(test,near,count)
dofile("tests/unit_skins.lua")(test,near)
assert(loadfile("tests/ellesmere.lua"))(test,near)
assert(loadfile("tests/npc_cities.lua"))(test,near)
assert(loadfile("tests/settings.lua"))(test,near)
assert(loadfile("tests/shared_media.lua"))(test,near)
assert(loadfile("tests/cast_bars.lua"))(test,near,count)
assert(loadfile("tests/blizzard_units.lua"))(test,near)
assert(loadfile("tests/stock_stone.lua"))(test,near)
assert(loadfile("tests/named_profiles.lua"))(test)
print(string.format("%d tests passed; no functional native-frame writes. In-game testing is still required.",passed))
