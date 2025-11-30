local Gypsy = exports['gypsy-core']:GetCoreObject()

-- ====================================================================================
--                              HELPER FUNCTIONS
-- ====================================================================================

--- Helper: Get CitizenID from source
--- @param source number Player source
--- @param callback function Callback with (citizenid, error)
local function GetCitizenId(source, callback)
    local identifiers = GetPlayerIdentifiers(source)
    local license = identifiers and identifiers[1]
    
    if not license then
        print('^1[Garage] No license found for source: ' .. source .. '^0')
        callback(nil, 'No license found')
        return
    end
    
    exports.oxmysql:execute('SELECT citizenid FROM players WHERE license = ?', {license}, function(result)
        if not result then
            print('^1[Garage] Database error: Failed to query players table^0')
            callback(nil, 'Database error')
            return
        end
        
        if result[1] then
            callback(result[1].citizenid, nil)
        else
            print('^1[Garage] Player not found in database for license: ' .. license .. '^0')
            callback(nil, 'Player not found in database')
        end
    end)
end

--- Helper: Send notification to player
--- @param source number Player source
--- @param message string Notification message
--- @param type string Notification type (success, error, warning, info)
--- @param duration number Duration in ms (optional)
local function Notify(source, message, type, duration)
    TriggerClientEvent('gypsy-notifications:client:notify', source, {
        message = message,
        type = type or 'info',
        duration = duration or 3000
    })
end

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
    
    --- Конфискует машину (отправляет на штрафплощадку)
    ImpoundVehicle = function(plate, fee)
        fee = fee or 500
        exports.oxmysql:execute('UPDATE gypsy_vehicles SET state = 2, impound_fee = ?, impounded_at = NOW() WHERE plate = ?', 
            {fee, plate})
        exports['gypsy-core']:Emit('garage:vehicleImpounded', plate, fee)
        return true
    end,
    
    --- Устанавливает состояние машины
    SetVehicleState = function(plate, state, fee)
        exports.oxmysql:execute('UPDATE gypsy_vehicles SET state = ?, impound_fee = ?, impounded_at = NOW() WHERE plate = ?', 
            {state, fee or 0, plate})
        return true
    end,
    
    --- Получает машины по состоянию
    GetVehiclesByState = function(citizenid, state)
        local promise = promise.new()
        exports.oxmysql:execute('SELECT * FROM gypsy_vehicles WHERE citizenid = ? AND state = ?', 
            {citizenid, state}, function(result)
            promise:resolve(result or {})
        end)
        return Citizen.Await(promise)
    end
}

-- ====================================================================================
--                              DATABASE MIGRATION
-- ====================================================================================

CreateThread(function()
    Wait(2000) -- Wait for DB connection
    
    -- Check and add impound_fee column
    exports.oxmysql:execute('SHOW COLUMNS FROM gypsy_vehicles LIKE "impound_fee"', {}, function(result)
        if not result or #result == 0 then
            print('^3[Garage] Adding impound_fee column to gypsy_vehicles...^0')
            exports.oxmysql:execute('ALTER TABLE gypsy_vehicles ADD COLUMN impound_fee INT DEFAULT 0', {})
        end
    end)
    
    -- Check and add impounded_at column
    exports.oxmysql:execute('SHOW COLUMNS FROM gypsy_vehicles LIKE "impounded_at"', {}, function(result)
        if not result or #result == 0 then
            print('^3[Garage] Adding impounded_at column to gypsy_vehicles...^0')
            exports.oxmysql:execute('ALTER TABLE gypsy_vehicles ADD COLUMN impounded_at TIMESTAMP NULL DEFAULT NULL', {})
        end
    end)
end)

-- Регистрируем сервис в ServiceLocator
CreateThread(function()
    Wait(1000) -- Ждем загрузки Core
    exports['gypsy-core']:RegisterService('Garage', GarageService, {
        version = '1.0.0',
        description = 'Gypsy Garage System'
    })
    print('^2[Garage] Service registered in ServiceLocator^0')
end)

-- Database schema is managed by gypsy-core/setup_database.sql
-- No need to create tables here


