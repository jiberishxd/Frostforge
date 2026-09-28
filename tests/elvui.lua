local test,near=...
-- Public object/anchor shapes inspected in ElvUI v15.26. No upstream code is run.
local anchors={TOPLEFT={0,1},TOPRIGHT={1,1},BOTTOMLEFT={0,0},BOTTOMRIGHT={1,0}}
local function anchored(bar)
    function bar:GetRect()
        local targets={}
        for i,p in ipairs(self.points) do
            local x,y,w,h=p[2]:GetRect();local a=anchors[p[3]]
            local ratio=p[2]:GetEffectiveScale()/self:GetEffectiveScale()
            targets[i]={x=(x+w*a[1])*ratio+p[4],y=(y+h*a[2])*ratio+p[5],a=anchors[p[1]]}
        end
        local first,second=targets[1],targets[2];local w,h=self.w,self.h
        if second then
            if first.a[1]~=second.a[1] then w=(second.x-first.x)/(second.a[1]-first.a[1]) end
            if first.a[2]~=second.a[2] then h=(second.y-first.y)/(second.a[2]-first.a[2]) end
        end
        return first.x-first.a[1]*w,first.y-first.a[2]*h,w,h
    end
    function bar:GetWidth() return select(3,self:GetRect()) end
    function bar:GetHeight() return select(4,self:GetRect()) end
end
local function elv(M,unit)
    local title=unit:sub(1,1):upper()..unit:sub(2)
    local root=M.native("ElvUF_"..title,244,54)
    root.rect={400,500};root.strata="LOW";root.level=5;root.USE_POWERBAR=true
    local function bar(kind,height,level)
        local b=M.region(root,"StatusBar",240,height);b.elvLayoutBar=true;b.strata="LOW";b.level=level
        b.fill=M.region(b,"Texture",240,height);b.fill.fillTexture=true
        b.fill.path="ElvUI-Selected-"..kind;b.fill.texCoord={0,0,0,1,1,0,1,1}
        root[kind]=b;anchored(b);return b
    end
    local h=bar("Health",40,10)
    h.points={{"TOPLEFT",root,"TOPLEFT",2,-2},{"BOTTOMRIGHT",root,"BOTTOMRIGHT",-2,12}}
    local backdrop=M.region(h,"Frame",242,42);h.backdrop=backdrop;backdrop.level=9
    function backdrop:GetRect() local x,y,w,height=h:GetRect();return x-1,y-1,w+2,height+2 end
    local p=bar("Power",8,15)
    p.points={{"TOPLEFT",backdrop,"BOTTOMLEFT",1,-1},{"TOPRIGHT",backdrop,"BOTTOMRIGHT",-1,-1}}
    h.ClipFrame=M.region(h,"Frame",240,40);h.ClipFrame.clipsChildren=true
    p.ClipFrame=M.region(p,"Frame",240,8);p.ClipFrame.clipsChildren=true
    root.RaisedElementParent=M.region(root,"Frame",244,54);root.RaisedElementParent.level=100
    _G[title.."Frame"].shown=false
    return root,h,p
end
local function enable(J,key) assert(J.ProfileManager:Set(key or "playerFrame","unitFrameShown",true)) end
local function clear(J) assert(not next(J.Core.notices),next(J.Core.notices)) end
local function stack(h,p) local _,hy,_,hh=h:GetRect();local _,py=p:GetRect();return hy+hh-py end

