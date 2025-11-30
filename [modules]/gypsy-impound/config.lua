Config = {}

Config.ImpoundLocation = {
    coords = vector3(409.0, -1623.0, 29.3), -- Near Police Station
    heading = 230.0,
    blip = {
        sprite = 67,
        color = 47, -- Orange
        scale = 0.8,
        label = 'Штрафплощадка'
    }
}

Config.SpawnPoint = {
    coords = vector3(405.0, -1632.0, 29.3), -- Adjusted to be on the road/clear area
    heading = 230.0
}

-- Time in milliseconds before a vehicle on the street is auto-impounded
Config.AutoImpoundTime = 30 * 60 * 1000 -- 30 minutes

-- Default fee if not set
Config.DefaultFee = 500

-- Distance to interact with impound NPC/Marker
Config.InteractDistance = 2.0
