local _, J = ...

-- Sculpted RGBA test assets; the RGB design references are never packaged.
J.Media = {
    setupInGame = "Interface\\AddOns\\Frostforge\\Media\\Setup\\setup-ingame",
    setupSettings = "Interface\\AddOns\\Frostforge\\Media\\Setup\\setup-settings",
    logo = "Interface\\AddOns\\Frostforge\\Media\\Branding\\frostforge-logo",
    panelStone = "Interface\\AddOns\\Frostforge\\Media\\Branding\\frostforge-stone",
    minimap = "Interface\\AddOns\\Frostforge\\Media\\Minimaps\\class_paladin",
    hub = "Interface\\AddOns\\Frostforge\\Media\\Hubs\\class_paladin",
    -- All health variants contain this same grayscale stone. Reuse the active
    -- asset rather than distributing another copy for SharedMedia consumers.
    stone = "Interface\\AddOns\\Frostforge\\Media\\UnitFrames\\class_paladin-health",
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
