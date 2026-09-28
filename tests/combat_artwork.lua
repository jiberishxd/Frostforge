local test=...
local function near(a,b) assert(math.abs(a-b)<.00001,tostring(a).." ~= "..tostring(b)) end
local function currentShell(J,u,id,mirror)
    local entry=J.UnitSkinCatalog.entries[id]
    local h,p=entry.opening.health,entry.opening.power
    for _,kind in ipairs({"health","power","footer"}) do
        local record=u[kind]
        assert(record.id==id,"Stale "..kind.." identity: "..tostring(record.id))
        for _,texture in pairs(record.trim.textures) do assert(texture.path==entry.shell,"Mixed shell artwork") end
        local uv=record.trim.textures[kind=="health" and "2_2" or "1_2"].texCoord
        near(uv[1],(mirror and h[3] or h[1])/512);near(uv[2],(mirror and h[1] or h[3])/512)
        near(uv[3],(kind=="health" and h[2] or p[2])/256)
        near(uv[4],(kind=="health" and h[4] or p[4])/256)
        if kind~="health" then
            local t=record.trim.textures
            near(t.footerLeft.texCoord[2],t["2_2"].texCoord[1])
            near(t["2_2"].texCoord[2],t.footerRight.texCoord[1])
            near(t["2_2"].texCoord[4],1)
        end
    end
end

