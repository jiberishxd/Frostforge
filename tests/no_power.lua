local test,near=...
local function setup(M,J,provider,key)
    if provider=="BLIZZARD" then
        local bars=J.Core.client:UnitBars(key)
        return _G[key:sub(1,1):upper()..key:sub(2)],bars.health,bars.power
    end
    local title=key:sub(1,1):upper()..key:sub(2):gsub("Frame","")
    local root=M.native((provider=="ELVUI" and "ElvUF_" or "EllesmereUIUnitFrames_")..title,240,50)
    root.rect={400,500};root.level=8;root.strata="MEDIUM"
    local h=M.region(root,"StatusBar",240,40);h.level=10;h.strata="MEDIUM";h.euiLayoutBar=true
    h.points={{"TOPLEFT",root,"TOPLEFT",0,0}}
    local p=M.region(root,"StatusBar",240,8);p.level=11;p.strata="MEDIUM";p.euiLayoutBar=true
    p.points={{"TOPLEFT",h,"BOTTOMLEFT",0,-2}}
    root.Health=h;root.Power=p
    _G[key:sub(1,1):upper()..key:sub(2)].shown=false
    return root,h,p
end
local function seam(u)
    local a,b=u.health.trim.frame,u.footer.trim.frame
    local _,ay= a:GetRect();local _,by,_,bh=b:GetRect()
    near(ay,by+bh)
    local backing=u.footer.backing
    assert(backing.color[4]==1 and backing.color[1]<.03 and backing.sub==-8)
    near(backing.w,u.footer.trim.textures["1_2"].w)
    near(backing.h,u.footer.trim.textures["1_2"].h)
    assert(u.footer.trim.textures["2_2"].texCoord[4]==1,"Lower ornament was cropped")
end
for _,interface in ipairs({120100,16001}) do
    for _,provider in ipairs({"BLIZZARD","ELLESMERE","ELVUI"}) do
        test(provider.." no-power shells retain complete artwork and opaque wells on "..interface,function(M)
            local J=M.load({interface=interface})
            for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
                local root,h,p=setup(M,J,provider,key);p.shown=false
                J.ProfileManager:Set(key,"unitFrameSource",provider)
                J.ProfileManager:Set(key,"unitFrameShown",true)
                local u=J.UnitSkins.units[key]
                assert(u.health.trim.frame.shown and u.footer.trim.frame.shown and not u.power.trim.frame.shown)
                assert(not p.shown and u.footer.trim.frame.parent==UIParent)
                seam(u)
                for id in pairs(J.UnitSkinCatalog.entries) do
                    J.ProfileManager:Set(key,"portraitMode","FIXED");J.ProfileManager:Set(key,"portrait",id)
                    seam(u)
                end
                J.ProfileManager:Set(key,"unitFrameWidth",125);J.ProfileManager:Set(key,"unitFrameHeight",80)
                J.ProfileManager:Set(key,"unitFrameX",9);J.ProfileManager:Set(key,"unitFrameY",-7);seam(u)
                p.shown=true;M.tick(J.Core)
                assert(not u.footer.trim.frame.shown and u.power.trim.frame.shown and u.power.trim.well.frame.shown)
                assert(u.power.trim.well.frame.level<p.level and u.power.trim.well.frame.strata==p.strata)
                local frames,textures=#M.frames,M.textures
                local geometry,writes=M.geometryWrites,M.nativeLayoutWrites
                M.combat=true;p.shown=false;M.tick(J.Core)
                assert(u.footer.trim.frame.shown and not u.power.trim.frame.shown and not u.power.trim.well.frame.shown)
                assert(M.geometryWrites==geometry and M.nativeLayoutWrites==writes)
                seam(u)
                p.shown=true;M.tick(J.Core);assert(not u.footer.trim.frame.shown and u.power.trim.well.frame.shown)
                M.combat=false
                for i=1,4 do p.shown=false;M.tick(J.Core);p.shown=true;M.tick(J.Core) end
                assert(#M.frames==frames and M.textures==textures)
                root.shown=false;M.tick(J.Core)
                assert(not u.health.trim.frame.shown and not u.footer.trim.frame.shown and not u.power.trim.well.frame.shown)
                J.ProfileManager:Set(key,"unitFrameShown",false)
                assert(not u.footer.trim.frame.shown and p.shown)
            end
            assert(not next(J.Core.notices),next(J.Core.notices))
        end)
    end
end

test("missing zero-height and transparent power use a health-anchored footer",function(M)
    local J=M.load();local root,h,p=setup(M,J,"ELVUI","targetFrame")
    root.Power=nil;J.ProfileManager:Set("targetFrame","unitFrameShown",true)
    local u=J.UnitSkins.units.targetFrame;assert(u.footer.trim.frame.shown and not u.power);seam(u)
    root.Power=p;p.h=0;M.tick(J.Core);assert(u.footer.trim.frame.shown);seam(u)
    p.h=8;p.alpha=0;M.tick(J.Core);assert(u.footer.trim.frame.shown);seam(u)
    p.alpha=1;M.tick(J.Core);assert(not u.footer.trim.frame.shown and u.power.trim.frame.shown)
    h.forbidden=true;M.tick(J.Core);assert(not u.footer.trim.frame.shown)
    assert(not next(J.Core.notices),next(J.Core.notices))
end)

test("hidden power containers keep full artwork while the health bar remains visible",function(M)
    local J=M.load();local bars=J.Core.client:UnitBars("playerFrame")
    local parent=bars.power:GetParent();parent.shown=false
    J.ProfileManager:Set("playerFrame","unitFrameShown",true)
    local u=J.UnitSkins.units.playerFrame
    assert(bars.power.shown and u.footer.trim.frame.shown and not u.power.trim.frame.shown);seam(u)
    parent.shown=true;parent.alpha=0;M.tick(J.Core);assert(u.footer.trim.frame.shown)
    parent.alpha=1;M.tick(J.Core);assert(not u.footer.trim.frame.shown and u.power.trim.well.frame.shown)
    assert(not next(J.Core.notices),next(J.Core.notices))
end)
