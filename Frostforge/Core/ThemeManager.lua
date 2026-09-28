local _, J = ...
local Themes = { registry = {} }
J.ThemeManager = Themes

local function configurationOnly(value, depth)
    if depth > 8 or type(value) == "function" then return false end
    if type(value) == "table" then
        for k, v in pairs(value) do
            if type(k) ~= "string" or not configurationOnly(v, depth + 1) then return false end
        end
    elseif type(value) ~= "string" and type(value) ~= "number" and type(value) ~= "boolean" then
        return false
    end
    return true
end

function Themes:Register(id, theme)
    assert(type(id) == "string" and id:match("^[a-z_]+$"), "Invalid theme ID")
    assert(not self.registry[id], "Duplicate theme")
    assert(configurationOnly(theme, 0), "Themes must contain configuration only")
    assert(type(theme.name) == "string", "Theme name required")
    for _, key in ipairs(J.Core.order) do
        local config = assert(theme[key], "Missing theme component: " .. key)
        local units = {playerFrame="player",targetFrame="target",focusFrame="focus"}
        assert(config.unit == units[key], "Invalid portrait unit token: " .. key)
        assert(type(config.texture) == "string", "Texture required")
        assert(config.mirror == nil or type(config.mirror) == "boolean", "Invalid mirroring option")
        if config.pieces then
            assert(type(config.pieces) == "table" and next(config.pieces), "Artwork pieces required")
            assert(J.Core:IsNumber(config.designHeight) and config.designHeight > 0, "Invalid design height")
            assert(J.Core:IsNumber(config.minimumWidth) and config.minimumWidth > 0, "Invalid minimum width")
            for name, piece in pairs(config.pieces) do
                assert(type(piece) == "table", "Invalid artwork piece: " .. name)
                for _, field in ipairs({"leftAnchor","rightAnchor","leftOffset","rightOffset","y","height","u1","u2","v1","v2","order"}) do
                    assert(J.Core:IsNumber(piece[field]), "Invalid piece geometry: " .. name .. "." .. field)
                end
                assert(piece.leftAnchor >= 0 and piece.rightAnchor <= 1 and piece.rightAnchor >= piece.leftAnchor)
                assert(piece.height > 0 and piece.y >= 0 and piece.y + piece.height <= config.designHeight + 0.01)
                assert(piece.u1 >= 0 and piece.u2 <= 1 and piece.u2 > piece.u1)
                assert(piece.v1 >= 0 and piece.v2 <= 1 and piece.v2 > piece.v1)
                assert(piece.order >= 0 and piece.order <= 7 and piece.order == math.floor(piece.order))
                local width = config.minimumWidth*(piece.rightAnchor-piece.leftAnchor)+piece.rightOffset-piece.leftOffset
                assert(width > 0, "Piece collapses at minimum width: " .. name)
            end
        end
        for property in pairs(J.Core.properties) do
            local portrait = J.BlizzardUnits.styleProperties[property] or J.BlizzardUnits.textProperties[property] or property == "portraitMode" or property == "unitFrameStrata" or property == "castBarLevel" or property == "castBarStrata" or property == "blizzardPortraitFrameHidden" or property == "blizzardPortraitHidden" or property == "blizzardNameEnabled" or property == "blizzardNameX" or property == "blizzardNameY" or property == "blizzardNameSize" or property == "blizzardNameAlign" or property == "blizzardNameOutline" or property == "castBarShown" or property == "castBarSource" or property == "castBarStyle" or property == "castBarArt" or property == "castBarWeight" or property == "castBarPadding" or property == "castBarWidth" or property == "castBarHeight" or property == "portrait" or property == "unitStyle" or property == "unitFrameShown" or property == "unitFrameFill" or property == "unitFrameWidth" or property == "unitFrameHeight" or property == "unitFrameX" or property == "unitFrameY" or property == "unitFrameInset" or property == "unitFrameSource" or property == "portraitSource"
            local hub = property == "hubMode" or property == "hub" or property == "hubSource"
            local minimap = property == "minimapMode" or property == "minimap" or property=="minimapRound"
            if (not J.BlizzardUnits.placementProperties[property] or key=="targetFrame" or key=="focusFrame") and (not J.BlizzardUnits.sharedStyleProperties[property] or key=="playerFrame") and (property~="blizzardStone" or key=="playerFrame") and property~="unitStyle" and (not portrait or config.unit) and (not hub or key == "actionHub") and (not minimap or key == "minimap") then
                assert(J.Core:ValidateProperty(property, config[property]) ~= nil,
                    "Invalid theme property: " .. key .. "." .. property)
            end
        end
    end
    self.registry[id] = J.Core:Copy(theme)
end

function Themes:Resolve(key)
    local profile = J.ProfileManager.current
    local theme = self.registry[profile.theme]
    local result = J.Core:Copy(theme[key])
    for property, value in pairs(profile.modules[key] or {}) do result[property] = value end
    if result.unit then result.unitStyle=result.unitFrameShown and "FULL" or "PORTRAIT" end
    return result
end

-- Read-only settings shared within a single update pass. Never retained across
-- ticks: imports, profile switches and provider changes are visible immediately.
-- Layout code still uses Resolve() for its independently mutable copy.
function Themes:Read(key)
    if not self.readPass then return self:Resolve(key) end
    if not self.readPass[key] then self.readPass[key]=self:Resolve(key) end
    return self.readPass[key]
end

function Themes:Load(id)
    if not self.registry[id] then return false, "Unknown theme. Phase 1 includes only paladin_ret." end
    if not J.ProfileManager.writable then return false, J.ProfileManager.notice end
    J.ProfileManager.current.theme = id
    J.Core:RequestRefresh(true)
    return true
end
