local test,near=...
-- Shape of the public objects in the supplied EllesmereUI 9.2.9 release.
-- No upstream code is copied or executed by this offline fixture.
local function eui(M,unit)
    local title=unit:sub(1,1):upper()..unit:sub(2)
    local root=M.native("EllesmereUIUnitFrames_"..title,240,48)
    root.rect={400,500};root.strata="MEDIUM";root.level=10
    local clip=M.region(root,"Frame",240,48)
    clip.points={{"TOPLEFT",root,"TOPLEFT",0,0},{"BOTTOMRIGHT",root,"BOTTOMRIGHT",0,0}}
    clip.clipsChildren=true;root._barClip=clip
    local function bar(kind,height,points)
        local b=M.region(clip,"StatusBar",190,height)
        b.points=points;b.euiLayoutBar=true;b.strata="MEDIUM";b.level=12
        b.fill=M.region(b,"Texture",190,height);b.fill.fillTexture=true
        b.fill.path="Interface\\Buttons\\WHITE8X8";b.fill.texCoord={0,0,0,1,1,0,1,1}
        root[kind]=b;return b
    end
    local health=bar("Health",40,{{"TOPLEFT",clip,"TOPLEFT",50,0},{"RIGHT",clip,"RIGHT",0,0}})
    local power=bar("Power",8,{{"TOPLEFT",health,"BOTTOMLEFT",0,0},{"TOPRIGHT",health,"BOTTOMRIGHT",0,0}})
    local bd=M.region(root,"Frame",48,48)
    bd.points={{"TOPLEFT",root,"TOPLEFT",0,0}}
    root.Portrait=M.region(bd,"Texture",48,48);root.Portrait.backdrop=bd
    EllesmereUI=EllesmereUI or {_ufPortraitSide={}}
    EllesmereUI._ufPortraitSide[root]=unit=="player" and "left" or "right"
    _G[title.."Frame"].shown=false
    return root,health,power,bd
end
local function enable(J,key)
    -- Existing material/restoration cases exercise the explicit Jiberish fill mode.
    assert(J.ProfileManager:Set(key or "playerFrame","unitFrameFill","JIBERISH"))
    assert(J.ProfileManager:Set(key or "playerFrame","unitFrameShown",true))
end
local function clear(J) assert(not next(J.Core.notices), next(J.Core.notices)) end

