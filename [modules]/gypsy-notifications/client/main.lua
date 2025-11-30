-- Gypsy Notifications - Client
local notificationQueue = {}
local isProcessing = false

-- ====================================================================================
--                                  CORE FUNCTIONS
-- ====================================================================================

--- Показать уведомление
--- @param message string Текст сообщения
--- @param type string Тип: 'success', 'error', 'warning', 'info'
--- @param duration number Длительность в мс (опционально)
local function ShowNotification(message, type, duration)
    type = type or 'info'
    duration = duration or Config.DefaultDuration
    
    -- Отправляем в NUI
    SendNUIMessage({
        action = 'showNotification',
        data = {
            message = message,
            type = type,
            duration = duration,
            icon = Config.Icons[type] or Config.Icons.info
        }
    })
end

-- ====================================================================================
--                                  EVENTS
-- ====================================================================================

-- Событие от сервера
RegisterNetEvent('gypsy-notifications:client:notify', function(data)
    if type(data) == 'table' then
        ShowNotification(data.message, data.type, data.duration)
    elseif type(data) == 'string' then
        -- Обратная совместимость: если передана просто строка
        ShowNotification(data, 'info', Config.DefaultDuration)
    end
end)

-- Для совместимости с gypsy-hud (если другие модули используют старое событие)
RegisterNetEvent('gypsy-hud:client:notify', function(data)
    if type(data) == 'table' then
        ShowNotification(data.message, data.type, data.duration)
    end
end)

-- ====================================================================================
--                                  EXPORTS
-- ====================================================================================

--- Экспорт для прямого вызова из других клиентских скриптов
--- @param message string Текст сообщения
--- @param type string Тип: 'success', 'error', 'warning', 'info'
--- @param duration number Длительность в мс (опционально)
exports('Notify', function(message, type, duration)
    ShowNotification(message, type, duration)
end)

-- Короткие алиасы для удобства
exports('Success', function(message, duration)
    ShowNotification(message, 'success', duration)
end)

exports('Error', function(message, duration)
    ShowNotification(message, 'error', duration)
end)

exports('Warning', function(message, duration)
    ShowNotification(message, 'warning', duration)
end)

exports('Info', function(message, duration)
    ShowNotification(message, 'info', duration)
end)

-- ====================================================================================
--                                  NOTE: SERVICE LOCATOR
-- ====================================================================================

-- Service Locator в gypsy-core доступен только на серверной стороне.
-- Клиентские модули используют прямые экспорты (см. выше).
-- Серверная интеграция происходит через NotificationService в gypsy-core.

-- ====================================================================================
--                                  DEBUG COMMANDS
-- ====================================================================================

-- Команды для тестирования
RegisterCommand('testnotify', function(source, args)
    local type = args[1] or 'info'
    local messages = {
        success = 'Операция выполнена успешно!',
        error = 'Произошла ошибка!',
        warning = 'Внимание! Низкий уровень топлива',
        info = 'Информационное сообщение'
    }
    
    ShowNotification(messages[type] or messages.info, type, 3000)
end, false)

RegisterCommand('spamnotify', function(source, args)
    local count = tonumber(args[1]) or 5
    local types = {'success', 'error', 'warning', 'info'}
    
    for i = 1, count do
        local type = types[math.random(1, #types)]
        ShowNotification('Тестовое уведомление #' .. i, type, 3000)
        Wait(100) -- Небольшая задержка между уведомлениями
    end
end, false)

-- Проверка регистрации сервиса
RegisterCommand('checkservice', function(source, args)
    local serviceName = args[1] or 'Notification'
    
    if exports['gypsy-core'] and exports['gypsy-core'].HasService then
        local hasService = exports['gypsy-core']:HasService(serviceName)
        if hasService then
            print('^2[Service Check] Service "' .. serviceName .. '" is registered^0')
            ShowNotification('Сервис "' .. serviceName .. '" зарегистрирован', 'success', 3000)
        else
            print('^1[Service Check] Service "' .. serviceName .. '" is NOT registered^0')
            ShowNotification('Сервис "' .. serviceName .. '" не найден', 'error', 3000)
        end
    else
        print('^3[Service Check] Service Locator not available^0')
        ShowNotification('Service Locator недоступен', 'warning', 3000)
    end
end, false)

print('^2[Gypsy-Notifications] Client initialized^0')
