local test,near,count=...
local function member(M,source,unit,index,tot)
    local name=tot and (source=="BLIZZARD" and "TargetFrameToT" or source=="ELVUI" and "ElvUF_TargetTarget" or "EllesmereUIUnitFrames_TargetTarget") or "SmallMember"..source..index
    local root=M.native(name,150,45,.9);root.level=10;root.strata="MEDIUM"
    root.unit=unit;root.GetAttribute=function(self) return self.unit end
    local health=M.region(root,"Frame",110,20);health.rect={30,60};health.fill=M.region(health,"Texture",110,20)
    health.level=12;health.strata="MEDIUM"
    local power=M.region(root,"Frame",110,8);power.rect={30,50};power.fill=M.region(power,"Texture",110,8)
    local portrait=M.region(root,"Texture",36,36);portrait.rect={-20,45}
    if source=="BLIZZARD" then
        root.healthbar,root.manabar,root.Portrait=health,power,portrait
    else
        root.Health,root.Power=health,power
        root.Portrait=portrait;root.USE_PORTRAIT_OVERLAY=false
        local bd=M.region(root,"Frame",36,36);bd.level=13;bd.strata="MEDIUM"
        portrait.backdrop=bd;bd._isInside=false
        if source=="ELLESMERE" and not tot then
            bd._on=true;bd._gIn=false;bd._gSide="left";bd._2d=portrait
            local ns=EllesmereUI._ModuleNS.EllesmereUIRaidFrames
            ns._partyAllButtons[index]=root;ns.data[root]={health=health,power=power,pt=bd}
        end
    end
    return root,health,power,portrait
end
local function fixture(M,source,tot)
    M.unitData.party1={player=true,class="DRUID",race="NightElf",faction="Alliance"}
    M.unitData.party2={player=true,class="HUNTER",race="Orc",faction="Horde"}
    M.unitData.targettarget={player=true,class="MAGE",race="Gnome",faction="Alliance"}
    if tot then return {member(M,source,"targettarget",1,true)} end
    if source=="BLIZZARD" then
        PartyFrame=M.native("PartyFrame",200,500)
        local list={}
        PartyFrame.PartyMemberFramePool={EnumerateActive=function() return pairs(list) end}
        -- Intentionally sorted differently from unit tokens.
        local first=member(M,source,"party2",1);local second=member(M,source,"party1",2)
        list[first]=true;list[second]=true
        return {first,second},list
    elseif source=="ELVUI" then
        local header=M.native("ElvUF_PartyGroup1",200,500)
        header[1]=member(M,source,"party2",1);header[2]=member(M,source,"party1",2)
        return {header[1],header[2]}
    else
        local ns={_partyAllButtons={},data={}};ns.GetFFD=function(root) return ns.data[root] end
        EllesmereUI={_ModuleNS={EllesmereUIRaidFrames=ns}}
        return {member(M,source,"party2",1),member(M,source,"party1",2)}
    end
end
local function enable(J,key,source,portrait)
    assert(J.ProfileManager:SetMany({{key,"unitFrameSource",source},{key,"portraitSource",source},
        {key,"unitFrameShown",true},{key,"shown",portrait or false}}))
end
local function record(J,key,root,kind) return J.SmallFrames.groups[key][kind or "border"].records[root] end

for _,interface in ipairs({120100,16001}) do
    for _,source in ipairs({"BLIZZARD","ELVUI","ELLESMERE"}) do
        test(source.." compact party borders and portraits on "..interface,function(M)
            local J=M.load({interface=interface});local roots=fixture(M,source)
            enable(J,"partyFrames",source,true)
            local first,second=record(J,"partyFrames",roots[1]),record(J,"partyFrames",roots[2])
            assert(first.id=="CLASS_HUNTER" and second.id=="CLASS_DRUID")
            near(first.frame.h,30);near(first.frame.w,110)
            assert(first.frame.strata=="MEDIUM" and first.frame.level==13 and first.frame.fixedStrata and first.frame.fixedLevel)
            local portrait=record(J,"partyFrames",roots[2],"portrait")
            assert(portrait.id=="CLASS_DRUID" and portrait.frame.shown)
            for _,m in ipairs({first,second,portrait}) do
                assert(m.frame.parent==UIParent and not m.frame.mouse and not m.frame.keyboard and not m.frame.wheel)
            end
            local writes=M.geometryWrites;M.combat=true
            roots[1].unit="party1";roots[2].unit="party2";M.event(J.Core,"GROUP_ROSTER_UPDATE")
            assert(first.id=="CLASS_DRUID" and second.id=="CLASS_HUNTER" and portrait.id=="CLASS_HUNTER")
            assert(writes==M.geometryWrites,"Sorting rewrote protected layout")
            M.unitData.party1=nil;M.tick(J.Core)
            assert(not first.frame.shown and first.id=="CLASS_DRUID","Empty slot flashed Neutral")
            roots[2].shown=false;M.tick(J.Core);assert(not second.frame.shown and not portrait.frame.shown)
            M.combat=false;roots[2].shown=true;M.tick(J.Core)
            assert(second.frame.shown and not next(J.Core.notices))
        end)
        test(source.." Target of Target matches combat identity on "..interface,function(M)
            local J=M.load({interface=interface});local root=fixture(M,source,true)[1]
            enable(J,"targetTargetFrame",source)
            local m=record(J,"targetTargetFrame",root)
            assert(m.id=="CLASS_MAGE" and m.frame.shown)
            for _,t in pairs(m.textures) do assert(t.texCoord[1]>t.texCoord[2]) end
            M.combat=true;local writes=M.geometryWrites
            M.unitData.targettarget={player=false};M.event(J.Core,"UNIT_TARGET","target")
            assert(m.id=="FACTION_NEUTRAL")
            M.unitData.targettarget={player=true,class="DRUID"};M.event(J.Core,"UNIT_TARGET","target")
            assert(m.id=="CLASS_DRUID" and m.frame.shown and writes==M.geometryWrites)
            M.unitData.targettarget=nil;M.event(J.Core,"PLAYER_TARGET_CHANGED")
            assert(not m.frame.shown and m.id=="CLASS_DRUID")
            assert(not next(J.Core.notices))
        end)
    end
