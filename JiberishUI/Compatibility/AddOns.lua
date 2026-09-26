local _, J = ...
local A = {}
J.AddOnAnchors = A

local units = {playerFrame="player",targetFrame="target",focusFrame="focus"}
local titles = {player="Player",target="Target",focus="Focus"}
local labels = {BLINKII="Blinkii's Portraits",MMT="mMediaTag & Tools",ELVUI="ElvUI",ELLESMERE="EllesmereUI"}
J.Core.properties.portraitSource = {AUTO=true,BLIZZARD=true,BLINKII=true,MMT=true,ELVUI=true,ELLESMERE=true}
J.Core.properties.unitFrameSource = {AUTO=true,BLIZZARD=true,ELLESMERE=true}
J.Core.properties.hubSource = {AUTO=true,BLIZZARD=true,ELVUI=true,ELLESMERE=true}

local function field(object,key)
    if not J.Core:IsSafe(object) or type(object) ~= "table" then return nil end
    local value = object[key]
    if J.Core:IsSafe(value) then return value end
end

local function visible(frame)
    if not J.Core:IsUsableFrame(frame) then return false end
    local value = frame:IsVisible()
    if not J.Core:IsSafe(value) or value ~= true then return false end
    local alpha=type(frame.GetEffectiveAlpha)=="function" and frame:GetEffectiveAlpha() or frame:GetAlpha()
    return J.Core:IsNumber(alpha) and alpha>0
end

function A:CastBarCandidate(source,key)
    local unit=units[key]
    if not unit then return end
    if source=="BLIZZARD" then
        local bars=J.Core.client:CastBars(key)
        local first
        for _,frame in ipairs(bars or {}) do
            if J.Core:IsUsableFrame(frame) then
                local root=unit=="player" and PlayerFrame or unit=="target" and TargetFrame or FocusFrame
                local result={frame=frame,source=source,nativeRoot=root}
                if visible(frame) then return result end
                first=first or result
            end
        end
        return first
    end
    local resource
    if source=="ELLESMERE" and unit=="player" then
        local host=ERB_CastBarFrame
        if J.Core:IsUsableFrame(host) then
            local bar=field(host,"_bar")
            if J.Core:IsUsableFrame(bar) then
                resource={frame=bar,source=source,name="Ellesmere Resource Bars",chrome=field(host,"_border")}
                if visible(bar) then return resource end
            end
        end
    end
    local name=(source=="ELLESMERE" and "EllesmereUIUnitFrames_" or "ElvUF_")..titles[unit]
    local root=_G[name]
    if not J.Core:IsUsableFrame(root) then return resource end
    local frame=field(root,"Castbar")
    if J.Core:IsUsableFrame(frame) then
        local result={frame=frame,source=source,rootVisible=visible(root),
            name=source=="ELLESMERE" and "Ellesmere Unit Frames" or "ElvUI",
            chrome=source=="ELLESMERE" and (field(frame,"_blizzArtFr") or field(frame,"_classicArt")) or nil}
        if visible(frame) then return result end
        -- The main Resource Bars cast stays hidden/transparent while idle.
        -- Prepare it before combat instead of attaching the disabled mini bar.
        if resource then resource.rootVisible=result.rootVisible end
        return resource or result
    end
    return resource
end

