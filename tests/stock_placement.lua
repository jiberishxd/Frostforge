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
