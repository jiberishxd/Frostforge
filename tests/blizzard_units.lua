local test,near=...
local keys={"playerFrame","targetFrame","focusFrame"}
for _,interface in ipairs({120100,16001}) do
    test("stock portrait and name controls restore exactly on "..interface,function(M)
        local J=M.load({interface=interface})
        assert((M.stockWrites or 0)==0)
        for _,key in ipairs(keys) do
            local root,portrait,name=J.BlizzardUnits:Regions(key)
            local points=name.points;local path,size,flags=name:GetFont();local align=name:GetJustifyH()
            portrait.alpha=.6
            J.ProfileManager:Set(key,"blizzardPortraitHidden",true)
            assert(portrait.alpha==0 and root.shown and portrait.shown and J.Core.modules[key].frame.shown)
            J.ProfileManager:Set(key,"blizzardNameX",21);J.ProfileManager:Set(key,"blizzardNameY",-10)
            J.ProfileManager:Set(key,"blizzardNameSize",18);J.ProfileManager:Set(key,"blizzardNameAlign","RIGHT")
            J.ProfileManager:Set(key,"blizzardNameOutline","OUTLINE")
            assert(name.points==points and select(2,name:GetFont())==size,"Disabled name controls changed the label")
            J.ProfileManager:Set(key,"blizzardNameEnabled",true)
            assert(select(2,name:GetFont())==18 and name:GetJustifyH()=="RIGHT")
            near(name.points[1][4],26);near(name.points[1][5],-2)
            local writes=M.stockWrites
            for i=1,5 do M.tick(J.Core) end
            assert(M.stockWrites==writes,"Repeated writes or offset drift")
            J.ProfileManager:Set(key,"shown",false);assert(portrait.alpha==0,"Portrait-art toggle changed stock option")
            J.ProfileManager:Set(key,"blizzardPortraitHidden",false);near(portrait.alpha,.6)
            J.ProfileManager:Set(key,"blizzardNameEnabled",false)
            assert(name:GetFont()==path and select(2,name:GetFont())==size and select(3,name:GetFont())==flags)
            assert(name:GetJustifyH()==align and name.points[1][2]==points[1][2])
            near(name.points[1][4],5);near(name.points[1][5],8)
        end
        assert(not next(J.Core.notices))
    end)
end

test("stock options queue in combat and restore when Blizzard frame is hidden",function(M)
    local J=M.load();local root,p,n=J.BlizzardUnits:Regions("playerFrame")
    M.combat=true;J.ProfileManager:Set("playerFrame","blizzardPortraitHidden",true)
    J.ProfileManager:Set("playerFrame","blizzardNameEnabled",true)
    assert(p.alpha==1 and (M.stockWrites or 0)==0)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(p.alpha==0)
    local writes=M.stockWrites
    M.combat=true;J.ProfileManager:Reset("playerFrame");assert(p.alpha==0 and M.stockWrites==writes)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(p.alpha==1)
    J.ProfileManager:Set("playerFrame","blizzardPortraitHidden",true)
    J.ProfileManager:Set("playerFrame","blizzardNameEnabled",true)
    root.shown=false;M.tick(J.Core);assert(p.alpha==1 and select(2,n:GetFont())==11)
    root.shown=true;M.tick(J.Core);assert(p.alpha==0 and select(2,n:GetFont())==12)
end)

test("stock name follows native layout updates without offset accumulation",function(M)
    local J=M.load();local root,p,n=J.BlizzardUnits:Regions("targetFrame")
    J.ProfileManager:Set("targetFrame","blizzardNameX",10);J.ProfileManager:Set("targetFrame","blizzardNameEnabled",true)
    n.points={{"LEFT",root,"LEFT",80,30},{"RIGHT",root,"RIGHT",-15,30}}
    n.font={"Fonts/Other.ttf",14,"THICKOUTLINE"}
    M.tick(J.Core)
    assert(n.points[1][4]==90 and n.points[2][4]==-5 and n.font[2]==12 and n.font[3]=="THICKOUTLINE")
    J.ProfileManager:Set("targetFrame","blizzardNameEnabled",false)
    assert(n.points[1][4]==80 and n.points[2][4]==-15 and n.font[2]==14 and n.font[1]=="Fonts/Other.ttf")
    assert(n.points[1][2]==root)
end)

test("stock options leave missing forbidden and restricted regions alone and recover",function(M)
    local J=M.load();local root,p,n=J.BlizzardUnits:Regions("focusFrame")
    p.forbidden=true;n.forbidden=true
    J.ProfileManager:Set("focusFrame","blizzardPortraitHidden",true)
    J.ProfileManager:Set("focusFrame","blizzardNameEnabled",true)
    assert((M.stockWrites or 0)==0)
    p.forbidden=false;n.forbidden=false;local read=n.GetFont
    n.GetFont=function() return M.secret,12,"" end
    M.tick(J.Core);assert(p.alpha==0 and not J.BlizzardUnits.units.focusFrame.name)
    n.GetFont=read;M.tick(J.Core);assert(J.BlizzardUnits.units.focusFrame.name)
    root.forbidden=true;M.tick(J.Core);assert(p.alpha==1 and n.font[2]==11)
    assert(not next(J.Core.notices))
end)

test("stock controls restore old labels when native regions are replaced",function(M)
    local J=M.load();local root,p,n=J.BlizzardUnits:Regions("playerFrame")
    J.ProfileManager:Set("playerFrame","blizzardNameEnabled",true)
    J.ProfileManager:Set("playerFrame","blizzardPortraitHidden",true)
    M.native("PlayerFrame",232,100,1.3)
    M.tick(J.Core)
    local _,p2,n2=J.BlizzardUnits:Regions("playerFrame")
    assert(p.alpha==1 and n.font[2]==11 and p2.alpha==0 and n2.font[2]==12)
    assert(J.BlizzardUnits.units.playerFrame.name.region==n2)
end)

test("stock configuration is scoped persisted and reset through its own settings page",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:SetPage("blizzard")
    assert(S.nativePortraitToggle:IsVisible() and S.nativeNameToggle:IsVisible())
    S.nativePortraitToggle.scripts.OnClick();S.nativeNameToggle.scripts.OnClick()
    J.ProfileManager:Set("playerFrame","blizzardNameSize",20)
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset("playerFrame");assert(J.ProfileManager:Import(backup))
    local config=J.ThemeManager:Resolve("playerFrame")
    assert(config.blizzardPortraitHidden and config.blizzardNameEnabled and config.blizzardNameSize==20)
    assert(not J.ThemeManager:Resolve("targetFrame").blizzardNameEnabled)
    assert(not J.ProfileManager:Set("minimap","blizzardPortraitHidden",true))
    assert(not J.ProfileManager:Set("playerFrame","blizzardNameX",301))
    assert(not J.ProfileManager:Set("playerFrame","blizzardNameSize",5))
    S.nativeReset.scripts.OnClick();assert(not J.ThemeManager:Resolve("playerFrame").blizzardNameEnabled)
    S:Select("actionHub");assert(S.page=="placement" and not S.pageButtons.blizzard:IsVisible())
end)
