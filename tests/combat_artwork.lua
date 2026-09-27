local test=...
for _,interface in ipairs({120100,16001}) do
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

    test("target shell stays fitted when combat changes identity and power visibility on "..interface,function(M)
        local J=M.load({interface=interface})
        J.ProfileManager:Set("targetFrame","unitFrameShown",true)
        local u=J.UnitSkins.units.targetFrame;local bars=J.Core.client:UnitBars("targetFrame")
        local original=u.health.id
        local geometry,writes,frames=M.geometryWrites,M.appearanceWrites,#M.frames
        M.combat=true;M.unitData.target.player=false
        M.event(J.Core,"PLAYER_TARGET_CHANGED")
        assert(u.health.trim.frame.shown and u.power.trim.frame.shown,"Identity change hid the fitted shell")
        assert(u.health.id==original and J.Core.dirty)
        bars.power.shown=false;M.tick(J.Core)
        assert(u.health.trim.frame.shown and u.footer.trim.frame.shown and not u.power.trim.frame.shown)
        TargetFrame.shown=false;M.tick(J.Core)
        assert(not u.health.trim.frame.shown and not u.footer.trim.frame.shown)
        TargetFrame.shown=true;M.tick(J.Core)
        assert(u.health.trim.frame.shown and u.footer.trim.frame.shown)
        assert(M.geometryWrites==geometry and M.appearanceWrites==writes and #M.frames==frames)
        M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
        assert(u.health.id=="FACTION_NEUTRAL" and u.footer.id=="FACTION_NEUTRAL")
        assert(u.health.trim.frame.shown and u.footer.trim.frame.shown and not next(J.Core.notices))
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
