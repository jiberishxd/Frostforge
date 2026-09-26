local test,near=...
local function fixture(M,key,kind)
    local root=key=="targetFrame" and TargetFrame or FocusFrame
    local region=M.region(root,kind=="Auras" and "AuraContainer" or "StatusBar",150,10)
    region.stockPresentation=true
    region.points={{"TOPLEFT",root,"BOTTOMLEFT",43,5}};region.shown=false
    if kind=="Auras" then
        root.TargetFrameContent.TargetFrameContentContextual=M.region(root.TargetFrameContent,"Frame",200,100)
        root.TargetFrameContent.TargetFrameContentContextual.Auras=region
    else root.spellbar=region;region.fill=M.region(region,"Texture",150,10);region.strata="LOW";region.level=499 end
    return region,root
end

test("aura placement uses the public accessor and follows fresh native baselines on target and focus",function(M)
    local J=M.load()
    for _,key in ipairs({"targetFrame","focusFrame"}) do
        local a,root=fixture(M,key,"Auras")
        root.TargetFrameContent.TargetFrameContentContextual.Auras=nil
        local nativeX,nativeY=5,9
        function root:GetAuraContainer() return a end
        function root:AnchorAuraContainer() a.points={{"TOPLEFT",root,"BOTTOMLEFT",nativeX,nativeY}} end
        root:AnchorAuraContainer()
        J.ProfileManager:Set(key,"blizzardAurasEnabled",true)
        J.ProfileManager:Set(key,"blizzardAurasX",10);J.ProfileManager:Set(key,"blizzardAurasY",20)
        assert(a.points[1][4]==15 and a.points[1][5]==29)
        -- A fresh native baseline may equal the last customized coordinates.
        nativeX,nativeY=15,29;root:AnchorAuraContainer()
        assert(a.points[1][4]==25 and a.points[1][5]==49)
        M.tick(J.Core);assert(a.points[1][4]==25 and a.points[1][5]==49)
        J.ProfileManager:Set(key,"blizzardAurasEnabled",false)
        assert(a.points[1][4]==15 and a.points[1][5]==29)
    end
    assert(not next(J.Core.notices))
end)

test("aura hooks defer in combat and restore after queued disable or profile switch",function(M)
    local J=M.load();local a,root=fixture(M,"targetFrame","Auras")
    local nativeY=9
    function root:AnchorAuraContainer() a.points={{"TOPLEFT",root,"BOTTOMLEFT",5,nativeY}} end
    root:AnchorAuraContainer()
    J.ProfileManager:Set("targetFrame","blizzardAurasEnabled",true)
    J.ProfileManager:Set("targetFrame","blizzardAurasY",80)
    local writes=M.stockWrites;M.combat=true;nativeY=89;root:AnchorAuraContainer()
    J.ProfileManager:Set("targetFrame","blizzardAurasX",20)
    assert(M.stockWrites==writes and a.points[1][5]==89)
    assert(J.BlizzardUnits.placementStatus.targetFrameAuras:find("after combat",1,true))
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(a.points[1][4]==25 and a.points[1][5]==169)
    M.combat=true;J.ProfileManager:Set("targetFrame","blizzardAurasEnabled",false)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(a.points[1][4]==5 and a.points[1][5]==89)
    J.ProfileManager:Set("targetFrame","blizzardAurasEnabled",true)
    J.ProfileManager:SaveAs("No aura customization",true)
    root:AnchorAuraContainer()
    assert(a.points[1][4]==5 and a.points[1][5]==89 and not next(J.Core.notices))
end)

test("aura replacement restores the old group even during a native layout callback",function(M)
    local J=M.load();local a,root=fixture(M,"targetFrame","Auras")
    local current=a
    function root:GetAuraContainer() return current end
    function root:AnchorAuraContainer() current.points={{"TOPLEFT",root,"BOTTOMLEFT",5,9}} end
    root:AnchorAuraContainer()
    J.ProfileManager:Set("targetFrame","blizzardAurasEnabled",true)
    J.ProfileManager:Set("targetFrame","blizzardAurasY",30)
    current=fixture(M,"targetFrame","Auras")
    root:AnchorAuraContainer()
    assert(a.points[1][5]==9 and current.points[1][5]==39)
    J.ProfileManager:Set("targetFrame","blizzardAurasEnabled",false)
    assert(current.points[1][5]==9 and not next(J.Core.notices))
end)

