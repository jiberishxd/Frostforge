local _,J=...
local U=J.Util
local I={providers={},conflicts={},hookTargets={}};J.Integrations=I
local singles={'player','target','focus','pet','targettarget','focustarget','boss'}
local function loaded(name)
    local fn=C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    return fn and fn(name)
end
local function module(engine,name)
    if engine and type(engine.GetModule)=='function' then
        local ok,value=pcall(engine.GetModule,engine,name,true)
        if ok then return value end
    end
end
local function walk(root,callback,depth)
    if not root or not root.GetChildren or depth<=0 then return end
    if root.IsForbidden and root:IsForbidden() then return end
    for _,child in ipairs({root:GetChildren()}) do
        if U.Safe(child) and not (child.IsForbidden and child:IsForbidden()) then
            callback(child);walk(child,callback,depth-1)
        end
    end
end
function I:Discover(native)
    local out,claims,conflicts,targets={},{},{},{}
    local function claim(group,provider)
        if claims[group] and claims[group]~=provider then
            conflicts[group]='ElvUI and Ellesmere both own this group. Enable one frame provider for this group, then reload.'
        else claims[group]=provider end
    end
    local function watch(object,names)
        if object then for _,name in ipairs(names) do
            if type(object[name])=='function' then targets[#targets+1]={object,name} end
        end end
    end
    local function unit(frame,group,provider,regions,compact)
        if not frame or not frame.CreateTexture then return end
        regions=regions or {health=frame.Health,power=frame.Power}
        if not regions.health or not regions.health.GetStatusBarTexture then return end
        regions.decorations=regions.decorations or {};regions.portraits=regions.portraits or {}
        if not compact then
            if provider=='elvui' then
                if not frame.USE_PORTRAIT_OVERLAY then
                    for _,key in ipairs({'Portrait2D','Portrait3D'}) do
                        local p=frame[key];if p and p.backdrop then regions.portraits[#regions.portraits+1]={region=p.backdrop} end
                    end
                end
            else
                local p=frame.Portrait;local backdrop=p and p.backdrop
                if backdrop and not backdrop._isInside then
                    local shell=backdrop._shapeBorderTex
                    regions.portraits[#regions.portraits+1]={region=backdrop,shell=shell}
                end
            end
        end
        out[#out+1]={frame=frame,group=group,kind='external',provider=provider,regions=regions}
        watch(frame,{'Update'})
    end
    local function buttons(list,group,provider)
        for _,b in pairs(list or {}) do
            if U.Safe(b) and b.CreateTexture and b.GetNormalTexture then
                local registry=EllesmereUI and EllesmereUI._ModuleNS
                local ns=provider=='ellesmere' and registry and registry.EllesmereUIActionBars
                local data=ns and ns._eabFD and ns._eabFD[b]
                local shaped=data and (data.shapeApplied or (data.shapeMask and data.shapeMask:IsShown()))
                local shell=shaped and data.shapeBorder
                out[#out+1]={frame=b,group=group,kind='externalbutton',provider=provider,regions={shell=shell}}
            end
        end
    end
    local function sharedButtons(groups,provider)
        for _,group in ipairs(groups) do claim(group,provider) end
        for _,desc in ipairs(native) do
            for _,group in ipairs(groups) do
                if desc.group==group and desc.kind=='button' then buttons({desc.frame},group,provider) end
            end
        end
    end
    local engine=loaded('ElvUI') and ElvUI and ElvUI[1]
    if engine then
        local private=engine.private or {}
        local uf=module(engine,'UnitFrames')
        if private.unitframe and private.unitframe.enable then
            for _,group in ipairs(singles) do
                claim(group,'elvui')
                if group=='boss' then
                    for i=1,MAX_BOSS_FRAMES or 5 do unit(_G['ElvUF_Boss'..i],group,'elvui') end
                else unit(uf and (uf.units and uf.units[group] or uf[group]),group,'elvui') end
            end
            for _,group in ipairs({'party','partypet','raid'}) do claim(group,'elvui') end
            for key,header in pairs(uf and uf.headers or {}) do
                local group=key=='party' and 'party' or key=='raidpets' and 'partypet' or (key:match('^raid%d$') and 'raid')
                if group then walk(header,function(frame)
                    if frame.Health and frame.GetObjectType and frame:GetObjectType()=='Button' then unit(frame,group,'elvui',nil,true) end
                end,3) end
            end
            watch(uf,{'Update_AllFrames','CreateAndUpdateUF','CreateAndUpdateHeaderGroup','UpdateGroupHeader','Configure_Portrait'})
        end
        if private.actionbar and private.actionbar.enable then
            local ab=module(engine,'ActionBars')
            for _,group in ipairs({'actionbars','petbar','stancebar'}) do claim(group,'elvui') end
            for _,bar in pairs(ab and ab.handledBars or {}) do buttons(bar.buttons,'actionbars','elvui') end
            buttons(ElvUI_BarPet and ElvUI_BarPet.buttons,'petbar','elvui')
            local stance={};for i=1,10 do stance[i]=_G['ElvUI_StanceBarButton'..i] end
            buttons(stance,'stancebar','elvui')
            sharedButtons({'extrabar','flyout','vehiclebar'},'elvui')
            local lab=engine.Libs and engine.Libs.LAB
            buttons(lab and lab.FlyoutButtons,'flyout','elvui')
            watch(ab,{'UpdateButtonSettings','PositionAndSizeBar','StyleButton','CreateBar','LAB_FlyoutSpells','LAB_FlyoutCreated','SetupFlyoutButton'})
        end
    end
    local registry=EllesmereUI and EllesmereUI._ModuleNS or {}
    local uf=loaded('EllesmereUIUnitFrames') and registry.EllesmereUIUnitFrames
    if uf and uf._eufEnabled and uf.db then
        for _,group in ipairs(singles) do
            local source=uf.GetUnitFrameSource and uf.GetUnitFrameSource(group) or 'eui'
            if source~='blizzard' then
                claim(group,'ellesmere')
                if source~='hidden' then
                    if group=='boss' then
                        for i=1,MAX_BOSS_FRAMES or 5 do unit(_G['EllesmereUIUnitFrames_Boss'..i],group,'ellesmere',{health=(_G['EllesmereUIUnitFrames_Boss'..i] or {}).Health,power=(_G['EllesmereUIUnitFrames_Boss'..i] or {}).Power,unitField='_euiUnit'}) end
                    else
                        local f=uf.frames and uf.frames[group]
                        if f then unit(f,group,'ellesmere',{health=f.Health,power=f.Power,unitField='_euiUnit'}) end
                    end
                end
            end
        end
        watch(uf,{'ReloadFrames','ApplyFramePosition','UpdateFrameVisibility','UF_SetBossFramesActive'})
    end
    local rf=loaded('EllesmereUIRaidFrames') and registry.EllesmereUIRaidFrames
    if rf and rf.db and rf.GetFFD then
        claim('raid','ellesmere');claim('party','ellesmere');claim('partypet','ellesmere')
        for _,entry in ipairs({{rf._allButtons,'raid'},{rf._partyAllButtons,'party'}}) do
            for _,frame in ipairs(entry[1] or {}) do
                local data=rf.GetFFD(frame)
                if data and not data._isExtra then unit(frame,entry[2],'ellesmere',
                    {health=data.health,power=data.power,unitField='attribute'},true) end
            end
        end
        watch(rf,{'ReloadFrames','ReloadPartyFrames','ApplyFrameStrata'})
    end
    local ab=loaded('EllesmereUIActionBars') and registry.EllesmereUIActionBars
    if ab and ab.EAB and ab.EAB.db then
        for _,group in ipairs({'actionbars','petbar','stancebar'}) do claim(group,'ellesmere') end
        for key,list in pairs(ab.barButtons or {}) do
            local group=key=='PetBar' and 'petbar' or key=='StanceBar' and 'stancebar' or 'actionbars'
            buttons(list,group,'ellesmere')
        end
        sharedButtons({'extrabar','flyout','vehiclebar'},'ellesmere')
        watch(ab,{'BuildBarButtons'})
        watch(ab.EAB,{'ApplyBorders','ApplyShapes','ApplyBordersForBar','ApplyShapesForBar','ApplyButtonSizeForBar','ApplyPaddingForBar'})
    end
    -- Never decorate a hidden Blizzard replacement when its provider is still initializing.
    if loaded('ElvUI') and not engine then
        for _,group in ipairs(J.Groups) do claim(group,'elvui');conflicts[group]='ElvUI engine is not available yet.' end
    end
    for _,entry in ipairs({{'EllesmereUIUnitFrames',singles},{'EllesmereUIRaidFrames',{'party','partypet','raid'}},
        {'EllesmereUIActionBars',{'actionbars','petbar','stancebar'}}}) do
        if loaded(entry[1]) and not registry[entry[1]] then
            for _,group in ipairs(entry[2]) do claim(group,'ellesmere');conflicts[group]='Ellesmere frame registry is unavailable; this installed version is not supported.' end
        end
    end
    local filtered,seen={},{}
    for _,desc in ipairs(native) do
        desc.provider='blizzard'
        if not claims[desc.group] and not seen[desc.frame] then filtered[#filtered+1]=desc;seen[desc.frame]=true end
    end
    for _,desc in ipairs(out) do
        if not conflicts[desc.group] and not seen[desc.frame] then filtered[#filtered+1]=desc;seen[desc.frame]=true end
    end
    self.providers=claims;self.conflicts=conflicts;self.hookTargets=targets
    return filtered
end
function I:InstallHooks()
    for _,entry in ipairs(self.hookTargets) do
        local object,name=entry[1],entry[2]
        J.hooks[object]=J.hooks[object] or {}
        if not J.hooks[object][name] then
            J.hooks[object][name]=true
            hooksecurefunc(object,name,function() J:Schedule() end)
        end
    end
end