for _,interface in ipairs({120100,16001}) do
    test("Ellesmere portraits and full frames attach on client "..interface,function(M)
        local roots={}
        for _,unit in ipairs({"player","target","focus"}) do roots[unit]=eui(M,unit) end
        local J=M.load({interface=interface})
        for unit,root in pairs(roots) do
            local key=unit.."Frame";enable(J,key)
            local portrait=J.Core.modules[key]
            assert(portrait.frame.shown and portrait.snapshot.source=="ELLESMERE")
            local u=J.UnitSkins.units[key]
            assert(u.health.bar==root.Health and u.power.bar==root.Power)
            assert(u.health.active and u.power.active and u.health.trim.frame.shown and u.power.trim.frame.shown)
            assert(root._barClip.clipsChildren and root._barClip.h==48)
            local _,bottom= root.Power:GetRect();local _,topBase,_,height=root._barClip:GetRect()
            near(bottom,topBase);near(root.Health.h-root.Power.points[1][5]+root.Power.h,height)
            assert(-root.Power.points[1][5]>5)
            J.ProfileManager:Set(key,"shown",false)
            assert(not portrait.frame.shown and u.health.trim.frame.shown)
            J.ProfileManager:Set(key,"unitFrameShown",false)
            assert(not u.health and not u.power)
            near(root.Health.h,40);near(root.Power.h,8);assert(#root.Power.points==2)
            assert(root.Health.fill.path=="Interface\\Buttons\\WHITE8X8")
        end
        clear(J)
    end)
end

for _,interface in ipairs({120100,16001}) do
    test("Ellesmere recessed edges stay above all three unit fills on "..interface,function(M)
        for _,unit in ipairs({"player","target","focus"}) do eui(M,unit) end
        local J=M.load({interface=interface})
        for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
            enable(J,key)
            J.ProfileManager:Set(key,"unitFrameStrata","BACKGROUND");J.ProfileManager:Set(key,"level",0)
            for _,kind in ipairs({"health","power"}) do
                local r=J.UnitSkins.units[key][kind];local rim=r.trim.rim
                assert(rim.frame.shown and rim.frame.strata=="MEDIUM" and rim.frame.level>r.bar.level)
                assert(rim.textures.top.h>=1.5 and rim.textures.top.h<=r.bar.h*.22+.001)
            end
        end
        clear(J)
    end)
end

test("automatic portraits skip inactive and transparent providers",function(M)
    local root=eui(M,"player")
    local stale=M.native("ElvUF_Player",240,48)
    local bd=M.region(stale,"Frame",48,48);stale.Portrait=M.region(bd,"Texture",48,48);stale.Portrait.backdrop=bd
    stale.alpha=0
    local bp=M.native("StaleBlinkii",48,48);bp.portrait=M.region(bp,"Texture",48,48);bp.portrait.shown=false
    BLINKIISPORTRAITS={Portraits={player=bp}}
    local J=M.load();local p=J.Core.modules.playerFrame
    assert(p.snapshot.source=="ELLESMERE" and p.frame.shown)
    stale.alpha=1;bd.shown=false;M.tick(J.Core)
    assert(p.snapshot.source=="ELLESMERE")
    bd.shown=true;M.tick(J.Core);assert(p.snapshot.source=="ELVUI")
    J.ProfileManager:Set("playerFrame","portraitSource","ELLESMERE")
    assert(p.snapshot.frame==root.Portrait.backdrop)
    clear(J)
end)

test("Ellesmere shell provider is independent from Blinkii portraits",function(M)
    local root=eui(M,"player")
    local bp=M.native("BlinkiiPlayer",58,58);bp.portrait=M.region(bp,"Texture",116,116)
    BLINKIISPORTRAITS={Portraits={player=bp}}
    local J=M.load();enable(J)
    assert(J.Core.modules.playerFrame.snapshot.source=="BLINKII")
    assert(J.UnitSkins.units.playerFrame.health.bar==root.Health)
    J.SettingsUI:Open();J.SettingsUI:Select("playerFrame")
    assert(J.SettingsUI.controls.unitFrameSource.button.shown and J.SettingsUI.styleButton.check.shown)
    J.ProfileManager:Set("playerFrame","unitFrameSource","BLIZZARD")
    assert(root.Health.h==40 and root.Power.h==8)
    assert(not J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    J.ProfileManager:Set("playerFrame","unitFrameSource","ELLESMERE")
    assert(J.UnitSkins.units.playerFrame.health.bar==root.Health)
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset();assert(J.ProfileManager:Import(backup))
    assert(J.ThemeManager:Resolve("playerFrame").unitFrameSource=="ELLESMERE")
    assert(not J.ProfileManager:Set("actionHub","unitFrameSource","ELLESMERE"))
    clear(J)
end)

test("Ellesmere late loading and replacement restore old objects",function(M)
    local J=M.load();enable(J)
    J.ProfileManager:Set("playerFrame","unitFrameSource","ELLESMERE")
    assert(not J.UnitSkins.units.playerFrame.health)
    local root=eui(M,"player");M.event(J.Core,"ADDON_LOADED","EllesmereUIUnitFrames")
    assert(J.UnitSkins.units.playerFrame.health.bar==root.Health)
    local old=root;root=eui(M,"player");M.tick(J.Core)
    assert(old.Health.h==40 and old.Power.h==8 and old.Health.fill.path=="Interface\\Buttons\\WHITE8X8")
    assert(J.UnitSkins.units.playerFrame.health.bar==root.Health)
    clear(J)
end)

test("Ellesmere fitting never changes layout or fills in combat",function(M)
    local root=eui(M,"player");local J=M.load()
    M.combat=true;enable(J);assert(not M.euiLayoutWrites and not M.appearanceWrites)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    local writes,appearance=M.euiLayoutWrites,M.appearanceWrites
    assert(writes>0 and appearance>0)
    M.combat=true;J.ProfileManager:Set("playerFrame","unitFrameShown",false);M.tick(J.Core)
    assert(writes==M.euiLayoutWrites and appearance==M.appearanceWrites)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(root.Health.h==40 and root.Power.h==8)
    clear(J)
end)

test("Ellesmere provider profile redraw becomes the restored layout",function(M)
    local root,h,p=eui(M,"player");local J=M.load();enable(J)
    h.h=50;p.h=10;p.points={{"TOPLEFT",h,"BOTTOMLEFT",0,0}};root.h=60;root._barClip.h=60
    h.fill:SetTexture("Changed-Ellesmere-Texture")
    M.tick(J.Core)
    assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    assert(h.h==50 and p.h==10 and p.points[1][5]==0)
    assert(h.fill.path=="Changed-Ellesmere-Texture")
    clear(J)
end)

test("all 42 Ellesmere themes fit one stack without cumulative shrink",function(M)
    local root,h,p=eui(M,"player");local J=M.load();enable(J)
    J.ProfileManager:Set("playerFrame","portraitMode","FIXED")
    for id in pairs(J.UnitSkinCatalog.entries) do
        J.ProfileManager:Set("playerFrame","portrait",id)
        near(h.h-p.points[1][5]+p.h,48)
        local u=J.UnitSkins.units.playerFrame
        near(u.health.trim.applied.width-h.w,(512-(J.UnitSkinCatalog.entries[id].opening.health[3]-J.UnitSkinCatalog.entries[id].opening.health[1]))*u.health.geometry.capScale)
        assert(u.health.id==id and u.power.id==id)
    end
    local writes,appearance=M.euiLayoutWrites,M.appearanceWrites
    for i=1,20 do M.tick(J.Core) end
    assert(writes==M.euiLayoutWrites and appearance==M.appearanceWrites)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false);near(h.h,40);near(p.h,8)
    clear(J)
end)

test("Ellesmere hidden forbidden and secret bounds cannot be styled unsafely",function(M)
    local root,h,p=eui(M,"player");local J=M.load();enable(J)
    root.shown=false;M.tick(J.Core);assert(not J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    root.shown=true;M.tick(J.Core);assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    h.forbidden=true;M.tick(J.Core);assert(not J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    h.forbidden=false;M.tick(J.Core)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    h.secretRect=true;enable(J);assert(not J.UnitSkins.units.playerFrame.health.trim or not J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    h.secretRect=false;M.tick(J.Core);assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    clear(J)
end)

test("unusual Ellesmere bar layouts retain geometry and report texture-only mode",function(M)
    local root,h,p=eui(M,"player");p.points={{"BOTTOMLEFT",h,"TOPLEFT",0,0}}
    local J=M.load();enable(J)
    assert(not M.euiLayoutWrites and h.h==40 and p.h==8)
    assert(J.UnitSkins.units.playerFrame.health.active and not J.UnitSkins.units.playerFrame.health.trim)
    assert(J.UnitSkins.status.playerFrame:find("textures only",1,true))
    p.points={{"TOPLEFT",h,"BOTTOMLEFT",0,0}};M.tick(J.Core)
    assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    h.orientation="VERTICAL";M.tick(J.Core);assert(h.h==40 and p.h==8)
    assert(not J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    clear(J)
end)

test("Ellesmere stock portrait masks and side changes keep matching artwork",function(M)
    local root,h,p,bd=eui(M,"player")
    local mask=M.region(bd,"MaskTexture",60,60);mask.atlas="UI-HUD-UnitFrame-Player-Portrait-Mask";bd._blizzMask=mask
    local J=M.load();local art=J.Core.modules.playerFrame
    assert(art.snapshot.portraitShape=="PLAYER" and art.textures.main.texCoord[1]==0)
    near(art.frame.w,128)
    mask.atlas="CircleMask";mask.w,mask.h=58,58;EllesmereUI._ufPortraitSide[root]="right"
    M.tick(J.Core);near(art.frame.w,128)
    assert(art.snapshot.portraitMirror and art.textures.main.texCoord[1]==1)
    local target,th,tp,tbd=eui(M,"target");EllesmereUI._ufPortraitSide[target]="left"
    M.tick(J.Core);assert(J.Core.modules.targetFrame.applied.mirror==false)
    clear(J)
end)

test("Ellesmere default layering follows its provider and respects explicit overrides",function(M)
    local root,h,p,bd=eui(M,"player");bd.strata="MEDIUM";bd.level=11
    local J=M.load();enable(J)
    local portrait=J.Core.modules.playerFrame;local skin=J.UnitSkins.units.playerFrame
    assert(portrait.frame.strata=="MEDIUM" and portrait.frame.level==10)
    assert(skin.health.trim.frame.strata=="MEDIUM" and skin.health.trim.frame.level==11)
    root.strata="HIGH";root.level=20;bd.strata="HIGH";bd.level=21
    M.tick(J.Core)
    assert(portrait.frame.strata=="HIGH" and portrait.frame.level==20)
    assert(skin.power.trim.frame.strata=="HIGH" and skin.power.trim.frame.level==21)
    J.ProfileManager:Set("playerFrame","strata","BACKGROUND");J.ProfileManager:Set("playerFrame","level",3)
    assert(portrait.frame.strata=="BACKGROUND" and portrait.frame.level==3)
    assert(skin.health.trim.frame.strata=="HIGH" and skin.health.trim.frame.level==3)
    J.ProfileManager:Set("playerFrame","unitFrameStrata","BACKGROUND")
    assert(skin.health.trim.frame.strata=="BACKGROUND")
    J.Core:Status();local messages=table.concat(M.messages,"\n")
    assert(messages:find("requested AUTO | resolved ELLESMERE",1,true))
    assert(messages:find("unit frame: on | requested AUTO | EllesmereUI:",1,true))
    clear(J)
end)

test("hidden or detached Ellesmere power restores fitting and keeps provider geometry",function(M)
    local root,h,p=eui(M,"player");local J=M.load();enable(J)
    p.shown=false;M.tick(J.Core)
    near(h.h,40);near(p.h,8)
    assert(not J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    p.shown=true;M.tick(J.Core);assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    p.parent=root;p.points={{"TOP",h,"BOTTOM",0,-15}};p.h=12
    M.tick(J.Core)
    near(h.h,40);near(p.h,12);assert(p.points[1][1]=="TOP" and p.points[1][5]==-15)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    assert(p.parent==root and p.points[1][5]==-15)
    clear(J)
end)

test("Ellesmere scale changes and partial redraws retain original stack dimensions",function(M)
    local root,h,p=eui(M,"player");local J=M.load();enable(J)
    root.scale=.75;M.tick(J.Core);near(h.h-p.points[1][5]+p.h,48)
    h.h=50;M.tick(J.Core);near(h.h-p.points[1][5]+p.h,58)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false);near(h.h,50);near(p.h,8)
    clear(J)
end)

test("automatic Ellesmere fills respect provider choices and do not install texture hooks",function(M)
    local root,h,p=eui(M,"player");local J=M.load()
    J.ProfileManager:Set("playerFrame","unitFrameShown",true)
    local u=J.UnitSkins.units.playerFrame
    assert(u.health.trim.frame.shown and not u.health.active and not M.hooks)
    assert(not M.appearanceWrites and h.fill.path=="Interface\\Buttons\\WHITE8X8")
    h.fill:SetTexture("Provider-Stone");p.fill:SetTexture("Provider-Mana")
    local writes=M.appearanceWrites
    for i=1,5 do M.tick(J.Core) end
    assert(h.fill.path=="Provider-Stone" and p.fill.path=="Provider-Mana" and writes==M.appearanceWrites)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    assert(h.fill.path=="Provider-Stone" and p.fill.path=="Provider-Mana")
    clear(J)
end)

test("provider may select JiberishUI Stone without later being reset to stale media",function(M)
    local root,h,p=eui(M,"player");local J=M.load();enable(J)
    h:SetStatusBarTexture(J.Media.stone)
    J.ProfileManager:Set("playerFrame","unitFrameFill","AUTO")
    assert(h.fill.path==J.Media.stone and p.fill.path=="Interface\\Buttons\\WHITE8X8")
    assert(not J.UnitSkins.units.playerFrame.health.active)
    local writes=M.appearanceWrites
    M.tick(J.Core);assert(writes==M.appearanceWrites)
    J.ProfileManager:Set("playerFrame","unitFrameFill","JIBERISH")
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    assert(h.fill.path==J.Media.stone)
    clear(J)
end)

test("switching texture ownership during combat defers writes and keeps latest choice",function(M)
    local root,h,p=eui(M,"player");local J=M.load();enable(J)
    local writes=M.appearanceWrites
    M.combat=true
    J.ProfileManager:Set("playerFrame","unitFrameFill","PROVIDER")
    J.ProfileManager:Set("playerFrame","unitFrameFill","JIBERISH")
    J.ProfileManager:Set("playerFrame","unitFrameFill","AUTO")
    assert(M.appearanceWrites==writes and J.UnitSkins.units.playerFrame.health.active)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(not J.UnitSkins.units.playerFrame.health.active)
    assert(h.fill.path=="Interface\\Buttons\\WHITE8X8" and J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    clear(J)
end)
