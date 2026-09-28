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
    if tot then return {(member(M,source,"targettarget",1,true))} end
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
        return {member(M,source,"party2",1),(member(M,source,"party1",2))}
    end
end
local function enable(J,key,source,portrait)
    assert(J.ProfileManager:SetMany({{key,"unitFrameSource",source},{key,"portraitSource",source},
        {key,"unitFrameShown",true},{key,"shown",portrait or false}}))
end
local function record(J,key,root,kind) return J.SmallFrames.groups[key][kind or "border"].records[root] end
local function registered(J,key,m)
    local g,c=m.geometry,J.ThemeManager:Read(key)
    local inset=J.UnitSkinCatalog.entries[m.id].castInsets
    local scale=m.textures['11'].w/48
    local w,h=g.w*c.unitFrameWidth/100,g.h*c.unitFrameHeight/100
    local function xy(name) local _,_,_,x,y=m.textures[name]:GetPoint();return x,-y end
    local left=xy('21');local right=xy('23');local _,top=xy('12');local _,bottom=xy('32')
    near(left+(48-(g.mirror and inset[3] or inset[1]))*scale,(g.w-w)/2-c.smallFramePadding)
    near(right+(g.mirror and inset[1] or inset[3])*scale,(g.w+w)/2+c.smallFramePadding)
    near(top+(48-inset[2])*scale,(g.h-h)/2-c.smallFramePadding)
    near(bottom+inset[4]*scale,(g.h+h)/2+c.smallFramePadding)
end

for _,interface in ipairs({120100,16001}) do
    for _,source in ipairs({"BLIZZARD","ELVUI","ELLESMERE"}) do
        test(source.." compact party borders and portraits on "..interface,function(M)
            local J=M.load({interface=interface});local roots=fixture(M,source)
            enable(J,"partyFrames",source,true)
            local first,second=record(J,"partyFrames",roots[1]),record(J,"partyFrames",roots[2])
            assert(first.id=="CLASS_HUNTER" and second.id=="CLASS_DRUID")
            near(first.frame.h,30);near(first.frame.w,110)
            assert(first.frame.strata=="MEDIUM" and first.frame.level==(source=="BLIZZARD" and 13 or 14) and first.frame.fixedStrata and first.frame.fixedLevel)
            local portrait=record(J,"partyFrames",roots[2],"portrait")
            assert(portrait.id=="CLASS_DRUID" and portrait.frame.shown)
            for _,m in ipairs({first,second,portrait}) do
                assert(m.frame.parent==UIParent and not m.frame.mouse and not m.frame.keyboard and not m.frame.wheel)
            end
            local writes=M.frameGeometryWrites;M.combat=true
            roots[1].unit="party1";roots[2].unit="party2";M.event(J.Core,"GROUP_ROSTER_UPDATE")
            assert(first.id=="CLASS_DRUID" and second.id=="CLASS_HUNTER" and portrait.id=="CLASS_HUNTER")
            assert(writes==M.frameGeometryWrites,"Sorting rewrote protected layout")
            registered(J,"partyFrames",first);registered(J,"partyFrames",second)
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
            M.combat=true;local writes=M.frameGeometryWrites
            M.unitData.targettarget={player=false};M.event(J.Core,"UNIT_TARGET","target")
            assert(m.id=="FACTION_NEUTRAL")
            M.unitData.targettarget={player=true,class="DRUID"};M.event(J.Core,"UNIT_TARGET","target")
            assert(m.id=="CLASS_DRUID" and m.frame.shown and writes==M.frameGeometryWrites)
            registered(J,"targetTargetFrame",m)
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
        registered(J,"partyFrames",m)
    end
    assert(portrait.id=="CLASS_HUNTER")
    J.ProfileManager:Set("partyFrames","smallFrameArt","MATCH")
    J.ProfileManager:Set("partyFrames","portraitMode","RACE");assert(m.id=="RACE_ORC")
    J.ProfileManager:Set("partyFrames","portraitMode","FACTION");assert(m.id=="FACTION_HORDE")
    J.ProfileManager:Set("partyFrames","unitFrameShown",false);assert(not m.frame.shown and portrait.frame.shown)
    J.ProfileManager:Set("partyFrames","shown",false);assert(not portrait.frame.shown)
    J.ProfileManager:Set("partyFrames","unitFrameShown",true);assert(m.frame.shown and not portrait.frame.shown)
end)