test("unavailable aura anchors report status and recover without reading protected data",function(M)
    local J=M.load();local a,root=fixture(M,"targetFrame","Auras")
    function root:AnchorAuraContainer() a.points={{"TOPLEFT",root,"BOTTOMLEFT",5,9}} end
    a.forbidden=true
    J.ProfileManager:Set("targetFrame","blizzardAurasEnabled",true)
    J.ProfileManager:Set("targetFrame","blizzardAurasY",60)
    assert(J.BlizzardUnits.placementStatus.targetFrameAuras=="Waiting for readable Blizzard anchors.")
    a.forbidden=false;a.points[1][5]=M.secret
    M.tick(J.Core);assert(a.points[1][5]==M.secret)
    root:AnchorAuraContainer();assert(a.points[1][5]==69)
    local S=J.SettingsUI;S:Open();S:Select("targetFrame");S:SetPage("blizzard")
    S.stockAurasButton.scripts.OnClick()
    assert(S.stockPlacementStatus.text=="Applied: X 0 / Y 60")
    J.Core:Status()
    assert(table.concat(M.messages,"\n"):find("targetFrameAuras placement: Applied",1,true))
    assert(not next(J.Core.notices))
end)

test("aura placement guards reentry and can retry after a rejected write",function(M)
    local J=M.load();local a,root=fixture(M,"targetFrame","Auras")
    local nativeAnchor=function() a.points={{"TOPLEFT",root,"BOTTOMLEFT",5,9}} end
    root.AnchorAuraContainer=nativeAnchor;root:AnchorAuraContainer()
    local setPoint=a.SetPoint;local fail=true
    function a:SetPoint(...)
        if fail then error("mock anchor unavailable") end
        -- A native update triggered by this write must not recurse forever.
        root:AnchorAuraContainer();setPoint(self,...)
    end
    J.ProfileManager:Set("targetFrame","blizzardAurasEnabled",true)
    J.ProfileManager:Set("targetFrame","blizzardAurasY",40)
    assert(J.BlizzardUnits.placementStatus.targetFrameAuras=="Placement unavailable; see /jui status.")
    assert(not J.BlizzardUnits.placementBusy.targetFrameAuras)
    fail=false;root:AnchorAuraContainer()
    assert(a.points[#a.points][5]==49 and not J.BlizzardUnits.placementBusy.targetFrameAuras)
end)
for _,interface in ipairs({16001,120100}) do
    for _,kind in ipairs({"Auras","CastPosition"}) do
        test("stock "..kind.." positioning survives reanchor and restores on "..interface,function(M)
            local J=M.load({interface=interface});local region,root=fixture(M,"targetFrame",kind)
            local prefix="blizzard"..kind
            J.ProfileManager:Set("targetFrame",prefix.."X",30)
            J.ProfileManager:Set("targetFrame",prefix.."Y",50)
            assert(region.points[1][4]==43)
            J.ProfileManager:Set("targetFrame",prefix.."Enabled",true)
            assert(region.points[1][4]==73 and region.points[1][5]==55 and not region.shown)
            local writes=M.stockWrites;for i=1,5 do M.tick(J.Core) end;assert(M.stockWrites==writes)
            -- Stock layout replaces the whole anchor when aura rows change.
            region.points={{"BOTTOMLEFT",root,"TOPLEFT",20,-10}};M.tick(J.Core)
            assert(region.points[1][4]==50 and region.points[1][5]==40)
            J.ProfileManager:Set("targetFrame",prefix.."X",40);assert(region.points[1][4]==60 and region.points[1][5]==40)
            M.combat=true;writes=M.stockWrites;J.ProfileManager:Set("targetFrame",prefix.."Y",80)
            assert(M.stockWrites==writes and region.points[1][5]==40)
            M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(region.points[1][5]==70)
            region.forbidden=true;J.ProfileManager:Set("targetFrame",prefix.."Enabled",false)
            region.forbidden=false;M.tick(J.Core)
            assert(region.points[1][4]==20 and region.points[1][5]==-10 and not next(J.Core.notices))
        end)
    end
end

test("target placement controls restore on profile change and leave other providers alone",function(M)
    local J=M.load();local a=fixture(M,"targetFrame","Auras");local bar=fixture(M,"targetFrame","CastPosition")
    local focus=fixture(M,"focusFrame","Auras")
    EllesmereUIUnitFrames_Target=M.native("EllesmereUIUnitFrames_Target",200,60)
    EllesmereUIUnitFrames_Target.Castbar=M.region(EllesmereUIUnitFrames_Target,"StatusBar",150,10)
    local S=J.SettingsUI;S:Open();S:Select("targetFrame");S:SetPage("blizzard")
    S.stockAurasButton.scripts.OnClick();assert(S.stockPlacementDialog:IsShown() and S.stockPlacementPanels.Auras:IsShown())
    S.stockPlacementToggles.Auras.scripts.OnClick();S:Set("blizzardAurasX",10)
    assert(a.points[1][4]==53 and focus.points[1][4]==43)
    S.stockCastPositionButton.scripts.OnClick();S.stockPlacementToggles.CastPosition.scripts.OnClick();S:Set("blizzardCastPositionY",60)
    assert(bar.points[1][5]==65 and #EllesmereUIUnitFrames_Target.Castbar.points==0)
    assert(not J.ProfileManager:Set("playerFrame","blizzardAurasX",10))
    assert(not J.ProfileManager:Set("actionHub","blizzardCastPositionEnabled",true))
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset();assert(a.points[1][4]==43 and bar.points[1][5]==5)
    assert(J.ProfileManager:Import(backup));assert(a.points[1][4]==53 and bar.points[1][5]==65)
    J.ProfileManager:SaveAs("Clean placement",true);assert(a.points[1][4]==43 and bar.points[1][5]==5)
    assert(not next(J.Core.notices))
end)

test("target cast art follows moved stock bars and clears cast-start layers without geometry writes",function(M)
    local J=M.load();local bar,root=fixture(M,"targetFrame","CastPosition");root.level=500
    local fx=M.region(bar,"Frame",150,10);fx.level=510;fx.strata="HIGH"
    bar.GetChildren=function() return fx end
    J.ProfileManager:Set("targetFrame","castBarShown",true)
    J.ProfileManager:Set("targetFrame","castBarSource","BLIZZARD")
    J.ProfileManager:Set("targetFrame","blizzardCastPositionEnabled",true)
    J.ProfileManager:Set("targetFrame","blizzardCastPositionX",60)
    local c=J.CastBars.units.targetFrame
    assert(c.frame.fixedLevel and c.frame.fixedStrata and c.frame.points[1][2]==bar and bar.points[1][4]==103)
    M.combat=true;bar.shown=true;fx.level=700;fx.strata="TOOLTIP"
    local writes=M.geometryWrites;M.tick(J.Core)
    assert(c.active and c.frame.shown and c.frame.strata=="TOOLTIP" and c.frame.level==701 and M.geometryWrites==writes)
    bar.shown=false;J.CastBars:Sync();assert(not c.frame.shown)
    M.combat=false;assert(not next(J.Core.notices))
end)

for _,interface in ipairs({16001,120100}) do
    test("stock aura offsets survive Blizzard's layout callback before the next tick on "..interface,function(M)
        local J=M.load({interface=interface});local a,root=fixture(M,"targetFrame","Auras")
        local rim=M.region(root,"Texture",232,100)
        local nativeX,nativeY,above=5,9,false
        function root:GetAuraContainer() return a end
        function root:AnchorAuraContainer()
            a.points={{above and "BOTTOMLEFT" or "TOPLEFT",rim,above and "TOPLEFT" or "BOTTOMLEFT",nativeX,nativeY}}
        end
        function root:UpdateAuraContainerAnchors() self:AnchorAuraContainer() end
        root:AnchorAuraContainer()
        local S=J.SettingsUI;S:Open();S:Select("targetFrame");S:SetPage("blizzard")
        S.stockAurasButton.scripts.OnClick();S.stockPlacementToggles.Auras.scripts.OnClick()
        -- Exercise the actual vertical slider, then the typed horizontal edit.
        S.controls.blizzardAurasY.slider.scripts.OnValueChanged(nil,70)
        S.controls.blizzardAurasX.edit:SetText("-25");S.controls.blizzardAurasX.edit.scripts.OnEnterPressed()
        assert(a.points[1][4]==-20 and a.points[1][5]==79)
        local hooks=M.hooks
        for i=1,4 do
            M.tick(J.Core);root:UpdateAuraContainerAnchors()
            assert(a.points[1][4]==-20 and a.points[1][5]==79,"Native layout erased configured X/Y after JUI's tick")
        end
        assert(M.hooks==hooks,"Installed duplicate aura hooks")
        above=true;nativeY=-6;root:UpdateAuraContainerAnchors()
        assert(a.points[1][1]=="BOTTOMLEFT" and a.points[1][5]==64)
        nativeY=12;root:UpdateAuraContainerAnchors();assert(a.points[1][5]==82)
        J.ProfileManager:Set("targetFrame","blizzardAurasEnabled",false)
        assert(a.points[1][4]==5 and a.points[1][5]==12)
        root:UpdateAuraContainerAnchors();assert(a.points[1][4]==5 and a.points[1][5]==12)
        assert(not next(J.Core.notices))
    end)
end
