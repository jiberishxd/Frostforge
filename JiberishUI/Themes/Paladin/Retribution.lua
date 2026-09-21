local _, J = ...

-- Configuration and media references only. All behavior belongs to Core/Modules.
J.ThemeManager:Register("paladin_ret", {
    name = "Retribution Paladin",
    minimap = {
        texture = J.Media.surround, crest = J.Media.crest,
        width = 240, height = 240, x = 0, y = 0, scale = 1,
        point = "CENTER", relativePoint = "CENTER",
        strata = "BACKGROUND", layer = "BACKGROUND", opacity = 1, shown = true,
        crestWidth = 155, crestHeight = 52,
    },
    playerFrame = {
        texture = J.Media.surround, crest = J.Media.crest,
        width = 270, height = 130, x = 0, y = 0, scale = 1,
        point = "CENTER", relativePoint = "CENTER",
        strata = "BACKGROUND", layer = "BACKGROUND", opacity = 1, shown = true,
        crestWidth = 144, crestHeight = 48,
    },
    targetFrame = {
        texture = J.Media.surround, crest = J.Media.crest,
        width = 270, height = 130, x = 0, y = 0, scale = 1,
        point = "CENTER", relativePoint = "CENTER",
        strata = "BACKGROUND", layer = "BACKGROUND", opacity = 1, shown = true,
        crestWidth = 144, crestHeight = 48,
    },
    actionHub = {
        texture = J.Media.hub, crest = J.Media.crest,
        width = 660, height = 150, x = 0, y = -8, scale = 1,
        point = "BOTTOM", relativePoint = "BOTTOM",
        strata = "BACKGROUND", layer = "BACKGROUND", opacity = 0.85, shown = true,
        crestWidth = 195, crestHeight = 65,
    },
})
