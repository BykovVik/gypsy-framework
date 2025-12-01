Config = {}

-- ====================================================================================
--                              ЛОКАЦИИ
-- ====================================================================================

-- Компания кабельного ТВ (промзона La Mesa)
Config.Company = {
    coords = vector3(883.5, -40.0, 78.8),  -- La Mesa industrial area
    heading = 240.0,
    blip = {
        sprite = 521,  -- TV icon
        color = 3,     -- Blue
        scale = 0.8,
        label = "Cable TV Company"
    }
}

-- База (та же точка)
Config.Base = {
    coords = vector3(883.5, -40.0, 78.8),
    heading = 240.0
}

-- ====================================================================================
--                              ТРАНСПОРТ
-- ====================================================================================

Config.VehicleSpawn = {
    coords = vector3(890.0, -45.0, 78.8),
    heading = 240.0,
    model = 'burrito'  -- Модель фургона (можно: burrito, speedo, rumpo)
}

-- ====================================================================================
--                              НАСТРОЙКИ РАБОТЫ
-- ====================================================================================

Config.Job = {
    MaxVehicles = 3,           -- Максимум фургонов одновременно
    InstallsPerShift = 5,      -- Установок за смену
    CooldownMinutes = 30,      -- Откат после смены (в минутах)
    InstallTimeout = 10 * 60,  -- Таймаут установки 10 минут (в секундах)
    SkillCheckCount = 3,       -- Количество skill checks
    SkillCheckDifficulty = 3   -- Сложность (1-5)
}

Config.Payment = {
    BaseRate = 0.5,            -- $0.5 за метр
    SuccessMultipliers = {
        [3] = 1.5,             -- 3/3 успешных = +50%
        [2] = 1.2,             -- 2/3 успешных = +20%
        [1] = 1.0,             -- 1/3 успешных = базовая
        [0] = 0.5              -- 0/3 успешных = -50%
    },
    VehicleDestroyFine = 500
}

-- ====================================================================================
--                              ТОЧКИ УСТАНОВКИ
-- ====================================================================================
-- Доступные улицы, парковки, крыши с лестницами (НЕ закрытые здания!)

Config.InstallPoints = {
    -- Downtown (улицы, парковки)
    {coords = vector3(129.0, -1298.0, 29.2), label = "Strawberry Ave"},
    {coords = vector3(-58.0, -1098.0, 26.4), label = "Integrity Way"},
    {coords = vector3(240.0, -880.0, 30.5), label = "Legion Square"},
    {coords = vector3(145.0, -1035.0, 29.3), label = "Pillbox Parking"},
    
    -- Vinewood (улицы)
    {coords = vector3(374.0, 328.0, 103.6), label = "Vinewood Blvd"},
    {coords = vector3(285.0, 177.0, 104.4), label = "Vinewood Hills"},
    {coords = vector3(-60.0, 361.0, 113.1), label = "West Vinewood"},
    
    -- Vespucci (набережная, парковки)
    {coords = vector3(-1183.0, -1561.0, 4.4), label = "Vespucci Beach"},
    {coords = vector3(-1304.37, -1261.37, 4.6), label = "Beach Parking"}, --исправлено
    {coords = vector3(-1457.0, -503.0, 32.8), label = "Del Perro"},
    
    -- Grove Street / Davis
    {coords = vector3(114.0, -1961.0, 20.8), label = "Grove Street"},
    {coords = vector3(-47.0, -1757.0, 29.4), label = "Davis Ave"},
    {coords = vector3(23.0, -1897.0, 23.0), label = "Davis Parking"},
    
    -- Mirror Park
    {coords = vector3(1163.0, -324.0, 69.2), label = "Mirror Park Dr"},
    {coords = vector3(1029.0, -763.0, 58.0), label = "East Vinewood"},
    {coords = vector3(850.0, -533.0, 57.9), label = "Mirror Park Ave"},
    
    -- Rockford Hills
    {coords = vector3(-1289.0, -1115.0, 7.0), label = "Rockford Dr"},
    {coords = vector3(-801.0, -1185.0, 10.3), label = "Portola Dr"},
    {coords = vector3(-1306.0, -394.0, 36.7), label = "Rockford Plaza"},
    
    -- Sandy Shores
    {coords = vector3(1961.0, 3740.0, 32.3), label = "Sandy Shores Main"},
    {coords = vector3(1698.0, 3597.0, 35.6), label = "Sandy Blvd"}
}

-- Названия каналов для мини-игры (80-е стиль!)
Config.ChannelNames = {
    "MTV",
    "CNN",
    "ESPN",
    "HBO",
    "Showtime",
    "Nickelodeon",
    "Discovery",
    "Comedy Central",
    "USA Network"
}