for _,interface in ipairs({120100,16001}) do
    for _,source in ipairs({"BLIZZARD","ELVUI","ELLESMERE"}) do
        for _,key in ipairs({"partyFrames","targetTargetFrame"}) do
            test(source.." "..key.." clears nested chrome and combat layer changes on "..interface,function(M)
                local J=M.load({interface=interface});local root=fixture(M,source,key=="targetTargetFrame")[1]
                local chrome=M.region(root,"Frame",150,45);chrome.level=700;chrome.strata="HIGH"
                local highlight=M.region(chrome,"Frame",150,45);highlight.level=900;highlight.strata="TOOLTIP"
                root.GetChildren=function() return chrome end
                chrome.GetChildren=function() return highlight end
                enable(J,key,source,true)
                local border,portrait=record(J,key,root),record(J,key,root,"portrait")
                assert(border.frame.strata=="TOOLTIP" and border.frame.level==901)
                assert(portrait and portrait.frame.strata=="TOOLTIP" and portrait.frame.level==901)
                assert(J.ProfileManager:Set(key,"smallFrameLevel",8));assert(border.frame.level==908 and portrait.frame.level==901)
                J.ProfileManager:Set(key,"strata","HIGH");J.ProfileManager:Set(key,"level",4)
                assert(portrait.frame.strata=="HIGH" and portrait.frame.level==704 and border.frame.level==908)
                J.ProfileManager:Set(key,"unitFrameStrata","HIGH")
                assert(border.frame.strata=="HIGH" and border.frame.level==708)
                J.ProfileManager:Set(key,"unitFrameStrata","TOOLTIP")
                local writes=M.geometryWrites;M.combat=true;highlight.level=950;chrome.level=750;M.tick(J.Core)
                assert(border.frame.strata=="TOOLTIP" and border.frame.level==958 and portrait.frame.level==754)
                assert(M.geometryWrites==writes,"Layer change refitted artwork during combat")
                J.ProfileManager:Set(key,"smallFrameLevel",12)
                assert(border.frame.level==958,"Combat setting was not deferred")
                border.frame.protected=true;highlight.level=980;M.tick(J.Core)
                assert(border.frame.level==958 and J.Core.dirty)
                M.combat=false;border.frame.protected=false;M.event(J.Core,"PLAYER_REGEN_ENABLED")
                assert(border.frame.level==992 and portrait.frame.level==754)
                local backup=J.ProfileManager:Export();J.ProfileManager:Reset(key);assert(J.ProfileManager:Import(backup))
                assert(J.ThemeManager:Resolve(key).smallFrameLevel==12 and border.frame.level==992)
                for i=1,10 do M.tick(J.Core) end
                assert(border.frame.level==992,"Frame level grew on every tick")
                assert(highlight.level==980 and chrome.level==750 and root.level==10 and M.nativeWrites==0)
                assert(not next(J.Core.notices))
            end)
        end
    end
end

