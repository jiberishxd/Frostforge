local _, J = ...
local module = { key = "actionHub" }

function module:Create()
    -- No secure template, no Blizzard children, no input handlers.
    local frame = CreateFrame("Frame","JiberishUIActionHubArtwork",UIParent)
    frame:EnableMouse(false)
    local textures = {}
    for name in pairs(J.ThemeManager:Resolve(self.key).pieces or {main=true}) do
        textures[name] = frame:CreateTexture(nil,"BACKGROUND")
    end
    J.Core:FinishCreate(self,frame,textures)
end

J.Core:RegisterModule(module)
