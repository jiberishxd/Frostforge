local _, J = ...

-- Sculpted RGBA test assets; the RGB design references are never packaged.
J.Media = {
    logo = "Interface\\AddOns\\JiberishUI\\Media\\Branding\\frostforge-logo.tga",
    panelStone = "Interface\\AddOns\\JiberishUI\\Media\\Branding\\frostforge-stone.tga",
    minimap = "Interface\\AddOns\\JiberishUI\\Media\\Minimaps\\class_paladin.tga",
    hub = "Interface\\AddOns\\JiberishUI\\Media\\Hubs\\class_paladin.tga",
    -- All health variants contain this same grayscale stone. Reuse the active
    -- asset rather than distributing another copy for SharedMedia consumers.
    stone = "Interface\\AddOns\\JiberishUI\\Media\\UnitFrames\\class_paladin-health.tga",
}

function J.Media:RegisterShared()
    if not LibStub then return false end
    local ok, library = pcall(function() return LibStub("LibSharedMedia-3.0", true) end)
    if not ok or not library or type(library.Register) ~= "function" then return false end
    if self.sharedLibrary == library then return true end
    -- Preserve the old name so texture selections in other addons still load.
    for _, name in ipairs({"Frostforge Stone", "JiberishUI Stone"}) do
        local registered, result = pcall(library.Register, library, "statusbar", name, self.stone)
        if not registered or not result then return false end
    end
    self.sharedLibrary = library
    return true
end
