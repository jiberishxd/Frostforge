local _, J = ...
local Profiles = { writable = true }
J.ProfileManager = Profiles

local function defaults()
    return { version = 2, theme = "paladin_ret", debug = false, modules = {} }
end

-- The former width controlled long bar rails. Convert that layout to compact
-- portraits once; retain relative adjustments, scale, visibility and layering.
local function migrateShell(profile)
    for _,key in ipairs({"playerFrame","targetFrame"}) do
        local c = profile.modules[key]
        if c then
            local oldX = key == "playerFrame" and -46 or 46
            local newX = key == "playerFrame" and -23 or 22
            local newY = key == "playerFrame" and 11 or 12
            if c.width or c.height then
                local s = math.min((c.height or 170)/170,(c.width or 300)/260)
                c.width,c.height = math.max(16,128*s),math.max(16,128*s)
            end
            if c.x then c.x=math.max(-2048,math.min(2048,newX+c.x-oldX)) end
            if c.y then c.y=math.max(-2048,math.min(2048,newY+c.y-16)) end
        end
    end
end

local function supported(key,property)
    if property=="blizzardStone" then return key=="playerFrame" end
    if property == "castBarShown" or property == "unitFrameStrata" or property == "castBarLevel" or property == "castBarStrata" or property == "blizzardPortraitFrameHidden" or property == "blizzardPortraitHidden" or property == "blizzardNameEnabled" or property == "blizzardNameX" or property == "blizzardNameY" or property == "blizzardNameSize" or property == "blizzardNameAlign" or property == "blizzardNameOutline" or property == "castBarSource" or property == "castBarStyle" or property == "castBarArt" or property == "castBarWeight" or property == "castBarPadding" or property == "castBarWidth" or property == "castBarHeight" or property == "portrait" or property == "portraitMode" or property == "portraitSource" or property == "unitStyle" or property == "unitFrameShown" or property == "unitFrameFill" or property == "unitFrameWidth" or property == "unitFrameHeight" or property == "unitFrameX" or property == "unitFrameY" or property == "unitFrameInset" or property == "unitFrameSource" then return J.Portraits:IsUnitKey(key) end
    if property == "hub" or property == "hubMode" or property == "hubSource" then return key == "actionHub" end
    if property == "minimap" or property == "minimapMode" then return key == "minimap" end
    return true
end

local function migrateUnitToggles(profile)
    for _,key in ipairs({"playerFrame","targetFrame","focusFrame"}) do
        local c=profile.modules[key]
        if c then
            if c.unitFrameShown==nil and c.unitStyle then c.unitFrameShown=c.unitStyle=="FULL" end
            c.unitStyle=nil
            -- Preserve the previous shared layering once; later choices are independent.
            if c.unitFrameStrata==nil and c.strata then c.unitFrameStrata=c.strata end
        end
    end
end

function Profiles:Sanitize(source)
    local current=defaults()
    if type(source)~="table" then return current end
    if J.ThemeManager.registry[source.theme] then current.theme=source.theme end
    current.debug=source.debug==true
    if type(source.window)=="table" and J.Core:IsNumber(source.window.x) and J.Core:IsNumber(source.window.y)
        and math.abs(source.window.x)<=10000 and math.abs(source.window.y)<=10000 then
        current.window={x=source.window.x,y=source.window.y}
    end
    if type(source.modules)=="table" then
        for _,key in ipairs(J.Core.order) do
            if type(source.modules[key])=="table" then
                local target={}
                for property,value in pairs(source.modules[key]) do
                    local valid=J.Core:ValidateProperty(property,value)
                    if valid~=nil and supported(key,property) then target[property]=valid end
                end
                current.modules[key]=target
            end
        end
    end
    if source.version~=2 then migrateShell(current) end
    migrateUnitToggles(current)
    return current
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
        if type(source) == "table" and type(source.version) == "number" and source.version > 2 then
            self.writable = false
            self.notice = "Newer Phase 1 settings version found; preserved without changes."
        end
    end
    self.current = defaults()
    if self.writable and type(source) == "table" then
        self.current = self:Sanitize(source)
        self.notice = "Phase 1 settings loaded."
        if source.version ~= 2 then
            self.notice = "Portrait backgrounds loaded; previous bar-shell sizing converted."
        end
    elseif self.writable and not self.notice then
        self.notice = "New Phase 1 settings; earlier profiles preserved separately."
    end
    migrateUnitToggles(self.current)
    if self.writable then self:InitializeNamed(source) end
    -- Never convert, erase, or apply the previous renderer's profiles.
    if self.writable then JiberishUIDB.phase1 = self.current end
end

function Profiles:SetWindowPosition(x,y)
    if not self.writable or not J.Core:IsNumber(x) or not J.Core:IsNumber(y)
        or math.abs(x) > 10000 or math.abs(y) > 10000 then return false end
    self.current.window = {x=x,y=y}
    return true
end

function Profiles:Set(key, property, value)
    if not self.writable then return false, self.notice end
    if not J.Core.modules[key] then return false, "Unknown component." end
    if not supported(key,property) then return false, "Artwork selection does not apply to this component." end
    local valid = J.Core:ValidateProperty(property, value)
    if valid == nil then return false, J.Core:PropertyHelp(property) end
    if property=="unitStyle" then property,valid="unitFrameShown",valid=="FULL" end
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
    local fields = { "JF2", self.current.theme }
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
    local version, theme, tail = text:match("^JF([12]);([a-z_]+)(.*)$")
    if not theme or not J.ThemeManager.registry[theme] then return false, "Invalid backup theme." end
    local candidate, seen = defaults(), {}
    candidate.theme = theme
    candidate.debug = self.current.debug
    candidate.window = J.Core:Copy(self.current.window)
    while tail ~= "" do
        local key, property, value, rest = tail:match("^;(%w+)%.(%w+)=([^;]+)(.*)$")
        if not key or not J.Core.modules[key] then return false, "Invalid backup component." end
        local id = key .. "." .. property
        local valid = J.Core:ValidateProperty(property, value)
        if seen[id] or valid == nil or not supported(key,property) then return false, "Invalid or duplicate backup property." end
        seen[id] = true
        candidate.modules[key] = candidate.modules[key] or {}
        candidate.modules[key][property] = valid
        tail = rest
    end
    if version == "1" then migrateShell(candidate) end
    migrateUnitToggles(candidate)
    self.current = candidate
    JiberishUIDB.phase1 = candidate
    if self.store and self.activeID then self.store.profiles[self.activeID].settings=candidate end
    J.Core:RequestRefresh(true)
    return true
end
