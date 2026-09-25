-- Extra assertions use the same no-functional-native-writes harness.
return function(test,near)
local function bars(J,key) return J.Core.client:UnitBars(key or "playerFrame") end
local function enable(J,key) assert(J.ProfileManager:Set(key or "playerFrame","unitStyle","FULL")) end

test("portrait-only remains default without touching native bar appearance",function(M)
    local J=M.load()
    assert(not next(J.UnitSkins.units) and not M.hooks and not M.appearanceWrites)
    assert(J.ThemeManager:Resolve("playerFrame").unitStyle=="PORTRAIT")
end)
for _,interface in ipairs({120100,16001}) do
    test("optional full skin fits both native bars on client "..interface,function(M)
        local J=M.load({interface=interface})
        for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
            enable(J,key)
            local native=bars(J,key)
            for kind,bar in pairs(native) do
                local r=J.UnitSkins.units[key][kind]
                assert(r.active and r.trim.frame.parent==UIParent and r.trim.frame.mouse==false)
                assert(bar.fill.path==J.UnitSkinCatalog.entries[r.id][kind] and bar.fill.atlas==nil)
                assert(r.trim.frame.points[1][2]==bar)
                near(r.trim.frame:GetEffectiveScale(),bar:GetEffectiveScale())
                local opening=J.UnitSkinCatalog.entries[r.id].opening
                local h,p=opening.health,opening.power
                near(r.trim.frame.w,bar.w+(512-h[3]+h[1])*r.geometry.capScale)
                near(r.trim.frame.h,bar.h+(kind=="health" and (h[2]+p[2]-h[4])*r.geometry.capScale or (256-p[4])*r.geometry.capScale))
                local config=J.ThemeManager:Resolve(key)
                assert(r.trim.frame.strata==config.strata and r.trim.frame.level==config.level)
                assert(r.trim.frame.shown)
            end
        end
        assert(not next(J.Core.notices))
    end)
end

test("disabling full skin restores exact original atlas and UVs",function(M)
    local J=M.load();local b=bars(J).health;local atlas=b.fill.atlas
    local coords={b.fill:GetTexCoord()}
    enable(J);assert(J.ProfileManager:Set("playerFrame","unitStyle","PORTRAIT"))
    assert(b.fill.atlas==atlas)
    for i,v in ipairs({b.fill:GetTexCoord()}) do near(v,coords[i]) end
    assert(not J.UnitSkins.units.playerFrame.health)
    for _,t in pairs(J.UnitSkins.units.playerFrame.trims) do assert(not t.frame.shown) end
end)

test("file-ID texture sources restore without assuming a native atlas",function(M)
    local J=M.load();local b=bars(J).health;b.fill.atlas=nil;b.fill.path=123456
    enable(J);J.ProfileManager:Reset("playerFrame")
    assert(b.fill.path==123456 and not b.fill.atlas)
end)

test("texture redraw hooks defer writes and preserve the newest native atlas",function(M)
    local J=M.load();enable(J);local b=bars(J).health
    b.fill:SetAtlas("Native-Vehicle-Health")
    local writes=M.appearanceWrites
    assert(b.fill.atlas=="Native-Vehicle-Health")
    M.tick(J.Core)
    assert(M.appearanceWrites>writes and b.fill.path==J.UnitSkinCatalog.entries.CLASS_PALADIN.health)
    J.ProfileManager:Set("playerFrame","unitStyle","PORTRAIT")
    assert(b.fill.atlas=="Native-Vehicle-Health")
end)

test("UV-only redraws cannot capture our replacement as the original",function(M)
    local J=M.load();local b=bars(J).health;local original=b.fill.atlas;enable(J)
    b.fill:SetTexCoord(0,1,0,1);M.tick(J.Core)
    J.ProfileManager:Set("playerFrame","unitStyle","PORTRAIT")
    assert(b.fill.atlas==original)
end)

test("enable disable and native redraws never write appearance in combat",function(M)
    local J=M.load();local b=bars(J).health;local original=b.fill.atlas
    M.combat=true;enable(J)
    assert(not M.appearanceWrites)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    local writes=M.appearanceWrites;M.combat=true
    J.ProfileManager:Set("playerFrame","unitStyle","PORTRAIT");M.tick(J.Core)
    assert(M.appearanceWrites==writes and J.UnitSkins.units.playerFrame.health.active)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(b.fill.atlas==original)
    enable(J);M.combat=true
    -- Simulate a Blizzard engine redraw (not an addon call) during lockdown.
    b.fill.atlas="Native-Combat-Redraw";b.fill.path="native-textures"
    J.UnitSkins.units.playerFrame.health.external=true
    writes=M.appearanceWrites;M.tick(J.Core);assert(M.appearanceWrites==writes)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    J.ProfileManager:Set("playerFrame","unitStyle","PORTRAIT")
    assert(b.fill.atlas=="Native-Combat-Redraw")
end)

