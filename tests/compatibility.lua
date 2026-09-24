local test,near = ...
local function blinkii(M,unit,size)
    BLINKIISPORTRAITS=BLINKIISPORTRAITS or {Portraits={}}
    local frame=M.native("BPTest_"..unit,size or 64,size or 64)
    frame.portrait=M.region(frame,"Texture",128,128)
    frame.maskFile="Interface\\Addons\\Blinkiis_Portraits\\media\\circle_mask.tga"
    BLINKIISPORTRAITS.Portraits[unit]=frame
    return frame
end
local function replacement(M,source,unit,size)
    local prefix=source=="ELVUI" and "ElvUF_" or "EllesmereUIUnitFrames_"
    local root=M.native(prefix..unit,240,60)
    local bd=M.region(root,"Frame",size or 60,size or 60)
    root.Portrait=M.region(bd,"Texture",60,60)
    root.Portrait.backdrop=bd
    return root,bd
end

test("Blinkii priority and per-unit source choice work on both clients",function(M)
    for _,interface in ipairs({120100,16001}) do
        local bp=blinkii(M,"player")
        local elv,elvPortrait=replacement(M,"ELVUI","Player")
        local eui,euiPortrait=replacement(M,"ELLESMERE","Player")
        local J=M.load({interface=interface});local m=J.Core.modules.playerFrame
        assert(m.snapshot.frame==bp and m.snapshot.source=="BLINKII")
        J.ProfileManager:Set("playerFrame","portraitSource","ELVUI")
        assert(m.snapshot.frame==elvPortrait)
        J.ProfileManager:Set("playerFrame","portraitSource","ELLESMERE")
        assert(m.snapshot.frame==euiPortrait)
        J.ProfileManager:Set("playerFrame","portraitSource","BLIZZARD")
        assert(m.snapshot.frame==PlayerFrame and m.frame.w==128)
        assert(m.textures.main.texCoord[1]==0)
        assert(J.Core.modules.targetFrame.snapshot.source=="BLIZZARD")
        assert(not next(J.Core.notices))
    end
end)

test("Blinkii masks fit the visible opening and preserve its center under scaling",function(M)
    local bp=blinkii(M,"player",58);bp.scale=1.5
    local J=M.load();local m=J.Core.modules.playerFrame
    local fit=J.PortraitMaskFits[bp.maskFile:lower()]*2
    near(m.frame.w,128*fit)
    near(m.frame:GetEffectiveScale(),bp:GetEffectiveScale())
    assert(m.textures.main.texCoord[1]==0.5 and m.textures.main.texCoord[2]==1)
    local function centered()
        local p=m.frame.points[1]
        near(p[4]+(154-128)/256*m.frame.w,0)
        near(p[5]-(148-128)/256*m.frame.h,0)
    end
    centered()
    J.ProfileManager:Set("playerFrame","scale",1.8);centered()
    J.ProfileManager:Set("playerFrame","width",192);centered()
    bp.w,bp.h=116,116;M.tick(J.Core);centered()
    bp.maskFile="Interface\\Addons\\Blinkiis_Portraits\\media\\square_mask.tga"
    M.tick(J.Core)
    near(m.frame.w,192*116/58*J.PortraitMaskFits[bp.maskFile:lower()]*2)
    bp.maskFile="Interface\\Addons\\Custom\\mask.tga";M.tick(J.Core)
    near(m.snapshot.portraitFit,math.sqrt(8))
    assert(not next(J.Core.notices))
end)

test("mirrored external target surrounds register their actual opening",function(M)
    local bp=blinkii(M,"target",80)
    local J=M.load();local m=J.Core.modules.targetFrame
    local p=m.frame.points[1]
    near(p[4]+(102-128)/256*m.frame.w,0)
    near(p[5]-(148-128)/256*m.frame.h,0)
    assert(p[2]==bp and m.textures.main.texCoord[1]==1)
    J.ProfileManager:Set("targetFrame","x",32)
    near(m.frame.points[1][4]+(102-128)/256*m.frame.w,10)
end)

