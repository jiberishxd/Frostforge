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
    assert(P:Set('actionbars','actionMode','buttons'));J:ResolveRequested()
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
    assert(P:Set('actionbars','actionMode','buttons'));J:ResolveRequested()
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
test('gradient portrait and surround settings round trip with bounded validation',function()
    local p=P.Default()
    p.global={healthMode='class',healthGradient=true,powerMode='type',powerGradient=true,gradientDirection='VERTICAL',gradientStrength=0.65}
    p.groups.player={portraitSkin='blackstone',portraitStyle='halloween',portraitScale=1.2,portraitOpacity=0.8,portraitBorder=false,portraitTint={0.5,0.6,0.7}}
    p.groups.actionbars={actionMode='surround',hubStyle='christmas',hubScope='all',hubPadding=14,hubMicro=true,hubBags=false,hubBackdrop=0.2,hubOpacity=0.75,hubArtworkScale=1.2}
    local text=assert(P.Export(p));equal(P.Export(assert(P.Import(text))),text)
    for key,value in pairs({gradientStrength=1,gradientDirection='DIAGONAL',portraitStyle='unknown',portraitSkin='unknown',portraitScale=20,hubStyle='unknown',hubScope='unknown',actionMode='unknown',hubBackdrop=1,hubMicro='yes'}) do
        local invalid=P.Default();invalid.global[key]=value;assert(not P.Validate(invalid),key)
    end
end)
test('all class gradients use native class identities and retain state priority',function()
    local owner=CreateFrame('Frame',nil,UIParent);owner.unit='player';local bar=M.bar(owner)
    local config=P:Resolve('player');config.healthMode='class';config.healthGradient=true;config.gradientStrength=0.6
    local record=J.Colors.Attach(owner,bar,'health',nil,function() return config end)
    local original=RAID_CLASS_COLORS;RAID_CLASS_COLORS={};local count=0
    for class in pairs(J.Fantasy.classes) do
        count=count+1;RAID_CLASS_COLORS[class]={r=0.2+count/50,g=0.5,b=0.8};M.class=class
        J.Colors.Apply(record)
        local gradient=bar.fill.gradient;assert(gradient);equal(gradient.direction,'HORIZONTAL')
        assert(math.abs(gradient.low.r-RAID_CLASS_COLORS[class].r*0.4)<0.000001)
        assert(gradient.high.r>gradient.low.r);equal(bar:GetStatusBarTexture():GetTexture(),J.Neutral)
    end
    equal(count,13);config.gradientDirection='VERTICAL';J.Colors.Apply(record);equal(bar.fill.gradient.direction,'VERTICAL')
    local writes=M.layoutWrites;M.combat=true;J.Colors.Apply(record);equal(M.layoutWrites,writes);M.combat=false
    for _,state in ipairs({'dead','tapped','restricted'}) do
        M[state]=true;J.Colors.Apply(record);equal(bar.fill:GetTexture(),'native');assert(not bar.fill.gradient)
        M[state]=nil;J.Colors.Apply(record);assert(bar.fill.gradient)
    end
    M.connected=false;J.Colors.Apply(record);assert(not bar.fill.gradient);M.connected=true
    owner.displayThreatHealthBarColor=true;J.Colors.Apply(record);equal(bar.fill:GetTexture(),'native');owner.displayThreatHealthBarColor=false
    M.class=M.secret;J.Colors.Apply(record);assert(not bar.fill.gradient);M.class=nil
    config.healthMode='native';J.Colors.Apply(record);RAID_CLASS_COLORS=original
end)
test('power gradients respect palette changes and native artwork refreshes',function()
    local owner=CreateFrame('Frame',nil,UIParent);owner.unit='player';local bar=M.bar(owner)
    local config=P:Resolve('player');config.powerMode='type';config.powerGradient=true;config.powerColors.MANA={0.1,0.4,0.9}
    local record=J.Colors.Attach(owner,bar,'power',nil,function() return config end)
    J.Colors.Apply(record);assert(bar.fill.gradient);equal(bar.fill.gradient.low.b,0.45)
    bar:SetStatusBarTexture('native-resource-change');assert(bar.fill.gradient);equal(bar.fill:GetTexture(),J.Neutral)
    bar:SetStatusBarColor(0.2,0.3,0.4,1);assert(bar.fill.gradient)
    config.powerMode='class';J.Colors.Apply(record);equal(bar.fill.gradient.low.r,RAID_CLASS_COLORS.MAGE.r*0.5)
    config.powerMode='type'
    config.powerGradient=false;J.Colors.Apply(record);assert(not bar.fill.gradient);equal(bar.color[2],0.4)
    config.powerMode='native';J.Colors.Apply(record);equal(bar.fill:GetTexture(),'native-resource-change');equal(bar.color[2],0.3)
end)
test('portrait art and trim are independent of unit bars and retain native geometry',function()
    local f,health,power,portrait,shell=M.portraitUnit('player')
    local cfg=P:Resolve('player');cfg.skin='human';cfg.portraitSkin='blackstone';cfg.portraitStyle='mage'
    local contour=J.Renderer.CreateContour(shell,{health=health,power=power,portrait=portrait})
    assert(J.Renderer.Apply(contour,cfg));assert(contour.arcs[1]:GetTexture():find('black_basalt',1,true))
    assert(contour.bars[1].pieces.top:GetTexture():find('human',1,true));equal(shell:GetAlpha(),1)
    local crest=J.Fantasy.CreatePortrait(f,portrait);assert(J.Fantasy.Portrait(crest,cfg,true));assert(crest.texture:IsShown())
    equal(crest.texture.points[1][1],'BOTTOM');equal(crest.texture.points[1][3],'TOP')
    local textures,writes=M.textures,M.layoutWrites;M.combat=true
    cfg.portraitStyle='halloween';J.Fantasy.Portrait(crest,cfg,false);equal(M.textures,textures);equal(M.layoutWrites,writes);M.combat=false
    cfg.portraitBorder=false;J.Renderer.Apply(contour,cfg);assert(not contour.arcs[1]:IsShown());assert(contour.bars[1].pieces.top:IsShown())
    portrait:Hide();J.Fantasy.Portrait(crest,cfg,true);assert(not crest.texture:IsShown());portrait:Show()
    M.missing='fantasy';assert(not J.Fantasy.Portrait(crest,cfg,true));assert(not crest.texture:IsShown());equal(shell:GetAlpha(),1);M.missing=nil
    cfg.portraitStyle='class';M.player=false;J.Fantasy.Portrait(crest,cfg,true);assert(not crest.texture:IsShown());M.player=true
    equal(#J.Fantasy.order,15)
end)
test('portrait and fantasy browsers preserve scope and reuse cards',function()
    local s=J.SettingsUI;s.scope='target';s:BrowseSkins('portraitSkin');local card=s.browser.cards[1]
    local old=P:Resolve('target').skin;card.scripts.OnClick();equal(P:Resolve('target').skin,old);equal(P:Resolve('target').portraitSkin,card.skin)
    s.scope='player';s:BrowseFantasy('portraitStyle');local browser=s.fantasyBrowser
    s.scope='target';browser.cards[1].scripts.OnClick();equal(P:Resolve('player').portraitStyle,browser.cards[1].style)
    local textures=M.textures;s:BrowseFantasy('portraitStyle');browser.page=3;s:RefreshFantasy();equal(M.textures,textures)
    browser.cards[3].scripts.OnClick();equal(P:Resolve('target').portraitStyle,'christmas')
    s:ShowPage('actions');equal(s.scope,'actionbars');assert(s.pages.actions:IsShown());assert(not s.pages.portrait:IsShown())
    s:ShowPage('colors');s.scope='global';s:Refresh()
end)
test('surround bounds combine scaled bars micro menu and bags without moving them',function()
    UIParent:SetSize(1920,1080)
    local a=CreateFrame('Button',nil,UIParent);a.rect={850,50,40,40}
    local b=CreateFrame('Button',nil,UIParent);b.rect={1800,100,80,80};b.scale=0.5
    local side=CreateFrame('Button',nil,UIParent);side.rect={1850,600,40,300}
    local micro=CreateFrame('Frame',nil,UIParent);micro.rect={1450,20,300,30}
    local bags=CreateFrame('Frame',nil,UIParent);bags.rect={1730,50,170,35}
    local bounds,count=J.ActionHub.Bounds({a,b,side},'cluster',{micro,bags});equal(count,4);equal(bounds[1],850);equal(bounds[3],1900);equal(bounds[4],90)
    local all=J.ActionHub.Bounds({a,b,side},'all',{});equal(all[4],900)
    side.rect={M.secret,0,40,40};local safe=J.ActionHub.Bounds({a,side},'all',{});equal(safe[1],850)
    a:Hide();b:Hide();assert(not J.ActionHub.Bounds({a,b},'all',{}));a:Show();b:Show()
    local previousConfig=J.active.actionbars;J.active.actionbars=P:Resolve('actionbars');J.active.actionbars.actionMode='surround'
    MicroMenu,BagsBar=micro,bags
    local originalA,originalB=a.rect,b.rect
    J.ActionHub:Update({{frame=a,group='actionbars',kind='button'},{frame=b,group='actionbars',kind='externalbutton'}},true)
    assert(J.ActionHub.applied);equal(a.rect,originalA);equal(b.rect,originalB);equal(J.ActionHub.frame:GetWidth(),bounds[3]-bounds[1]+20)
    local writes,textures=M.layoutWrites,M.textures;M.combat=true;J.ActionHub:Update({{frame=a,group='actionbars',kind='button'}},false)
    equal(M.layoutWrites,writes);equal(M.textures,textures);M.combat=false
    local changed=J.Util.Copy(J.active.actionbars);changed.hubStyle='christmas';J.ActionHub.config=changed
    M.missing='fantasy';J.ActionHub:Layout(true);assert(not J.ActionHub.applied);assert(not J.ActionHub.frame:IsShown());M.missing=nil
    J.ActionHub:Layout(true);assert(J.ActionHub.applied)
    J.conflicts.actionbars='provider conflict';J.ActionHub:Layout(true);assert(not J.ActionHub.applied);J.conflicts.actionbars=nil
    MicroMenu,BagsBar=nil,nil;J.active.actionbars=previousConfig
end)
test('switching to a surround restores current native button artwork and retains clicks',function()
    local cfg=J.active.actionbars;J.active.actionbars=J.Util.Copy(cfg);J.active.actionbars.actionMode='buttons'
    local b=CreateFrame('Button',nil,UIParent);local click=function() end;b:SetScript('OnClick',click)
    for _,state in ipairs({'Normal','Pushed','Highlight','Checked'}) do b['Set'..state..'Texture'](b,'original-'..state) end
    J:Attach({frame=b,group='actionbars',kind='button'});local record=J.records[b]
    assert(record.buttonCustom);b:SetNormalAtlas('latest-native-normal')
    b:GetNormalTexture():SetVertexColor(0.4,0.6,0.8,1)
    J.active.actionbars.actionMode='surround';J:RefreshSafely(record,true)
    equal(b:GetNormalTexture():GetAtlas(),'latest-native-normal');equal(b:GetPushedTexture():GetTexture(),'original-Pushed');equal(b.scripts.OnClick,click)
    equal(b:GetNormalTexture().vertex[2],0.6)
    local hooks,textures=M.hooks,M.textures
    J.active.actionbars.actionMode='both';J:RefreshSafely(record,true);assert(b:GetNormalTexture():GetTexture():find('button%-normal'))
    J.active.actionbars.actionMode='native';J:RefreshSafely(record,true);equal(b:GetNormalTexture():GetAtlas(),'latest-native-normal')
    equal(M.hooks,hooks);equal(M.textures,textures);J.active.actionbars=cfg
end)
test('surround mode preserves provider borders through native refresh and alpha changes',function()
    local cfg=J.active.actionbars;J.active.actionbars=J.Util.Copy(cfg);J.active.actionbars.actionMode='buttons'
    local b=CreateFrame('Button',nil,UIParent);b:SetNormalTexture('provider-normal')
    local shell=b:CreateTexture();shell:SetTexture('provider-shape');shell:SetAlpha(0.8)
    J:Attach({frame=b,group='actionbars',kind='externalbutton',provider='ellesmere',regions={shell=shell}})
    local record=J.records[b];equal(shell:GetAlpha(),0)
    J.active.actionbars.actionMode='surround';J:RefreshSafely(record,true);equal(shell:GetAlpha(),0.8)
    shell:SetAlpha(0.5);equal(shell:GetAlpha(),0.5);equal(b:GetNormalTexture():GetTexture(),'provider-normal')
    J.active.actionbars.actionMode='both';J:RefreshSafely(record,true);equal(shell:GetAlpha(),0)
    J.active.actionbars.actionMode='native';J:RefreshSafely(record,true);equal(shell:GetAlpha(),0.5)
    J.active.actionbars=cfg
end)
test('new appearance changes queue during combat and apply the latest choices',function()
    local old=J.active.player;M.combat=true
    assert(P:Set('player','portraitStyle','halloween'));assert(P:Set('player','portraitStyle','christmas'))
    assert(P:Set('player','healthGradient',true));assert(P:Set('player','healthMode','class'))
    equal(J.active.player,old);M.combat=false;J:RefreshAll()
    equal(J.active.player.portraitStyle,'christmas');assert(J.active.player.healthGradient)
end)
test('crest offsets and expanded size preserve anchors and defer geometry in combat',function()
    local owner,_,_,portrait=M.portraitUnit('player');owner.scale=0.5;portrait.scale=0.75
    local cfg=P:Resolve('player');cfg.portraitStyle='mage';cfg.portraitX=-42;cfg.portraitY=28;cfg.portraitScale=2.5
    local record=J.Fantasy.CreatePortrait(owner,portrait);assert(J.Fantasy.Portrait(record,cfg,true))
    local point=record.texture.points[1];equal(point[2],portrait);equal(point[4],-42);equal(point[5],29)
    equal(record.texture:GetWidth(),math.min(110,50*0.75/0.5*1.4)*2.5)
    local writes=M.layoutWrites;M.combat=true;cfg.portraitX=100;J.Fantasy.Portrait(record,cfg,false)
    equal(M.layoutWrites,writes);equal(record.texture.points[1][4],-42);M.combat=false
    assert(J.Fantasy.Portrait(record,cfg,true));equal(record.texture.points[1][4],100)
end)
test('hub and crest customization round trips and rejects unsafe bounds',function()
    local p=P.Default();p.groups.player={portraitX=-250,portraitY=250,portraitScale=3}
    p.groups.actionbars={actionMode='hub',hubX=-300,hubY=50,hubWidth=1250,hubHeight=320,hubDock=true,
        hubActionsX=25,hubActionsY=120,hubActionsScale=0.8,hubRowGap=16,hubBar2X=-150,hubBar2Y=-30,hubBar2Scale=0.9,
        hubMicroX=-370,hubMicroY=30,hubMicroScale=0.7,hubBagsX=360,hubBagsY=30,hubBagsScale=1.1,
        hubArtworkX=65,hubArtworkY=-40,hubArtworkScale=2.5}
    local text=assert(P.Export(p));equal(P.Export(assert(P.Import(text))),text)
    for key,value in pairs({portraitX=251,portraitY=-251,portraitScale=3.1,hubWidth=0,hubHeight=601,hubDock='true',hubActionsScale=0,hubArtworkY=401,hubBagsScale=99,hubMicroX=901}) do
        local bad=P.Default();bad.global[key]=value;assert(not P.Validate(bad),key)
    end
end)
test('Blizzard docking uses stable scaled anchors, preserves click behavior, and restores latest native layout',function()
    UIParent:SetSize(1920,1080)
    local old={MainActionBar,MultiBarBottomLeft,MultiBarBottomRight,MicroMenuContainer,MicroMenu,BagsBar}
    local function frame(x)
        local f=CreateFrame('Frame',nil,UIParent);f:SetSize(500,40);f:SetPoint('BOTTOM',UIParent,'BOTTOM',x,20);return f
    end
    MainActionBar=frame(25);MultiBarBottomLeft=frame(50);MultiBarBottomRight=frame(75)
    MicroMenuContainer=frame(100);BagsBar=frame(125)
    local click=function() end;MainActionBar:SetScript('OnClick',click);MainActionBar:SetScale(0.8)
    local cfg=P:Resolve('actionbars');cfg.actionMode='hub';cfg.hubDock=true;cfg.hubActionsX=80;cfg.hubActionsScale=0.5
    cfg.hubBar2X=-25;cfg.hubBar2Y=10;cfg.hubBar2Scale=0.8
    local l=J.HubLayout;l:Apply(cfg)
    equal(MainActionBar:GetScale(),0.4);equal(MainActionBar.points[1][4],200);equal(MainActionBar.points[1][5],cfg.hubActionsY/0.4)
    equal(MainActionBar:GetParent(),UIParent);equal(MainActionBar.scripts.OnClick,click)
    equal(MultiBarBottomLeft.points[1][4],55/0.4)
    local writes,hooks=M.layoutWrites,M.hooks;l:Apply(cfg);equal(M.layoutWrites,writes);equal(M.hooks,hooks)
    M.combat=true;cfg.hubActionsX=-100;l:Apply(cfg);l:Release();equal(M.layoutWrites,writes);M.combat=false
    l:Apply(cfg);equal(MainActionBar.points[1][4],-250)
    -- A native layout refresh supersedes the initial restore snapshot.
    MainActionBar:ClearAllPoints();MainActionBar:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',42,37);MainActionBar:SetScale(0.9)
    l:Apply(cfg);equal(MainActionBar:GetScale(),0.45)
    cfg.hubDock=false;l:Apply(cfg);equal(MainActionBar:GetScale(),0.9);equal(MainActionBar.points[1][1],'BOTTOMLEFT');equal(MainActionBar.points[1][4],42)
    cfg.hubDock=true;l:Apply(cfg);cfg.hubMicro=false;l:Apply(cfg);equal(MicroMenuContainer.points[1][4],100)
    EditModeManagerFrame=CreateFrame('Frame',nil,UIParent);l:Apply(cfg);equal(MainActionBar.points[1][4],42)
    MainActionBar:ClearAllPoints();MainActionBar:SetPoint('BOTTOM',UIParent,'BOTTOM',70,30)
    EditModeManagerFrame:Hide();l:Apply(cfg);cfg.actionMode='native';l:Apply(cfg);equal(MainActionBar.points[1][4],70)
    EditModeManagerFrame=nil
    MainActionBar,MultiBarBottomLeft,MultiBarBottomRight,MicroMenuContainer,MicroMenu,BagsBar=unpack(old,1,6)
end)
test('hub never docks provider controls or conflicting frames',function()
    local old=MainActionBar;MainActionBar=CreateFrame('Frame',nil,UIParent);MainActionBar:SetPoint('BOTTOM',UIParent,'BOTTOM',27,10)
    local cfg=P:Resolve('actionbars');cfg.actionMode='hub';cfg.hubDock=true
    local before=M.layoutWrites;J.Integrations.providers.actionbars='elvui';J.HubLayout:Apply(cfg);equal(M.layoutWrites,before)
    J.Integrations.providers.actionbars='ellesmere';J.HubLayout:Apply(cfg);equal(M.layoutWrites,before)
    J.Integrations.providers.actionbars=nil;J.conflicts.actionbars='conflict';J.HubLayout:Apply(cfg);equal(M.layoutWrites,before)
    J.conflicts.actionbars=nil;MainActionBar=old
end)
test('console geometry clamps to screen, uses a reusable chassis, and restores on missing artwork',function()
    local cfg=P:Resolve('actionbars');cfg.actionMode='hub';cfg.hubDock=false;cfg.hubStyle='mage';cfg.hubX=1200;cfg.hubY=700;cfg.hubWidth=1100;cfg.hubHeight=500
    UIParent:SetSize(1000,600)
    local x,y,w,h=J.HubLayout.Geometry(cfg);equal(x,0);equal(y,100);equal(w,1000);equal(h,500)
    local b=CreateFrame('Button',nil,UIParent);b.rect={420,160,40,40}
    local old=J.active.actionbars;J.active.actionbars=cfg
    J.ActionHub:Update({{frame=b,group='actionbars',kind='button'}},true);assert(J.ActionHub.applied)
    equal(#J.ActionHub.console,9);equal(J.ActionHub.frame:GetWidth(),1000)
    equal(J.ActionHub.console[5].vertex[4],cfg.hubBackdrop*cfg.hubOpacity);assert(not J.ActionHub.background:IsShown())
    cfg.hubArtworkX=-70;cfg.hubArtworkY=-40;J.ActionHub.lastConfig=nil;J.ActionHub:Layout(true)
    equal(J.ActionHub.crest.points[1][4],-70);equal(J.ActionHub.crest.points[1][5],-38)
    local textures,writes=M.textures,M.layoutWrites;J.ActionHub:Layout(true);equal(M.textures,textures);equal(M.layoutWrites,writes)
    M.combat=true;J.ActionHub:Layout(false);equal(M.layoutWrites,writes);M.combat=false
    J.ActionHub.lastConfig=nil;M.missing='hub';J.ActionHub:Layout(true);assert(not J.ActionHub.applied);M.missing=nil
    J.ActionHub:Layout(true);assert(J.ActionHub.applied)
    EditModeManagerFrame=CreateFrame('Frame',nil,UIParent);J.ActionHub:Layout(true);assert(not J.ActionHub.applied);EditModeManagerFrame=nil
    cfg.actionMode='native';J.ActionHub:Layout(true);assert(not J.ActionHub.frame:IsShown())
    J.active.actionbars=old;UIParent:SetSize(1920,1080)
end)
test('both adapters are independent and unknown clients fail closed',function()
    assert(J.Adapters.retail.units~=J.Adapters.forever.units);equal(J.Adapters.forever.interface,16001)
    J.ready=false;M.interface=16001;J:Initialize();equal(J.adapter.id,'forever');M.flush()
    J.ready=false;J.adapter=nil;M.interface=99999;J:Initialize();assert(not J.ready);M.interface=120100
end)
print(string.format('\n%d test groups passed (mock runtime; no in-game compatibility claim).',count))
