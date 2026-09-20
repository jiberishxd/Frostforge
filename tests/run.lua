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
    frame.ManaBar=M.bar(frame);frame.HealthBar.HealthBarMask=frame.HealthBar:CreateTexture();frame.ManaBar.ManaBarMask=frame.ManaBar:CreateTexture()
    TargetFrameToT=frame
    M.missing='human';J.active.targettarget=P:Resolve('targettarget');J.active.targettarget.skin='human'
    J:Attach({frame=frame,group='targettarget',kind='unit',definition=J.AdapterCommon.Units.small});equal(frame.FrameTexture:GetAlpha(),1);assert(not J.records[frame].applied);M.missing=nil
    J:RefreshAll();equal(frame.FrameTexture:GetAlpha(),0)
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
test('both adapters are independent and unknown clients fail closed',function()
    assert(J.Adapters.retail.units~=J.Adapters.forever.units);equal(J.Adapters.forever.interface,16001)
    J.ready=false;M.interface=16001;J:Initialize();equal(J.adapter.id,'forever');M.flush()
    J.ready=false;J.adapter=nil;M.interface=99999;J:Initialize();assert(not J.ready);M.interface=120100
end)
print(string.format('\n%d test groups passed (mock runtime; no in-game compatibility claim).',count))
