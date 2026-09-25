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

-- Verified Forever Mainline paths. Walk and gate each container independently;
-- a missing/forbidden child leaves that bar native. No fallback to other addons.
function Forever:UnitBars(key)
    local root=self:Resolve(key)
    if not J.Portraits:IsUnitKey(key) or not J.Core:IsUsableFrame(root) then return end
    -- UnitFrame_Initialize binds these to the live native bars. Forever builds
    -- can change the XML nesting while retaining those initialized references.
    local result={}
    for kind,bar in pairs({health=root.healthbar,power=root.manabar}) do
        if J.Core:IsUsableFrame(bar) and type(bar.GetStatusBarTexture)=="function" then result[kind]=bar end
    end
    if result.health and result.power then return result end
    local content=key=="playerFrame" and root.PlayerFrameContent or root.TargetFrameContent
    if not J.Core:IsUsableFrame(content) then return next(result) and result or nil end
    local main=key=="playerFrame" and content.PlayerFrameContentMain or content.TargetFrameContentMain
    if not J.Core:IsUsableFrame(main) then return next(result) and result or nil end
    local health=main.HealthBarsContainer
    if J.Core:IsUsableFrame(health) then health=health.HealthBar else health=nil end
    local power
    if key=="playerFrame" then
        local area=main.ManaBarArea
        if J.Core:IsUsableFrame(area) then power=area.ManaBar end
    else power=main.ManaBar end
    for kind,bar in pairs({health=health,power=power}) do
        if not result[kind] and J.Core:IsUsableFrame(bar) and type(bar.GetStatusBarTexture)=="function" then result[kind]=bar end
    end
    return result
end