test("shell themes preserve the health-bar anchor independently of portrait sizing",function(M)
    local J=M.load();enable(J,"targetFrame")
    local r=J.UnitSkins.units.targetFrame.health;local w,h=r.trim.frame.w,r.trim.frame.h
    for id in pairs(J.PortraitCatalog.entries) do
        J.ProfileManager:Set("targetFrame","portraitMode","FIXED")
        J.ProfileManager:Set("targetFrame","portrait",id)
        assert(r.id==id and r.trim.textures["1_1"].path==J.UnitSkinCatalog.entries[id].shell
            and r.texture.path==J.UnitSkinCatalog.entries[id].health)
        near(r.trim.textures["1_2"].w,bars(J,"targetFrame").health.w)
        assert(r.trim.frame.points[1][2]==bars(J,"targetFrame").health)
    end
    J.ProfileManager:Set("targetFrame","portraitMode","CLASS")
    M.unitData.target.class="DEATHKNIGHT";M.tick(J.Core)
    assert(r.id=="CLASS_DEATHKNIGHT")
    w,h=r.trim.frame.w,r.trim.frame.h
    J.ProfileManager:Set("targetFrame","width",190);J.ProfileManager:Set("targetFrame","x",80)
    near(r.trim.frame.w,w);near(r.trim.frame.h,h)
end)

test("native resizing scale and hidden power bars are followed independently",function(M)
    local J=M.load();enable(J)
    local b=bars(J);b.health.w=180;b.health.h=24;b.health.scale=1.4;b.power.shown=false
    UIParent.scale=.8;M.tick(J.Core)
    local unit=J.UnitSkins.units.playerFrame
    local opening=J.UnitSkinCatalog.entries[unit.health.id].opening.health
    near(unit.health.trim.frame.w,180+(512-opening[3]+opening[1])*24/(opening[4]-opening[2]));near(unit.health.trim.frame:GetEffectiveScale(),b.health:GetEffectiveScale())
    assert(unit.health.trim.frame.shown and not unit.power.trim.frame.shown)
    b.power.shown=true;M.tick(J.Core);assert(unit.power.trim.frame.shown)
    PlayerFrame.shown=false;M.tick(J.Core);assert(not unit.health.trim.frame.shown)
end)

