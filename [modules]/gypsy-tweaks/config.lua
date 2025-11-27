Config = {}

-- Physics & Damage
Config.Physics = {
    MeleeForceMultiplier = 0.4, -- 0.0 to 1.0. Lower = less knockback from punches.
    VehicleDamageMultiplier = 0.5, -- 0.0 to 1.0. Lower = tougher cars (80s steel!).
    DisableRagdollOnCollision = true, -- If true, players won't fall over from small bumps.
    WeaponDamageMultiplier = 0.8, -- Global damage multiplier for weapons (longer gunfights).
}

-- Atmosphere & Density
Config.Atmosphere = {
    TrafficDensity = 0.4, -- 0.0 to 1.0. 
    PedDensity = 0.5, -- 0.0 to 1.0.
    ParkedCarDensity = 0.6, -- 0.0 to 1.0.
    EnableTimecycle = true, -- Enable visual color grading?
    TimecycleModifier = "yell_tunnel_nodirect", -- A warm, slightly gritty look. Try also: "rply_saturation", "cinema".
}

-- Player Mechanics
Config.Player = {
    DisableAutoRegen = true, -- If true, health won't regenerate automatically.
    InfiniteStamina = false, -- If true, player can run forever.
    WeaponRecoilMultiplier = 1.2, -- Higher = more recoil.
    HeadshotOneTap = false, -- If false, headshots act like normal body shots (for RPG balance).
}
