local Gypsy = exports['gypsy-core']:GetCoreObject()

-- ====================================================================================
--                              GARAGE SERVICE
-- ====================================================================================

local GarageService = {
    version = '1.0.0',
    
    --- Получает список машин игрока
    GetVehicles = function(source, garage)
        local identifiers = GetPlayerIdentifiers(source)
        local license = identifiers and identifiers[1]
        
        if not license then return {} end
        
        -- Промис для асинхронного получения
        local promise = promise.new()
        
        exports.oxmysql:execute('SELECT citizenid FROM players WHERE license = ?', {license}, function(playerResult)
            if not playerResult or not playerResult[1] then
                promise:resolve({})
                return
            end
            
            local citizenid = playerResult[1].citizenid
            
            exports.oxmysql:execute('SELECT * FROM gypsy_vehicles WHERE citizenid = ? AND garage = ?', {citizenid, garage}, function(result)
                promise:resolve(result or {})
            end)
        end)
        
        return Citizen.Await(promise)
    end,
    
    --- Спавнит машину
    SpawnVehicle = function(source, plate)
        -- Логика уже реализована в RegisterNetEvent
        TriggerEvent('gypsy-garage:server:spawnVehicle', source, plate)
        return true
    end,
    
    --- Паркует машину
    ParkVehicle = function(source, plate, mods)
        -- Логика уже реализована в RegisterNetEvent
        TriggerEvent('gypsy-garage:server:parkVehicle', source, plate, mods)
        return true
    end,
    
    --- Конфискует машину
    ImpoundVehicle = function(source, plate)
        exports.oxmysql:execute('UPDATE gypsy_vehicles SET state = 1 WHERE plate = ?', {plate})
        exports['gypsy-core']:Emit('garage:vehicleImpounded', source, plate)
        return true
    end
}

-- Регистрируем сервис в ServiceLocator
CreateThread(function()
    Wait(1000) -- Ждем загрузки Core
    exports['gypsy-core']:RegisterService('Garage', GarageService, {
        version = '1.0.0',
        description = 'Gypsy Garage System'
    })
    print('^2[Garage] Service registered in ServiceLocator^0')
end)

