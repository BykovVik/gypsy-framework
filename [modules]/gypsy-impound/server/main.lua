local Gypsy = exports['gypsy-core']:GetCoreObject()

-- ====================================================================================
--                              HELPER FUNCTIONS
-- ====================================================================================

local function Notify(source, message, type, duration)
    TriggerClientEvent('gypsy-notifications:client:notify', source, {
        message = message,
        type = type or 'info',
        duration = duration or 3000
    })
end

local function GetCitizenId(source, callback)
    local identifiers = GetPlayerIdentifiers(source)
    local license = identifiers and identifiers[1]
    
    if not license then return end
    
    exports.oxmysql:execute('SELECT citizenid FROM players WHERE license = ?', {license}, function(result)
        if result and result[1] then
            callback(result[1].citizenid)
        end
    end)
end

-- ====================================================================================
--                              AUTO IMPOUND LOGIC
-- ====================================================================================

local function CheckLostVehicles()
    print('^3[Impound] Running auto-impound check...^0')
    
    -- 1. Get all vehicles marked as "Out" (state = 0)
    exports.oxmysql:execute('SELECT plate FROM gypsy_vehicles WHERE state = 0', {}, function(dbVehicles)
        if not dbVehicles or #dbVehicles == 0 then return end
        
        -- 2. Get all active vehicles in the world
        local allVehicles = GetAllVehicles()
        local activePlates = {}
        
        for _, veh in ipairs(allVehicles) do
            local plate = GetVehicleNumberPlateText(veh)
            if plate then
                plate = string.gsub(plate, "^%s*(.-)%s*$", "%1") -- Trim whitespace
                activePlates[plate] = true
            end
        end
        
        -- 3. Compare and Impound
        local impoundedCount = 0
        for _, dbVeh in ipairs(dbVehicles) do
            local plate = dbVeh.plate
            if not activePlates[plate] then
                -- Vehicle is marked as OUT but does not exist in the world -> Impound it
                local GarageService = exports['gypsy-core']:GetService('Garage')
                if GarageService then
                    GarageService.ImpoundVehicle(plate, Config.DefaultFee)
                    impoundedCount = impoundedCount + 1
                    print('^3[Impound] Auto-impounded lost vehicle: ' .. plate .. '^0')
                end
            end
        end
        
        if impoundedCount > 0 then
            print('^2[Impound] Auto-impound complete. ' .. impoundedCount .. ' vehicles sent to impound.^0')
        end
    end)
end

-- Start Auto-Impound Loop
CreateThread(function()
    Wait(5000) -- Initial wait
    while true do
        CheckLostVehicles()
        Wait(Config.AutoImpoundTime)
    end
end)

-- ====================================================================================
--                              EVENTS
-- ====================================================================================

-- Get Impounded Vehicles
RegisterNetEvent('gypsy-impound:server:getVehicles', function()
    local src = source
    GetCitizenId(src, function(citizenid)
        local GarageService = exports['gypsy-core']:GetService('Garage')
        if GarageService then
            local vehicles = GarageService.GetVehiclesByState(citizenid, 2) -- State 2 = Impounded
            TriggerClientEvent('gypsy-impound:client:openMenu', src, vehicles)
        else
            Notify(src, 'Сервис гаража недоступен', 'error')
        end
    end)
end)

-- Retrieve Vehicle (Pay Fee)
RegisterNetEvent('gypsy-impound:server:retrieveVehicle', function(plate)
    local src = source
    
    GetCitizenId(src, function(citizenid)
        exports.oxmysql:execute('SELECT * FROM gypsy_vehicles WHERE plate = ? AND citizenid = ?', {plate, citizenid}, function(result)
            if not result or not result[1] then
                Notify(src, 'Транспорт не найден', 'error')
                return
            end
            
            local vehicle = result[1]
            local fee = vehicle.impound_fee or Config.DefaultFee
            local Player = Gypsy.Functions.GetPlayer(src)
            
            if not Player then return end
            
            local cash = Player.Functions.GetMoney('cash')
            local bank = Player.Functions.GetMoney('bank')
            
            if cash >= fee then
                Player.Functions.RemoveMoney('cash', fee, 'impound-fee')
            elseif bank >= fee then
                Player.Functions.RemoveMoney('bank', fee, 'impound-fee')
            else
                Notify(src, 'Недостаточно средств. Штраф: $' .. fee, 'error')
                return
            end
            
            -- Success
            local GarageService = exports['gypsy-core']:GetService('Garage')
            if GarageService then
                -- Set state to 0 (Out) because we are about to spawn it
                GarageService.SetVehicleState(plate, 0, 0)
                
                TriggerClientEvent('gypsy-impound:client:spawnVehicle', src, vehicle)
                Notify(src, 'Штраф оплачен. Транспорт выдан.', 'success')
            end
        end)
    end)
end)

-- ====================================================================================
--                              COMMANDS
-- ====================================================================================

-- Admin Command: /impound [plate]
RegisterCommand('impound', function(source, args)
    local src = source
    
    -- TODO: Add permission check here (e.g. IsPlayerAceAllowed)
    
    local plate = args[1]
    if not plate then
        Notify(src, 'Использование: /impound [номер]', 'info')
        return
    end
    
    plate = string.upper(plate)
    
    local GarageService = exports['gypsy-core']:GetService('Garage')
    if GarageService then
        GarageService.ImpoundVehicle(plate, Config.DefaultFee)
        Notify(src, 'Транспорт ' .. plate .. ' отправлен на штрафплощадку', 'success')
    else
        Notify(src, 'Сервис гаража недоступен', 'error')
    end
end, false) -- Set to true for admin only in production
