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
        assert(type(config.texture) == "string", "Texture required")
        for property in pairs(J.Core.properties) do
            assert(J.Core:ValidateProperty(property, config[property]) ~= nil,
                "Invalid theme property: " .. key .. "." .. property)
        end
    end
    self.registry[id] = J.Core:Copy(theme)
end

function Themes:Resolve(key)
    local profile = J.ProfileManager.current
    local theme = self.registry[profile.theme]
    local result = J.Core:Copy(theme[key])
    for property, value in pairs(profile.modules[key] or {}) do result[property] = value end
    return result
end

function Themes:Load(id)
    if not self.registry[id] then return false, "Unknown theme. Phase 1 includes only paladin_ret." end
    if not J.ProfileManager.writable then return false, J.ProfileManager.notice end
    J.ProfileManager.current.theme = id
    J.Core:RequestRefresh(true)
    return true
end
