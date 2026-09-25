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
                near(r.trim.frame.w,bar.w+212*r.geometry.capScale)
                near(r.trim.frame.h,bar.h+(kind=="health" and 84*r.geometry.capScale+1 or 96*r.geometry.capScale))
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

test("skin artwork selection never changes native sizing or the common fit",function(M)
    local J=M.load();enable(J,"targetFrame")
    local r=J.UnitSkins.units.targetFrame.health;local w,h=r.trim.frame.w,r.trim.frame.h
    for id in pairs(J.PortraitCatalog.entries) do
        J.ProfileManager:Set("targetFrame","portraitMode","FIXED")
        J.ProfileManager:Set("targetFrame","portrait",id)
        assert(r.id==id and r.trim.textures["1_1"].path==J.UnitSkinCatalog.entries[id].shell
            and r.texture.path==J.UnitSkinCatalog.entries[id].health)
        near(r.trim.frame.w,w);near(r.trim.frame.h,h)
    end
    J.ProfileManager:Set("targetFrame","portraitMode","CLASS")
    M.unitData.target.class="DEATHKNIGHT";M.tick(J.Core)
    assert(r.id=="CLASS_DEATHKNIGHT")
    J.ProfileManager:Set("targetFrame","width",190);J.ProfileManager:Set("targetFrame","x",80)
    near(r.trim.frame.w,w);near(r.trim.frame.h,h)
end)

test("native resizing scale and hidden power bars are followed independently",function(M)
    local J=M.load();enable(J)
    local b=bars(J);b.health.w=180;b.health.h=24;b.health.scale=1.4;b.power.shown=false
    UIParent.scale=.8;M.tick(J.Core)
    local unit=J.UnitSkins.units.playerFrame
    near(unit.health.trim.frame.w,180+212*24/48);near(unit.health.trim.frame:GetEffectiveScale(),b.health:GetEffectiveScale())
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

test("restricted redraw hides stale shell until native metadata is readable",function(M)
    local J=M.load();enable(J);local b=bars(J).health
    b.fill:SetAtlas("Native-Changed-Health");b.fill.secretCoords=true
    M.tick(J.Core)
    assert(b.fill.atlas=="Native-Changed-Health")
    assert(not J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    b.fill.secretCoords=false;M.tick(J.Core)
    assert(J.UnitSkins.units.playerFrame.health.trim.frame.shown)
    J.ProfileManager:Set("playerFrame","unitStyle","PORTRAIT")
    assert(b.fill.atlas=="Native-Changed-Health")
end)

end
