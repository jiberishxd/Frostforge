local _, J = ...
local Profiles = { writable = true }
J.ProfileManager = Profiles

local function defaults()
    return { version = 1, theme = "paladin_ret", debug = false, modules = {} }
end

function Profiles:Initialize()
    local source
    if JiberishUIDB == nil then
        self.notice = "No saved settings table received; first run or client loading failure."
        JiberishUIDB = {}
    elseif type(JiberishUIDB) ~= "table" then
        self.writable = false
        self.notice = "Existing settings have an unknown format; preserved without changes."
    end
    if self.writable then
        source = JiberishUIDB.phase1
        if type(source) == "table" and type(source.version) == "number" and source.version > 1 then
            self.writable = false
            self.notice = "Newer Phase 1 settings version found; preserved without changes."
        end
    end
    self.current = defaults()
    if self.writable and type(source) == "table" then
        if J.ThemeManager.registry[source.theme] then self.current.theme = source.theme end
        self.current.debug = source.debug == true
        if type(source.modules) == "table" then
            for _, key in ipairs(J.Core.order) do
                if type(source.modules[key]) == "table" then
                    local target = {}
                    for property, value in pairs(source.modules[key]) do
                        local valid = J.Core:ValidateProperty(property, value)
                        if valid ~= nil then target[property] = valid end
                    end
                    self.current.modules[key] = target
                end
            end
        end
        self.notice = "Phase 1 settings loaded."
    elseif self.writable and not self.notice then
        self.notice = "New Phase 1 settings; earlier profiles preserved separately."
    end
    -- Never convert, erase, or apply the previous renderer's profiles.
    if self.writable then JiberishUIDB.phase1 = self.current end
end

function Profiles:Set(key, property, value)
    if not self.writable then return false, self.notice end
    if not J.Core.modules[key] then return false, "Unknown component." end
    local valid = J.Core:ValidateProperty(property, value)
    if valid == nil then return false, J.Core:PropertyHelp(property) end
    local overrides = self.current.modules[key] or {}
    self.current.modules[key] = overrides
    overrides[property] = valid
    J.Core:RequestRefresh(true)
    return true
end

function Profiles:Reset(key)
    if not self.writable then return false, self.notice end
    if key and not J.Core.modules[key] then return false, "Unknown component." end
    if key then self.current.modules[key] = nil else self.current.modules = {} end
    J.Core:RequestRefresh(true)
    return true
end

-- A bounded command-format backup. No Lua or other code is ever evaluated.
function Profiles:Export()
    local fields = { "JF1", self.current.theme }
    for _, key in ipairs(J.Core.order) do
        local config = self.current.modules[key] or {}
        for _, property in ipairs(J.Core.propertyOrder) do
            if config[property] ~= nil then
                fields[#fields + 1] = key .. "." .. property .. "=" .. tostring(config[property])
            end
        end
    end
    return table.concat(fields, ";")
end

function Profiles:Import(text)
    if not self.writable then return false, self.notice end
    if type(text) ~= "string" or #text > 8192 then return false, "Invalid backup length." end
    local theme, tail = text:match("^JF1;([a-z_]+)(.*)$")
    if not theme or not J.ThemeManager.registry[theme] then return false, "Invalid backup theme." end
    local candidate, seen = defaults(), {}
    candidate.theme = theme
    candidate.debug = self.current.debug
    while tail ~= "" do
        local key, property, value, rest = tail:match("^;(%w+)%.(%w+)=([^;]+)(.*)$")
        if not key or not J.Core.modules[key] then return false, "Invalid backup component." end
        local id = key .. "." .. property
        local valid = J.Core:ValidateProperty(property, value)
        if seen[id] or valid == nil then return false, "Invalid or duplicate backup property." end
        seen[id] = true
        candidate.modules[key] = candidate.modules[key] or {}
        candidate.modules[key][property] = valid
        tail = rest
    end
    self.current = candidate
    JiberishUIDB.phase1 = candidate
    J.Core:RequestRefresh(true)
    return true
end
