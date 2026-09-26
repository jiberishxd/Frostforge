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
    assert(S.nativePortraitToggle:IsVisible() and S.nativePortraitFrameToggle:IsVisible() and S.nativeNameToggle:IsVisible())
    S.nativePortraitToggle.scripts.OnClick();S.nativePortraitFrameToggle.scripts.OnClick();S.nativeNameToggle.scripts.OnClick()
    J.ProfileManager:Set("playerFrame","blizzardNameSize",20)
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset("playerFrame");assert(J.ProfileManager:Import(backup))
    local config=J.ThemeManager:Resolve("playerFrame")
    assert(config.blizzardPortraitHidden and config.blizzardPortraitFrameHidden and config.blizzardNameEnabled and config.blizzardNameSize==20)
    assert(not J.ThemeManager:Resolve("targetFrame").blizzardNameEnabled)
    assert(not J.ProfileManager:Set("minimap","blizzardPortraitHidden",true))
    assert(not J.ProfileManager:Set("playerFrame","blizzardNameX",301))
    assert(not J.ProfileManager:Set("playerFrame","blizzardNameSize",5))
    S.nativeReset.scripts.OnClick();assert(not J.ThemeManager:Resolve("playerFrame").blizzardNameEnabled and not J.ThemeManager:Resolve("playerFrame").blizzardPortraitFrameHidden)
    S:Select("actionHub");assert(S.page=="placement" and not S.pageButtons.blizzard:IsVisible())
end)

for _,interface in ipairs({120100,16001}) do
    test("full stock portrait removal preserves bars and restores chrome on "..interface,function(M)
        local J=M.load({interface=interface})
        for _,key in ipairs(keys) do
            local root,portrait,name=J.BlizzardUnits:Regions(key)
            local prefix=key=="playerFrame" and "PlayerFrame" or "TargetFrame"
            local container=root[prefix.."Container"]
            local border=M.region(container,"Texture",232,100);border.stockPresentation=true;border.alpha=.7
            container.FrameTexture=border
            local main=root[prefix.."Content"][prefix.."ContentMain"]
            local badge=M.region(main,"Texture",24,24);badge.stockPresentation=true
            main.LevelBackgroundCircle=badge
            local flash=M.region(main,"Texture",232,100);flash.stockPresentation=true;main.StatusTexture=flash
            J.ProfileManager:Set(key,"blizzardPortraitFrameHidden",true)
            near(border.alpha,.7)
            J.ProfileManager:Set(key,"unitFrameShown",true)
            assert(portrait.alpha==0 and border.alpha==0 and badge.alpha==0 and flash.alpha==0)
            assert(root.shown and main.shown and name.alpha==1)
            local bars=J.Core.client:UnitBars(key)
            assert(bars.health.shown and bars.health.alpha==1 and bars.power.alpha==1)
            M.combat=true;J.ProfileManager:Set(key,"blizzardPortraitFrameHidden",false)
            assert(border.alpha==0)
            M.combat=false;M.tick(J.Core);near(border.alpha,.7);near(badge.alpha,1);near(flash.alpha,1)
            J.ProfileManager:Set(key,"blizzardPortraitFrameHidden",true)
            J.ProfileManager:Set(key,"unitFrameShown",false)
            near(border.alpha,.7);near(portrait.alpha,1)
        end
    end)
end

for _,interface in ipairs({120100,16001}) do
    test("rounded Blizzard anchors do not drift across ticks or slider edits on "..interface,function(M)
        local J=M.load({interface=interface});local _,_,n=J.BlizzardUnits:Regions("targetFrame")
        local getPoint=n.GetPoint
        n.GetPoint=function(self,index)
            local point,relative,relativePoint,x,y=getPoint(self,index)
            return point,relative,relativePoint,x+.0023,y-.0017
        end
        J.ProfileManager:Set("targetFrame","blizzardNameEnabled",true)
        for _,x in ipairs({20,-30,0,50,2}) do
            J.ProfileManager:Set("targetFrame","blizzardNameX",x)
            J.ProfileManager:Set("targetFrame","blizzardNameY",-11)
            local px,py=n.points[1][4],n.points[1][5]
            local writes=M.stockWrites
            for i=1,20 do M.tick(J.Core) end
            near(n.points[1][4],px);near(n.points[1][5],py)
            near(px,5.0023+x);near(py,7.9983-11)
            assert(M.stockWrites==writes,"Rounded readback triggered repeated writes")
        end
        J.ProfileManager:Set("targetFrame","blizzardNameEnabled",false)
        near(n.points[1][4],5.0023);near(n.points[1][5],7.9983)
    end)
end

local function textRegion(M,parent,anchor,x,y)
    local n=M.region(parent,"FontString",100,12);n.stockPresentation=true
    n.points={{anchor,parent,anchor,x,y}};n.font={"Fonts/Test.ttf",11,"OUTLINE"}
    return n
end

