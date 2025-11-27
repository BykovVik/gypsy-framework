local Gypsy = exports['gypsy-core']:GetCoreObject()
local VehicleKeys = {} -- [plate] = { [citizenid] = true }

print('[Vehicle] Server script loaded')

-- Helper: Normalize Plate
local function Trim(value)
    if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

-- Event: Give Keys
RegisterNetEvent('gypsy-vehicle:server:giveKeys')
AddEventHandler('gypsy-vehicle:server:giveKeys', function(plate, target)
    local src = source
    print('[Vehicle] Server: giveKeys event received from ' .. src .. ' for plate: ' .. tostring(plate))
    
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then 
        print('[Vehicle] Server: Error - Player not found for source ' .. src)
        return 
    end
    print('[Vehicle] Server: Player found: ' .. player.citizenid)
    
    plate = Trim(plate)
    
    if not VehicleKeys[plate] then VehicleKeys[plate] = {} end
    
    -- If target provided, give to them, else give to self
    local targetId = target or player.citizenid
    VehicleKeys[plate][targetId] = true
    
    TriggerClientEvent('gypsy-vehicle:client:updateKeys', src, plate)
    print('[Vehicle] Keys given for ' .. plate .. ' to ' .. targetId)
end)

-- Event: Check Keys
RegisterNetEvent('gypsy-vehicle:server:hasKeys', function(plate)
    local src = source
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then 
        TriggerClientEvent('gypsy-vehicle:client:hasKeysResponse', src, false)
        return 
    end
    
    plate = Trim(plate)
    
    if VehicleKeys[plate] and VehicleKeys[plate][player.citizenid] then
        TriggerClientEvent('gypsy-vehicle:client:hasKeysResponse', src, true)
    else
        TriggerClientEvent('gypsy-vehicle:client:hasKeysResponse', src, false)
    end
end)

-- Event: Toggle Lock
RegisterNetEvent('gypsy-vehicle:server:toggleLock', function(netId)
    local src = source
    local entity = NetworkGetEntityFromNetworkId(netId)
    
    if DoesEntityExist(entity) then
        local plate = Trim(GetVehicleNumberPlateText(entity))
        local player = exports['gypsy-core']:GetPlayer(src)
        
        if VehicleKeys[plate] and VehicleKeys[plate][player.citizenid] then
            local locked = GetVehicleDoorLockStatus(entity)
            local newStatus = 2
            if locked == 2 then newStatus = 1 end -- If locked(2), unlock(1). Else lock(2).
            
            SetVehicleDoorsLocked(entity, newStatus)
            TriggerClientEvent('gypsy-vehicle:client:animateLock', src)
            
            local statusMsg = (newStatus == 2) and "Locked" or "Unlocked"
            TriggerClientEvent('gypsy:client:debug', src, 'Vehicle ' .. statusMsg)
        else
            TriggerClientEvent('gypsy:client:debug', src, 'You do not have keys for this vehicle.')
        end
    else
        TriggerClientEvent('gypsy:client:debug', src, 'Error: Entity not found.')
    end
end)


-- ====================================================================================
--                              VEHICLE SERVICE
-- ====================================================================================

local VehicleService = {
    version = '1.0.0',
    
    --- Выдает ключи от машины
    GiveKeys = function(source, plate, targetCitizenId)
        plate = Trim(plate)
        if not VehicleKeys[plate] then VehicleKeys[plate] = {} end
        
        local player = exports['gypsy-core']:GetPlayer(source)
        if not player then return false end
        
        local targetId = targetCitizenId or player.citizenid
        VehicleKeys[plate][targetId] = true
        
        TriggerClientEvent('gypsy-vehicle:client:updateKeys', source, plate)
        print('[Vehicle] Keys given for ' .. plate .. ' to ' .. targetId)
        return true
    end,
    
    --- Проверяет наличие ключей
    HasKeys = function(source, plate)
        local player = exports['gypsy-core']:GetPlayer(source)
        if not player then return false end
        
        plate = Trim(plate)
        
        if VehicleKeys[plate] and VehicleKeys[plate][player.citizenid] then
            return true
        else
            return false
        end
    end,
    
    --- Забирает ключи
    RemoveKeys = function(source, plate)
        local player = exports['gypsy-core']:GetPlayer(source)
        if not player then return false end
        
        plate = Trim(plate)
        
        if VehicleKeys[plate] then
            VehicleKeys[plate][player.citizenid] = nil
            return true
        end
        return false
    end
}

-- Регистрируем сервис в ServiceLocator
CreateThread(function()
    Wait(1000) -- Ждем загрузки Core
    exports['gypsy-core']:RegisterService('Vehicle', VehicleService, {
        version = '1.0.0',
        description = 'Gypsy Vehicle System'
    })
    print('^2[Vehicle] Service registered in ServiceLocator^0')
end)