test("small frame layer discovery is bounded shared and tolerant of restricted children",function(M)
    local J=M.load();local root=fixture(M,"ELVUI")[1]
    local broken=M.region(root,"Frame",150,45);broken.GetFrameStrata=function() error("Restricted metadata") end
    local forbidden=M.region(root,"Frame",150,45);forbidden.forbidden=true
    local secret=M.region(root,"Frame",150,45);secret.GetFrameLevel=function() return M.secret end
    local chrome=M.region(root,"Frame",150,45);chrome.strata="HIGH";chrome.level=90
    local scans=0
    root.GetChildren=function() scans=scans+1;return broken,forbidden,secret,chrome,root end
    chrome.GetChildren=function() error("Restricted children") end
    enable(J,"partyFrames","ELVUI",true)
    local border=record(J,"partyFrames",root);local portrait=record(J,"partyFrames",root,"portrait")
    assert(border.frame.strata=="HIGH" and border.frame.level==91 and portrait.frame.level==91)
    scans=0;M.tick(J.Core);assert(scans==1,"Portrait and border rescanned the same provider tree")
    local own=M.region(root,"Frame",150,45);own.strata="TOOLTIP";own.level=9000;J.Core.owned[own]="test"
    local children={own};local reads=0
    for i=1,200 do
        local child=M.region(root,"Frame",1,1);child.GetFrameLevel=function() reads=reads+1;return 50 end
        children[#children+1]=child
    end
    root.GetChildren=function() return unpack(children) end
    M.tick(J.Core)
    assert(reads<64 and border.frame.strata=="MEDIUM" and not next(J.Core.notices))
end)

test("Target of Target clears parent layers without inspecting other party members",function(M)
    local J=M.load();local root=fixture(M,"BLIZZARD",true)[1]
    local parent=M.native("TargetHost",200,100);parent.level=500;parent.strata="DIALOG"
    parent.GetChildren=function() error("Parent subtree must not be traversed") end
    root.parent=parent;enable(J,"targetTargetFrame","BLIZZARD")
    local border=record(J,"targetTargetFrame",root)
    assert(border.frame.strata=="DIALOG" and border.frame.level==501)
    J.ProfileManager:Set("targetTargetFrame","unitFrameStrata","TOOLTIP")
    assert(border.frame.strata=="TOOLTIP" and border.frame.level==501 and not next(J.Core.notices))
end)

test("compact border level controls are independent and persist in old profiles",function(M)
    local J=M.load();local S=J.SettingsUI;S:Open()
    for _,key in ipairs(J.SmallFrames.keys) do
        S:Select(key);S:SetPage("advanced")
        assert(S.controls.smallFrameLevel.slider:IsVisible() and S.controls.unitFrameStrata.label.text=="Compact border strata")
        assert(not S.controls.unitFrameFill.button:IsVisible())
        S.controls.unitFrameStrata.options.TOOLTIP.scripts.OnClick()
        S:Set("smallFrameLevel",20)
        local c=J.ThemeManager:Resolve(key)
        assert(c.unitFrameStrata=="TOOLTIP" and c.smallFrameLevel==20 and c.level==1)
        assert(not J.ProfileManager:Set(key,"smallFrameLevel",0) and not J.ProfileManager:Set(key,"smallFrameLevel",101))
    end
    S:Select("playerFrame");assert(not S.controls.smallFrameLevel.slider:IsVisible() and S.controls.unitFrameFill.button:IsVisible())
    assert(not J.ProfileManager:Set("playerFrame","smallFrameLevel",20))
    assert(J.ProfileManager:Import("JF2;paladin_ret;partyFrames.unitFrameStrata=HIGH"))
    assert(J.ThemeManager:Resolve("partyFrames").smallFrameLevel==1 and not next(J.Core.notices))
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

for _,interface in ipairs({120100,16001}) do
    for _,source in ipairs({"AUTO","ELLESMERE"}) do
        test("Ellesmere protected range fading keeps every party member decorated "..source.." "..interface,function(M)
            local J=M.load({interface=interface});local roots=fixture(M,"ELLESMERE")
            M.unitData.party3={player=true,class="PRIEST"};M.unitData.party4={player=true,class="MAGE"}
            roots[3]=member(M,"ELLESMERE","party3",3);roots[4]=member(M,"ELLESMERE","party4",4)
            local parked=member(M,"ELLESMERE",nil,5);parked.shown=false
            local self=member(M,"ELLESMERE","player",6)
            -- EUI 9.3 gives self a plain alpha, but range-fades the other four
            -- with SetAlphaFromBoolean(UnitInRange(...)). Children inherit it.
            for _,root in ipairs(roots) do root.secretAlpha=true end
            J.ProfileManager:Set("partyFrames","opacity",.6)
            enable(J,"partyFrames",source,true)
            local function check()
                for _,root in ipairs(roots) do
                    for _,kind in ipairs({"border","portrait"}) do
                        local m=record(J,"partyFrames",root,kind)
                        assert(m and m.frame.shown and m.id=="CLASS_"..M.unitData[root.unit].class,
                            "Range-faded "..root.unit.." lost "..kind..": "..tostring(m and m.id).." / "..tostring(m and m.frame.shown).." / "..tostring(next(J.Core.notices)))
                        assert(issecretvalue(m.frame.alpha),"Native range alpha was not passed directly to the renderer")
                        for _,t in pairs(m.textures) do assert(t.shown);near(t.alpha,.6) end
                    end
                end
                assert(record(J,"partyFrames",self).frame.shown)
                assert(not record(J,"partyFrames",parked).frame.shown)
                assert(not next(J.Core.notices))
            end
            check()
            local geometry=M.frameGeometryWrites;local frames,textures=#M.frames,M.textures
            M.combat=true;roots[1].unit,roots[2].unit=roots[2].unit,roots[1].unit
            M.event(J.Core,"GROUP_ROSTER_UPDATE");M.tick(J.Core);check()
            assert(M.frameGeometryWrites==geometry and #M.frames==frames and M.textures==textures)
            local root=roots[1];root.shown=false;M.tick(J.Core)
            assert(not record(J,"partyFrames",root).frame.shown)
            root.shown=true;root.secretAlpha=false;root.alpha=.4;M.tick(J.Core)
            for _,kind in ipairs({"border","portrait"}) do
                local m=record(J,"partyFrames",root,kind)
                assert(m.frame.shown);near(m.frame.alpha,.24)
                for _,t in pairs(m.textures) do near(t.alpha,1) end
            end
            root.alpha=0;M.tick(J.Core);assert(not record(J,"partyFrames",root).frame.shown)
            root.secretAlpha=true;M.tick(J.Core);check()
            local m=record(J,"partyFrames",root);m.frame.protected=true
            J.SmallFrames:Tick();assert(J.Core.dirty)
            M.combat=false;M.event(J.Core,"PLAYER_REGEN_ENABLED");check()
            assert((M.nativeLayoutWrites or 0)==0 and (M.appearanceWrites or 0)==0)
        end)
    end
end

test("retired party attachments reuse a bounded frame pool after repeated roster changes",function(M)
    local J=M.load();local roots,list=fixture(M,"BLIZZARD");enable(J,"partyFrames","BLIZZARD",true)
    local retired=record(J,"partyFrames",roots[1]);local objects=#M.objects
    for i=1,10 do
        list[roots[1]]=nil;M.tick(J.Core);assert(not retired.frame.shown)
        list[roots[1]]=true;M.tick(J.Core);assert(record(J,"partyFrames",roots[1])==retired)
    end
    assert(#M.objects==objects and not next(J.Core.notices))
end)

local function partyReport(M,J,command)
    M.messages={}
    local writes,objects=M.writes,#M.objects
    local profile=J.ProfileManager:Export()
    J.Core:Command(command or "partydebug")
    local text=table.concat(M.messages,"\n")
    assert(text:find("Party diagnostics "..J.Core.version,1,true) and text:find("End party diagnostics.",1,true),text)
    assert(M.writes==writes and #M.objects==objects and J.ProfileManager:Export()==profile,"Diagnostic mutated UI or settings")
    return text
end

test("party diagnostic always explains disabled and not-yet-attached states",function(M)
    local J=M.load()
    assert(partyReport(M,J):find("border: off",1,true))
    enable(J,"partyFrames","ELLESMERE")
    local text=partyReport(M,J,"status party")
    assert(text:find("border: on | requested=ELLESMERE | provider=EllesmereUI | candidates=0",1,true))
    assert(text:find("no cached party frames",1,true) and not next(J.Core.notices))
end)

for _,interface in ipairs({120100,16001}) do
    for _,source in ipairs({"BLIZZARD","ELVUI","ELLESMERE"}) do
        test("party diagnostic reads each "..source.." border and portrait without mutation "..interface,function(M)
            local J=M.load({interface=interface});fixture(M,source);enable(J,"partyFrames",source,true)
            M.combat=true
            local text=partyReport(M,J,"diagnostics party")
            assert(text:find("combat=yes",1,true))
            for _,kind in ipairs({"border","portrait"}) do
                for i=1,2 do
                    local prefix=kind.." #"..i
                    assert(text:find(prefix.." unit=party",1,true))
                    assert(text:find(prefix.." attached=yes | eligible=yes | artwork=ready | shown=yes",1,true))
                    assert(text:find(prefix.." root: gate=yes | visible=yes | effectiveAlpha=1 | alpha=1",1,true))
                end
            end
            assert(not next(J.Core.notices))
        end)
    end
end

test("party diagnostic separates unreadable effective alpha from secret alpha without stopping",function(M)
    local J=M.load({interface=16001});local roots=fixture(M,"ELLESMERE")
    local self=member(M,"ELLESMERE","player",6)
    for _,root in ipairs(roots) do
        root.GetEffectiveAlpha=function() error(M.secret) end
        root.GetAlpha=function() return M.secret end
    end
    enable(J,"partyFrames","ELLESMERE")
    assert(J.SmallFrames.status.partyFrames:find("1 visible / 3 attached",1,true))
    local text=partyReport(M,J)
    for i=1,2 do
        assert(text:find("border #"..i.." attached=yes | eligible=no | artwork=ready | shown=no",1,true))
        assert(text:find("border #"..i.." root: gate=no | visible=yes | effectiveAlpha=error | alpha=restricted",1,true))
        assert(text:find("border #"..i.." health: gate=no | visible=yes | effectiveAlpha=error | alpha=1",1,true))
    end
    assert(text:find("border #3 unit=player",1,true) and record(J,"partyFrames",self).frame.shown)
    assert(not next(J.Core.notices))
end)

test("party diagnostic distinguishes restricted and failed identity reads and continues to other frames",function(M)
    local J=M.load();local roots=fixture(M,"ELLESMERE");enable(J,"partyFrames","ELLESMERE")
    roots[1].GetAttribute=function() return M.secret end
    roots[1].IsVisible=function() return M.secret end
    roots[1].secretAlpha=true
    roots[2].GetAttribute=function() error(M.secret) end
    M.tick(J.Core)
    local text=partyReport(M,J)
    assert(text:find("border #1 unit=none | attribute=restricted | exists=not checked | present=no",1,true))
    assert(text:find("border #1 root: gate=no | visible=restricted | effectiveAlpha=restricted",1,true))
    assert(text:find("border #2 unit=none | attribute=error",1,true))
    assert(not text:find("diagnostic read failed",1,true) and not next(J.Core.notices))
end)

test("party diagnostic reports removed units, zero alpha and forbidden cached frames",function(M)
    local J=M.load();local roots=fixture(M,"ELLESMERE");enable(J,"partyFrames","ELLESMERE")
    M.unitData.party2=nil;roots[1].alpha=0
    M.combat=true;M.tick(J.Core)
    roots[2].forbidden=true
    local text=partyReport(M,J)
    assert(text:find("border #1 unit=party2 | attribute=party2 | exists=no | present=no",1,true))
    assert(text:find("border #1 root: gate=no | visible=yes | effectiveAlpha=0 | alpha=0",1,true))
    assert(text:find("border #2 root: gate=no | visible=unavailable | effectiveAlpha=unavailable",1,true))
    assert(not next(J.Core.notices))
end)

test("party diagnostic never treats restricted existence as an absent member",function(M)
    local J=M.load();local roots=fixture(M,"ELLESMERE");enable(J,"partyFrames","ELLESMERE")
    local original=UnitExists
    UnitExists=function(unit) if unit=="party2" then return M.secret end;return original(unit) end
    roots[1].secretAlpha=true;M.tick(J.Core)
    local text=partyReport(M,J)
    assert(text:find("border #1 unit=party2 | attribute=party2 | exists=restricted | present=yes",1,true))
    assert(text:find("border #1 attached=yes | eligible=yes | artwork=ready | shown=yes",1,true))
    assert(text:find("border #1 root: gate=yes | visible=yes | effectiveAlpha=restricted",1,true))
    assert(not next(J.Core.notices))
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
