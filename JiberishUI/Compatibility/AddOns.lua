local _, J = ...
local A = {}
J.AddOnAnchors = A

local units = {playerFrame="player",targetFrame="target",focusFrame="focus"}
local titles = {player="Player",target="Target",focus="Focus"}
local labels = {BLINKII="Blinkii's Portraits",MMT="mMediaTag & Tools",ELVUI="ElvUI",ELLESMERE="EllesmereUI"}
J.Core.properties.portraitSource = {AUTO=true,BLIZZARD=true,BLINKII=true,MMT=true,ELVUI=true,ELLESMERE=true}
J.Core.properties.hubSource = {AUTO=true,BLIZZARD=true,ELVUI=true,ELLESMERE=true}

local function field(object,key)
    if not J.Core:IsSafe(object) or type(object) ~= "table" then return nil end
    local value = object[key]
    if J.Core:IsSafe(value) then return value end
end

local function visible(frame)
    if not J.Core:IsUsableFrame(frame) then return false end
    local value = frame:IsVisible()
    return J.Core:IsSafe(value) and value == true
end

function A:Candidate(source,key)
    local unit = units[key]
    local frame,region,name,fit
    if source == "BLINKII" and unit then
        -- Use the active registry, never a stale Display/Clickable global.
        frame = field(field(BLINKIISPORTRAITS,"Portraits"),unit)
        if not J.Core:IsUsableFrame(frame) then return nil end
        region = frame.portrait
        name = "Blinkii " .. unit
        local mask = field(frame,"maskFile")
        fit = type(mask) == "string" and J.PortraitMaskFits[mask:lower()] or nil
        if fit then fit = fit*2 end
        -- Unknown/custom masks may occupy the whole twice-sized texture.
        fit = fit or math.sqrt(8)
    elseif source == "MMT" and unit then
        -- 4.x keeps active units in its engine; 3.x uses capitalized module fields.
        -- Do not resurrect a legacy/global frame when a modern unit is disabled.
        if not J.Core:IsSafe(ElvUI_mMediaTag) then return nil end
        if ElvUI_mMediaTag ~= nil then
            local module = field(field(ElvUI_mMediaTag,3),"Portraits")
            frame = field(field(module,"portraits"),unit)
            if not J.Core:IsUsableFrame(frame) then return nil end
            region = frame.unit_portrait
        else
            local module = field(field(mMT,"Modules"),"Portraits")
            frame = field(module,titles[unit])
            if not J.Core:IsUsableFrame(frame) then return nil end
            region = frame.portrait
        end
        local mask = frame.mask
        if not J.Core:IsUsableFrame(mask) then return nil end
        if type(mask.GetTexture) == "function" then
            local path = mask:GetTexture()
            if J.Core:IsSafe(path) and type(path) == "string" then fit = J.PortraitMaskFits[path:lower()] end
        end
        -- Read the mask itself: modern masks are twice the button size, legacy
        -- masks match it, and zoomed portrait content can be larger than either.
        return {frame=frame,root=frame,region=region,bounds=mask,name="mMediaTag "..unit,
            source=source,portrait=true,fit=fit or math.sqrt(2)}
    elseif unit then
        name = (source == "ELVUI" and "ElvUF_" or "EllesmereUIUnitFrames_") .. titles[unit]
        local root = _G[name]
        if not J.Core:IsUsableFrame(root) then return nil end
        region = root.Portrait
        if not J.Core:IsUsableFrame(region) then return {root=root,name=name,source=source} end
        frame = region.backdrop
        if not J.Core:IsUsableFrame(frame) then return {root=root,name=name,source=source} end
        -- Portraits over health bars have no separate opening to decorate.
        local overlay
        if source == "ELVUI" then overlay=root.USE_PORTRAIT_OVERLAY
        else overlay=frame._isInside end
        if not J.Core:IsSafe(overlay) or overlay then return {root=root,name=name,source=source} end
        local bounds
        fit = math.sqrt(2)
        if source == "ELLESMERE" and region ~= field(frame,"_3d") then
            local mask = frame._shapeMask
            if visible(mask) and type(mask.GetTexture) == "function" then
                local path = mask:GetTexture()
                if J.Core:IsSafe(path) and type(path) == "string" then
                    local measured = J.PortraitMaskFits[path:lower()]
                    if measured then fit,bounds = measured,mask end
                end
            end
        end
        return {frame=frame,root=root,region=region,bounds=bounds,name=labels[source].." "..unit,
            source=source,portrait=true,fit=fit}
    elseif key == "actionHub" then
        name = source == "ELVUI" and "ElvUI_Bar1" or "EABBar_MainBar"
        frame = _G[name]
    end
    if not J.Core:IsUsableFrame(frame) then return nil end
    return {frame=frame,root=frame,region=region,name=name,source=source,portrait=unit~=nil,fit=fit}
end

function A:Resolve(key)
    if not units[key] and key ~= "actionHub" then return nil,nil,false end
    local profile = J.ProfileManager.current
    local property = units[key] and "portraitSource" or "hubSource"
    local overrides = profile.modules[key]
    local source = overrides and overrides[property] or J.ThemeManager.registry[profile.theme][key][property]
    if source == "BLIZZARD" then return nil,nil,false end
    if source ~= "AUTO" then
        local candidate = self:Candidate(source,key)
        if candidate and candidate.frame then return candidate,nil,true end
        return nil,"Waiting for an enabled " .. labels[source] .. " portrait/bar",true
    end
    local hidden
    for _,id in ipairs(units[key] and {"BLINKII","MMT","ELVUI","ELLESMERE"} or {"ELVUI","ELLESMERE"}) do
        local candidate = self:Candidate(id,key)
        if candidate then
            if visible(candidate.root) then
                if candidate.frame then return candidate,nil,true end
                return nil,labels[id] .. " portrait disabled or inside health bar",true
            end
            hidden = hidden or candidate
        end
    end
    -- A visible Blizzard root can coexist with disabled replacement modules.
    local native = J.Core.client:Resolve(key)
    if visible(native) then return nil,nil,false end
    if hidden and hidden.frame then return hidden,nil,true end
    return nil,nil,false
end

function A:Visible(anchor)
    if not visible(anchor.root) or not visible(anchor.frame) then return false end
    return not anchor.portrait or visible(anchor.region)
end

function A:Fit(key,config,snapshot)
    if not snapshot.portraitFit then return end
    local defaults = J.ThemeManager.registry[J.ProfileManager.current.theme][key]
    -- Register the artwork's actual opening, not its off-center canvas. Round
    -- atlases have center (154,148), radius 58 in a 256-square half-atlas.
    local diameter = math.max(snapshot.w,snapshot.h) * snapshot.portraitFit
    config.width,config.height = config.width*diameter/58,config.height*diameter/58
    config.roundPortrait = true
    local cx = config.mirror and 102 or 154
    local dx = (128-cx)/256 * config.width * config.scale
    local dy = (148-128)/256 * config.height * config.scale
    config.x,config.y = config.x-defaults.x+dx,config.y-defaults.y+dy
    config.point,config.relativePoint = "CENTER","CENTER"
end
