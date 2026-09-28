local _, J = ...
local module = { key = "minimap" }

function module:Create()
    -- No secure template, no Blizzard children, no input handlers.
    local frame = CreateFrame("Frame","JiberishUIMinimapArtwork",UIParent)
    if frame.SetFixedFrameStrata then frame:SetFixedFrameStrata(true) end
    if frame.SetFixedFrameLevel then frame:SetFixedFrameLevel(true) end
    frame:EnableMouse(false)
    local textures = {}
    for name in pairs(J.ThemeManager:Resolve(self.key).pieces or {main=true}) do
        textures[name] = frame:CreateTexture(nil,"BACKGROUND")
    end
    J.Core:FinishCreate(self,frame,textures)
end

J.Core:RegisterModule(module)
