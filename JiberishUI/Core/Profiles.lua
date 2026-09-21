local _, J = ...
local U = J.Util
local P = {}; J.Profiles = P
local ranges = {thickness={2,12}, inset={-8,12}, opacity={0,1}, ornament={0,1}}
local modes = {healthMode={native=true,custom=true,class=true},powerMode={native=true,custom=true,type=true}}
local function color(value)
    if type(value) ~= 'table' then return false end
    for k,v in pairs(value) do
        if k~=1 and k~=2 and k~=3 then return false end
        if not U.Number(v) or v<0 or v>1 then return false end
    end
    return value[1]~=nil and value[2]~=nil and value[3]~=nil
end
local function options(value)
    if type(value) ~= 'table' then return false end
    for k,v in pairs(value) do
        if k == 'skin' then
            if not J.Skins[v] then return false end
        elseif k == 'enabled' then
            if type(v)~='boolean' then return false end
        elseif ranges[k] then
            if not U.Number(v) or v<ranges[k][1] or v>ranges[k][2] then return false end
        elseif modes[k] then
            if type(v)~='string' or not modes[k][v] then return false end
        elseif k=='tint' or k=='healthColor' or k=='powerColor' then
            if not color(v) then return false end
        elseif k=='powerColors' then
            if type(v)~='table' then return false end
            local count=0
            for token,rgb in pairs(v) do
                count=count+1
                if count>32 or type(token)~='string' or #token>32 or not token:match('^[A-Z_]+$') or not color(rgb) then return false end
            end
        else return false end
    end
    return true
end
function P.Validate(value)
    if type(value)~='table' then return false, 'Profile must be a table.' end
    for k in pairs(value) do if k~='skin' and k~='global' and k~='groups' then return false,'Unknown profile field.' end end
    if type(value.skin)~='string' or not J.Skins[value.skin] then return false,'Unknown skin.' end
    if not options(value.global) or type(value.groups)~='table' then return false,'Invalid global settings.' end
    for group,settings in pairs(value.groups) do
        if not J.GroupSet[group] or not options(settings) then return false,'Invalid frame settings.' end
    end
    return true
end
function P.Default() return {skin='human',global={},groups={}} end
function P:Init()
    local name,realm = UnitFullName('player')
    self.character = (name or 'Player')..'-'..(realm or GetRealmName() or '')
    local db = JiberishUIDB
    self.loadState=type(db)=='table' and 'received' or 'missing'
    if type(db)=='table' and U.Number(db.version) and db.version>1 then return false,'Settings are from a newer addon version; preserved without changes.' end
    if type(db)~='table' then db={version=1,profiles={},characters={}}; JiberishUIDB=db end
    db.version=1
    if type(db.profiles)~='table' then db.profiles={} end
    if type(db.characters)~='table' then db.characters={} end
    if not P.Validate(db.profiles.Default) then
        if db.profiles.Default then db.recoveryDefault=U.Copy(db.profiles.Default);self.loadState='invalid-default' end
        db.profiles.Default=P.Default()
    end
    local selected=db.characters[self.character]
    if type(selected)~='string' or not P.Validate(db.profiles[selected]) then selected='Default' end
    db.characters[self.character]=selected; self.db=db
    return true
end
function P:LoadStatus()
    if self.loadState=='received' then return 'Saved settings table received from the client.' end
    if self.loadState=='invalid-default' then return 'Invalid Default profile preserved as recovery data; Default was rebuilt.' end
    return 'No saved settings table received (first run or client loading failure).'
end
function P:Name() return self.db.characters[self.character] end
function P:Current() return self.db.profiles[self:Name()] end
function P:Resolve(group)
    local profile=self:Current(); local override=profile.groups[group] or {}
    local skin=override.skin or profile.global.skin or profile.skin
    local result=U.Copy(J.Skins[skin].defaults)
    U.Merge(result,profile.global); U.Merge(result,override); result.skin=skin
    return result
