Gypsy = {}
Gypsy.PlayerData = {}
Gypsy.RequestId = 0
Gypsy.ServerCallbacks = {}
Gypsy.Functions = {}

-- ====================================================================================
--                                  INITIALIZATION
-- ====================================================================================

CreateThread(function()
    Wait(500)
    print('[Gypsy-Core] Client Initialized. Joining...')
    TriggerServerEvent('gypsy:join')
end)

RegisterNetEvent('gypsy:client:forceReload', function()
    print('^3[Gypsy-Core] Hot-Reload detected! Re-initializing...^0')
    -- Reset State
    Gypsy.PlayerData = {}
    
    -- НЕ триггерим coreReady здесь - это вызовет повторный спавн
    -- Ждем события playerLoaded от сервера, которое само вызовет coreReady
end)

RegisterNetEvent('gypsy-core:client:playerLoaded', function(playerData)
    Gypsy.PlayerData = playerData
    print('[Gypsy-Core] Player Data Loaded.')
    TriggerEvent('gypsy:client:coreReady')
end)

-- ====================================================================================
--                                  CALLBACKS & EVENTS
-- ====================================================================================

function Gypsy.Functions.TriggerCallback(name, cb, ...)
    Gypsy.RequestId = Gypsy.RequestId + 1
    Gypsy.ServerCallbacks[Gypsy.RequestId] = cb
    TriggerServerEvent('gypsy-core:server:triggerCallback', name, Gypsy.RequestId, ...)
end

RegisterNetEvent('gypsy-core:client:callbackReturn', function(requestId, ...)
    if Gypsy.ServerCallbacks[requestId] then
        Gypsy.ServerCallbacks[requestId](...)
        Gypsy.ServerCallbacks[requestId] = nil
    end
end)

RegisterNetEvent('gypsy-core:client:updateStatus', function(metadata)
    if Gypsy.PlayerData then
        Gypsy.PlayerData.metadata = metadata
    end
    TriggerEvent('gypsy-hud:client:updateStatus', metadata)
end)

RegisterNetEvent('gypsy:client:debug', function(msg)
    print('^2[Gypsy-Core DEBUG] ' .. msg .. '^0')
end)

RegisterNetEvent('gypsy-core:client:applyStarvationDamage', function(damage)
    local ped = PlayerPedId()
    local currentHealth = GetEntityHealth(ped)
    local newHealth = currentHealth - damage
    
    SetEntityHealth(ped, newHealth)
end)

-- ====================================================================================
--                                  EXPORTS
-- ====================================================================================

exports('GetCoreObject', function() return Gypsy end)

function Gypsy.Functions.GetPlayerData()
    return Gypsy.PlayerData
end
