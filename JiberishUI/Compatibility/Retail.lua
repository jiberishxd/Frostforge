local _, J = ...
local Retail = {
    id = "retail",
    revision = "78282522143e25c3540583734fd192c3d69be910",
    baseline = 120100,
}
J.Core.clients.retail = Retail

function Retail:Matches(interface)
    return J.Core:IsNumber(interface) and interface >= 120000 and interface < 130000
end

function Retail:Resolve(key)
    -- Retail 12.x root frames only. Never reach into health/power containers.
    local frame, name
    if key == "minimap" then frame, name = Minimap, "Minimap"
    elseif key == "playerFrame" then frame, name = PlayerFrame, "PlayerFrame"
    elseif key == "targetFrame" then frame, name = TargetFrame, "TargetFrame"
    elseif key == "actionHub" then frame, name = MainActionBar, "MainActionBar" end
    if frame == nil then return nil, name, "Waiting for Blizzard " .. (name or key) end
    -- Required before inspecting geometry, including any future hook argument.
    if not J.Core:IsUsableFrame(frame) then return nil, name, "Forbidden/unavailable Retail anchor" end
    return frame, name
end