for _,interface in ipairs({120100,16001}) do
    test("neutral beast changes to Druid and back with independent Focus in combat on "..interface,function(M)
        local J=M.load({interface=interface})
        local bars=J.Core.client:UnitBars("targetFrame")
        M.unitData.target.player=false;bars.power.shown=false
        J.ProfileManager:Set("targetFrame","unitFrameShown",true)
        J.ProfileManager:Set("focusFrame","unitFrameShown",true)
        local u=J.UnitSkins.units.targetFrame
        currentShell(J,u,"FACTION_NEUTRAL",true)
        local geometry,appearance,native,frames,textures,hooks=M.geometryWrites,M.appearanceWrites,M.nativeLayoutWrites,#M.frames,M.textures,M.hooks
        M.combat=true
        M.unitData.target.player=true;M.unitData.target.class="DRUID";bars.power.shown=true
        M.event(J.Core,"PLAYER_TARGET_CHANGED")
        currentShell(J,u,"CLASS_DRUID",true)
        currentShell(J,J.UnitSkins.units.focusFrame,"CLASS_MAGE",true)
        assert(u.health.trim.frame.shown and u.power.trim.frame.shown and not u.footer.trim.frame.shown)
        assert(J.Core.modules.targetFrame.portraitID=="CLASS_DRUID")
        assert(u.health.layoutID=="FACTION_NEUTRAL","Combat paint changed the fitted layout")
        local writes=M.writes
        for i=1,8 do M.tick(J.Core) end
        assert(M.writes==writes,"Stable combat identity repainted repeatedly")
        M.unitData.target.class=M.secret;M.event(J.Core,"PLAYER_TARGET_CHANGED")
        currentShell(J,u,"FACTION_NEUTRAL",true)
        M.unitData.target.class="DRUID";M.tick(J.Core);currentShell(J,u,"CLASS_DRUID",true)
        M.unitData.target.player=false;bars.power.shown=false;M.event(J.Core,"PLAYER_TARGET_CHANGED")
        currentShell(J,u,"FACTION_NEUTRAL",true)
        assert(u.health.trim.frame.shown and u.footer.trim.frame.shown and not u.power.trim.frame.shown)
        M.unitData.target.player=true;M.unitData.target.class="DRUID";bars.power.shown=true
        M.event(J.Core,"PLAYER_TARGET_CHANGED")
        assert(M.geometryWrites==geometry and M.appearanceWrites==appearance and M.nativeLayoutWrites==native)
        assert(#M.frames==frames and M.textures==textures and M.hooks==hooks)
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        currentShell(J,u,"CLASS_DRUID",true)
        assert(u.health.layoutID=="CLASS_DRUID" and J.UnitSkins.powerLayouts.targetFrame.id=="CLASS_DRUID")
        assert(not next(J.Core.notices),next(J.Core.notices))
    end)

    test("all shell identities remap both mirrored and player openings in combat on "..interface,function(M)
        local J=M.load({interface=interface})
        for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
            J.ProfileManager:Set(key,"portraitMode","FIXED")
            J.ProfileManager:Set(key,"unitFrameShown",true)
        end
        local geometry,appearance,native,frames,textures=M.geometryWrites,M.appearanceWrites,M.nativeLayoutWrites,#M.frames,M.textures
        M.combat=true
        for id in pairs(J.UnitSkinCatalog.entries) do
            for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
                J.ProfileManager:Set(key,"portrait",id)
                currentShell(J,J.UnitSkins.units[key],id,key~="playerFrame")
            end
        end
        assert(M.geometryWrites==geometry and M.appearanceWrites==appearance and M.nativeLayoutWrites==native)
        assert(#M.frames==frames and M.textures==textures and not next(J.Core.notices),next(J.Core.notices))
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
            local u=J.UnitSkins.units[key]
            assert(u.health.layoutID==u.health.id and u.power.layoutID==u.power.id and u.footer.layoutID==u.footer.id)
        end
    end)

    test("protected or forbidden shell art defers atomically and recovers in combat on "..interface,function(M)
        local J=M.load({interface=interface})
        J.ProfileManager:Set("targetFrame","unitFrameShown",true)
        local u=J.UnitSkins.units.targetFrame
        M.combat=true;local geometry,native=M.geometryWrites,M.appearanceWrites
        for _,gate in ipairs({"frame","texture","forbidden"}) do
            M.unitData.target.class="ROGUE";M.tick(J.Core)
            for _,kind in ipairs({"health","power","footer"}) do
                local trim=u[kind].trim
                if gate=="frame" then trim.frame.protected=true
                elseif gate=="texture" then trim.textures["1_1"].protected=true
                else trim.textures["1_1"].forbidden=true end
            end
            M.unitData.target.class="DRUID";M.event(J.Core,"PLAYER_TARGET_CHANGED")
            currentShell(J,u,"CLASS_ROGUE",true)
            for _,kind in ipairs({"health","power","footer"}) do
                local trim=u[kind].trim
                trim.frame.protected=false;trim.textures["1_1"].protected=false;trim.textures["1_1"].forbidden=false
            end
            M.tick(J.Core);currentShell(J,u,"CLASS_DRUID",true)
        end
        assert(M.geometryWrites==geometry and M.appearanceWrites==native and not next(J.Core.notices),next(J.Core.notices))
    end)

    test("target and focus portraits recover a transient combat anchor failure on "..interface,function(M)
        local J=M.load({interface=interface})
        M.combat=true
        local geometry,frames=M.geometryWrites,#M.frames
        for _,key in ipairs({"targetFrame","focusFrame"}) do
            local root=J.Core.client:Resolve(key);local module=J.Core.modules[key]
            for _,field in ipairs({"secretAlpha","secretScale","forbidden"}) do
                root[field]=true;M.tick(J.Core)
                assert(not module.frame.shown and not module.snapshot)
                root[field]=false;M.tick(J.Core)
                assert(module.frame.shown,"Existing portrait attachment did not recover during combat")
            end
            root.shown=false;M.tick(J.Core);assert(not module.frame.shown)
            root.shown=true;M.unitData[key:gsub("Frame","")].player=false
            M.event(J.Core,key=="targetFrame" and "PLAYER_TARGET_CHANGED" or "PLAYER_FOCUS_CHANGED")
            assert(module.frame.shown and module.portraitID=="FACTION_NEUTRAL")
        end
        assert(M.geometryWrites==geometry and #M.frames==frames and not next(J.Core.notices))
    end)

    test("combat recovery never attaches portrait artwork to a replacement root on "..interface,function(M)
        local J=M.load({interface=interface});local m=J.Core.modules.targetFrame
        local old=TargetFrame
        local replacement=M.native("ReplacementTargetFrame",old.w,old.h)
        replacement.TargetFrameContainer=old.TargetFrameContainer
        M.combat=true;local geometry=M.geometryWrites
        old.secretAlpha=true;M.tick(J.Core);old.secretAlpha=false
        TargetFrame=replacement;M.tick(J.Core)
        assert(not m.frame.shown and m.frame.points[1][2]==old)
        assert(M.geometryWrites==geometry)
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        assert(m.frame.shown and m.frame.points[1][2]==replacement and not next(J.Core.notices))
    end)

    test("target shell changes identity without moving bars during combat on "..interface,function(M)
        local J=M.load({interface=interface})
        J.ProfileManager:Set("targetFrame","unitFrameShown",true)
        local u=J.UnitSkins.units.targetFrame;local bars=J.Core.client:UnitBars("targetFrame")
        local original=u.health.id
        local geometry,writes,frames=M.geometryWrites,M.appearanceWrites,#M.frames
        M.combat=true;M.unitData.target.player=false
        M.event(J.Core,"PLAYER_TARGET_CHANGED")
        assert(u.health.trim.frame.shown and u.power.trim.frame.shown,"Identity change hid the fitted shell")
        assert(u.health.id=="FACTION_NEUTRAL" and u.health.id~=original and J.Core.dirty,
            "Shell retained the previous target's identity during combat")
        bars.power.shown=false;M.tick(J.Core)
        assert(u.health.trim.frame.shown and u.footer.trim.frame.shown and not u.power.trim.frame.shown)
        TargetFrame.shown=false;M.tick(J.Core)
        assert(not u.health.trim.frame.shown and not u.footer.trim.frame.shown)
        TargetFrame.shown=true;M.tick(J.Core)
        assert(u.health.trim.frame.shown and u.footer.trim.frame.shown)
        -- Reported case: fighting a powerless beast, then targeting a Druid.
        M.unitData.target.player=true;M.unitData.target.class="DRUID";bars.power.shown=true
        M.event(J.Core,"PLAYER_TARGET_CHANGED")
        for _,kind in ipairs({"health","power","footer"}) do
            assert(u[kind].id=="CLASS_DRUID","Combat target did not switch to Druid: "..kind)
            for _,texture in pairs(u[kind].trim.textures) do
                assert(texture.path==J.UnitSkinCatalog.entries.CLASS_DRUID.shell)
            end
        end
        assert(u.health.trim.frame.shown and u.power.trim.frame.shown and not u.footer.trim.frame.shown)
        assert(M.geometryWrites==geometry and M.appearanceWrites==writes and #M.frames==frames)
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        assert(u.health.id=="CLASS_DRUID" and u.footer.id=="CLASS_DRUID")
        assert(u.health.trim.frame.shown and u.power.trim.frame.shown and not next(J.Core.notices))
    end)

    test("transient native fill reads do not retire a combat shell on "..interface,function(M)
        local J=M.load({interface=interface})
        J.ProfileManager:Set("targetFrame","unitFrameShown",true)
        local u=J.UnitSkins.units.targetFrame;local bars=J.Core.client:UnitBars("targetFrame")
        local original=u.health
        local getter=bars.health.GetStatusBarTexture
        M.combat=true;local geometry,writes=M.geometryWrites,M.appearanceWrites
        bars.health.GetStatusBarTexture=function() return M.secret end
        M.tick(J.Core)
        assert(u.health==original and original.trim.frame.shown,"Unreadable fill hid independent artwork")
        bars.health.GetStatusBarTexture=function() error("Native texture is being replaced") end
        M.tick(J.Core)
        assert(u.health==original and original.trim.frame.shown)
        bars.health.GetStatusBarTexture=getter;M.tick(J.Core)
        assert(u.health==original and original.trim.frame.shown)
        assert(M.geometryWrites==geometry and M.appearanceWrites==writes)
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        assert(u.health.trim.frame.shown and not next(J.Core.notices))
    end)

    test("shell-only target recovers the same temporarily unavailable bars in combat on "..interface,function(M)
        local J=M.load({interface=interface})
        J.ProfileManager:Set("targetFrame","unitFrameFill","PROVIDER")
        J.ProfileManager:Set("targetFrame","unitFrameShown",true)
        local u=J.UnitSkins.units.targetFrame;local health,power=u.health,u.power
        M.combat=true;local geometry,frames=M.geometryWrites,#M.frames
        TargetFrame.forbidden=true;M.tick(J.Core)
        assert(u.health==health and u.power==power)
        assert(not health.trim.frame.shown and not power.trim.frame.shown)
        TargetFrame.forbidden=false;M.tick(J.Core)
        assert(health.trim.frame.shown and power.trim.frame.shown)
        assert(M.geometryWrites==geometry and #M.frames==frames and not next(J.Core.notices))
    end)
end
