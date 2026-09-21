local addon, J = ...
J.name, J.version = addon, '0.1.0-alpha.3'
J.Util = {}
local U = J.Util
function U.Safe(value)
    return not (issecretvalue and issecretvalue(value))
end
function U.Number(value)
    return U.Safe(value) and type(value) == 'number' and value == value and value > -math.huge and value < math.huge
end
function U.Copy(value)
    if type(value) ~= 'table' then return value end
    local copy = {}
    for k,v in pairs(value) do copy[k] = U.Copy(v) end
    return copy
end
function U.Merge(target, source)
    for k,v in pairs(source or {}) do
        if type(v) == 'table' then
            if type(target[k]) ~= 'table' then target[k] = {} end
            U.Merge(target[k], v)
        else target[k] = v end
    end
    return target
end
function U.Clamp(n, low, high) return math.max(low, math.min(high, n)) end
function U.Path(object, path)
    for key in path:gmatch('[^.]+') do
        if not object then return nil end
        object = object[key]
    end
    return object
end
function U.Combat() return InCombatLockdown and InCombatLockdown() end
function U.HookScript(region,script,callback)
    -- Textures expose HookScript too, but do not support every Frame script.
    if not region or type(region.HookScript)~='function' or type(region.HasScript)~='function' then return false end
    local ok,supported=pcall(region.HasScript,region,script)
    if not ok or not U.Safe(supported) or not supported then return false end
    region:HookScript(script,callback)
    return true
end
function U.ErrorSummary(message,stack)
    -- Keep code locations and a fixed error category, never the raw payload or locals.
    if not U.Safe(message) or type(message)~='string' then return 'Runtime error (details unavailable).' end
    local file,line=message:gsub('\\','/'):match('JiberishUI/([%w_/-]+%.lua)["%]: ]*(%d+)')
    if not file and U.Safe(stack) and type(stack)=='string' then
        file,line=stack:gsub('\\','/'):match('JiberishUI/([%w_/-]+%.lua)["%]: ]*(%d+)')
    end
    local kind='Runtime error'
    for _,entry in ipairs({{'secret','Restricted value'},{'forbidden','Forbidden frame access'},
        {"Doesn't have a",'Unsupported widget script'},{'unsupported script','Unsupported widget script'},
        {'Usage:','Invalid API call'},{'bad argument','Invalid API argument'},
        {'attempt to call','Unavailable function'},{'attempt to index','Unavailable frame or field'},
        {'SetPoint','Invalid anchor'}}) do
        if message:find(entry[1],1,true) then kind=entry[2]; break end
    end
    return kind..(file and (' at '..file..':'..line) or '')..'.'
end
function J:Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cff86bfffJiberishUI|r: '..message) end
end
function U.Pixel(value, region)
    if PixelUtil and region.GetEffectiveScale then
        local scale = region:GetEffectiveScale()
        if U.Number(scale) and scale > 0 then return PixelUtil.GetNearestPixelSize(value, scale) end
    end
    return value
end
J.Groups = { 'player','target','focus','pet','boss','targettarget','focustarget','party','partypet','raid','actionbars','petbar','stancebar','vehiclebar','extrabar','flyout','totembar' }
J.GroupLabels = {player='Player',target='Target',focus='Focus',pet='Pet',boss='Boss',targettarget='Target of target',focustarget='Focus target',party='Party',partypet='Party pets',raid='Raid',actionbars='Action bars',petbar='Pet action bar',stancebar='Stance / form',vehiclebar='Vehicle / override',extrabar='Extra / zone ability',flyout='Spell flyouts',totembar='Forever totem bar'}
J.GroupSet = {}; for _,group in ipairs(J.Groups) do J.GroupSet[group] = true end