test("partial and reordered native text anchors do not double unchanged offsets",function(M)
    local J=M.load();local root,_,n=J.BlizzardUnits:Regions("targetFrame")
    n.points={{"TOPLEFT",root,"TOPLEFT",0,-8},{"TOPRIGHT",root,"TOPRIGHT",0,-8}}
    J.ProfileManager:Set("targetFrame","blizzardNameX",10);J.ProfileManager:Set("targetFrame","blizzardNameY",4)
    J.ProfileManager:Set("targetFrame","blizzardNameEnabled",true)
    n.points={{"TOPRIGHT",root,"TOPRIGHT",10,-4},{"TOPLEFT",root,"TOPLEFT",80,-4}}
    M.tick(J.Core)
    near(n.points[1][4],10);near(n.points[1][5],-4)
    near(n.points[2][4],90);near(n.points[2][5],-4)
    local writes=M.stockWrites
    for i=1,20 do M.tick(J.Core) end
    assert(writes==M.stockWrites)
    J.ProfileManager:Set("targetFrame","blizzardNameEnabled",false)
    near(n.points[1][4],0);near(n.points[1][5],-8)
    near(n.points[2][4],80);near(n.points[2][5],-8)
end)

for _,interface in ipairs({120100,16001}) do
    test("every Blizzard text group adjusts independently and restores on "..interface,function(M)
        local J=M.load({interface=interface})
        for _,key in ipairs(keys) do
            local root,_,name=J.BlizzardUnits:Regions(key)
            local prefix=key=="playerFrame" and "PlayerFrame" or "TargetFrame"
            local main=root[prefix.."Content"][prefix.."ContentMain"]
            local bars=J.Core.client:UnitBars(key)
            bars.health.LeftText=textRegion(M,bars.health,"LEFT",3,0)
            bars.health.LeftText.justify="LEFT"
            bars.health.RightText=textRegion(M,bars.health,"RIGHT",-3,0)
            bars.health.RightText.justify="RIGHT"
            bars.health.TextString=bars.health.LeftText -- duplicate aliases must not double offsets
            bars.power.ManaBarText=textRegion(M,bars.power,"CENTER",0,0)
            main.LevelText=textRegion(M,main,"CENTER",0,0)
            if key=="playerFrame" then PlayerLevelText=main.LevelText end
            local cast=M.region(root,"Frame",150,20);cast.level=499;cast.strata="LOW"
            cast.Text=textRegion(M,cast,"TOPLEFT",0,-8)
            cast.CastTimeText=textRegion(M,cast,"RIGHT",10,0)
            cast.shown=false
            if key=="playerFrame" then PlayerCastingBarFrame=cast else root.spellbar=cast end
            local groups=J.BlizzardUnits:TextRegions(key,root,name)
            local originals={}
            for _,group in ipairs(J.BlizzardUnits.textGroups) do
                for region in pairs(groups[group]) do originals[region]={region.points[1][4],region.points[1][5],region:GetJustifyH()} end
            end
            for i,group in ipairs(J.BlizzardUnits.textGroups) do
                local property="blizzard"..group
                J.ProfileManager:Set(key,property.."X",i*3);J.ProfileManager:Set(key,property.."Y",-i*2)
                J.ProfileManager:Set(key,property.."Size",15)
                J.ProfileManager:Set(key,property.."Align","KEEP")
                J.ProfileManager:Set(key,property.."Enabled",true)
                assert(next(groups[group]),"Missing test group "..group)
                for region in pairs(groups[group]) do
                    near(region.points[1][4],originals[region][1]+i*3)
                    near(region.points[1][5],originals[region][2]-i*2)
                    assert(region.font[2]==15 and region:GetJustifyH()==originals[region][3])
                end
            end
            assert(not cast.shown and root.shown,"Text options changed native visibility")
            local writes=M.stockWrites
            for i=1,5 do M.tick(J.Core) end
            assert(M.stockWrites==writes)
            M.combat=true
            for _,group in ipairs(J.BlizzardUnits.textGroups) do J.ProfileManager:Set(key,"blizzard"..group.."Enabled",false) end
            assert(M.stockWrites==writes)
            M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
            for region,original in pairs(originals) do
                near(region.points[1][4],original[1]);near(region.points[1][5],original[2]);assert(region.font[2]==11)
            end
        end
        assert(not next(J.Core.notices))
    end)
end

test("text selectors and backups retain each label's separate setup",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:SetPage("blizzard")
    for i,group in ipairs(J.BlizzardUnits.textGroups) do
        S.textButtons[group].scripts.OnClick()
        assert(S.textPanels[group]:IsVisible() and S.textGroup==group)
        S.textToggles[group].scripts.OnClick()
        S.controls["blizzard"..group.."X"].slider:SetValue(i*4)
        S.controls["blizzard"..group.."Y"].slider:SetValue(-i)
    end
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset();assert(J.ProfileManager:Import(backup))
    local c=J.ThemeManager:Resolve("playerFrame")
    for i,group in ipairs(J.BlizzardUnits.textGroups) do
        assert(c["blizzard"..group.."Enabled"] and c["blizzard"..group.."X"]==i*4 and c["blizzard"..group.."Y"]==-i)
        assert(not J.ProfileManager:Set("minimap","blizzard"..group.."X",10))
    end
    S.nativeReset.scripts.OnClick()
    for _,group in ipairs(J.BlizzardUnits.textGroups) do assert(not J.ThemeManager:Resolve("playerFrame")["blizzard"..group.."Enabled"]) end
end)
