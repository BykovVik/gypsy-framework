-- ====================================================================================
--                          NOTIFICATION SERVICE
-- ====================================================================================

NotificationService = {
    version = '1.0.0',
    
    --- Отправляет уведомление игроку
    --- @param source number ID игрока
    --- @param message string Текст сообщения
    --- @param type string Тип: 'success', 'error', 'info', 'warning'
    --- @param duration number Длительность в мс (опционально)
    Send = function(source, message, type, duration)
        type = type or 'info'
        duration = duration or 3000
        
        -- Пробуем использовать gypsy-notifications (приоритет)
        if GetResourceState('gypsy-notifications') == 'started' then
            TriggerClientEvent('gypsy-notifications:client:notify', source, {
                message = message,
                type = type,
                duration = duration
            })
            return true
        end
        
        -- Fallback: gypsy-hud (для обратной совместимости)
        if GetResourceState('gypsy-hud') == 'started' then
            TriggerClientEvent('gypsy-hud:client:notify', source, {
                message = message,
                type = type,
                duration = duration
            })
            return true
        end
        
        -- Пробуем ox_lib
        if GetResourceState('ox_lib') == 'started' then
            TriggerClientEvent('ox_lib:notify', source, {
                type = type,
                description = message,
                duration = duration
            })
            return true
        end
        
        -- Fallback: chat
        local color = '^0'
        if type == 'success' then color = '^2'
        elseif type == 'error' then color = '^1'
        elseif type == 'warning' then color = '^3'
        end
        
        TriggerClientEvent('chat:addMessage', source, {
            args = {'System', color .. message .. '^0'}
        })
        return true
    end,
        

    
    --- Отправляет уведомление всем игрокам
    SendAll = function(message, type, duration)
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            NotificationService.Send(tonumber(playerId), message, type, duration)
        end
    end
}

-- Регистрируем сервис в ServiceLocator
CreateThread(function()
    Wait(1000)
    exports['gypsy-core']:RegisterService('Notification', NotificationService, {
        version = '1.0.0',
        description = 'Unified Notification System'
    })
    print('^2[NotificationService] Service registered in ServiceLocator^0')
end)

-- Экспорты для обратной совместимости
exports('Notify', function(source, message, type, duration)
    return NotificationService.Send(source, message, type, duration)
end)

exports('NotifyAll', function(message, type, duration)
    return NotificationService.SendAll(message, type, duration)
end)
