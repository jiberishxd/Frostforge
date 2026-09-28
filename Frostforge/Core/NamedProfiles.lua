local _,J=...
local P=J.ProfileManager

local function cleanName(value)
    if type(value)~="string" then return end
    value=value:match("^%s*(.-)%s*$")
    if value=="" or #value>64 or value:find("[%c|]") then return end
    return value
end

local function entryOK(entry)
    return type(entry)=="table" and cleanName(entry.name) and type(entry.settings)=="table"
        and (entry.settings.version==nil or (type(entry.settings.version)=="number" and entry.settings.version<=2))
end

function P:ProfileList()
    local result={}
    for id,entry in pairs(self.store and self.store.profiles or {}) do
        if type(id)=="string" and entryOK(entry) then result[#result+1]={id=id,name=entry.name} end
    end
    table.sort(result,function(a,b)
        if a.name:lower()==b.name:lower() then return a.id<b.id end
        return a.name:lower()<b.name:lower()
    end)
    return result
end

function P:NewProfileID()
    local n=1
    while self.store.profiles["profile"..n]~=nil do n=n+1 end
    return "profile"..n,n
end

function P:ProfileName()
    local entry=self.store and self.store.profiles[self.activeID]
    return entry and entry.name or "Unsaved setup"
end

-- WoW's per-character SavedVariables holds only the selected ID. Named
-- profiles live account-wide; an unseen alt gets its own automatic setup.
-- Older renderer profiles remain in their original, separate namespace.
function P:InitializeNamed(legacy)
    local store,character=JiberishUIDB.profileStore,JiberishUICharacterDB
    if store~=nil and (type(store)~="table" or store.version~=1 or type(store.profiles)~="table") then
        self.writable=false;self.notice="Unknown named-profile format; saved data preserved."
        return
    end
    if character~=nil and (type(character)~="table" or (character.version~=nil and character.version~=1)) then
        self.writable=false;self.notice="Unknown character-profile format; saved data preserved."
        return
    end
    local first=store==nil
    self.store=store or {version=1,profiles={}}
    local id=character and character.profile
    local entry=type(id)=="string" and self.store.profiles[id]
    if type(entry)=="table" and type(entry.settings)=="table" and type(entry.settings.version)=="number" and entry.settings.version>2 then
        self.writable=false;self.notice="Newer character setup found; saved data preserved."
        return
    end
    if not entryOK(entry) then
        local number
        id,number=self:NewProfileID()
        local name=first and type(legacy)=="table" and "Imported setup" or "Character "..number
        local used={};for _,row in ipairs(self:ProfileList()) do used[row.name:lower()]=true end
        while used[name:lower()] do number=number+1;name="Character "..number end
        entry={name=name,settings=first and self.current or self:Sanitize(nil)}
        self.store.profiles[id]=entry
        if not first then self.notice="New character profile created with automatic class artwork." end
    else
        entry.settings=self:Sanitize(entry.settings)
    end
    self.activeID,self.current=id,entry.settings
    JiberishUIDB.profileStore=self.store
    JiberishUICharacterDB=character or {}
    JiberishUICharacterDB.version,JiberishUICharacterDB.profile=1,id
end

function P:CheckProfileName(name,except)
    name=cleanName(name)
    if not name then return nil,"Enter a short profile name without control characters or | (maximum 64 bytes)." end
    for _,row in ipairs(self:ProfileList()) do
        if row.id~=except and row.name:lower()==name:lower() then return nil,"That profile name already exists." end
    end
    return name
end

function P:UseProfile(id)
    if not self.writable then return false,self.notice end
    if InCombatLockdown() then return false,"Switch profiles after combat ends." end
    local entry=type(id)=="string" and self.store and self.store.profiles[id]
    if not entryOK(entry) then return false,"Choose a valid saved profile." end
    entry.settings=self:Sanitize(entry.settings)
    self.activeID,self.current=id,entry.settings
    JiberishUICharacterDB.profile=id
    JiberishUIDB.phase1=self.current
    J.Core:RequestRefresh(true)
    if J.SettingsUI.frame then J.SettingsUI:FitWindow() end
    return true
end

function P:SaveAs(name,fresh)
    if not self.writable then return false,self.notice end
    if InCombatLockdown() then return false,"Create profiles after combat ends." end
    local valid,reason=self:CheckProfileName(name)
    if not valid then return false,reason end
    local id=self:NewProfileID()
    self.store.profiles[id]={name=valid,settings=fresh and self:Sanitize(nil) or J.Core:Copy(self.current)}
    return self:UseProfile(id)
end

function P:RenameProfile(name)
    if not self.writable then return false,self.notice end
    local valid,reason=self:CheckProfileName(name,self.activeID)
    if not valid then return false,reason end
    self.store.profiles[self.activeID].name=valid
    return true
end
