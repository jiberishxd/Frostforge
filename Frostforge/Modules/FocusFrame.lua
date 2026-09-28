local _, J = ...
local module = { key = "focusFrame" }

function module:Create()
    local frame = CreateFrame("Frame","JiberishUIFocusArtwork",UIParent)
    frame:EnableMouse(false)
    local textures = {main=frame:CreateTexture(nil,"BACKGROUND")}
    J.Core:FinishCreate(self,frame,textures)
end

J.Core:RegisterModule(module)