-- Initialize DB
CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `gypsy_vehicles` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) DEFAULT NULL,
            `vehicle` varchar(50) DEFAULT NULL,
            `hash` varchar(50) DEFAULT NULL,
            `mods` longtext DEFAULT NULL,
            `plate` varchar(15) NOT NULL,
            `garage` varchar(50) DEFAULT 'legion',
            `state` int(11) DEFAULT 1,
            PRIMARY KEY (`id`),
            KEY `plate` (`plate`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- Get Player Vehicles
RegisterNetEvent('gypsy-garage:server:getMyVehicles', function(garage)
    local src = source
    
    
    -- Get player's license directly
    local identifiers = GetPlayerIdentifiers(src)
    local license = identifiers and identifiers[1]
    
    if not license then
        
        return
    end
    
    
    
    -- First, get the citizenid from the license
    exports.oxmysql:execute('SELECT citizenid FROM players WHERE license = ?', {license}, function(playerResult)
        if not playerResult or not playerResult[1] then
            
            return
        end
        
        local citizenid = playerResult[1].citizenid
        
        
        -- Now get their vehicles
        exports.oxmysql:execute('SELECT * FROM gypsy_vehicles WHERE citizenid = ? AND garage = ?', {citizenid, garage}, function(result)
            
            TriggerClientEvent('gypsy-garage:client:openMenu', src, result)
        end)
    end)
end)

-- Spawn Vehicle
-- Spawn Vehicle
RegisterNetEvent('gypsy-garage:server:spawnVehicle', function(plate)
    local src = source
    
    
    -- Get player's license directly
    local identifiers = GetPlayerIdentifiers(src)
    local license = identifiers and identifiers[1]
    
    if not license then
        
        return
    end
    
    -- Get citizenid from DB
    exports.oxmysql:execute('SELECT citizenid FROM players WHERE license = ?', {license}, function(playerResult)
        if not playerResult or not playerResult[1] then
            
            return
        end
        
        local citizenid = playerResult[1].citizenid
        
        
        exports.oxmysql:execute('SELECT * FROM gypsy_vehicles WHERE plate = ? AND citizenid = ?', {plate, citizenid}, function(result)
            if result and result[1] then
                local vehData = result[1]
                
                if vehData.state == 1 then -- In Garage
                    -- Update state to Out
                    if vehData.mods then
                        local props = json.decode(vehData.mods)
                        
                    end
                    exports.oxmysql:execute('UPDATE gypsy_vehicles SET state = 0 WHERE plate = ?', {plate})
                    TriggerClientEvent('gypsy-garage:client:spawnVehicleCallback', src, vehData)
                    
                    -- Emit событие через EventBus
                    exports['gypsy-core']:Emit('garage:vehicleSpawned', src, plate, vehData)
                else
                    TriggerClientEvent('chat:addMessage', src, {args = {'Garage', 'Vehicle is not in the garage (State: '..vehData.state..')'}})
                end
            else
                TriggerClientEvent('chat:addMessage', src, {args = {'Garage', 'Vehicle not found.'}})
            end
        end)
    end)
end)

-- Admin Command to clear all vehicles (for testing cleanup)
-- Removed as per cleanup request

-- Park Vehicle
RegisterNetEvent('gypsy-garage:server:parkVehicle', function(plate, mods)
    local src = source
    
    -- Get player's license directly
    local identifiers = GetPlayerIdentifiers(src)
    local license = identifiers and identifiers[1]
    
    if not license then
        return
    end
    
    -- Get citizenid from DB
    exports.oxmysql:execute('SELECT citizenid FROM players WHERE license = ?', {license}, function(playerResult)
        if not playerResult or not playerResult[1] then
            TriggerClientEvent('chat:addMessage', src, {args = {'Garage', 'Error: Player data not found.'}})
            return
        end
        
        local citizenid = playerResult[1].citizenid
        
        -- Check vehicle
        exports.oxmysql:execute('SELECT * FROM gypsy_vehicles WHERE plate = ?', {plate}, function(result)
            if result and result[1] then
                if result[1].citizenid == citizenid then
                    
                    exports.oxmysql:execute('UPDATE gypsy_vehicles SET state = 1, mods = ? WHERE plate = ?', {json.encode(mods), plate}, function()
                        TriggerClientEvent('gypsy-garage:client:parkSuccess', src)
                        TriggerClientEvent('chat:addMessage', src, {args = {'Garage', 'Vehicle Parked.'}})
                        
                        -- Emit событие через EventBus
                        exports['gypsy-core']:Emit('garage:vehicleParked', src, plate, mods)
                    end)
                else
                    TriggerClientEvent('chat:addMessage', src, {args = {'Garage', 'This is not your vehicle.'}})
                end
            else
                local model = 'unknown'
                if mods.model then model = tostring(mods.model) end
                
                exports.oxmysql:execute('INSERT INTO gypsy_vehicles (citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?)', {
                    citizenid, model, model, json.encode(mods), plate, 1
                }, function(id)
                    if id then
                        TriggerClientEvent('gypsy-garage:client:parkSuccess', src)
                        TriggerClientEvent('chat:addMessage', src, {args = {'Garage', 'Vehicle Saved (New Registration)'}})
                    else
                        TriggerClientEvent('chat:addMessage', src, {args = {'Garage', 'Error: Failed to save vehicle.'}})
                    end
                end)
            end
        end)
    end)
end)

-- Impound Vehicle (Force Return)
RegisterNetEvent('gypsy-garage:server:impoundVehicle', function(plate)
    local src = source
    exports.oxmysql:execute('UPDATE gypsy_vehicles SET state = 1 WHERE plate = ?', {plate}, function(result)
        TriggerClientEvent('chat:addMessage', src, {args = {'Garage', 'Vehicle ' .. plate .. ' impounded (State set to 1). Try /takecar now.'}})
    end)
end)
