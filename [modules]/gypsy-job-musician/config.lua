Config = {}

-- ====================================================================================
--                              НАСТРОЙКИ ВЫСТУПЛЕНИЯ
-- ====================================================================================

Config.Performance = {
    DurationMinutes = 2,        -- Длительность выступления (минуты)
    TipInterval = 15,           -- Чаевые каждые X секунд
    MinTip = 5,                 -- Минимум чаевых
    MaxTip = 30,                -- Максимум чаевых
    TipInterval = 15,           -- Чаевые каждые X секунд
    MinTip = 5,                 -- Минимум чаевых
    MaxTip = 30,                -- Максимум чаевых
    CooldownMinutes = 30        -- Откат после выступления (минуты)
}

-- Модель микрофонной стойки (маркер работы)
Config.MicProp = "prop_speaker_03"
Config.PropHeadingOffset = 180.0 -- Смещение поворота пропа (если он смотрит не туда)

-- ====================================================================================
--                              ЛОКАЦИИ ВЫСТУПЛЕНИЙ
-- ====================================================================================

Config.Locations = {
    -- Vespucci Beach (прямо на песке у променада)
    {
        coords = vector3(-1325.78, -1308.48, 4.84),
        heading = 110.0,   -- Направление взгляда (градусы)
        label = "Vespucci Beach",
        multiplier = 1.5,  -- +50% чаевых (туристы)
        blip = {
            sprite = 136,
            color = 27,
            scale = 0.7
        }
    },
    
    -- Del Perro Beach (Ликерный магазин)
    {
        coords = vector3(-1230.32, -903.74, 12.15),
        heading = 35.0,
        label = "Del Perro Pier",
        multiplier = 1.4,  -- +40% чаевых
        blip = {
            sprite = 136,
            color = 27,
            scale = 0.7
        }
    },
    
    -- Legion Square (центр города, у фонтана)
    {
        coords = vector3(222.15, -959.27, 29.28),
        heading = 320.0,
        label = "Legion Square",
        multiplier = 1.0,  -- Обычные чаевые
        blip = {
            sprite = 136,
            color = 27,
            scale = 0.7
        }
    }
}

-- ====================================================================================
--                              ИНСТРУМЕНТЫ
-- ====================================================================================

Config.Instruments = {
    guitar = {
        label = "Гитара",
        prop = "prop_acc_guitar_01",
        animDict = "amb@world_human_musician@guitar@male@base",
        animName = "base",
        boneIndex = 60309,
        offset = vector3(0.0, 0.0, 0.0),
        rotation = vector3(0.0, 0.0, 0.0)
    },
    
    drums = {
        label = "Барабаны",
        prop = "prop_bongos_01",  -- Бонги (маленькие барабаны)
        animDict = "amb@world_human_musician@bongos@male@base",
        animName = "base",
        boneIndex = 60309,
        offset = vector3(0.0, 0.0, 0.0),
        rotation = vector3(0.0, 0.0, 0.0)
    },
    
    violin = {
        label = "Скрипка",
        prop = "prop_acc_guitar_01",  -- Используем гитару как замену (нет модели скрипки)
        animDict = "amb@world_human_musician@violin@male@base",
        animName = "base",
        boneIndex = 60309,
        offset = vector3(0.0, 0.0, 0.0),
        rotation = vector3(0.0, 0.0, 0.0)
    }
}

-- Инструмент по умолчанию (если не выбран)
Config.DefaultInstrument = "guitar"
