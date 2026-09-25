local _, J = ...

-- Configuration and media references only. All behavior belongs to Core/Modules.
-- UVs reference the original PNG proportions, retained by TGA encoding.
local hubPieces = {
    leftWing = { leftAnchor=0,rightAnchor=0,leftOffset=0,rightOffset=620*240/724,
        y=0,height=240,u1=0,u2=620/2172,v1=0,v2=1,order=2 },
    leftRail = { leftAnchor=0,rightAnchor=0.5,leftOffset=620*240/724,rightOffset=-106*240/724,
        y=0,height=240,u1=620/2172,u2=980/2172,v1=0,v2=1,order=0 },
    sun = { leftAnchor=0.5,rightAnchor=0.5,leftOffset=-106*240/724,rightOffset=124*240/724,
        y=0,height=240,u1=980/2172,u2=1210/2172,v1=0,v2=1,order=3 },
    rightRail = { leftAnchor=0.5,rightAnchor=1,leftOffset=124*240/724,rightOffset=-620*240/724,
        y=0,height=240,u1=1210/2172,u2=1552/2172,v1=0,v2=1,order=0 },
    rightWing = { leftAnchor=1,rightAnchor=1,leftOffset=-620*240/724,rightOffset=0,
        y=0,height=240,u1=1552/2172,u2=1,v1=0,v2=1,order=2 },
}
J.ThemeManager:Register("paladin_ret", {
    name = "Retribution Paladin",
    minimap = {
        minimapMode = "CLASS", minimap = "CLASS_PALADIN",
        texture = J.MinimapCatalog.entries.CLASS_PALADIN.texture,
        width = 340, height = 340, x = 0, y = 0, scale = 1,
        anchor = "FRAME", point = "CENTER", relativePoint = "CENTER",
        strata = "BACKGROUND", level = 0, layer = "BACKGROUND", opacity = 1, shown = true,
    },
    playerFrame = {
        blizzardStone = true,
        texture = J.PortraitCatalog.entries.CLASS_PALADIN.texture,
        unit = "player", portraitMode = "CLASS", portrait = "CLASS_PALADIN", unitFrameShown = false, unitFrameFill = "AUTO", unitFrameWidth = 100, unitFrameHeight = 100, unitFrameInset = 3, unitFrameSource = "AUTO", portraitSource = "AUTO",
        castBarShown = false, castBarSource = "AUTO", castBarStyle = "CAPPED", castBarArt = "MATCH", castBarWeight = 1, castBarPadding = 1, castBarWidth = 100, castBarHeight = 100, castBarStrata = "AUTO", unitFrameStrata = "AUTO",
        blizzardPortraitHidden = false, blizzardNameEnabled = false, blizzardNameX = 0, blizzardNameY = 0, blizzardNameSize = 12, blizzardNameAlign = "CENTER", blizzardNameOutline = "KEEP",
        width = 128, height = 128, x = -23, y = 11, scale = 1,
        anchor = "FRAME", point = "LEFT", relativePoint = "LEFT",
        strata = "BACKGROUND", level = 0, layer = "BACKGROUND", opacity = 1, shown = true,
    },
    targetFrame = {
        texture = J.PortraitCatalog.entries.CLASS_PALADIN.texture, mirror = true,
        unit = "target", portraitMode = "CLASS", portrait = "CLASS_PALADIN", unitFrameShown = false, unitFrameFill = "AUTO", unitFrameWidth = 100, unitFrameHeight = 100, unitFrameInset = 3, unitFrameSource = "AUTO", portraitSource = "AUTO",
        castBarShown = false, castBarSource = "AUTO", castBarStyle = "CAPPED", castBarArt = "MATCH", castBarWeight = 1, castBarPadding = 1, castBarWidth = 100, castBarHeight = 100, castBarStrata = "AUTO", unitFrameStrata = "AUTO",
        blizzardPortraitHidden = false, blizzardNameEnabled = false, blizzardNameX = 0, blizzardNameY = 0, blizzardNameSize = 12, blizzardNameAlign = "CENTER", blizzardNameOutline = "KEEP",
        width = 128, height = 128, x = 22, y = 12, scale = 1,
        anchor = "FRAME", point = "RIGHT", relativePoint = "RIGHT",
        strata = "BACKGROUND", level = 0, layer = "BACKGROUND", opacity = 1, shown = true,
    },
    focusFrame = {
        texture = J.PortraitCatalog.entries.CLASS_PALADIN.texture, mirror = true,
        unit = "focus", portraitMode = "CLASS", portrait = "CLASS_PALADIN", unitFrameShown = false, unitFrameFill = "AUTO", unitFrameWidth = 100, unitFrameHeight = 100, unitFrameInset = 3, unitFrameSource = "AUTO", portraitSource = "AUTO",
        castBarShown = false, castBarSource = "AUTO", castBarStyle = "CAPPED", castBarArt = "MATCH", castBarWeight = 1, castBarPadding = 1, castBarWidth = 100, castBarHeight = 100, castBarStrata = "AUTO", unitFrameStrata = "AUTO",
        blizzardPortraitHidden = false, blizzardNameEnabled = false, blizzardNameX = 0, blizzardNameY = 0, blizzardNameSize = 12, blizzardNameAlign = "CENTER", blizzardNameOutline = "KEEP",
        width = 128, height = 128, x = 22, y = 12, scale = 1,
        anchor = "FRAME", point = "RIGHT", relativePoint = "RIGHT",
        strata = "BACKGROUND", level = 0, layer = "BACKGROUND", opacity = 1, shown = true,
    },
    actionHub = {
        hubMode = "CLASS", hub = "CLASS_PALADIN", hubSource = "AUTO",
        texture = J.Media.hub,
        width = 1480, height = 240, x = 0, y = -14, scale = 1,
        anchor = "SCREEN", point = "BOTTOM", relativePoint = "BOTTOM",
        pieces = hubPieces, designHeight = 240, minimumWidth = 600,
        strata = "BACKGROUND", level = 0, layer = "BACKGROUND", opacity = 1, shown = true,
    },
})
