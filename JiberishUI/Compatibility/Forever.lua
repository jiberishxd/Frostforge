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
    elseif key == "actionHub" then frame, name = MainActionBar, "MainActionBar" end
    if frame == nil then return nil, name, "Waiting for Forever " .. (name or key) end
    if not J.Core:IsUsableFrame(frame) then return nil, name, "Forbidden/unavailable Forever anchor" end
    return frame, name
end