test("late Blinkii loading clickable replacement and removal reuse owned frames",function(M)
    local J=M.load();local m=J.Core.modules.playerFrame;local owned=m.frame
    local n=#M.frames
    local first=blinkii(M,"player");M.event(J.Core,"ADDON_LOADED","Blinkiis_Portraits")
    assert(m.snapshot.frame==first and m.frame==owned)
    local second=blinkii(M,"player",72);second.protected=true;first.shown=false
    M.tick(J.Core);assert(m.snapshot.frame==second and m.frame==owned)
    BLINKIISPORTRAITS.Portraits.player=nil;M.tick(J.Core)
    assert(m.snapshot.frame==PlayerFrame and m.frame.w==128)
    assert(#M.frames==n+2 and not next(J.Core.notices))
end)

test("external profiles inherit alpha visibility scale and child replacement",function(M)
    local root,bd=replacement(M,"ELVUI","Focus")
    FocusFrame.shown=false;root.alpha=0.4;bd.scale=0.8
    local J=M.load();local m=J.Core.modules.focusFrame
    near(m.frame:GetEffectiveScale(),bd:GetEffectiveScale());near(m.frame.alpha,0.4)
    root.Portrait.shown=false;M.tick(J.Core);assert(not m.frame.shown)
    root.Portrait.shown=true;M.tick(J.Core);assert(m.frame.shown)
    root.shown=false;M.tick(J.Core);assert(not m.frame.shown)
    root.shown=true
    local nextBD=M.region(root,"Frame",75,75)
    root.Portrait=M.region(nextBD,"PlayerModel",75,75);root.Portrait.backdrop=nextBD
    M.tick(J.Core);assert(m.snapshot.frame==nextBD and m.frame.shown)
    local writes=M.writes;M.tick(J.Core);M.tick(J.Core)
    assert(M.writes==writes and not next(J.Core.notices))
end)

test("disabled or overlay portraits do not decorate hidden Blizzard frames",function(M)
    local root,bd=replacement(M,"ELVUI","Player");PlayerFrame.shown=false
    local J=M.load();local m=J.Core.modules.playerFrame
    root.USE_PORTRAIT_OVERLAY=true;M.tick(J.Core);assert(not m.frame.shown and not m.snapshot)
    root.USE_PORTRAIT_OVERLAY=false;M.tick(J.Core);assert(m.frame.shown)
    root.USE_PORTRAIT_OVERLAY=M.secret;M.tick(J.Core);assert(not m.frame.shown)
    root.USE_PORTRAIT_OVERLAY=false
    root.Portrait=nil;M.tick(J.Core);assert(not m.frame.shown)
    local eui,portrait=replacement(M,"ELLESMERE","Target")
    portrait._isInside=true;M.tick(J.Core);assert(not J.Core.modules.targetFrame.frame.shown)
    assert(not next(J.Core.notices))
end)


test("Ellesmere detached masks fit independently of expanded portrait art",function(M)
    local root,bd=replacement(M,"ELLESMERE","Player",64)
    local mask=M.region(bd,"Texture",62,62)
    mask.path="Interface\\AddOns\\EllesmereUI\\media\\portraits\\circle_mask.tga"
    bd._shapeMask=mask;root.Portrait.w,root.Portrait.h=95,95
    local J=M.load();local m=J.Core.modules.playerFrame
    near(m.frame.w,128*62/58*J.PortraitMaskFits[mask.path:lower()])
    mask.w,mask.h=70,70;M.tick(J.Core)
    near(m.snapshot.w,70)
    mask.shown=false;M.tick(J.Core)
    near(m.snapshot.portraitFit,math.sqrt(2));near(m.snapshot.w,64)
    assert(not next(J.Core.notices))
end)

test("missing explicit sources wait instead of falling back and recover",function(M)
    local J=M.load();local m=J.Core.modules.targetFrame
    J.ProfileManager:Set("targetFrame","portraitSource","BLINKII")
    assert(not m.frame.shown and not m.snapshot)
    local bp=blinkii(M,"target");M.tick(J.Core);assert(m.frame.shown and m.snapshot.frame==bp)
    bp.forbidden=true;M.tick(J.Core);assert(not m.frame.shown)
    bp.forbidden=false;bp.portrait.forbidden=true;M.tick(J.Core);assert(not m.frame.shown)
    bp.portrait.forbidden=false;bp.secretScale=true;M.tick(J.Core);assert(not m.frame.shown)
    bp.secretScale=false;bp.secretAlpha=true;M.tick(J.Core);assert(not m.frame.shown)
    bp.secretAlpha=false;bp.maskFile=M.secret;M.tick(J.Core);assert(m.frame.shown)
    BLINKIISPORTRAITS.Portraits=M.secret;M.tick(J.Core);assert(not m.frame.shown)
    assert(not next(J.Core.notices))
end)

test("source switches and clickable protection defer in combat",function(M)
    local bp=blinkii(M,"player")
    local J=M.load();local m=J.Core.modules.playerFrame
    M.combat=true
    local geometry=M.geometryWrites
    local nextBP=blinkii(M,"player",100);nextBP.protected=true
    M.tick(J.Core);assert(not m.frame.shown and M.geometryWrites==geometry)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(m.frame.shown and m.snapshot.frame==nextBP)
    m.frame.protected=true;M.combat=true
    local writes=M.writes
    J.ProfileManager:Set("playerFrame","portraitSource","BLIZZARD")
    assert(M.writes==writes and J.Core.dirty)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    assert(m.snapshot.frame==PlayerFrame and m.frame.w==128)
    assert(not next(J.Core.notices))
end)

test("ElvUI and Ellesmere hubs follow their actual main bars",function(M)
    local elv=M.native("ElvUI_Bar1",600,40,1.2)
    local eui=M.native("EABBar_MainBar",580,50,0.8)
    MainActionBar.shown=false
    local J=M.load();local m=J.Core.modules.actionHub
    assert(m.snapshot.frame==elv and m.frame.shown)
    near(m.frame:GetEffectiveScale(),elv:GetEffectiveScale())
    J.ProfileManager:Set("actionHub","hubSource","ELLESMERE")
    J.ProfileManager:Set("actionHub","anchor","FRAME")
    assert(m.snapshot.frame==eui and m.frame.points[1][2]==eui)
    eui.alpha=0.25;M.tick(J.Core);near(m.frame.alpha,0.25)
    eui.shown=false;M.tick(J.Core);assert(not m.frame.shown)
    assert(J.Core.modules.minimap.snapshot.frame==Minimap)
    assert(not next(J.Core.notices))
end)

test("source settings are atomic scoped persistent and available in options",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open()
    local backup=J.ProfileManager:Export()
    assert(not J.ProfileManager:Set("minimap","portraitSource","ELVUI"))
    assert(not J.ProfileManager:Set("playerFrame","hubSource","ELLESMERE"))
    assert(not J.ProfileManager:Set("actionHub","hubSource","BLINKII"))
    assert(not J.ProfileManager:Import(backup..";actionHub.portraitSource=BLINKII"))
    assert(J.ProfileManager:Export()==backup)
    S.controls.portraitSource.options.BLINKII.scripts.OnClick()
    assert(J.ThemeManager:Resolve("playerFrame").portraitSource=="BLINKII")
    S:Select("actionHub")
    assert(not S.controls.portraitSource.button.shown and S.controls.hubSource.button.shown)
    S.controls.hubSource.options.ELLESMERE.scripts.OnClick()
    S:Select("minimap");assert(not S.controls.hubSource.button.shown)
    backup=J.ProfileManager:Export();assert(J.ProfileManager:Import(backup))
    local nextJ=M.load({db=JiberishUIDB})
    assert(nextJ.ThemeManager:Resolve("playerFrame").portraitSource=="BLINKII")
    assert(nextJ.ThemeManager:Resolve("actionHub").hubSource=="ELLESMERE")
end)
