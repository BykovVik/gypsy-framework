Config = {}

-- ============================================================================
-- SPAWN POINTS
-- ============================================================================
-- 6 tested spawn locations across Los Santos
-- ============================================================================

Config.SpawnPoints = {
    {
        name = "Legion Square",
        hint = "центр города",
        description = "Downtown Los Santos - Legion Square",
        coords = { x = 195.17, y = -933.77, z = 30.69, w = 144.5 }
    },
    {
        name = "Motel",
        hint = "мотель",
        description = "Pink Cage Motel",
        coords = { x = 327.56, y = -205.08, z = 54.09, w = 163.5 }
    },
    {
        name = "Grove Street",
        hint = "гетто",
        description = "Grove Street - The Hood",
        coords = { x = -48.58, y = -1792.35, z = 27.83, w = 48.5 }
    },
    {
        name = "Sandy Shores",
        hint = "пустыня",
        description = "Sandy Shores Airfield",
        coords = { x = 1836.91, y = 3686.85, z = 34.27, w = 298.5 }
    },
    {
        name = "Paleto Bay",
        hint = "север",
        description = "Paleto Bay - Northern Town",
        coords = { x = -105.72, y = 6470.18, z = 31.63, w = 42.5 }
    },
    {
        name = "Beach",
        hint = "пляж",
        description = "Vespucci Beach",
        coords = { x = -1044.73, y = -2749.13, z = 21.36, w = 329.5 }
    }
}

-- ============================================================================
-- CHARACTER SETTINGS
-- ============================================================================

Config.MaxCharacters = 3

Config.DefaultMoney = {
    cash = 5000,
    bank = 25000
}

Config.DefaultJob = {
    name = 'unemployed',
    label = 'Unemployed',
    grade = 0
}

-- ============================================================================
-- CAMERA SETTINGS
-- ============================================================================
-- Camera and ped positions for character preview
-- ============================================================================

Config.CameraCoords = { x = 402.92, y = -996.88, z = -99.00, w = 180.0 }
Config.PedCoords = { x = 402.92, y = -1000.5, z = -99.00, w = 180.0 }
