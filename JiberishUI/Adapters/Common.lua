local _, J = ...
local U=J.Util
local A={}; J.AdapterCommon=A
J.Adapters={}
local unitGroups={player=true,target=true,focus=true,pet=true,boss=true,targettarget=true,focustarget=true,party=true,partypet=true,raid=true}
function A.Conflict(group)
    local loaded=C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    if not loaded then return end
    if J.Integrations and J.Integrations.conflicts[group] then return J.Integrations.conflicts[group] end
    if unitGroups[group] then
        if loaded('ShadowedUnitFrames') then return 'Shadowed Unit Frames is loaded.' end
        if loaded('PitBull4') then return 'PitBull is loaded.' end
    else
        for _,addon in ipairs({'Bartender4','Dominos','Masque_Blizzard'}) do
            if loaded(addon) then return addon..' owns overlapping action buttons.' end
        end
    end
end
local function add(out,frame,group,kind,definition)
    if frame and frame.CreateTexture then out[#out+1]={frame=frame,group=group,kind=kind,definition=definition} end
end
local function children(frame,fn,depth)
    if not frame or not frame.GetChildren or depth<=0 then return end
    for _,child in ipairs({frame:GetChildren()}) do
        fn(child); children(child,fn,depth-1)
    end
end
function A.Discover(adapter)
    local out={}
    for _,entry in ipairs({{'PlayerFrame','player','player'},{'TargetFrame','target','target'},{'FocusFrame','focus','target'},
        {'PetFrame','pet','pet'},{'TargetFrameToT','targettarget','small'},{'FocusFrameToT','focustarget','small'}}) do
        add(out,_G[entry[1]],entry[2],'unit',adapter.units[entry[3]])
    end
    local bosses=BossTargetFrameContainer and BossTargetFrameContainer.BossTargetFrames
    if bosses then for _,frame in ipairs(bosses) do add(out,frame,'boss','unit',adapter.units.target) end
    else for i=1,MAX_BOSS_FRAMES or 5 do add(out,_G['Boss'..i..'TargetFrame'],'boss','unit',adapter.units.target) end end
    if PartyFrame then
        for i=1,4 do
            local member=PartyFrame['MemberFrame'..i] or _G['PartyMemberFrame'..i]
            add(out,member,'party','unit',adapter.units.party)
            if member then add(out,member.PetFrame,'partypet','unit',adapter.units.partypet) end
        end
    end
    if CompactPartyFrame then
        for _,frame in ipairs(CompactPartyFrame.memberUnitFrames or {}) do add(out,frame,'party','compact',adapter.units.compact) end
        for _,frame in ipairs(CompactPartyFrame.petUnitFrames or {}) do add(out,frame,'partypet','compact',adapter.units.compact) end
    end
    -- Traverse only the Blizzard raid container; shared helpers also serve nameplates.
    children(CompactRaidFrameContainer,function(frame)
        if frame.healthBar and frame.powerBar and frame.GetObjectType and frame:GetObjectType()=='Button' then
            add(out,frame,'raid','compact',adapter.units.compact)
        end
    end,3)
    for _,entry in ipairs(adapter.bars) do
        local container=_G[entry[1]]
        if container then
            for _,button in ipairs(container.actionButtons or container.buttons or {}) do add(out,button,entry[2],'button') end
        end
    end
    -- Some special bars still instantiate globally named buttons rather than lists.
    for _,entry in ipairs(adapter.buttonPrefixes) do
        for i=1,entry[3] do add(out,_G[entry[1]..i],entry[2],'button') end
    end
    add(out,ExtraActionButton1,'extrabar','button')
    if ZoneAbilityFrame and ZoneAbilityFrame.SpellButtonContainer then
        children(ZoneAbilityFrame.SpellButtonContainer,function(frame)
            if frame.GetNormalTexture and (frame.Icon or frame.icon) then add(out,frame,'extrabar','button') end
        end,2)
    end
    if SpellFlyout then for _,button in ipairs(SpellFlyout.buttons or {}) do add(out,button,'flyout','button') end end
    if adapter.id=='forever' then
        for _,name in ipairs({'MultiCastSummonSpellButton','MultiCastRecallSpellButton'}) do add(out,_G[name],'totembar','button') end
        children(MultiCastFlyoutFrame,function(frame)
            if frame.GetNormalTexture and (frame.icon or frame.Icon) then add(out,frame,'totembar','button') end
        end,2)
    end
    if MainActionBar and MainActionBar.BorderArt then add(out,MainActionBar,'actionbars','rail') end
    return J.Integrations and J.Integrations:Discover(out) or out
end
function A.Resolve(frame,definition)
    local health=U.Path(frame,definition.health)
    if not health or not health.GetStatusBarTexture then return nil,'Health-bar layout does not match this adapter.' end
    local result={health=health,power=definition.power and U.Path(frame,definition.power),
        portrait=definition.portrait and U.Path(frame,definition.portrait),
        healthMask=definition.healthMask and U.Path(frame,definition.healthMask),
        powerMask=definition.powerMask and U.Path(frame,definition.powerMask),decorations={}}
    if definition.globals then
        result.power=_G[definition.globals.power]; result.portrait=_G[definition.globals.portrait]
        result.healthMask=_G[definition.globals.healthMask]; result.powerMask=_G[definition.globals.powerMask]
    end
    if (definition.power or (definition.globals and definition.globals.power)) and
        (not result.power or not result.power.GetStatusBarTexture) then return nil,'Power-bar layout does not match this adapter.' end
    if (definition.portrait or (definition.globals and definition.globals.portrait)) and
        (not result.portrait or not result.portrait.GetTexture) then return nil,'Portrait layout does not match this adapter.' end
    if (definition.healthMask or (definition.globals and definition.globals.healthMask)) and not result.healthMask then
        return nil,'Health mask is unavailable; leaving the frame native.'
    end
    if (definition.powerMask or (definition.globals and definition.globals.powerMask)) and not result.powerMask then
        return nil,'Power mask is unavailable; leaving the frame native.'
    end
    for _,path in ipairs(definition.decorations or {}) do
        local region=U.Path(frame,path)
        if region and region.GetObjectType and region:GetObjectType()=='Texture' then result.decorations[#result.decorations+1]=region end
    end
    for _,name in ipairs(definition.globalDecorations or {}) do
        if _G[name] then result.decorations[#result.decorations+1]=_G[name] end
    end
    return result
end
A.Units={
    player={health='PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar',power='PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar',
        portrait='PlayerFrameContainer.PlayerPortrait',healthMask='PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBarMask',powerMask='PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.ManaBarMask',
        decorations={'PlayerFrameContainer.FrameTexture','PlayerFrameContainer.VehicleFrameTexture','PlayerFrameContainer.AlternatePowerFrameTexture'},variant='bar'},
    target={health='TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar',power='TargetFrameContent.TargetFrameContentMain.ManaBar',
        portrait='TargetFrameContainer.Portrait',healthMask='TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBarMask',powerMask='TargetFrameContent.TargetFrameContentMain.ManaBar.ManaBarMask',
        decorations={'TargetFrameContainer.FrameTexture'},variant='bar'},
    pet={health='healthbar',globals={power='PetFrameManaBar',portrait='PetPortrait',healthMask='PetFrameHealthBarMask',powerMask='PetFrameManaBarMask'},globalDecorations={'PetFrameTexture'},variant='small'},
    small={health='HealthBar',power='ManaBar',portrait='Portrait',healthMask='HealthBar.HealthBarMask',powerMask='ManaBar.ManaBarMask',decorations={'FrameTexture'},variant='small'},
    party={health='HealthBarContainer.HealthBar',power='ManaBar',portrait='Portrait',healthMask='HealthBarContainer.HealthBarMask',powerMask='ManaBar.ManaBarMask',decorations={'Texture','VehicleTexture'},variant='small'},
    partypet={health='HealthBar',portrait='Portrait',decorations={'Texture'},variant='small'},
    compact={health='healthBar',power='powerBar',decorations={},variant='compact'},
}
A.Bars={{'MainActionBar','actionbars'},{'MultiBarBottomLeft','actionbars'},{'MultiBarBottomRight','actionbars'},
    {'MultiBarRight','actionbars'},{'MultiBarLeft','actionbars'},{'MultiBar5','actionbars'},{'MultiBar6','actionbars'},{'MultiBar7','actionbars'},
    {'PetActionBar','petbar'},{'StanceBar','stancebar'},{'PossessActionBar','vehiclebar'},{'OverrideActionBar','vehiclebar'}}
A.ButtonPrefixes={{'ActionButton','actionbars',12},{'PetActionButton','petbar',10},{'StanceButton','stancebar',10},
    {'PossessButton','vehiclebar',2},{'OverrideActionBarButton','vehiclebar',6}}
A.NativeFunctions={'PlayerFrame_UpdateArt','PlayerFrame_ToPlayerArt','PlayerFrame_ToVehicleArt','PetFrame_Update',
    'CompactUnitFrame_SetUpFrame','CompactUnitFrame_UpdateAll','UnitFrameHealthBar_Update','UnitFrameManaBar_UpdateType'}
