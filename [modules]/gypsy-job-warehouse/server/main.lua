-- Warehouse Job - Server
print('^2[Warehouse] Loading...^0')

local ActiveWorkers = {}

-- ====================================================================================
--                              HELPER FUNCTIONS
-- ====================================================================================

local function IsNightTime()
    -- Получаем игровое время через ServiceLocator
    local hour = 12 -- По умолчанию день
    
    if exports['gypsy-core']:HasService('Weather') then
        local WeatherService = exports['gypsy-core']:GetService('Weather')
        hour = WeatherService.GetCurrentHour()
    else
        -- Fallback на серверное время если Weather сервис не доступен
        hour = tonumber(os.date("%H"))
    end
    
    -- Ночь: 22:00-06:00
    if Config.Job.IllegalHoursStart > Config.Job.IllegalHoursEnd then
        -- Переход через полночь (22-24 и 0-6)
        return hour >= Config.Job.IllegalHoursStart or hour < Config.Job.IllegalHoursEnd
    else
        -- Обычный диапазон
        return hour >= Config.Job.IllegalHoursStart and hour < Config.Job.IllegalHoursEnd
    end
end

local function CanStartShift(source)
    if ActiveWorkers[source] and ActiveWorkers[source].cooldown then
        local timeLeft = ActiveWorkers[source].cooldown - os.time()
        if timeLeft > 0 then
            return false, timeLeft
        end
    end
    
    local activeCount = 0
    for _, worker in pairs(ActiveWorkers) do
        if worker.working then
            activeCount = activeCount + 1
        end
    end
    
    if activeCount >= Config.Job.MaxWorkers then
        return false, 0
    end
    
    return true, 0
end

-- ====================================================================================
--                                  EVENTS
-- ====================================================================================

RegisterNetEvent('warehouse:server:startShift')
AddEventHandler('warehouse:server:startShift', function()
    local src = source
    local canStart, timeLeft = CanStartShift(src)
    
    if not canStart then
        if timeLeft > 0 then
            TriggerClientEvent('gypsy-notifications:client:notify', src, {
                message = string.format('Откат: %d мин', math.ceil(timeLeft / 60)),
                type = 'error'
            })
        else
            TriggerClientEvent('gypsy-notifications:client:notify', src, {
                message = 'Все места заняты (макс ' .. Config.Job.MaxWorkers .. ')',
                type = 'error'
            })
        end
        return
    end
    
    -- Проверка: нелегальная погрузка?
    local isIllegal = false
    if IsNightTime() then
        if math.random(100) <= Config.Job.IllegalChance then
            isIllegal = true
        end
    end
    
    ActiveWorkers[src] = {
        working = true,
        boxes = 0,
        isIllegal = isIllegal,
        startTime = os.time(),
        cooldown = nil
    }
    
    local shiftType = isIllegal and "нелегальная" or "обычная"
    local payment = isIllegal and Config.Payment.IllegalPayment or Config.Payment.NormalPayment
    
    TriggerClientEvent('warehouse:client:startShift', src, isIllegal)
    
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = string.format('Смена началась! (%s погрузка, $%d/ящик)', shiftType, payment),
        type = isIllegal and 'warning' or 'success',
        duration = 5000
    })
    
    print(string.format('^2[Warehouse] %s started shift (%s)^0', GetPlayerName(src), shiftType))
end)

RegisterNetEvent('warehouse:server:boxDelivered')
AddEventHandler('warehouse:server:boxDelivered', function()
    local src = source
    local Player = exports['gypsy-core']:GetPlayer(src)
    if not Player or not ActiveWorkers[src] then return end
    
    ActiveWorkers[src].boxes = ActiveWorkers[src].boxes + 1
    
    -- Оплата за ящик
    local payment = ActiveWorkers[src].isIllegal and Config.Payment.IllegalPayment or Config.Payment.NormalPayment
    Player.Functions.AddMoney('cash', payment, 'warehouse-box')
    
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = string.format('Ящик %d/%d: +$%d', ActiveWorkers[src].boxes, Config.Job.BoxesPerShift, payment),
        type = 'success'
    })
    
    -- Проверка завершения смены
    if ActiveWorkers[src].boxes >= Config.Job.BoxesPerShift then
        -- Установить откат
        ActiveWorkers[src].cooldown = os.time() + (Config.Job.CooldownMinutes * 60)
        ActiveWorkers[src].working = false
        
        TriggerClientEvent('warehouse:client:endShift', src)
        
        local totalEarned = ActiveWorkers[src].boxes * payment
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = string.format('Смена завершена! Заработано: $%d', totalEarned),
            type = 'success',
            duration = 5000
        })
        
        print(string.format('^2[Warehouse] %s completed shift: $%d^0', GetPlayerName(src), totalEarned))
    else
        -- Следующий ящик
        TriggerClientEvent('warehouse:client:nextBox', src)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if ActiveWorkers[src] then
        ActiveWorkers[src] = nil
    end
end)

print('^2[Warehouse] Server loaded^0')
