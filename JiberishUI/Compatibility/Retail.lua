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
    elseif key == "focusFrame" then frame, name = FocusFrame, "FocusFrame"
    elseif key == "actionHub" then frame, name = MainActionBar, "MainActionBar" end
    if frame == nil then return nil, name, "Waiting for Blizzard " .. (name or key) end
    -- Required before inspecting geometry, including any future hook argument.
    if not J.Core:IsUsableFrame(frame) then return nil, name, "Forbidden/unavailable Retail anchor" end
    return frame, name
end

function Retail:PortraitVisible(key,root)
    if not J.Portraits:IsUnitKey(key) then return true end
    local container = key == "playerFrame" and root.PlayerFrameContainer or root.TargetFrameContainer
    if not J.Core:IsUsableFrame(container) then return false end
    local portrait = key == "playerFrame" and container.PlayerPortrait or container.Portrait
    if not J.Core:IsUsableFrame(portrait) then return false end
    local visible=portrait:IsVisible()
    return J.Core:IsSafe(visible) and visible == true
end