function A:ResolveCastBar(key,config)
    if config.castBarSource~="AUTO" then
        local candidate=self:CastBarCandidate(config.castBarSource,key)
        if candidate then return candidate end
        return nil,"Waiting for "..config.castBarSource.." cast bar"
    end
    -- Prefer the configured unit/portrait provider, then an actually visible
    -- cast bar. Hidden candidates are still attached out of combat so the first
    -- cast can appear without creating or repositioning frames in combat.
    local preferred=config.unitFrameSource~="AUTO" and config.unitFrameSource or config.portraitSource
    local order,seen={},{}
    for _,source in ipairs({preferred,"ELLESMERE","ELVUI","BLIZZARD"}) do
        if (source=="BLIZZARD" or source=="ELLESMERE" or source=="ELVUI") and not seen[source] then
            seen[source]=true;order[#order+1]=source
        end
    end
    local first,active
    for _,source in ipairs(order) do
        local candidate=self:CastBarCandidate(source,key)
        if candidate then
            if visible(candidate.frame) then return candidate end
            first=first or candidate
            if candidate.rootVisible then active=active or candidate end
        end
    end
    local candidate=active or first
    if candidate then return candidate end
    return nil,"Waiting for a cast-bar provider"
end

function A:Candidate(source,key)
    local unit = units[key]
    local frame,region,name,fit,shape,mirror
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
        if source=="ELLESMERE" then
            local side=field(field(EllesmereUI,"_ufPortraitSide"),root)
            if side=="left" then mirror=false elseif side=="right" then mirror=true end
            local mask=field(frame,"_blizzMask")
            if visible(mask) and type(mask.GetAtlas)=="function" then
                local atlas=mask:GetAtlas()
                if J.Core:IsSafe(atlas) then
                    if atlas=="UI-HUD-UnitFrame-Player-Portrait-Mask" then fit,bounds,shape=1,mask,"PLAYER"
                    elseif atlas=="CircleMask" then fit,bounds,shape=1,mask,"ROUND" end
                end
            end
        end
        if source == "ELLESMERE" and not shape and region ~= field(frame,"_3d") then
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
            source=source,portrait=true,fit=fit,shape=shape,mirror=mirror}
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
    local hidden,disabled,replacement
    for _,id in ipairs(units[key] and {"BLINKII","MMT","ELVUI","ELLESMERE"} or {"ELVUI","ELLESMERE"}) do
        local candidate = self:Candidate(id,key)
        if candidate then
            if candidate.frame and self:Visible(candidate) then return candidate,nil,true end
            hidden = hidden or (candidate.frame and candidate)
            disabled=disabled or (labels[id] .. " portrait disabled, hidden or inside health bar")
            if (id=="ELVUI" or id=="ELLESMERE") and visible(candidate.root) then replacement=true end
        end
    end
    -- A disabled/transparent provider must not block another visible portrait.
    -- An active replacement with its portrait disabled must not decorate a
    -- leftover Blizzard frame; separate portrait addons may still fall back.
    if replacement then return hidden,disabled,true end
    local native = J.Core.client:Resolve(key)
    if visible(native) then return nil,nil,false end
    if hidden then return hidden,nil,true end
    if disabled then return nil,disabled,true end
    return nil,nil,false
end

function A:Visible(anchor)
    if not visible(anchor.root) or not visible(anchor.frame) then return false end
    return not anchor.portrait or visible(anchor.region)
end

function A:Fit(key,config,snapshot)
    if not snapshot.portraitFit then return end
    self:Layer(key,config,snapshot.providerStrata,snapshot.providerLevel)
    local defaults = J.ThemeManager.registry[J.ProfileManager.current.theme][key]
    -- Register the artwork's actual opening, not its off-center canvas. Round
    -- atlases have center (154,148), radius 58 in a 256-square half-atlas.
    local diameter = math.max(snapshot.w,snapshot.h) * snapshot.portraitFit
    local opening=snapshot.portraitShape=="PLAYER" and 60 or 58
    config.width,config.height = config.width*diameter/opening,config.height*diameter/opening
    config.roundPortrait = snapshot.portraitShape~="PLAYER"
    config.portraitAtlasUnit=config.roundPortrait and "target" or "player"
    if snapshot.portraitMirror~=nil then config.mirror=snapshot.portraitMirror end
    local cx = config.mirror and 102 or 154
    local dx = (128-cx)/256 * config.width * config.scale
    local dy = (148-128)/256 * config.height * config.scale
    config.x,config.y = config.x-defaults.x+dx,config.y-defaults.y+dy
    config.point,config.relativePoint = "CENTER","CENTER"
end

-- Default artwork must clear Ellesmere's opaque panel while staying below its
-- bars/portrait. Explicit user strata and level settings remain authoritative.
function A:Layer(key,config,strata,level)
    local overrides=J.ProfileManager.current.modules[key] or {}
    if overrides.strata==nil and J.Core:IsSafe(strata) and J.Core.properties.strata[strata] then config.strata=strata end
    if overrides.level==nil and J.Core:IsNumber(level) then config.level=math.max(0,level) end
end


-- Full shells select their provider separately from portrait-only addons.
function A:UnitBars(key,source)
    local unit=units[key]
    if not unit then return end
    source=source or "AUTO"
    local root=source~="BLIZZARD" and _G["EllesmereUIUnitFrames_"..titles[unit]]
    local native=J.Core.client:Resolve(key)
    if source=="ELLESMERE" or (J.Core:IsUsableFrame(root) and (visible(root) or not visible(native))) then
        if not J.Core:IsUsableFrame(root) then return nil,"Waiting for EllesmereUI unit frames" end
        local bars={root=root,source="ELLESMERE",name="EllesmereUI"}
        for kind,member in pairs({health="Health",power="Power"}) do
            local bar=field(root,member)
            if J.Core:IsUsableFrame(bar) and type(bar.GetStatusBarTexture)=="function" then bars[kind]=bar end
        end
        if not bars.health then return nil,"Waiting for EllesmereUI health bar" end
        return bars
    end
    local bars=J.Core.client:UnitBars(key)
    if bars then bars.root,bars.source,bars.name=native,"BLIZZARD","Blizzard" end
    return bars,"Waiting for Blizzard health / power bars"
end