end
function P:Commit(profile)
    local ok,err=P.Validate(profile); if not ok then return false,err end
    self.db.profiles[self:Name()]=U.Copy(profile)
    if J.RequestApply then J:RequestApply() end
    return true
end
function P:Set(group,key,value)
    local profile=U.Copy(self:Current())
    if group=='global' and key=='skin' then profile.skin=value; profile.global.skin=nil
    else
        local target=profile.global
        if group~='global' then
            if not J.GroupSet[group] then return false,'Unknown group.' end
            profile.groups[group]=profile.groups[group] or {}; target=profile.groups[group]
        end
        target[key]=U.Copy(value)
    end
    return self:Commit(profile)
end
function P:ClearGroup(group)
    local p=U.Copy(self:Current()); p.groups[group]=nil; return self:Commit(p)
end
function P:Select(name)
    if not P.Validate(self.db.profiles[name]) then return false,'Profile not found or invalid.' end
    self.db.characters[self.character]=name; if J.RequestApply then J:RequestApply() end; return true
end
function P:Copy(name)
    if type(name)~='string' or #name<1 or #name>48 or name:find('[%c|]') then return false,'Use a name of 1–48 characters without control characters.' end
    if self.db.profiles[name] then return false,'That profile already exists.' end
    self.db.profiles[name]=U.Copy(self:Current()); return self:Select(name)
end
function P:Reset() return self:Commit(P.Default()) end

-- A bounded data-only format. No loadstring, Lua evaluation, or executable imports.
function P.Export(profile)
    local valid,err=P.Validate(profile); if not valid then return nil,err end
    local lines={'JUI1'}
    local function walk(value,prefix)
        local keys={}; for k in pairs(value) do keys[#keys+1]=k end
        table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
        for _,k in ipairs(keys) do
            local v=value[k]; local path=prefix=='' and tostring(k) or prefix..'.'..k
            if type(v)=='table' then walk(v,path)
            else
                local kind=type(v):sub(1,1); local text=tostring(v)
                if type(v)=='number' then text=string.format('%.17g',v) end
                lines[#lines+1]=path..'='..kind..':'..text
            end
        end
    end
    walk(profile,''); return table.concat(lines,'\n')
end
function P.Import(text)
    if type(text)~='string' or #text>262144 then return nil,'Import is empty or too large.' end
    text=text:gsub('\r\n','\n'):gsub('\n+$','')
    if text:sub(1,5)~='JUI1\n' then return nil,'Not a JiberishUI profile.' end
    local result={global={},groups={}}; local seen={}; local count=0
    for line in text:sub(6):gmatch('[^\n]+') do
        count=count+1; if count>4096 then return nil,'Too many settings.' end
        local path,kind,raw=line:match('^([%w_%.]+)=([snb]):(.*)$')
        if not path or #path>100 or seen[path] then return nil,'Invalid or repeated setting.' end
        seen[path]=true
        local keys={}; for part in path:gmatch('[^.]+') do keys[#keys+1]=tonumber(part) or part end
        if #keys>5 or path:find('%.%.') or path:sub(1,1)=='.' or path:sub(-1)=='.' then return nil,'Invalid setting path.' end
        local value=raw
        if kind=='n' then value=tonumber(raw); if not U.Number(value) then return nil,'Invalid number.' end
        elseif kind=='b' then if raw~='true' and raw~='false' then return nil,'Invalid boolean.' end; value=raw=='true'
        elseif #raw>48 then return nil,'Value too long.' end
        local target=result
        for i=1,#keys-1 do
            local k=keys[i]
            if target[k]~=nil and type(target[k])~='table' then return nil,'Conflicting settings.' end
            target[k]=target[k] or {}; target=target[k]
        end
        if target[keys[#keys]]~=nil then return nil,'Conflicting settings.' end
        target[keys[#keys]]=value
    end
    local ok,err=P.Validate(result); if not ok then return nil,err end
    return result
end
