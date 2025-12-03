Config = {}

-- ====================================================================================
--                              ЛОКАЦИИ
-- ====================================================================================

-- Компания кабельного ТВ (Спутниковые антены возле Yellow Jack)
Config.Company = {
    coords = vector3(2064.91, 2954.41, 46.93),  -- Yellow Jack area
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
    coords = vector3(2063.50, 2954.43, 47.05),
    heading = 240.0
}

-- NPC для выдачи работы
Config.NPC = {
    model = "s_m_y_construct_01", -- Рабочий в комбинезоне
    coords = vector3(2063.50, 2954.43, 47.05),
    heading = 272.28
}

-- ====================================================================================
--                              ТРАНСПОРТ
-- ====================================================================================

Config.VehicleSpawn = {
    coords = vector3(2068.08, 2938.48, 47.29),
    heading = 240.0,
    model = 'burrito'  -- Модель фургона (можно: burrito, speedo, rumpo)
}

-- ====================================================================================
--                              НАСТРОЙКИ РАБОТЫ
-- ====================================================================================

Config.Job = {
    MaxVehicles = 5,           -- Максимум фургонов одновременно
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
    {coords = vector3(-49.20, -1069.44, 27.47), label = "Integrity Way"}, --исправлено
    {coords = vector3(262.37, -770.88, 30.74), label = "Legion Square"}, --исправлено
    {coords = vector3(177.57, -1072.02, 77.54), label = "Pillbox Parking"}, --исправлено
    
    -- Vinewood (улицы)
    {coords = vector3(374.0, 328.0, 103.6), label = "Vinewood Blvd"},
    {coords = vector3(285.0, 177.0, 104.4), label = "Vinewood Hills"},
    {coords = vector3(-60.0, 361.0, 113.1), label = "West Vinewood"},
    
    -- Vespucci (набережная, парковки)
    {coords = vector3(-1129.32, -1542.52, 15.60), label = "Vespucci Beach"}, --исправлено
    {coords = vector3(-1304.37, -1261.37, 4.6), label = "Beach Parking"}, --исправлено
    {coords = vector3(-1491.67, -537.51, 32.72), label = "Del Perro"}, --исправлено
    
    -- Grove Street / Davis
    {coords = vector3(88.04, -1963.96, 20.75), label = "Grove Street"}, --исправлено
    {coords = vector3(-47.0, -1757.0, 29.4), label = "Davis Ave"},
    {coords = vector3(23.0, -1897.0, 23.0), label = "Davis Parking"},
    
    -- Mirror Park
    {coords = vector3(1163.0, -324.0, 69.2), label = "Mirror Park Dr"},
    {coords = vector3(987.59, -727.49, 57.46), label = "East Vinewood"}, --исправлено
    {coords = vector3(850.0, -533.0, 57.9), label = "Mirror Park Ave"},
    
    -- Rockford Hills
    {coords = vector3(-1289.0, -1115.0, 7.0), label = "Rockford Dr"},
    {coords = vector3(-884.23, -1141.73, 5.78), label = "Portola Dr"}, --исправлено
    {coords = vector3(-1308.61, -378.39, 43.31), label = "Rockford Plaza"},  --исправлено
    
    -- Sandy Shores
    {coords = vector3(1961.0, 3740.0, 32.3), label = "Sandy Shores Main"},
    {coords = vector3(1696.25, 3611.24, 35.32), label = "Sandy Blvd"} --исправлено
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