end

test("compact artwork retains every race class faction design and independent toggles",function(M)
    local J=M.load();local root=fixture(M,"BLIZZARD")[1];enable(J,"partyFrames","BLIZZARD",true)
    local m=record(J,"partyFrames",root);local portrait=record(J,"partyFrames",root,"portrait")
    for id,entry in pairs(J.UnitSkinCatalog.entries) do
        assert(J.ProfileManager:Set("partyFrames","smallFrameArt",id));assert(m.id==id)
        for _,t in pairs(m.textures) do assert(t.path==entry.cast and t.w>0 and t.h>0) end
    end
    assert(portrait.id=="CLASS_HUNTER")
    J.ProfileManager:Set("partyFrames","smallFrameArt","MATCH")
    J.ProfileManager:Set("partyFrames","portraitMode","RACE");assert(m.id=="RACE_ORC")
    J.ProfileManager:Set("partyFrames","portraitMode","FACTION");assert(m.id=="FACTION_HORDE")
    J.ProfileManager:Set("partyFrames","unitFrameShown",false);assert(not m.frame.shown and portrait.frame.shown)
    J.ProfileManager:Set("partyFrames","shown",false);assert(not portrait.frame.shown)
    J.ProfileManager:Set("partyFrames","unitFrameShown",true);assert(m.frame.shown and not portrait.frame.shown)
end)

test("compact party frames with no portraits still support bar borders",function(M)
    local J=M.load();fixture(M,"BLIZZARD");PartyFrame.shown=false
    CompactPartyFrame=M.native("CompactPartyFrame",200,400)
    local root=M.native("CompactPartyMember1",130,45);root.unit="party1"
    root.healthBar=M.region(root,"Frame",130,35);root.healthBar.rect={0,10};root.healthBar.fill=M.region(root.healthBar,"Texture",130,35)
    CompactPartyFrame.memberUnitFrames={root}
    enable(J,"partyFrames","BLIZZARD",true)
    assert(record(J,"partyFrames",root).frame.shown)
    assert(not record(J,"partyFrames",root,"portrait"))
    assert(not next(J.Core.notices))
end)

test("party provider selection respects disabled portraits and explicit choices",function(M)
    local J=M.load();local native=fixture(M,"BLIZZARD");local elv=fixture(M,"ELVUI")
    elv[1].USE_PORTRAIT_OVERLAY=true;elv[2].Portrait=nil
    enable(J,"partyFrames","AUTO",true)
    assert(record(J,"partyFrames",elv[1]).frame.shown and not record(J,"partyFrames",native[1]))
    assert(not record(J,"partyFrames",native[1],"portrait"),"Fell back to stock portrait behind ElvUI")
    assert(J.SmallFrames.groups.partyFrames.portraitStatus:find("enable separate portraits",1,true))
    J.ProfileManager:Set("partyFrames","unitFrameSource","BLIZZARD")
    assert(record(J,"partyFrames",native[1]).frame.shown and not record(J,"partyFrames",elv[1]))
    assert(not next(J.Core.notices))
end)

