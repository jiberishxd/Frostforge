local M=dofile('tests/mock_wow.lua')
local J={}
for line in io.lines('JiberishUI/JiberishUI.toc') do
    if line:match('%.lua$') then assert(loadfile('JiberishUI/'..line:gsub('\\','/')))('JiberishUI',J) end
end
local count=0
local function test(name,fn)
    local ok,err=pcall(fn); if not ok then io.stderr:write('FAIL '..name..': '..tostring(err)..'\n'); os.exit(1) end
    count=count+1;print('PASS '..name)
end
local function equal(actual,expected) assert(actual==expected,tostring(actual)..' ~= '..tostring(expected)) end
local P=J.Profiles
test('startup and native Settings registration',function() J:Initialize();M.flush();assert(J.ready);J.SettingsUI:Open();equal(M.category,123);equal(P:Name(),'Default') end)
test('skin/global/group precedence and deep copy',function()
    P:Set('global','skin','orc');P:Set('global','opacity',0.8);P:Set('raid','skin','undead');P:Set('raid','opacity',0.4)
    equal(P:Resolve('player').skin,'orc');equal(P:Resolve('raid').skin,'undead');equal(P:Resolve('raid').opacity,0.4)
    local c=P:Resolve('raid');c.tint[1]=0;equal(P:Resolve('raid').tint[1],1)
end)
test('export/import round trip and malformed data rejection',function()
    local export=P.Export(P:Current());assert(P.Validate(P.Import(export)));equal(P.Export(P.Import(export)),export)
    for _,bad in ipairs({'return os.execute("bad")','JUI1\nskin=s:human\n.global.opacity=n:1','JUI1\nskin=s:human\nglobal.opacity=n:nan','JUI1\nskin=s:human\nglobal.opacity=n:2','JUI1\nskin=s:human\ngroups.nameplate.enabled=b:true','JUI1\nskin=s:human\nskin=s:orc','JUI1\nskin=s:human\nglobal.opacity=n:1\nglobal.opacity.x=n:1','JUI1\nskin=s:human\nglobal.healthColor.1=n:0.5'}) do assert(not P.Import(bad),bad) end
end)
test('all valid power palettes round trip within import limits',function()
    local p=P.Default()
    for _,group in ipairs(J.Groups) do
        p.groups[group]={powerColors={}}
        for i=1,32 do p.groups[group].powerColors[string.rep('A',i)]={0.123456789,0.23456789,0.3456789} end
    end
    assert(P.Validate(p));local text=P.Export(p);assert(#text>65536);assert(P.Import(text))
end)
test('named profiles and per-character assignment',function()
    assert(P:Copy('Raid setup'));equal(P:Name(),'Raid setup');assert(not P:Copy('Raid setup'));assert(P:Select('Default'))
    assert(P:Init());equal(P:Name(),'Default')
end)
test('forward schema is preserved',function()
    local old=JiberishUIDB;JiberishUIDB={version=99};local db=JiberishUIDB;assert(not P:Init());equal(JiberishUIDB,db);JiberishUIDB=old;assert(P:Init())
end)
test('fresh profile service restores serialized appearance and color modes without resetting',function()
    local savedGlobal=JiberishUIDB
    local profile=P.Default();profile.skin='dwarf';profile.global.healthMode='class';profile.global.powerMode='type'
    profile.groups.player={skin='alliance',healthMode='class',powerMode='custom',powerColor={0.1,0.2,0.3}}
    profile.groups.target={skin='bronze',opacity=0.6}
    local serialized=assert(P.Export(profile));local restored=assert(P.Import(serialized))
    JiberishUIDB={version=1,profiles={Default=restored},characters={}}
    local fresh={Util=J.Util,Skins=J.Skins,GroupSet=J.GroupSet}
    assert(loadfile('JiberishUI/Core/Profiles.lua'))('JiberishUI',fresh)
    assert(fresh.Profiles:Init());equal(fresh.Profiles.loadState,'received')
    equal(fresh.Profiles:Resolve('player').healthMode,'class');equal(fresh.Profiles:Resolve('player').skin,'alliance')
    equal(fresh.Profiles:Resolve('target').skin,'bronze');equal(fresh.Profiles:Resolve('target').healthMode,'class')
    equal(fresh.Profiles:Resolve('player').powerMode,'custom');equal(P.Export(fresh.Profiles:Current()),serialized)
    JiberishUIDB=savedGlobal
end)
test('persistence diagnostics distinguish missing input from rejected profile data',function()
    local savedGlobal=JiberishUIDB
    JiberishUIDB=nil;assert(P:Init());equal(P.loadState,'missing');assert(P:LoadStatus():find('No saved settings',1,true))
    JiberishUIDB={version=1,profiles={Default={skin='unknown'}},characters={}}
    assert(P:Init());equal(P.loadState,'invalid-default');equal(JiberishUIDB.recoveryDefault.skin,'unknown')
    JiberishUIDB=savedGlobal;assert(P:Init());equal(P.loadState,'received')
end)
test('direct export and import commands use the validated profile dialogs',function()
    local before=assert(P.Export(P:Current()))
    SlashCmdList.JIBERISHUI('export');equal(J.SettingsUI.dialog.edit:GetText(),before)
    SlashCmdList.JIBERISHUI('import');local apply=J.SettingsUI.dialog.action
    assert(not apply('return os.execute("bad")'));equal(P.Export(P:Current()),before)
    assert(apply(before));equal(P.Export(P:Current()),before);J.SettingsUI.dialog:Hide()
end)
local raid,outsider
test('container discovery includes compact pets and excludes nameplates',function()
    CompactRaidFrameContainer=CreateFrame('Frame',nil,UIParent);raid=M.compact(CompactRaidFrameContainer)
    outsider=M.compact(UIParent);CompactPartyFrame=CreateFrame('Frame',nil,UIParent);CompactPartyFrame.memberUnitFrames={};CompactPartyFrame.petUnitFrames={M.compact(CompactPartyFrame)}
    M.flush();J:RefreshAll();assert(J.records[raid]);assert(J.records[CompactPartyFrame.petUnitFrames[1]]);assert(not J.records[outsider])
    local textures,hooks=M.textures,M.hooks;CompactUnitFrame_UpdateAll(outsider);equal(textures,M.textures);equal(hooks,M.hooks)
end)
test('repeated refresh reuses textures and hooks',function()
    local textures,hooks=M.textures,M.hooks
    for i=1,10 do J:RefreshAll();CompactUnitFrame_UpdateAll(raid) end
    equal(M.textures,textures);equal(M.hooks,hooks)
end)
test('combat queues latest settings and defers newly discovered frames',function()
    M.flush();local before=J.active.raid.skin;M.combat=true
    P:Set('raid','skin','nightelf');P:Set('raid','skin','human');J:RefreshAll();equal(J.active.raid.skin,before)
    local fresh=M.compact(CompactRaidFrameContainer);local textures=M.textures;local geometry=M.layoutWrites
    J:RefreshAll();assert(not J.records[fresh]);equal(M.textures,textures);equal(M.layoutWrites,geometry)
    M.combat=false;J:RefreshAll();equal(J.active.raid.skin,'human');assert(J.records[fresh])
end)
test('disabling saves settings while live restoration requires reload',function()
    P:Set('raid','enabled',false);M.flush();equal(P:Resolve('raid').enabled,false);equal(J.active.raid.enabled,true);assert(J.reloadGroups.raid)
    P:Set('raid','enabled',true);M.flush();assert(not J.reloadGroups.raid)
end)
test('neutral fill, native priority, restricted input and threat coloring',function()
    P:Set('raid','healthMode','custom');P:Set('raid','healthColor',{0.2,0.3,0.4});M.flush()
    equal(raid.healthBar:GetStatusBarTexture():GetTexture(),J.Neutral)
    M.dead=true;J:RefreshAll();equal(raid.healthBar:GetStatusBarTexture():GetTexture(),'native');M.dead=false
    M.restricted=true;J:RefreshAll();equal(raid.healthBar:GetStatusBarTexture():GetTexture(),'native');M.restricted=false
    raid.displayThreatHealthBarColor=true;J:RefreshAll();equal(raid.healthBar:GetStatusBarTexture():GetTexture(),'native');raid.displayThreatHealthBarColor=false
    M.tapped=true;J:RefreshAll();equal(raid.healthBar:GetStatusBarTexture():GetTexture(),'native');M.tapped=false
    M.connected=false;J:RefreshAll();equal(raid.healthBar:GetStatusBarTexture():GetTexture(),'native');M.connected=true
end)
test('native texture/color resets reapply custom colors and preserve new fallback',function()
    J:RefreshAll();raid.healthBar:SetStatusBarTexture('new-native');raid.healthBar:SetStatusBarColor(0.7,0.6,0.5,1)
    equal(raid.healthBar:GetStatusBarTexture():GetTexture(),J.Neutral);equal(select(1,raid.healthBar:GetStatusBarColor()),0.2)
    P:Set('raid','healthMode','native');M.flush();equal(raid.healthBar:GetStatusBarTexture():GetTexture(),'new-native');equal(select(1,raid.healthBar:GetStatusBarColor()),0.7)
end)
test('class reaction and power-type modes do not read quantities',function()
    local cfg=P:Resolve('raid');cfg.healthMode='class';local rgb=J.Colors.Resolve(raid,'health',cfg);equal(rgb[1],0.4)
    M.player=false;rgb=J.Colors.Resolve(raid,'health',cfg);equal(rgb[1],1);M.player=true
    cfg.powerMode='type';cfg.powerColors.MANA={0.1,0.2,0.3};equal(J.Colors.Resolve(raid,'power',cfg)[1],0.1)
    M.restrictedPower=true;assert(not J.Colors.Resolve(raid,'power',cfg));M.restrictedPower=false
end)
test('native masks retained and addon mask removal deferred through combat',function()
    local frame=M.compact(UIParent);local bar=frame.healthBar;local mask=bar:CreateTexture();local cfg=P:Resolve('raid');cfg.healthMode='custom'
    local color=J.Colors.Attach(frame,bar,'health',mask,function() return cfg end)
    J.Colors.Apply(color);equal(bar.fill:GetNumMaskTextures(),1)
    M.combat=true;cfg.healthMode='native';J.Colors.Apply(color);equal(bar.fill:GetNumMaskTextures(),1)
    M.combat=false;J.Colors.Apply(color);equal(bar.fill:GetNumMaskTextures(),0)
    bar.fill:AddMaskTexture(mask);cfg.healthMode='custom';J.Colors.Apply(color);cfg.healthMode='native';J.Colors.Apply(color);equal(bar.fill:GetNumMaskTextures(),1)
end)
test('missing artwork retains native decoration',function()
    local frame=CreateFrame('Button',nil,UIParent);frame.HealthBar=M.bar(frame);frame.Portrait=frame:CreateTexture();frame.FrameTexture=frame:CreateTexture();frame.unit='targettarget'
    frame.ManaBar=M.bar(frame);frame.HealthBar.HealthBarMask=frame.HealthBar:CreateTexture();frame.ManaBar.ManaBarMask=frame.ManaBar:CreateTexture();frame.FrameTexture:SetAtlas('native-small-shell')
    TargetFrameToT=frame
    M.missing='human';J.active.targettarget=P:Resolve('targettarget');J.active.targettarget.skin='human'
    J:Attach({frame=frame,group='targettarget',kind='unit',definition=J.AdapterCommon.Units.small});equal(frame.FrameTexture:GetAlpha(),1);assert(not J.records[frame].applied);M.missing=nil
    J:RefreshAll();equal(frame.FrameTexture:GetAlpha(),1);assert(J.records[frame].applied)
end)
test('missing required regions fail closed before decoration suppression',function()
    local frame=CreateFrame('Button',nil,UIParent);frame.HealthBar=M.bar(frame);frame.FrameTexture=frame:CreateTexture()
    J:Attach({frame=frame,group='focustarget',kind='unit',definition=J.AdapterCommon.Units.small})
    assert(not J.records[frame]);equal(frame.FrameTexture:GetAlpha(),1)
end)
test('missing neutral artwork leaves native status bars intact',function()
    local saved=J.Colors.qualified;J.Colors.qualified=nil;M.missing='neutral.tga'
    local f=M.compact(UIParent);local r=J.Colors.Attach(f,f.healthBar,'health',nil,function() return P:Resolve('raid') end)
    assert(not r);equal(f.healthBar:GetStatusBarTexture():GetTexture(),'native');M.missing=nil;J.Colors.qualified=saved
end)
test('overlapping UI replacement skips affected module',function()
    M.loaded.Bartender4=true;local b=CreateFrame('Button',nil,UIParent);J:Attach({frame=b,group='actionbars',kind='button'});assert(not J.records[b]);M.loaded.Bartender4=nil
end)
test('button state reset and stable hooks',function()
    local b=CreateFrame('Button',nil,UIParent);for _,state in ipairs({'Normal','Pushed','Highlight','Checked'}) do b['Set'..state..'Texture'](b,'native') end
    J:Attach({frame=b,group='actionbars',kind='button'});local hooks=M.hooks
    b:SetNormalAtlas('blizzard-replacement');assert(b:GetNormalTexture():GetTexture():find('button%-normal.tga'));equal(M.hooks,hooks)
end)
test('pooled frame ownership loss stops custom updates',function()
    local frame=M.compact(CompactRaidFrameContainer);J:RefreshAll();assert(J.records[frame].applied)
    for i,child in ipairs(CompactRaidFrameContainer.children) do if child==frame then table.remove(CompactRaidFrameContainer.children,i); break end end
    J:RefreshAll();assert(not J.records[frame].owned);assert(not J.records[frame].applied)
    local writes=M.layoutWrites;CompactUnitFrame_UpdateAll(frame);equal(M.layoutWrites,writes)
end)
test('Forever endcaps retain independent containers',function()
    local bar=CreateFrame('Frame',nil,UIParent);bar.BorderArt=bar:CreateTexture();bar.EndCaps=CreateFrame('Frame',nil,bar)
    for _,key in ipairs({'LeftEndCap','RightEndCap'}) do local f=CreateFrame('Frame',nil,bar.EndCaps);f.Texture=f:CreateTexture();bar.EndCaps[key]=f end
    J:Attach({frame=bar,group='actionbars',kind='rail'});equal(#J.records[bar].endcaps,2);equal(bar.EndCaps.LeftEndCap.Texture:GetAlpha(),0);equal(J.records[bar].endcaps[1].texture:GetParent(),bar.EndCaps.LeftEndCap)
end)
test('diagnostics use geometry without unit identity or values',function()
    raid.unit='DO_NOT_LEAK';local output=J:Diagnostics();assert(output:find('120100'));assert(not output:find('DO_NOT_LEAK'));raid.unit='raid1'
end)
test('settings and synthetic preview render without unit data',function() J.SettingsUI:Refresh();J.SettingsUI:Dialog('Export',P.Export(P:Current()));equal(J.SettingsUI.previewHealth.value,75) end)
test('expanded catalog preserves classic IDs and every skin exports/imports',function()
    equal(#J.SkinOrder,52)
    for _,id in ipairs({'human','orc','nightelf','undead'}) do equal(J.Skins[id].material,id) end
    for _,id in ipairs(J.SkinOrder) do
        local p=P.Default();p.skin=id;local encoded=P.Export(p);equal(P.Import(encoded).skin,id)
        local skin=J.Skins[id];equal(skin.defaults.healthMode,'native');equal(skin.defaults.powerMode,'native')
    end
end)
test('catalog filters categories and uses literal case-insensitive search',function()
    equal(#J:FindSkins('class',''),13);equal(#J:FindSkins('race',''),29);equal(#J:FindSkins('faction',''),2);equal(#J:FindSkins('standard',''),8)
    equal(J:FindSkins('class',' MAGE ')[1],'mage');equal(#J:FindSkins('race','Night Elf'),4)
    equal(#J:FindSkins('all','%['),0);equal(J:FindSkins('standard','black stone')[1],'blackstone')
end)
test('new skin defaults preserve explicit global and group appearance overrides',function()
    P:Set('global','skin','mage');P:Set('global','opacity',0.7);P:Set('party','skin','blackstone');P:Set('party','tint',{0.8,0.9,1})
    equal(P:Resolve('player').skin,'mage');equal(P:Resolve('party').ornament,0);equal(P:Resolve('party').opacity,0.7)
    equal(P:Resolve('party').tint[1],0.8);P:ClearGroup('party');equal(P:Resolve('party').skin,'mage');M.flush()
end)
test('visual browser reuses cards, paginates, and handles empty results',function()
    local S=J.SettingsUI;S.scope='global';S:BrowseSkins();local f=S.browser;local textures=M.textures
    equal(f.cards[1].skin,'human');f.page=2;S:RefreshBrowser();assert(f.cards[1].skin~='human')
    f.category='class';f.page=100;S:RefreshBrowser();equal(f.page,3);assert(f.cards[1].skin);assert(not f.cards[2].shown)
    f.search:SetText('nonexistent style');S:RefreshBrowser();assert(not f.cards[1].shown);equal(f.page,1)
    f.search:SetText('');f.category='all';f.page=1;S:RefreshBrowser();equal(M.textures,textures)
end)
test('browser selection changes only the captured frame group',function()
    local S=J.SettingsUI;S.scope='target';S:BrowseSkins();S.browser.category='class';S.browser.search:SetText('warlock');S:RefreshBrowser()
    equal(S.browser.cards[1].skin,'warlock');S.browser.cards[1].scripts.OnClick()
    equal(P:Resolve('target').skin,'warlock');equal(P:Resolve('player').skin,'mage');assert(not S.browser.shown);M.flush()
end)
test('choosing a library preset during combat defers the live skin',function()
    local S=J.SettingsUI;local old=J.active.target.skin;M.combat=true;S.scope='target';S:BrowseSkins()
    S.browser.category='race';S.browser.search:SetText('moonwell');S:RefreshBrowser();S.browser.cards[1].scripts.OnClick()
    equal(P:Resolve('target').skin,'nightelf_moonwell');equal(J.active.target.skin,old)
    M.combat=false;J:RefreshAll();equal(J.active.target.skin,'nightelf_moonwell')
end)
test('portrait unit variants attach on both clients without unsupported texture scripts',function()
    for _,adapter in ipairs({J.Adapters.retail,J.Adapters.forever}) do
        for _,entry in ipairs({{'player','player'},{'target','target'},{'party','party'},{'pet','pet'},{'small','targettarget'},{'partypet','partypet'}}) do
            local variant,group=entry[1],entry[2]
            local frame,health,power,portrait,decoration=M.portraitUnit(variant)
            local before=J.active[group];local cfg=P:Resolve(group);cfg.skin='human';J.active[group]=cfg
            local ok=J:Protect(group,J.Attach,J,{frame=frame,group=group,kind='unit',definition=adapter.units[variant]})
            assert(ok,adapter.id..' '..variant);local record=assert(J.records[frame]);assert(record.applied and not record.failed)
            equal(decoration:GetAlpha(),1);assert(not portrait.scripts.OnSizeChanged)
            local textures,hooks=M.textures,M.hooks
            cfg.skin='mage';cfg.healthMode='custom';cfg.powerMode='custom'
            for i=1,5 do J:RefreshSafely(record,true) end
            assert(record.applied and not record.failed);equal(M.textures,textures);equal(M.hooks,hooks)
            equal(health:GetStatusBarTexture():GetTexture(),J.Neutral)
            if power then equal(power:GetStatusBarTexture():GetTexture(),J.Neutral) end
            assert(record.borders[1].arcs[1]:GetTexture():find('arcane_crystal',1,true))
            equal(record.borders[1].arcs[1].points[1][2],portrait)
            equal(record.borders[1].mask:GetTexture(),decoration:GetTexture())
            J.active[group]=before
        end
    end
end)
test('runtime error reports retain code locations without exposing payloads',function()
    local old=geterrorhandler;local captured={}
    geterrorhandler=function() return function(message) captured[#captured+1]=message end end
    local function fail() error('Interface/AddOns/JiberishUI/Core/Main.lua:123: attempt to call a nil value PRIVATE_UNIT_DATA',0) end
    assert(not J:Protect('diagnostic-test',fail));assert(not J:Protect('diagnostic-test',fail))
    equal(#captured,1);assert(captured[1]:find('Core/Main.lua:123',1,true));assert(not captured[1]:find('PRIVATE_UNIT_DATA',1,true))
    equal(J.Util.ErrorSummary(M.secret),'Runtime error (details unavailable).')
    equal(J.Util.ErrorSummary('Texture:HookScript(): Doesn\'t have a script. PRIVATE_UNIT_DATA','[JiberishUI/Core/Main.lua]:132: in function Attach'),
        'Unsupported widget script at Core/Main.lua:132.')
    J.failures['diagnostic-test']=nil;geterrorhandler=old
end)
test('live status distinguishes applied frames from failed attachments and empty groups',function()
    local old=J.records;local oldFailures=J.failures;J.records={};J.failures={}
    assert(J:LiveStatus('player'):find('No supported frames',1,true))
    J.records[{}]={group='player',applied=false,failed=true}
    assert(J:LiveStatus('player'):find('failed',1,true))
    J.records={};J.records[{}]={group='player',applied=true}
    assert(J:LiveStatus('player'):find('1 of 1',1,true))
    J.records=old;J.failures=oldFailures
    local output=J:Diagnostics();assert(output:find(' applied',1,true));assert(output:find(' failed',1,true))
end)
test('native silhouettes keep exact artwork bounds, atlas coordinates, and masks',function()
    local f=CreateFrame('Frame',nil,UIParent);local source=f:CreateTexture(nil,'BACKGROUND',nil,2)
    source:SetAtlas('native-teardrop-shell');source:SetTexCoord(0.1,0.8,0.2,0.9)
    local clip=f:CreateMaskTexture();clip:SetTexture('native-clip');source:AddMaskTexture(clip)
    local r=J.Renderer.CreateSilhouette(source);local cfg=P:Resolve('player')
    assert(J.Renderer.Apply(r,cfg));equal(r.mask:GetAtlas(),'native-teardrop-shell')
    equal(r.mask.coords[1],0.1);equal(r.mask.allPoints,source);equal(r.pieces.material.allPoints,source)
    equal(source:GetNumMaskTextures(),1);equal(r.pieces.material:GetNumMaskTextures(),2)
    equal(r.extraMasks[1].allPoints,clip)
    cfg.thickness=12;cfg.inset=12;assert(J.Renderer.Apply(r,cfg));equal(r.pieces.material.allPoints,source)
    local textures=M.textures;local writes=M.layoutWrites;M.combat=true
    source:SetAtlas('native-portrait-off-shell');assert(J.Renderer.Refresh(r,cfg))
    equal(r.mask:GetAtlas(),'native-portrait-off-shell');equal(M.textures,textures);equal(M.layoutWrites,writes);M.combat=false
    source:Hide();assert(J.Renderer.Apply(r,cfg));assert(not r.pieces.material.shown)
    source:Show();assert(J.Renderer.Apply(r,cfg));assert(r.pieces.material.shown)
    textures=M.textures
    for i=1,4 do
        source:RemoveMaskTexture(clip);assert(J.Renderer.Apply(r,cfg))
        equal(r.pieces.material:GetNumMaskTextures(),1)
        source:AddMaskTexture(clip);assert(J.Renderer.Apply(r,cfg))
    end
    equal(M.textures,textures)
end)
test('Blizzard contours preserve the native backdrop and exclude bar interiors',function()
    local frame,health,power,portrait,source=M.portraitUnit('player')
    local cfg=P:Resolve('player');cfg.healthMode='native';cfg.powerMode='native'
    local record=J.Renderer.CreateContour(source,{health=health,power=power,portrait=portrait})
    assert(J.Renderer.Apply(record,cfg));equal(source:GetAlpha(),1);equal(source:GetTexture(),'native')
    equal(#record.arcs,32);equal(#record.bars,2);equal(#record.blockers,2)
    for i,entry in ipairs(record.blockers) do
        equal(entry.mask:GetTexture(),J.MediaRoot..'outside-rect.tga')
        equal(entry.mask:GetWidth(),entry.bar:GetWidth()*2)
        equal(entry.mask.points[1][2],entry.bar)
    end
    for _,arc in ipairs(record.arcs) do
        equal(arc:GetNumMaskTextures(),3);assert(arc.vertices and #arc.vertices==4)
        assert(arc.allPoints~=source) -- No full-frame material fill.
        local v=arc.vertices
        local ax,ay=v[1][1]-0.5,v[1][2]+0.5
        local bx,by=v[2][1]-0.5,v[2][2]-0.5
        local cx,cy=v[3][1]+0.5,v[3][2]+0.5
        assert((bx-ax)*(cy-ay)-(by-ay)*(cx-ax)>0) -- Same vertex winding as an ordinary texture quad.
    end
    for _,border in ipairs(record.bars) do
        equal(border.pieces.top.points[1][2],border.pieces.tl)
        equal(border.pieces.tl.points[1][2],border.region)
        equal(border.pieces.tl.points[1][4],-2);equal(border.pieces.tl.points[1][5],2)
    end
    M.dead=true;assert(J.Renderer.Apply(record,cfg));equal(source:GetAlpha(),1);equal(health:GetStatusBarTexture():GetTexture(),'native');M.dead=false
    power:Hide();power:SetWidth(0);assert(J.Renderer.Apply(record,cfg))
    equal(record.blockers[2].mask:GetTexture(),J.Neutral)
    power:SetWidth(124);power:Show();assert(J.Renderer.Apply(record,cfg))
    local textures,writes=M.textures,M.layoutWrites;M.combat=true
    source:SetAtlas('native-vehicle');assert(J.Renderer.Refresh(record,cfg))
    equal(record.mask:GetAtlas(),'native-vehicle');equal(M.textures,textures);equal(M.layoutWrites,writes);M.combat=false
    source:Hide();assert(J.Renderer.Apply(record,cfg));assert(not record.arcs[1].shown)
end)
test('missing contour exclusion mask fails closed without losing the native backdrop',function()
    local frame,health,power,portrait,source=M.portraitUnit('target')
    M.missing='outside-rect.tga'
    J:Attach({frame=frame,group='target',kind='unit',definition=J.AdapterCommon.Units.target})
    assert(not J.records[frame].applied);equal(source:GetAlpha(),1)
    for _,piece in pairs(J.records[frame].borders[1].pieces) do assert(not piece.shown) end
    M.missing=nil
end)
local function externalUnit()
    local f=CreateFrame('Button',nil,UIParent);f.Health=M.bar(f);f.Power=M.bar(f,126,8);f.unit='player';return f
end
local function resetProviders()
    M.loaded.ElvUI=nil;M.loaded.EllesmereUIUnitFrames=nil;M.loaded.EllesmereUIRaidFrames=nil;M.loaded.EllesmereUIActionBars=nil
    ElvUI=nil;EllesmereUI=nil;ElvUI_BarPet=nil;J.Integrations:Discover({})
    for _,group in ipairs(J.Groups) do J.conflicts[group]=nil end
end
test('ElvUI discovers registered unit frames and bars without touching native or nameplate instances',function()
    local player=externalUnit();local outsider=externalUnit();local native=externalUnit()
    local header=CreateFrame('Frame',nil,UIParent);local party=externalUnit();header.children={party}
    local b=CreateFrame('Button',nil,UIParent);b:SetNormalTexture('elv-native-button')
    local uf={units={player=player},headers={party=header}}
    local ab={handledBars={bar1={buttons={b}}}}
    M.loaded.ElvUI=true;ElvUI={{private={unitframe={enable=true},actionbar={enable=true}},GetModule=function(_,name) return name=='UnitFrames' and uf or ab end}}
    local found=J.Integrations:Discover({{frame=native,group='player'}});local set={}
    for _,d in ipairs(found) do set[d.frame]=d;J:Attach(d) end
    assert(set[player] and set[party] and set[b]);assert(not set[native] and not set[outsider])
    equal(J.records[player].provider,'elvui');assert(J.records[player].applied)
    equal(b:GetNormalTexture():GetTexture(),'elv-native-button');equal(J.records[b].kind,'externalbutton')
    local textures,hooks=M.textures,M.hooks
    for i=1,5 do for _,d in ipairs(J.Integrations:Discover({})) do J:Attach(d);J:RefreshSafely(J.records[d.frame],true) end end
    equal(textures,M.textures);equal(hooks,M.hooks);resetProviders()
end)
test('Ellesmere unit source selection preserves Blizzard choices and uses its existing unit field',function()
    local native=externalUnit();local target=externalUnit();target.unit=nil;target._euiUnit='target'
    local backdrop=CreateFrame('Frame',nil,target);local shell=backdrop:CreateTexture();shell:SetTexture('ellesmere-teardrop-border')
    target.Portrait={backdrop=backdrop};backdrop._shapeBorderTex=shell
    local ns={_eufEnabled=true,db={profile={}},frames={target=target},GetUnitFrameSource=function(group) return group=='player' and 'blizzard' or 'eui' end}
    M.loaded.EllesmereUIUnitFrames=true;EllesmereUI={_ModuleNS={EllesmereUIUnitFrames=ns}}
    local found=J.Integrations:Discover({{frame=native,group='player',kind='compact'}});local desc
    for _,d in ipairs(found) do if d.frame==target then desc=d end end
    assert(desc);equal(found[1].frame,native);equal(J.Colors.Unit(target,'_euiUnit'),'target')
    shell:SetVertexColor(1,1,1,0.5)
    J:Attach(desc);assert(J.records[target].applied);equal(shell:GetAlpha(),0);equal(target.unit,nil)
    local shape=J.records[target].externalBorders[shell];equal(shape.mask:GetTexture(),'ellesmere-teardrop-border')
    equal(shape.nativeAlpha(),0.5)
    local fresh=CreateFrame('Frame',nil,target);target.Portrait={backdrop=fresh}
    for _,d in ipairs(J.Integrations:Discover({})) do J:Attach(d) end
    J:RefreshSafely(J.records[target],true);assert(not shape.active);equal(shell:GetAlpha(),1)
    resetProviders()
end)
test('Ellesmere party and raid discovery reads its external frame-data registry',function()
    local raid=CreateFrame('Button',nil,UIParent);local party=CreateFrame('Button',nil,UIParent)
    local data={[raid]={health=M.bar(raid),power=M.bar(raid)},[party]={health=M.bar(party),power=M.bar(party),_isParty=true}}
    raid.GetAttribute=function(_,key) assert(key=='unit');return 'raid1' end
    local ns={db={profile={}},_allButtons={raid},_partyAllButtons={party},GetFFD=function(f) return data[f] end}
    M.loaded.EllesmereUIRaidFrames=true;EllesmereUI={_ModuleNS={EllesmereUIRaidFrames=ns}}
    local found=J.Integrations:Discover({});equal(#found,2)
    for _,d in ipairs(found) do J:Attach(d);assert(J.records[d.frame].applied) end
    equal(J.records[raid].group,'raid');equal(J.records[party].group,'party')
    equal(J.Colors.Unit(raid,'attribute'),'raid1');equal(raid.unit,nil);equal(raid.Health,nil)
    resetProviders()
end)
test('Ellesmere action borders preserve native button state textures',function()
    local b=CreateFrame('Button',nil,UIParent);b:SetNormalTexture('eui-normal');b:SetHighlightTexture('eui-hover')
    M.loaded.EllesmereUIActionBars=true;EllesmereUI={_ModuleNS={EllesmereUIActionBars={EAB={db={profile={}}},barButtons={MainBar={b}}}}}
    local found=J.Integrations:Discover({});equal(#found,1);J:Attach(found[1]);assert(J.records[b].applied)
    equal(b:GetNormalTexture():GetTexture(),'eui-normal');equal(b:GetHighlightTexture():GetTexture(),'eui-hover')
    resetProviders()
end)
test('competing providers fail closed per group while mixed module providers work',function()
    local player=externalUnit();local target=externalUnit();local button=CreateFrame('Button',nil,UIParent)
    M.loaded.ElvUI=true;ElvUI={{private={unitframe={enable=true}},GetModule=function() return {units={player=player}} end}}
    M.loaded.EllesmereUIUnitFrames=true;M.loaded.EllesmereUIActionBars=true
    EllesmereUI={_ModuleNS={EllesmereUIUnitFrames={_eufEnabled=true,db={},frames={target=target}},
        EllesmereUIActionBars={EAB={db={}},barButtons={MainBar={button}}}}}
    local found=J.Integrations:Discover({});assert(J.AdapterCommon.Conflict('player'))
    equal(#found,1);equal(found[1].frame,button)
    M.loaded.EllesmereUIUnitFrames=nil;found=J.Integrations:Discover({});assert(not J.AdapterCommon.Conflict('player'))
    equal(J.Integrations.providers.player,'elvui');equal(J.Integrations.providers.actionbars,'ellesmere');equal(#found,2)
    resetProviders()
end)
test('external frames first discovered in combat remain native until combat ends',function()
    local f=externalUnit();local d={frame=f,group='player',kind='external',provider='elvui',regions={health=f.Health,power=f.Power}}
    M.combat=true;local textures=M.textures;J:Attach(d);assert(not J.records[f]);equal(M.textures,textures)
    M.combat=false;J:Attach(d);assert(J.records[f].applied)
end)
test('shared special buttons retain provider state textures and shapes',function()
    local b=CreateFrame('Button',nil,UIParent);b:SetNormalTexture('native-extra')
    local native={{frame=b,group='extrabar',kind='button'}}
    M.loaded.ElvUI=true;ElvUI={{private={actionbar={enable=true}}}}
    local found=J.Integrations:Discover(native);equal(#found,1);equal(found[1].kind,'externalbutton')
    equal(found[1].provider,'elvui');resetProviders()
    local shell=b:CreateTexture();shell:SetTexture('ellesmere-shaped-button')
    local data={[b]={shapeApplied=true,shapeBorder=shell}}
    M.loaded.EllesmereUIActionBars=true
    EllesmereUI={_ModuleNS={EllesmereUIActionBars={EAB={db={}},_eabFD=data,barButtons={}}}}
    found=J.Integrations:Discover(native);equal(#found,1);J:Attach(found[1])
    local record=J.records[b];local shaped=record.externalBorders[shell]
    assert(record.applied and shaped.active);equal(shell:GetAlpha(),0);equal(b:GetNormalTexture():GetTexture(),'native-extra')
    data[b].shapeApplied=false;found=J.Integrations:Discover(native);J:Attach(found[1]);J:RefreshSafely(record,true)
    assert(not shaped.active);equal(shell:GetAlpha(),1);assert(record.externalBorders[b].active)
    local textures,hooks=M.textures,M.hooks
    data[b].shapeApplied=true;found=J.Integrations:Discover(native);J:Attach(found[1]);J:RefreshSafely(record,true)
    equal(M.textures,textures);equal(M.hooks,hooks);resetProviders()
end)
test('external replacement bars restore old fills and hook each new bar once',function()
    local f=externalUnit();local d={frame=f,group='player',kind='external',provider='elvui',regions={health=f.Health,power=f.Power}}
    local old=J.active.player;J.active.player=J.Util.Copy(old);J.active.player.healthMode='custom'
    J:Attach(d);local previous=f.Health;equal(previous:GetStatusBarTexture():GetTexture(),J.Neutral)
    f.Health=M.bar(f);d.regions={health=f.Health,power=f.Power};J:Attach(d);J:RefreshSafely(J.records[f],true)
    equal(previous:GetStatusBarTexture():GetTexture(),'native');equal(f.Health:GetStatusBarTexture():GetTexture(),J.Neutral)
    previous:SetStatusBarColor(0.2,0.3,0.4,1);equal(previous.color[1],0.2)
    local hooks=M.hooks;J:Attach(d);equal(M.hooks,hooks);J.active.player=old
end)
test('missing external artwork does not report successful application',function()
    local f=externalUnit();M.missing='top.tga'
    J:Attach({frame=f,group='player',kind='external',provider='elvui',regions={health=f.Health}})
    assert(not J.records[f].applied);equal(f.Health:GetStatusBarTexture():GetTexture(),'native');M.missing=nil
end)
test('external hooks coalesce updates and are installed once',function()
    local uf={units={player=externalUnit()},Update_AllFrames=function() end}
    M.loaded.ElvUI=true;ElvUI={{private={unitframe={enable=true}},GetModule=function() return uf end}}
    J.Integrations:Discover({});J.Integrations:InstallHooks();local hooks=M.hooks
    J.Integrations:InstallHooks();equal(M.hooks,hooks)
    uf:Update_AllFrames();assert(J.scheduled);M.flush();assert(not J.scheduled);resetProviders()
end)
test('startup waits for login before attaching provider or native frames',function()
    IsLoggedIn=function() return false end
    local textures,hooks=M.textures,M.hooks;J:RefreshAll();equal(M.textures,textures);equal(M.hooks,hooks)
    IsLoggedIn=nil
end)
test('missing provider registries suppress native replacements with a diagnostic',function()
    local f=externalUnit();M.loaded.EllesmereUIUnitFrames=true;EllesmereUI={}
    local found=J.Integrations:Discover({{frame=f,group='player',kind='unit'}})
    equal(#found,0);assert(J.AdapterCommon.Conflict('player'));resetProviders()
end)
test('both adapters are independent and unknown clients fail closed',function()
    assert(J.Adapters.retail.units~=J.Adapters.forever.units);equal(J.Adapters.forever.interface,16001)
    J.ready=false;M.interface=16001;J:Initialize();equal(J.adapter.id,'forever');M.flush()
    J.ready=false;J.adapter=nil;M.interface=99999;J:Initialize();assert(not J.ready);M.interface=120100
end)
print(string.format('\n%d test groups passed (mock runtime; no in-game compatibility claim).',count))