-- Get Player Vehicles
RegisterNetEvent('gypsy-garage:server:getMyVehicles', function(garage)
    local src = source
    
    GetCitizenId(src, function(citizenid, err)
        if err then
            Notify(src, 'Ошибка получения данных игрока', 'error')
            return
        end
        
        print('^3[Garage] Player ' .. src .. ' requesting vehicles from garage: ' .. garage .. '^0')
        
        -- Get vehicles in garage only (state = 1)
        exports.oxmysql:execute('SELECT * FROM gypsy_vehicles WHERE citizenid = ? AND state = 1', {citizenid}, function(result)
            if not result then
                print('^1[Garage] Database error: Failed to query vehicles^0')
                Notify(src, 'Ошибка базы данных', 'error')
                return
            end
            
            print('^2[Garage] Found ' .. #result .. ' vehicles in garage for player ' .. src .. '^0')
            TriggerClientEvent('gypsy-garage:client:openMenu', src, result)
        end)
    end)
end)

-- Spawn Vehicle
RegisterNetEvent('gypsy-garage:server:spawnVehicle', function(plate)
    local src = source
    
    GetCitizenId(src, function(citizenid, err)
        if err then
            Notify(src, 'Ошибка получения данных игрока', 'error')
            return
        end
        
        print('^3[Garage] Player ' .. src .. ' requesting to spawn vehicle: ' .. plate .. '^0')
        
        exports.oxmysql:execute('SELECT * FROM gypsy_vehicles WHERE plate = ? AND citizenid = ?', {plate, citizenid}, function(result)
            if not result then
                print('^1[Garage] Database error: Failed to query vehicle^0')
                Notify(src, 'Ошибка базы данных', 'error')
                return
            end
            
            if not result[1] then
                print('^1[Garage] Vehicle not found: ' .. plate .. '^0')
                Notify(src, 'Транспорт не найден', 'error')
                return
            end
            
            local vehData = result[1]
            
            if vehData.state == 1 then -- In Garage
                -- Update state to Out
                exports.oxmysql:execute('UPDATE gypsy_vehicles SET state = 0 WHERE plate = ?', {plate}, function(updateResult)
                    if not updateResult then
                        print('^1[Garage] Database error: Failed to update vehicle state^0')
                        Notify(src, 'Ошибка обновления состояния', 'error')
                        return
                    end
                    
                    print('^2[Garage] Vehicle ' .. plate .. ' spawned for player ' .. src .. '^0')
                    TriggerClientEvent('gypsy-garage:client:spawnVehicleCallback', src, vehData)
                    Notify(src, 'Транспорт выдан', 'success')
                    
                    -- Emit событие через EventBus
                    exports['gypsy-core']:Emit('garage:vehicleSpawned', src, plate, vehData)
                end)
            elseif vehData.state == 2 then
                Notify(src, 'Транспорт на штрафплощадке', 'warning')
            else
                Notify(src, 'Транспорт уже на улице', 'warning')
            end
        end)
    end)
end)

-- Admin Command to clear all vehicles (for testing cleanup)
-- Removed as per cleanup request

-- Park Vehicle
RegisterNetEvent('gypsy-garage:server:parkVehicle', function(plate, mods)
    local src = source
    
    GetCitizenId(src, function(citizenid, err)
        if err then
            Notify(src, 'Ошибка получения данных игрока', 'error')
            return
        end
        
        print('^3[Garage] Player ' .. src .. ' parking vehicle: ' .. plate .. '^0')
        
        -- Check if vehicle exists
        exports.oxmysql:execute('SELECT * FROM gypsy_vehicles WHERE plate = ?', {plate}, function(result)
            if not result then
                print('^1[Garage] Database error: Failed to query vehicle^0')
                Notify(src, 'Ошибка базы данных', 'error')
                return
            end
            
            if result[1] then
                -- Vehicle exists, check ownership
                if result[1].citizenid == citizenid then
                    exports.oxmysql:execute('UPDATE gypsy_vehicles SET state = 1, mods = ? WHERE plate = ?', 
                        {json.encode(mods), plate}, function(updateResult)
                        if not updateResult then
                            print('^1[Garage] Database error: Failed to update vehicle^0')
                            Notify(src, 'Ошибка сохранения', 'error')
                            return
                        end
                        
                        print('^2[Garage] Vehicle ' .. plate .. ' parked successfully^0')
                        TriggerClientEvent('gypsy-garage:client:parkSuccess', src)
                        Notify(src, 'Транспорт припаркован', 'success')
                        
                        -- Emit событие через EventBus
                        exports['gypsy-core']:Emit('garage:vehicleParked', src, plate, mods)
                    end)
                else
                    print('^1[Garage] Ownership mismatch for vehicle: ' .. plate .. '^0')
                    Notify(src, 'Это не ваш транспорт', 'error')
                end
            else
                -- New vehicle, register it
                local model = 'unknown'
                if mods.model then model = tostring(mods.model) end
                
                print('^3[Garage] Registering new vehicle: ' .. plate .. '^0')
                exports.oxmysql:execute('INSERT INTO gypsy_vehicles (citizenid, vehicle, mods, plate, state) VALUES (?, ?, ?, ?, ?)', 
                    {citizenid, model, json.encode(mods), plate, 1}, function(insertResult)
                    if not insertResult then
                        print('^1[Garage] Database error: Failed to insert vehicle^0')
                        Notify(src, 'Ошибка регистрации транспорта', 'error')
                        return
                    end
                    
                    print('^2[Garage] New vehicle ' .. plate .. ' registered successfully^0')
                    TriggerClientEvent('gypsy-garage:client:parkSuccess', src)
                    Notify(src, 'Транспорт зарегистрирован', 'success')
                end)
            end
        end)
    end)
end)

-- Impound Vehicle (Force Return)
RegisterNetEvent('gypsy-garage:server:impoundVehicle', function(plate)
    local src = source
    
    print('^3[Garage] Admin impounding vehicle: ' .. plate .. '^0')
    exports.oxmysql:execute('UPDATE gypsy_vehicles SET state = 1 WHERE plate = ?', {plate}, function(result)
        if not result then
            print('^1[Garage] Database error: Failed to impound vehicle^0')
            Notify(src, 'Ошибка базы данных', 'error')
            return
        end
        
        print('^2[Garage] Vehicle ' .. plate .. ' impounded successfully^0')
        Notify(src, 'Транспорт ' .. plate .. ' возвращён в гараж', 'success')
    end)
end)