test("small frame preferences wait for combat end and restore through backups",function(M)
    local J=M.load();local root=fixture(M,"BLIZZARD")[1];enable(J,"partyFrames","BLIZZARD",true)
    J.ProfileManager:Set("partyFrames","smallFrameWeight",.9)
    local m=record(J,"partyFrames",root);local w=m.textures["11"].w
    M.combat=true
    J.ProfileManager:Set("partyFrames","smallFrameWeight",1.5);J.ProfileManager:Set("partyFrames","unitFrameShown",false)
    assert(m.frame.shown and m.textures["11"].w==w)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(not m.frame.shown)
    local saved=J.ProfileManager:Export();assert(saved:find("partyFrames.smallFrameWeight=1.5",1,true))
    J.ProfileManager:Reset("partyFrames");J.ProfileManager:Import(saved)
    assert(J.ThemeManager:Resolve("partyFrames").smallFrameWeight==1.5)
    J.ProfileManager:Set("partyFrames","unitFrameShown",true);assert(m.textures["11"].w>w)
    assert(not J.ProfileManager:Set("partyFrames","portraitSource","BLINKII"))
    assert(not J.ProfileManager:Set("partyFrames","castBarShown",true))
    assert(not J.ProfileManager:Set("playerFrame","smallFrameArt","RACE_ORC"))
end)

test("restricted party identity and geometry cannot leak into matching or stale frames",function(M)
    local J=M.load();local roots=fixture(M,"ELVUI");enable(J,"partyFrames","ELVUI",true)
    local root=roots[1];local m=record(J,"partyFrames",root)
    root.GetAttribute=function() return M.secret end
    M.combat=true;M.tick(J.Core);assert(not m.frame.shown)
    root.GetAttribute=function(self) return self.unit end
    root.Health.secretRect=true;M.tick(J.Core);assert(m.frame.shown,"Previously fitted art lost in combat")
    M.combat=false;M.tick(J.Core);assert(not m.frame.shown)
    root.Health.secretRect=false;M.tick(J.Core);assert(m.frame.shown)
    root.forbidden=true;M.tick(J.Core);assert(not m.frame.shown and not next(J.Core.notices))
end)

test("missing bars and late party creation defer safely during combat",function(M)
    local J=M.load();enable(J,"partyFrames","ELVUI",true)
    M.combat=true;local roots=fixture(M,"ELVUI");M.tick(J.Core)
    assert(not record(J,"partyFrames",roots[1]))
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
    local m=record(J,"partyFrames",roots[1]);assert(m.frame.shown)
    m.frame.protected=true;M.combat=true;M.unitData.party2.class="DRUID";M.tick(J.Core)
    assert(m.id=="CLASS_HUNTER" and J.Core.dirty)
    M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");assert(m.id=="CLASS_DRUID")
    assert(not next(J.Core.notices))
end)

test("small borders keep scale and corner proportions without touching native fills",function(M)
    local J=M.load();local root=fixture(M,"ELVUI")[1];enable(J,"partyFrames","ELVUI")
    local m=record(J,"partyFrames",root);local corner=m.textures["11"].w
    near(m.frame:GetEffectiveScale(),root.Health:GetEffectiveScale())
    J.ProfileManager:Set("partyFrames","unitFrameWidth",130);J.ProfileManager:Set("partyFrames","unitFrameX",8)
    near(m.textures["11"].w,corner);near(m.frame.points[1][4],8)
    J.ProfileManager:Set("partyFrames","unitFrameStrata","TOOLTIP");assert(m.frame.strata=="TOOLTIP")
    root.Power.rect={200,-100};M.tick(J.Core);near(m.frame.h,root.Health.h)
    assert(not M.appearanceWrites and not M.nativeLayoutWrites and not next(J.Core.notices))
end)

test("small frame settings expose independent border collections and linked portrait sizing",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open();S:Select("partyFrames")
    assert(S.tabs.partyFrames.selection:IsShown() and S.styleButton.caption.text=="Compact frame border")
    assert(not S.pageButtons.cast:IsShown() and not S.pageButtons.blizzard:IsShown())
    S.styleButton.scripts.OnClick();S.showButton.scripts.OnClick()
    assert(J.ThemeManager:Resolve("partyFrames").unitFrameShown and J.ThemeManager:Resolve("partyFrames").shown)
    S.unitBrowse.scripts.OnClick();assert(S.smallPicker:IsShown() and count(S.smallButtons)==42)
    S.smallButtons.RACE_NIGHTELF.scripts.OnClick()
    assert(J.ThemeManager:Resolve("partyFrames").smallFrameArt=="RACE_NIGHTELF")
    assert(S.unitPreview.path==J.UnitSkinCatalog.entries.RACE_NIGHTELF.cast)
    S.smallMatch.scripts.OnClick();assert(J.ThemeManager:Resolve("partyFrames").smallFrameArt=="MATCH")
    S:SetPage("placement");S:Set("portraitSize",160)
    assert(J.ThemeManager:Resolve("partyFrames").width==160 and J.ThemeManager:Resolve("partyFrames").height==160)
    S:Select("targetTargetFrame");S:SetPage("fitting");assert(S.controls.smallFrameWeight.slider:IsVisible())
    S:Select("playerFrame");assert(not S.controls.smallFrameWeight.slider:IsVisible())
    assert(S.fittingPanel:IsVisible() and S.pageButtons.cast:IsShown() and not next(J.Core.notices))
end)

