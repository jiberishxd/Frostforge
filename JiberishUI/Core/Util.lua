local addon, J = ...
J.name, J.version = addon, '0.1.0-alpha.2'
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
