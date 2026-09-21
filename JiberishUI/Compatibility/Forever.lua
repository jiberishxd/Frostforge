local _, J = ...
local Forever = {
    id = "forever",
    revision = "70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e",
    baseline = 16001,
}
J.Core.clients.forever = Forever

function Forever:Matches(interface)
    return J.Core:IsNumber(interface) and interface == self.baseline
end

function Forever:Resolve(key)
    -- Forever loads Mainline roots plus Camelot unit-frame overrides.
    -- Only these verified roots are used; no Retail child paths or mask rules
    -- are imported. A missing root remains native and is retried on discovery.
    local frame, name
    if key == "minimap" then frame, name = Minimap, "Minimap"
    elseif key == "playerFrame" then frame, name = PlayerFrame, "PlayerFrame"
    elseif key == "targetFrame" then frame, name = TargetFrame, "TargetFrame"
    elseif key == "focusFrame" then frame, name = FocusFrame, "FocusFrame"
    elseif key == "actionHub" then frame, name = MainActionBar, "MainActionBar" end
    if frame == nil then return nil, name, "Waiting for Forever " .. (name or key) end
    if not J.Core:IsUsableFrame(frame) then return nil, name, "Forbidden/unavailable Forever anchor" end
    return frame, name
end

function Forever:PortraitVisible(key,root)
    if not J.Portraits:IsUnitKey(key) then return true end
    -- Verified Forever Mainline portrait regions; Camelot controls their native
    -- presentation. Read visibility only and keep all native artwork untouched.
    local container = key == "playerFrame" and root.PlayerFrameContainer or root.TargetFrameContainer
    if not J.Core:IsUsableFrame(container) then return false end
    local portrait = key == "playerFrame" and container.PlayerPortrait or container.Portrait
    if not J.Core:IsUsableFrame(portrait) then return false end
    local visible=portrait:IsVisible()
    return J.Core:IsSafe(visible) and visible == true
end
