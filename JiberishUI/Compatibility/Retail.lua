local _, J = ...
local Retail = {
    id = "retail",
    revision = "78282522143e25c3540583734fd192c3d69be910",
    baseline = 120100,
}
J.Core.clients.retail = Retail

function Retail:CastBars(key)
    if key=="playerFrame" then
        local bars={}
        for _,name in ipairs({"PlayerCastingBarFrame","OverlayPlayerCastingBarFrame"}) do
            local frame=_G[name]
            if J.Core:IsUsableFrame(frame) then bars[#bars+1]=frame end
        end
        return bars
    end
    local root=key=="targetFrame" and TargetFrame or key=="focusFrame" and FocusFrame
    if J.Core:IsUsableFrame(root) and J.Core:IsUsableFrame(root.spellbar) then return {root.spellbar} end
end

function Retail:Matches(interface)
    return J.Core:IsNumber(interface) and interface >= 120000 and interface < 130000
end

function Retail:Resolve(key)
    -- Retail 12.x native roots. Appearance-only child access is isolated below.
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

-- Verified Retail Mainline paths. Walk and gate each container independently;
-- a missing/forbidden child leaves that bar native. No fallback to other addons.
function Retail:UnitBars(key)
    local root=self:Resolve(key)
    if not J.Portraits:IsUnitKey(key) or not J.Core:IsUsableFrame(root) then return end
    local content=key=="playerFrame" and root.PlayerFrameContent or root.TargetFrameContent
    if not J.Core:IsUsableFrame(content) then return end
    local main=key=="playerFrame" and content.PlayerFrameContentMain or content.TargetFrameContentMain
    if not J.Core:IsUsableFrame(main) then return end
    local health=main.HealthBarsContainer
    if J.Core:IsUsableFrame(health) then health=health.HealthBar else health=nil end
    local power
    if key=="playerFrame" then
        local area=main.ManaBarArea
        if J.Core:IsUsableFrame(area) then power=area.ManaBar end
    else power=main.ManaBar end
    local result={}
    for kind,bar in pairs({health=health,power=power}) do
        if J.Core:IsUsableFrame(bar) and type(bar.GetStatusBarTexture)=="function" then result[kind]=bar end
    end
    return result
end
