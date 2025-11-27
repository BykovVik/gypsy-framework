local Gypsy = exports['gypsy-core']:GetCoreObject()

-- ====================================================================================
--                              DEATH SERVICE
-- ====================================================================================

local DeathService = {
    version = '1.0.0',
    deadPlayers = {}, -- Хранит состояние мертвых игроков
    
    --- Проверяет мертв ли игрок
    IsDead = function(source)
        return DeathService.deadPlayers[source] == true
    end,
    
    --- Убивает игрока
    Kill = function(source, reason)
        DeathService.deadPlayers[source] = true
        -- Клиент сам определяет смерть через IsEntityDead
        exports['gypsy-core']:Emit('player:died', source, reason or 'unknown')
        print('^1[Death] Player ' .. GetPlayerName(source) .. ' died. Reason: ' .. (reason or 'unknown') .. '^0')
    end,
    
    --- Воскрешает игрока
    Revive = function(source)
        DeathService.deadPlayers[source] = false
        TriggerClientEvent('gypsy-death:client:revive', source)
        exports['gypsy-core']:Emit('player:revived', source)
        print('^2[Death] Player ' .. GetPlayerName(source) .. ' revived^0')
    end,
    
    --- Получает список мертвых игроков
    GetDeadPlayers = function()
        local dead = {}
        for source, isDead in pairs(DeathService.deadPlayers) do
            if isDead then
                table.insert(dead, source)
            end
        end
        return dead
    end
}

-- Регистрируем сервис в ServiceLocator
CreateThread(function()
    Wait(1000)
    exports['gypsy-core']:RegisterService('Death', DeathService, {
        version = '1.0.0',
        description = 'Gypsy Death System'
    })
    print('^2[Death] Service registered in ServiceLocator^0')
end)

-- Placeholder for future server-side death handling (logging, inventory clearing, etc.)
RegisterNetEvent('gypsy-death:server:onPlayerDied', function()
    local src = source
    DeathService.Kill(src, 'client_trigger')
end)

-- Очищаем состояние при дисконнекте
AddEventHandler('playerDropped', function()
    local src = source
    DeathService.deadPlayers[src] = nil
end)
