local _, J = ...
local module = { key = "targetFrame" }

function module:Create()
    -- No secure template, no Blizzard children, no input handlers.
    local frame = CreateFrame("Frame","JiberishUITargetArtwork",UIParent)
    frame:EnableMouse(false)
    local texture = frame:CreateTexture(nil,"BACKGROUND")
    local crest = frame:CreateTexture(nil,"BACKGROUND",nil,1)
    J.Core:FinishCreate(self,frame,texture,crest)
end

J.Core:RegisterModule(module)
