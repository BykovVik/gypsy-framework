Config = {}

-- ATM Locations (только снятие/внесение наличных)
Config.ATMLocations = {
    -- Downtown Los Santos
    vector3(147.4, -1035.8, 29.3),
    vector3(-1212.98, -330.84, 37.79),
    vector3(-2962.71, 482.93, 15.7),
    vector3(-112.22, 6469.3, 31.63),
    vector3(1175.07, 2706.64, 38.09),
    
    -- Sandy Shores
    vector3(1686.75, 4815.8, 42.01),
    
    -- Paleto Bay
    vector3(-386.73, 6045.95, 31.5),
}

-- Bank Locations (полный функционал + вклады)
Config.BankLocations = {
    -- Fleeca Bank - Legion Square
    vector3(149.46, -1040.54, 29.37),
    
    -- Fleeca Bank - Hawick Ave
    vector3(-1212.26, -330.76, 37.79),
    
    -- Fleeca Bank - Del Perro
    vector3(-2962.47, 482.63, 15.70),
    
    -- Fleeca Bank - Great Ocean Highway
    vector3(-112.81, 6469.91, 31.63),
    
    -- Fleeca Bank - Route 68
    vector3(1175.74, 2706.80, 38.09),
    
    -- Fleeca Bank - Paleto Bay
    vector3(-386.84, 6046.41, 31.50),
    
    -- Pacific Standard Bank (центральный)
    vector3(241.73, 227.65, 106.29),
}

-- Interest Settings
Config.InterestRate = 0.5 -- 0.5% в день (только онлайн время)
Config.InterestInterval = 3600000 -- 1 час в миллисекундах

-- Savings Account Settings
Config.MinimumDeposit = 100 -- Минимальный депозит
Config.MaximumBalance = 10000000 -- Максимальный баланс на счету

-- Interaction Settings
Config.ATMModel = `prop_atm_01` -- Модель банкомата
Config.InteractionDistance = 2.0 -- Дистанция взаимодействия
Config.BankInteractionDistance = 3.0 -- Дистанция для банков (больше, так как здание)