test("repeated style toggles reuse shell halves and secure hook dispatchers",function(M)
    local J=M.load();enable(J)
    local frames,textures,hooks=#M.frames,M.textures,M.hooks
    local writes=M.appearanceWrites
    for i=1,5 do M.tick(J.Core) end
    assert(M.appearanceWrites==writes)
    for i=1,10 do
        J.ProfileManager:Set("playerFrame","unitStyle","PORTRAIT");enable(J)
    end
    assert(#M.frames==frames and M.textures==textures and M.hooks==hooks)
end)

test("missing forbidden and restricted native fill regions stay untouched",function(M)
    local J=M.load();local b=bars(J)
    b.health.fill.forbidden=true;b.power.fill.secretCoords=true
    enable(J)
    assert(not M.appearanceWrites and not next(J.Core.notices))
    b.health.fill.forbidden=false;b.power.fill.secretCoords=false;M.tick(J.Core)
    assert(J.UnitSkins.units.playerFrame.health.active)
    b.health.fill.forbidden=true
    J.ProfileManager:Set("playerFrame","unitStyle","PORTRAIT")
    assert(not J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    b.health.fill.forbidden=false;M.tick(J.Core)
    assert(b.health.fill.atlas=="Native-PlayerFrame-Health")
end)

test("forbidden intermediate containers are rejected on both adapters",function(M)
    local J=M.load()
    PlayerFrame.PlayerFrameContent.forbidden=true
    enable(J)
    assert(not M.appearanceWrites and not next(J.Core.notices))
    assert(not J.Core.clients.forever:UnitBars("playerFrame"))
end)

test("style persists independently with scoped validation and UI control",function(M)
    local J=M.load();J.Core:Command("jui");J.SettingsUI:Open()
    assert(J.SettingsUI.styleButton.shown)
    J.SettingsUI.styleButton.scripts.OnClick()
    assert(J.ThemeManager:Resolve("playerFrame").unitStyle=="FULL")
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset()
    assert(J.ProfileManager:Import(backup) and J.ThemeManager:Resolve("playerFrame").unitStyle=="FULL")
    assert(J.ThemeManager:Resolve("targetFrame").unitStyle=="PORTRAIT")
    assert(not J.ProfileManager:Set("minimap","unitStyle","FULL"))
    assert(not J.ProfileManager:Set("playerFrame","unitStyle","INVALID"))
    J.SettingsUI:Select("minimap");assert(not J.SettingsUI.styleButton.shown)
end)

test("missing fill assets restore native texture immediately",function(M)
    local J=M.load();local b=bars(J).health;local old=b.fill.atlas
    M.missingTexture=true;enable(J)
    assert(b.fill.atlas==old and not J.UnitSkins.units.playerFrame.health.active)
    M.missingTexture=false;M.tick(J.Core)
    assert(b.fill.path==J.UnitSkinCatalog.entries.CLASS_PALADIN.health)
end)

test("native fill replacement restores old region and styles the new one",function(M)
    local J=M.load();enable(J);local b=bars(J).health;local old=b.fill
    local replacement=bars(J,"targetFrame").health.fill
    b.fill=replacement;M.tick(J.Core)
    assert(old.atlas=="Native-PlayerFrame-Health")
    assert(replacement.path==J.UnitSkinCatalog.entries.CLASS_PALADIN.health)
    J.ProfileManager:Reset("playerFrame")
    assert(replacement.atlas=="Native-TargetFrame-Health")
end)

test("full-skin profile reload is opt in and saves per unit",function(M)
    local J=M.load({db={phase1={version=2,theme="paladin_ret",modules={focusFrame={unitStyle="FULL"}}}}})
    assert(J.UnitSkins.units.focusFrame.health.active)
    assert(not J.UnitSkins.units.playerFrame and not J.UnitSkins.units.targetFrame)
    local restored=M.load({db=JiberishUIDB})
    assert(restored.ThemeManager:Resolve("focusFrame").unitStyle=="FULL")
end)

test("sculpted openings contain no art regions and mirror around native bars",function(M)
    local J=M.load()
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
        enable(J,key)
        local u=J.UnitSkins.units[key]
        assert(not u.health.trim.textures["2_2"] and not u.power.trim.textures["1_2"])
        local count=0
        for _,r in ipairs({u.health,u.power}) do
            for _,texture in pairs(r.trim.textures) do
                count=count+1;assert(texture.w>0 and texture.h>0)
                local uv=texture.texCoord
                assert((uv[1]>uv[2])==(key~="playerFrame"))
            end
        end
        assert(count==13)
    end
end)

test("theme changes replace both painted fills but preserve native restoration",function(M)
    local J=M.load();local b=bars(J);local original=b.health.fill.atlas;local powerOriginal=b.power.fill.atlas;enable(J)
    J.ProfileManager:Set("playerFrame","portraitMode","FIXED")
    J.ProfileManager:Set("playerFrame","portrait","CLASS_SHAMAN")
    assert(b.health.fill.path==J.UnitSkinCatalog.entries.CLASS_SHAMAN.health)
    assert(b.power.fill.path==J.UnitSkinCatalog.entries.CLASS_SHAMAN.power)
    J.ProfileManager:Set("playerFrame","unitStyle","PORTRAIT")
    assert(b.health.fill.atlas==original and b.power.fill.atlas==powerOriginal)
end)

test("shell layers follow user settings and defer protected changes in combat",function(M)
    local J=M.load();enable(J)
    local u=J.UnitSkins.units.playerFrame
    M.combat=true
    J.ProfileManager:Set("playerFrame","strata","HIGH")
    J.ProfileManager:Set("playerFrame","level",42)
    J.ProfileManager:Set("playerFrame","layer","ARTWORK")
    assert(u.health.trim.frame.strata=="BACKGROUND")
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    for _,r in ipairs({u.health,u.power}) do
        assert(r.trim.frame.strata=="HIGH" and r.trim.frame.level==42)
        for _,texture in pairs(r.trim.textures) do assert(texture.layer=="ARTWORK") end
    end
end)

test("restricted fill metadata does not hide independently fitted artwork",function(M)
    local J=M.load();enable(J);local b=bars(J).health
    b.fill:SetAtlas("Native-Changed-Health");b.fill.secretCoords=true
    M.tick(J.Core)
    assert(b.fill.atlas=="Native-Changed-Health")
    assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    assert(J.UnitSkins.status.playerFrame:find("native fill retained",1,true))
    b.fill.secretCoords=false;M.tick(J.Core)
    assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    J.ProfileManager:Set("playerFrame","unitStyle","PORTRAIT")
    assert(b.fill.atlas=="Native-Changed-Health")
end)

for _,interface in ipairs({120100,16001}) do
    test("portrait and unit-frame toggles are independent on client "..interface,function(M)
        local J=M.load({interface=interface})
        J.SettingsUI:Open()
        for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
            J.SettingsUI:Select(key)
            for _,pair in ipairs({{true,false},{false,false},{false,true},{true,true},{true,false}}) do
                local portrait,shell=pair[1],pair[2]
                local c=J.ThemeManager:Resolve(key)
                if c.shown~=portrait then J.SettingsUI.showButton.scripts.OnClick() end
                c=J.ThemeManager:Resolve(key)
                if c.unitFrameShown~=shell then J.SettingsUI.styleButton.scripts.OnClick() end
                assert(J.Core.modules[key].frame.shown==portrait)
                local u=J.UnitSkins.units[key]
                if shell then
                    assert(u.health.trim.frame.shown and u.power.trim.frame.shown)
                    assert(u.health.active and u.power.active)
                elseif u then
                    for _,trim in pairs(u.trims) do assert(not trim.frame.shown) end
                end
                assert(J.SettingsUI.showButton.check.shown==portrait)
                assert(J.SettingsUI.styleButton.check.shown==shell)
            end
        end
    end)
end

test("Forever uses initialized native bar bindings when XML child paths differ",function(M)
    local J=M.load({interface=16001})
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
        local b=bars(J,key);local root=J.Core.client:Resolve(key)
        root.healthbar,root.manabar=b.health,b.power
        root.PlayerFrameContent,root.TargetFrameContent=nil,nil
        J.ProfileManager:Set(key,"unitFrameShown",true)
        local u=J.UnitSkins.units[key]
        assert(u.health.bar==b.health and u.power.bar==b.power)
        assert(u.health.trim.frame.shown and u.power.trim.frame.shown)
    end
end)

test("unreadable fill at first enable leaves shells visible and retries materials",function(M)
    local J=M.load({interface=16001});local b=bars(J)
    b.health.fill.secretCoords=true;b.power.fill.forbidden=true
    enable(J)
    local u=J.UnitSkins.units.playerFrame
    assert(u.health.trim.frame.shown and u.power.trim.frame.shown)
    assert(not M.appearanceWrites)
    b.health.fill.secretCoords=false;b.power.fill.forbidden=false
    M.tick(J.Core)
    assert(u.health.active and u.power.active)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    assert(b.health.fill.atlas=="Native-PlayerFrame-Health")
    assert(b.power.fill.atlas=="Native-PlayerFrame-Mana")
end)

test("shells are independent of native fill getter failures",function(M)
    local J=M.load({interface=16001});local b=bars(J)
    b.health.fill.GetTexCoord=function() error("Texture coordinates unavailable") end
    b.power.fill.GetAtlas=function() error("Atlas unavailable") end
    enable(J)
    local u=J.UnitSkins.units.playerFrame
    assert(u.health.trim.frame.shown and u.power.trim.frame.shown)
    assert(not M.appearanceWrites and not next(J.Core.notices))
end)

test("missing secret and throwing fill objects cannot block the shell",function(M)
    local J=M.load({interface=16001});local b=bars(J)
    b.health.GetStatusBarTexture=function() return M.secret end
    b.power.GetStatusBarTexture=function() error("Texture not ready") end
    enable(J)
    local u=J.UnitSkins.units.playerFrame
    assert(u.health.trim.frame.shown and u.power.trim.frame.shown)
    assert(not M.appearanceWrites and not next(J.Core.notices))
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    assert(not u.health and not u.power)
end)

test("separate toggles migrate and round trip without losing hidden portraits",function(M)
    local J=M.load({db={phase1={version=2,theme="paladin_ret",modules={
        playerFrame={shown=false,unitStyle="FULL"},targetFrame={shown=true,unitStyle="PORTRAIT"},
        focusFrame={shown=false,unitStyle="FULL",unitFrameShown=false},
    }}}})
    assert(not J.Core.modules.playerFrame.frame.shown and J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    assert(not J.ThemeManager:Resolve("focusFrame").unitFrameShown)
    local backup=J.ProfileManager:Export()
    assert(backup:find("playerFrame.unitFrameShown=true",1,true) and not backup:find("unitStyle",1,true))
    J.ProfileManager:Reset();assert(J.ProfileManager:Import(backup))
    assert(not J.Core.modules.playerFrame.frame.shown and J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    assert(J.ProfileManager:Import("JF2;paladin_ret;playerFrame.shown=false;playerFrame.unitStyle=FULL"))
    assert(not J.Core.modules.playerFrame.frame.shown and J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    assert(not J.ProfileManager:Set("minimap","unitFrameShown",true))
end)

test("thick source divider gets real spacing and restores native power geometry",function(M)
    local J=M.load({interface=16001});local b=bars(J)
    local width,height=b.power.w,b.power.h
    local point={b.power:GetPoint()}
    enable(J)
    local h,p=J.UnitSkinCatalog.entries.CLASS_PALADIN.opening.health,J.UnitSkinCatalog.entries.CLASS_PALADIN.opening.power
    local k=b.health.h/(h[4]-h[2])
    assert(-b.power.points[1][5]>5)
    near(b.power.points[1][5],-(p[2]-h[4])*k)
    near(b.power.h,(p[4]-p[2])*k)
    assert(b.power.points[1][2]==b.health and b.power.w==b.health.w)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    near(b.power.w,width);near(b.power.h,height)
    for i,v in ipairs(point) do assert(b.power.points[1][i]==v) end
end)

test("power layout enable and restoration wait until combat ends",function(M)
    local J=M.load();local b=bars(J);local point={b.power:GetPoint()}
    M.combat=true;enable(J);assert(not M.nativeLayoutWrites)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    local writes=M.nativeLayoutWrites;assert(writes>0)
    M.combat=true;J.ProfileManager:Set("playerFrame","unitFrameShown",false);M.tick(J.Core)
    assert(M.nativeLayoutWrites==writes)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    for i,v in ipairs(point) do assert(b.power.points[1][i]==v) end
end)

test("new native power layout supersedes old restore geometry",function(M)
    local J=M.load();local b=bars(J);enable(J)
    b.power.points={{"TOPLEFT",PlayerFrame,"TOPLEFT",94,-80}};b.power.w=160;b.power.h=12
    M.tick(J.Core)
    J.ProfileManager:Set("playerFrame","unitFrameShown",false)
    assert(b.power.points[1][2]==PlayerFrame and b.power.points[1][4]==94 and b.power.points[1][5]==-80)
    assert(b.power.w==160 and b.power.h==12)
end)

test("stable full-frame ticks do not repeat native layout writes",function(M)
    local J=M.load();enable(J);local writes=M.nativeLayoutWrites
    for i=1,15 do M.tick(J.Core) end
    assert(M.nativeLayoutWrites==writes)
end)


test("every theme has a narrow painted inset above native fills and outside their center",function(M)
    local J=M.load();enable(J)
    J.ProfileManager:Set("playerFrame","portraitMode","FIXED")
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
    enable(J,key);J.ProfileManager:Set(key,"portraitMode","FIXED")
    for id in pairs(J.UnitSkinCatalog.entries) do
        J.ProfileManager:Set(key,"portrait",id)
        for _,kind in ipairs({"health","power"}) do
            local record=J.UnitSkins.units[key][kind];local rim=record.trim.rim
            assert(rim.frame.shown and rim.frame.mouse==false and rim.frame.level==record.bar:GetFrameLevel()+1)
            near(rim.frame.w,record.bar.w);near(rim.frame.h,record.bar.h)
            for name,t in pairs(rim.textures) do
                local x,y=t.points[1][4],-t.points[1][5]
                assert(x>=0 and y>=0 and x+t.w<=rim.frame.w+.001 and y+t.h<=rim.frame.h+.001)
                assert(not (x<rim.frame.w/2 and x+t.w>rim.frame.w/2 and y<rim.frame.h/2 and y+t.h>rim.frame.h/2))
                if not name:find("Shadow") then
                    assert(t.path==J.UnitSkinCatalog.entries[id].shell)
                    assert((t.texCoord[1]>t.texCoord[2])==(key~="playerFrame"))
                end
            end
        end
    end
    end
end)

test("shell width and height resize art around one center without changing bars or portraits",function(M)
    local J=M.load();enable(J)
    local u=J.UnitSkins.units.playerFrame;local b=bars(J);local hw,hh,pw,ph=b.health.w,b.health.h,b.power.w,b.power.h
    local healthW,healthH,powerH=u.health.trim.frame.w,u.health.trim.frame.h,u.power.trim.frame.h
    local portraitW,portraitH=J.Core.modules.playerFrame.frame.w,J.Core.modules.playerFrame.frame.h
    J.SettingsUI:Open();J.SettingsUI:SetPage("fitting")
    assert(J.SettingsUI.controls.unitFrameWidth.edit:IsVisible())
    J.SettingsUI.controls.unitFrameWidth.slider:SetValue(110)
    J.SettingsUI.controls.unitFrameHeight.slider:SetValue(120)
    near(u.health.trim.frame.w,healthW*1.1);near(u.health.trim.frame.h,healthH*1.2);near(u.power.trim.frame.h,powerH*1.2)
    local entry=J.UnitSkinCatalog.entries[u.health.id];local k=u.health.geometry.capScale
    local powerOrigin=(entry.opening.power[2]-entry.opening.health[2])*k
    local healthBottom=-u.health.trim.frame.points[1][5]+u.health.trim.frame.h
    local powerTop=powerOrigin-u.power.trim.frame.points[1][5]
    near(healthBottom,powerTop)
    near(u.health.trim.rim.frame.w,hw*1.1);near(u.health.trim.rim.frame.h,hh*1.2)
    assert(b.health.w==hw and b.health.h==hh and b.power.w==pw and b.power.h==ph)
    assert(J.Core.modules.playerFrame.frame.w==portraitW and J.Core.modules.playerFrame.frame.h==portraitH)
    J.SettingsUI:Select("minimap");assert(J.SettingsUI.page=="placement" and not J.SettingsUI.pageButtons.fitting.shown)
end)

test("inset and fitting changes queue in combat then reuse existing frames",function(M)
    local J=M.load();enable(J);local trim=J.UnitSkins.units.playerFrame.health.trim
    local w=trim.frame.w;local frames,textures=#M.frames,M.textures
    M.combat=true;J.ProfileManager:Set("playerFrame","unitFrameWidth",115);J.ProfileManager:Set("playerFrame","unitFrameInset",0)
    assert(trim.frame.w==w and trim.rim.frame.shown)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    near(trim.frame.w,w*1.15);assert(not trim.rim.frame.shown and trim.frame.shown)
    J.ProfileManager:Set("playerFrame","unitFrameInset",2)
    assert(trim.rim.frame.shown and #M.frames==frames and M.textures==textures)
    local writes=M.geometryWrites
    for i=1,10 do M.tick(J.Core) end
    assert(writes==M.geometryWrites)
end)

test("unit artwork fitting settings validate and round trip independently",function(M)
    local J=M.load()
    assert(J.ProfileManager:Set("targetFrame","unitFrameWidth",90))
    assert(J.ProfileManager:Set("targetFrame","unitFrameHeight",125))
    assert(J.ProfileManager:Set("targetFrame","unitFrameInset",2))
    assert(not J.ProfileManager:Set("minimap","unitFrameWidth",90))
    assert(not J.ProfileManager:Set("targetFrame","unitFrameWidth",0))
    assert(not J.ProfileManager:Set("targetFrame","unitFrameHeight",151))
    assert(not J.ProfileManager:Set("targetFrame","unitFrameInset",4))
    local backup=J.ProfileManager:Export();J.ProfileManager:Reset();assert(J.ProfileManager:Import(backup))
    local c=J.ThemeManager:Resolve("targetFrame")
    assert(c.unitFrameWidth==90 and c.unitFrameHeight==125 and c.unitFrameInset==2)
    assert(J.ThemeManager:Resolve("playerFrame").unitFrameWidth==100)
end)

test("protected inner rim is retired only after queued hiding completes",function(M)
    local J=M.load();J.ProfileManager:Set("playerFrame","unitFrameFill","PROVIDER");enable(J)
    local record=J.UnitSkins.units.playerFrame.health;record.trim.rim.frame.protected=true
    M.combat=true;J.ProfileManager:Set("playerFrame","unitFrameShown",false);M.tick(J.Core)
    assert(J.UnitSkins.units.playerFrame.health==record and record.trim.rim.frame.shown)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(not J.UnitSkins.units.playerFrame.health and not record.trim.rim.frame.shown)
end)

end
