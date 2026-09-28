local _, J = ...
local A = {}
J.SmallFrameAnchors = A
local labels={BLIZZARD="Blizzard",ELVUI="ElvUI",ELLESMERE="EllesmereUI"}
local function usable(frame) return J.Core:IsUsableFrame(frame) end
local function field(object,key)
    if not J.Core:IsSafe(object) or type(object)~="table" then return end
    if type(object.IsForbidden)=="function" and not usable(object) then return end
    local value=object[key]
    if J.Core:IsSafe(value) then return value end
end
local function call(object,method,...)
    if not usable(object) or type(object[method])~="function" then return end
    local ok,value=pcall(object[method],object,...)
    if ok and J.Core:IsSafe(value) then return value end
end
function A:Visible(frame)
    local shown,alpha=call(frame,"IsVisible"),call(frame,"GetEffectiveAlpha")
    return shown==true and J.Core:IsNumber(alpha) and alpha>0,alpha
end

-- Secure headers sort/reassign buttons. Never infer a member from slot number.
function A:Unit(candidate)
    if candidate.fixedUnit then return candidate.fixedUnit end
    if not usable(candidate.root) then return end
    local unit
    if type(candidate.root.GetAttribute)=="function" then
        local ok,value=pcall(candidate.root.GetAttribute,candidate.root,"unit")
        if not ok or not J.Core:IsSafe(value) then return end
        unit=value
    end
    if unit==nil then unit=field(candidate.root,"unit") or field(candidate.root,"unitToken") end
    if type(unit)=="string" and (unit=="player" or unit:match("^party[1-4]$") or unit:match("^raid%d%d?$")) then return unit end
end

local function elvPortrait(root)
    if field(root,"USE_PORTRAIT_OVERLAY")~=false then return end
    local portrait=field(root,"Portrait")
    local backdrop=field(portrait,"backdrop")
    if usable(portrait) and usable(backdrop) then
        return {region=portrait,bounds=backdrop,host=backdrop,fit=math.sqrt(2)}
    end
end
local function euiPortrait(root,data)
    local kit=field(data,"kitPortrait")
    if usable(kit) and call(kit,"IsShown")==true then return {region=kit,bounds=kit,host=root,fit=1} end
    local bd=field(data,"pt")
    if usable(bd) and field(bd,"_on")==true and field(bd,"_gIn")==false then
        local region
        for _,key in ipairs({"_2d","_3d","_class"}) do
            local r=field(bd,key)
            if call(r,"IsShown")==true then region=r;break end
        end
        local mask=field(bd,"_mask")
        local fit=math.sqrt(2)
        if call(mask,"IsShown")==true then
            local path=call(mask,"GetTexture")
            if type(path)=="string" then fit=J.PortraitMaskFits[path:lower()] or fit end
        else mask=nil end
        if region then return {region=region,bounds=mask or bd,host=bd,fit=fit,mirror=field(bd,"_gSide")=="right"} end
    end
end

function A:Candidates(key,source)
    local result,seen={},{}
    local function add(root,data,fixedUnit)
        if not usable(root) or seen[root] then return end
        seen[root]=true
        local candidate={root=root,source=source,name=labels[source],fixedUnit=fixedUnit}
        if source=="BLIZZARD" then
            candidate.health=field(root,"healthbar") or field(root,"healthBar") or field(field(root,"HealthBarContainer"),"HealthBar") or field(root,"HealthBar")
            candidate.power=field(root,"manabar") or field(root,"powerBar") or field(root,"ManaBar")
            local portrait=field(root,"Portrait") or field(root,"portrait")
            if usable(portrait) then candidate.portrait={region=portrait,bounds=portrait,host=root,fit=1} end
        elseif source=="ELVUI" or fixedUnit then
            candidate.health=field(root,"Health");candidate.power=field(root,"Power")
            if source=="ELVUI" then candidate.portrait=elvPortrait(root)
            else
                -- The unit-frame module uses the same detached portrait layout
                -- as Player/Target. Resolve it through the existing adapter.
                local p=J.AddOnAnchors:Candidate("ELLESMERE","targetTargetFrame")
                if p and p.frame then candidate.portrait={region=p.region,bounds=p.bounds or p.frame,
                    host=p.frame,fit=p.fit,shape=p.shape,mirror=p.mirror} end
            end
        else
            candidate.health=field(data,"health");candidate.power=field(data,"power")
            candidate.chrome=field(data,"border")
            candidate.portrait=euiPortrait(root,data)
        end
        if usable(candidate.health) then result[#result+1]=candidate end
    end
    if key=="targetTargetFrame" then
        local name=source=="BLIZZARD" and "TargetFrameToT" or source=="ELVUI" and "ElvUF_TargetTarget" or "EllesmereUIUnitFrames_TargetTarget"
        add(_G[name],nil,"targettarget")
    elseif source=="BLIZZARD" then
        local pool=field(PartyFrame,"PartyMemberFramePool")
        if usable(PartyFrame) and type(field(pool,"EnumerateActive"))=="function" then
            local n=0
            for root in pool:EnumerateActive() do add(root);n=n+1;if n>=4 then break end end
        end
        local list=usable(CompactPartyFrame) and field(CompactPartyFrame,"memberUnitFrames")
        for i=1,5 do add(field(list,i)) end
    elseif source=="ELVUI" then
        local header=ElvUF_PartyGroup1
        if usable(header) then
            for i=1,5 do add(field(header,i) or call(header,"GetAttribute","child"..i)) end
        end
    else
        -- EUI keeps party button state in its module registry, not on secure
        -- buttons. Only inspect this bounded party list (including self-first).
        local ns=field(field(EllesmereUI,"_ModuleNS"),"EllesmereUIRaidFrames")
        local list,get=field(ns,"_partyAllButtons"),field(ns,"GetFFD")
        if type(get)=="function" then
            for i=1,6 do
                local root=field(list,i)
                if usable(root) then
                    local ok,data=pcall(get,root)
                    if ok and J.Core:IsSafe(data) and type(data)=="table" then add(root,data) end
                end
            end
        end
    end
    return result
end

function A:Resolve(key,source)
    if source~="AUTO" then return self:Candidates(key,source),labels[source] end
    local first,firstName
    for _,id in ipairs({"ELLESMERE","ELVUI","BLIZZARD"}) do
        local candidates=self:Candidates(key,id)
        if #candidates>0 then
            first,firstName=first or candidates,firstName or labels[id]
            for _,candidate in ipairs(candidates) do
                if self:Visible(candidate.root) then return candidates,labels[id] end
            end
        end
    end
    return first or {},firstName or "provider"
end