for _,interface in ipairs({120100,16001}) do
    test("ElvUI combat target identity uses the fitted stack without hiding art on "..interface,function(M)
        local J=M.load({interface=interface})
        local root,h,p=elv(M,"target")
        M.unitData.target.player=false;enable(J,"targetFrame")
        local u=J.UnitSkins.units.targetFrame
        local healthHeight,powerHeight=h:GetHeight(),p:GetHeight()
        local geometry,native,appearance,frames=M.geometryWrites,M.elvLayoutWrites,M.appearanceWrites,#M.frames
        M.combat=true;M.unitData.target.player=true;M.unitData.target.class="DRUID"
        M.event(J.Core,"PLAYER_TARGET_CHANGED")
        assert(u.health.id=="CLASS_DRUID" and u.power.id=="CLASS_DRUID" and u.footer.id=="CLASS_DRUID")
        assert(u.health.trim.frame.shown and u.power.trim.frame.shown)
        near(h:GetHeight(),healthHeight);near(p:GetHeight(),powerHeight);near(stack(h,p),50)
        assert(J.UnitSkins.attachedLayouts.targetFrame.id=="FACTION_NEUTRAL")
        p.shown=false;M.tick(J.Core)
        assert(u.health.trim.frame.shown and u.footer.trim.frame.shown and not u.power.trim.frame.shown)
        p.shown=true;M.tick(J.Core)
        assert(u.health.trim.frame.shown and u.power.trim.frame.shown and not u.footer.trim.frame.shown)
        assert(M.geometryWrites==geometry and M.elvLayoutWrites==native and M.appearanceWrites==appearance and #M.frames==frames)
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        assert(J.UnitSkins.attachedLayouts.targetFrame.id=="CLASS_DRUID")
        near(stack(h,p),50)
        assert(h.fill.path=="ElvUI-Selected-Health" and p.fill.path=="ElvUI-Selected-Power")
        clear(J)
    end)

    test("ElvUI full shells attach independently to all units on "..interface,function(M)
        local J=M.load({interface=interface})
        for _,unit in ipairs({"player","target","focus"}) do
            local root,h,p=elv(M,unit);local key=unit.."Frame"
            near(stack(h,p),50);enable(J,key)
            local u=J.UnitSkins.units[key]
            assert(u.health.bar==h and u.power.bar==p and u.health.trim.frame.shown and u.power.trim.frame.shown)
            assert(u.health.trim.frame.parent==UIParent and h.parent==root and p.parent==root)
            assert(h.ClipFrame.clipsChildren and p.ClipFrame.clipsChildren)
            near(stack(h,p),50);assert(#h.points==1,"Opposing native anchors still constrain fitted height")
            assert(h:GetHeight()<40 and u.health.trim.frame.level>h.level and u.power.trim.frame.level>p.level)
            assert(u.health.trim.frame.level<root.RaisedElementParent.level)
            assert(h.fill.path=="ElvUI-Selected-Health" and p.fill.path=="ElvUI-Selected-Power" and not M.hooks)
            J.ProfileManager:Set(key,"shown",false);assert(u.health.trim.frame.shown)
            local writes=M.nativeLayoutWrites
            for i=1,10 do M.tick(J.Core) end
            assert(M.nativeLayoutWrites==writes,"Stable layout wrote repeatedly")
            J.ProfileManager:Set(key,"unitFrameShown",false)
            near(h:GetHeight(),40);near(p:GetHeight(),8);near(stack(h,p),50)
            assert(#h.points==2 and #p.points==2 and not u.health)
        end
        clear(J)
    end)
end

test("ElvUI source is selectable persisted and waits for the chosen provider",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:Select("targetFrame")
    S.controls.unitFrameSource.options.ELVUI.scripts.OnClick();enable(J,"targetFrame")
    assert(not J.UnitSkins.units.targetFrame.health)
    assert(J.UnitSkins.status.targetFrame:find("Waiting for ElvUI",1,true))
    local root,h,p=elv(M,"target");M.tick(J.Core)
    assert(J.UnitSkins.units.targetFrame.health.bar==h)
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset();assert(J.ProfileManager:Import(backup))
    assert(J.ThemeManager:Resolve("targetFrame").unitFrameSource=="ELVUI")
    J.ProfileManager:Set("targetFrame","unitFrameSource","BLIZZARD")
    near(h:GetHeight(),40);near(p:GetHeight(),8)
    assert(J.UnitSkins.units.targetFrame.health.bar~=h)
    root.shown=false;TargetFrame.shown=true
    J.ProfileManager:Set("targetFrame","unitFrameSource","AUTO")
    assert(J.UnitSkins.units.targetFrame.health.bar~=h)
    root.shown=true;M.tick(J.Core);assert(J.UnitSkins.units.targetFrame.health.bar==h)
    clear(J)
end)

test("ElvUI native redraws container resize and all themes keep the original stack",function(M)
    local J=M.load();local root,h,p=elv(M,"player");enable(J)
    for id in pairs(J.UnitSkinCatalog.entries) do
        J.ProfileManager:Set("playerFrame","portrait",id);J.ProfileManager:Set("playerFrame","portraitMode","FIXED")
        near(stack(h,p),50)
        assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    end
    root.w=300;root.h=64;M.tick(J.Core)
    near(h:GetWidth(),296);near(p:GetWidth(),296);near(stack(h,p),60)
    local writes=M.nativeLayoutWrites;M.tick(J.Core);assert(M.nativeLayoutWrites==writes)
    -- Simulate an ElvUI profile redraw of both bars.
    h.points={{"TOPLEFT",root,"TOPLEFT",6,-4},{"BOTTOMRIGHT",root,"BOTTOMRIGHT",-6,18}}
    p.points={{"TOPLEFT",h.backdrop,"BOTTOMLEFT",1,-1},{"TOPRIGHT",h.backdrop,"BOTTOMRIGHT",-1,-1}};p.h=12
    M.tick(J.Core);near(stack(h,p),56)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    near(h:GetWidth(),288);near(h:GetHeight(),42);near(p:GetHeight(),12)
    assert(h.points[1][4]==6 and #h.points==2 and #p.points==2)
    clear(J)
end)

test("ElvUI detached inset mini offset disabled and vertical bars are not repositioned",function(M)
    local J=M.load();local root,h,p=elv(M,"player");enable(J)
    for _,flag in ipairs({"POWERBAR_DETACHED","USE_INSET_POWERBAR","USE_MINI_POWERBAR","USE_POWERBAR_OFFSET"}) do
        root[flag]=true;M.tick(J.Core)
        near(h:GetHeight(),40);near(p:GetHeight(),8)
        assert(not J.UnitSkins.units.playerFrame.health.trim.frame.shown)
        assert(J.UnitSkins.status.playerFrame:find("attached full-width power",1,true))
        root[flag]=nil;M.tick(J.Core);assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    end
    root.USE_POWERBAR=false;p.shown=false;M.tick(J.Core);near(h:GetHeight(),40)
    root.USE_POWERBAR=true;p.shown=false;M.tick(J.Core);near(h:GetHeight(),40)
    p.shown=true;p.orientation="VERTICAL";M.tick(J.Core);near(h:GetHeight(),40)
    p.orientation="HORIZONTAL";M.tick(J.Core);assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    h.forbidden=true;p.forbidden=true;M.tick(J.Core);assert(not J.UnitSkins.units.playerFrame.trims.health.frame.shown)
    h.forbidden=false;p.forbidden=false;M.tick(J.Core)
    clear(J)
end)

test("ElvUI fitting and restoration defer in combat and follow hidden providers",function(M)
    local J=M.load();local root,h,p=elv(M,"focus");root.shown=false
    J.ProfileManager:Set("focusFrame","unitFrameSource","ELVUI")
    M.combat=true;enable(J,"focusFrame");assert(not M.elvLayoutWrites)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    local u=J.UnitSkins.units.focusFrame;assert(not u.health.trim.frame.shown)
    local writes=M.elvLayoutWrites
    M.combat=true;root.shown=true;M.tick(J.Core);assert(u.health.trim.frame.shown and M.elvLayoutWrites==writes)
    J.ProfileManager:Set("focusFrame","unitFrameShown",false);assert(M.elvLayoutWrites==writes)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");near(h:GetHeight(),40);near(p:GetHeight(),8)
    clear(J)
end)

test("ElvUI fill ownership and late bar replacement preserve provider media",function(M)
    local J=M.load();local root,h,p=elv(M,"player");enable(J)
    J.ProfileManager:Set("playerFrame","unitFrameFill","JIBERISH")
    assert(J.UnitSkins.units.playerFrame.health.active)
    h:SetStatusBarTexture("ElvUI-new-choice")
    J.ProfileManager:Set("playerFrame","unitFrameFill","AUTO")
    assert(h.fill.path=="ElvUI-new-choice" and p.fill.path=="ElvUI-Selected-Power")
    local newRoot,newHealth=elv(M,"player");M.tick(J.Core)
    near(h:GetHeight(),40);assert(J.UnitSkins.units.playerFrame.health.bar==newHealth)
    assert(newHealth.fill.path=="ElvUI-Selected-Health")
    clear(J)
end)

test("ElvUI rounded fitted sizes do not cause repeated writes or shrinking",function(M)
    local J=M.load();local root,h,p=elv(M,"player")
    for _,bar in ipairs({h,p}) do
        local setSize=bar.SetSize
        bar.SetSize=function(self,w,height)
            setSize(self,math.floor(w*100+.5)/100,math.floor(height*100+.5)/100)
        end
    end
    enable(J)
    local height=h:GetHeight();local power=p:GetHeight();local writes=M.elvLayoutWrites
    for i=1,40 do M.tick(J.Core) end
    near(h:GetHeight(),height);near(p:GetHeight(),power)
    assert(M.elvLayoutWrites==writes)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    near(h:GetHeight(),40);near(p:GetHeight(),8);clear(J)
end)