test("idle party passes reuse frames and do not refit or repaint",function(M)
    local J=M.load();local roots=fixture(M,"ELVUI");enable(J,"partyFrames","ELVUI",true)
    local objects,textures=#M.objects,M.textures
    local writes=M.geometryWrites;local paths=0
    for _,root in ipairs(roots) do
        for _,kind in ipairs({"border","portrait"}) do
            for _,t in pairs(record(J,"partyFrames",root,kind).textures) do
                local original=t.SetTexture;t.SetTexture=function(self,...) paths=paths+1;return original(self,...) end
            end
        end
    end
    collectgarbage("collect");local base=collectgarbage("count")
    for i=1,200 do M.tick(J.Core) end
    collectgarbage("collect")
    assert(#M.objects==objects and M.textures==textures and M.geometryWrites==writes and paths==0)
    assert(collectgarbage("count")-base<64 and not next(J.Core.notices))
end)

test("hidden Ellesmere party portraits attach before their first combat appearance",function(M)
    local J=M.load();local roots=fixture(M,"ELLESMERE")
    for _,root in ipairs(roots) do root.shown=false end
    enable(J,"partyFrames","ELLESMERE",true)
    local m=record(J,"partyFrames",roots[1],"portrait");assert(m and not m.frame.shown)
    M.combat=true;roots[1].shown=true;local writes=M.geometryWrites;M.tick(J.Core)
    assert(m.frame.shown and m.id=="CLASS_HUNTER" and writes==M.geometryWrites)
end)

test("Ellesmere kit portrait and sixth self-first button are discovered",function(M)
    local J=M.load();fixture(M,"ELLESMERE")
    local root,health,power,portrait=member(M,"ELLESMERE","player",6)
    local ns=EllesmereUI._ModuleNS.EllesmereUIRaidFrames
    ns.data[root]={health=health,power=power,kitPortrait=portrait}
    enable(J,"partyFrames","ELLESMERE",true)
    local m=record(J,"partyFrames",root,"portrait")
    assert(m and m.frame.shown and m.id=="CLASS_PALADIN")
    near(m.geometry.w,128*36/58)
end)

test("retired party attachments reuse a bounded frame pool after repeated roster changes",function(M)
    local J=M.load();local roots,list=fixture(M,"BLIZZARD");enable(J,"partyFrames","BLIZZARD",true)
    local retired=record(J,"partyFrames",roots[1]);local objects=#M.objects
    for i=1,10 do
        list[roots[1]]=nil;M.tick(J.Core);assert(not retired.frame.shown)
        list[roots[1]]=true;M.tick(J.Core);assert(record(J,"partyFrames",roots[1])==retired)
    end
    assert(#M.objects==objects and not next(J.Core.notices))
end)

test("party profile switches and sanitation preserve separate settings",function(M)
    local J=M.load();local root=fixture(M,"ELVUI")[1];enable(J,"partyFrames","ELVUI",true)
    J.ProfileManager:Set("partyFrames","smallFrameArt","RACE_TAUREN")
    local first=J.ProfileManager.activeID
    J.ProfileManager:SaveAs("Party test",false)
    J.ProfileManager:Set("partyFrames","smallFrameArt","CLASS_DRUID")
    J.ProfileManager:UseProfile(first)
    assert(record(J,"partyFrames",root).id=="RACE_TAUREN")
    local saved=J.ProfileManager:Sanitize(J.ProfileManager.current)
    assert(saved.modules.partyFrames.smallFrameArt=="RACE_TAUREN")
    saved.modules.partyFrames.portraitSource="BLINKII";saved.modules.partyFrames.blizzardPortraitHidden=true
    saved=J.ProfileManager:Sanitize(saved)
    assert(saved.modules.partyFrames.portraitSource==nil and saved.modules.partyFrames.blizzardPortraitHidden==nil)
    assert(not next(J.Core.notices))
end)

test("stock party and Target of Target borders include the wider offset mana bar",function(M)
    local J=M.load();local roots=fixture(M,"BLIZZARD",true)
    local root=roots[1]
    root.healthbar.w,root.healthbar.h,root.healthbar.rect=70,10,{40,60}
    root.manabar.w,root.manabar.h,root.manabar.rect=74,7,{36,52}
    enable(J,"targetTargetFrame","BLIZZARD")
    local m=record(J,"targetTargetFrame",root)
    near(m.frame.w,74);near(m.frame.h,18);near(m.frame.points[1][4],-4)
    root.manabar.shown=false;M.tick(J.Core)
    near(m.frame.w,70);near(m.frame.h,10)
end)
