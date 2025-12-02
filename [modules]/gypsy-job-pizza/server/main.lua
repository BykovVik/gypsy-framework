-- Pizza Delivery Job - Server
print('^2[Pizza Delivery] Loading...^0')

-- Состояние работников
local ActiveWorkers = {}

-- ====================================================================================
--                              HELPER FUNCTIONS
-- ====================================================================================

local function CanStartShift(source)
    -- Проверка отката
    if ActiveWorkers[source] and ActiveWorkers[source].cooldown then
        local timeLeft = ActiveWorkers[source].cooldown - os.time()
        if timeLeft > 0 then
            return false, timeLeft
        end
    end
    
    -- Проверка лимита работников
    local activeCount = 0
    for _, worker in pairs(ActiveWorkers) do
        if worker.vehicle then
            activeCount = activeCount + 1
        end
    end
    
    if activeCount >= Config.Job.MaxWorkers then
        return false, 0
    end
    
    return true, 0
end

-- Функция расчета времени доставки на основе расстояния
local function CalculateDeliveryTime(distance)
    local baseTime = distance / Config.Job.AverageSpeed
    local timeWithBuffer = baseTime * Config.Job.TimeMultiplier
    
    -- Ограничиваем мин/макс
    return math.max(
        Config.Job.MinDeliveryTime,
        math.min(Config.Job.MaxDeliveryTime, math.floor(timeWithBuffer))
    )
end

-- ====================================================================================
--                                  EVENTS
-- ====================================================================================

--- Начать смену
RegisterNetEvent('pizza:server:startShift')
AddEventHandler('pizza:server:startShift', function()
    local src = source
    local canStart, timeLeft = CanStartShift(src)
    
    if not canStart then
        local NotificationService = exports['gypsy-core']:GetService('Notification')
        if timeLeft > 0 then
            local minutes = math.ceil(timeLeft / 60)
            if NotificationService then
                NotificationService.Send(src, string.format('Откат: %d мин', minutes), 'error')
            end
        else
            if NotificationService then
                NotificationService.Send(src, 'Все места заняты (макс 5 работников)', 'error')
            end
        end
        return
    end
    
    TriggerClientEvent('pizza:client:spawnVehicle', src)
    print('^2[Pizza Delivery] ' .. GetPlayerName(src) .. ' started shift^0')
end)


--- Фургон успешно заспавнен
RegisterNetEvent('pizza:server:vehicleSpawned')
AddEventHandler('pizza:server:vehicleSpawned', function(netId)
    local src = source
    
    ActiveWorkers[src] = {
        vehicle = netId,
        deliveries = 0,
        startTime = os.time(),
        cooldown = nil,
        pendingMoney = 0
    }
    
    -- Выбираем случайную точку доставки
    local deliveryPoint = Config.DeliveryPoints[math.random(#Config.DeliveryPoints)]
    local distance = #(Config.Pizzeria.coords - deliveryPoint)
    local deliveryTime = CalculateDeliveryTime(distance)
    
    -- Отправляем клиенту первый заказ с точкой и временем
    TriggerClientEvent('pizza:client:newDelivery', src, 1, deliveryPoint, deliveryTime)
    
    local NotificationService = exports['gypsy-core']:GetService('Notification')
    if NotificationService then
        NotificationService.Send(src, 'Смена началась! Доставьте пиццы', 'success', 5000)
    end
end)

--- Доставка завершена
RegisterNetEvent('pizza:server:deliveryComplete')
AddEventHandler('pizza:server:deliveryComplete', function(distance, timeSpent, timePercentage)
    local src = source
    if not ActiveWorkers[src] then return end
    
    -- Базовая оплата
    local basePay = distance * Config.Payment.BaseRate
    
    -- Множитель времени
    local timeMultiplier = 0.1 -- По умолчанию минимум (просрочка)
    
    if timePercentage >= 50 then
        -- Осталось >= 50% времени → полная оплата
        timeMultiplier = 1.0
    elseif timePercentage > 0 then
        -- Осталось 0-50% времени → половина оплаты
        timeMultiplier = 0.5
    end
    
    -- Итоговая оплата
    local finalPay = math.floor(basePay * timeMultiplier)
    
    -- Накопить деньги
    ActiveWorkers[src].pendingMoney = (ActiveWorkers[src].pendingMoney or 0) + finalPay
    ActiveWorkers[src].deliveries = (ActiveWorkers[src].deliveries or 0) + 1
    
    -- Уведомление
    local timeStatus = ''
    if timeMultiplier == 1.0 then
        timeStatus = '⚡ Быстрая доставка! Полная оплата'
    elseif timeMultiplier == 0.5 then
        timeStatus = '⏱️ Средняя скорость. Половина оплаты'
    else
        timeStatus = '❄️ Пицца остыла. Минимальная оплата'
    end
    
    local NotificationService = exports['gypsy-core']:GetService('Notification')
    if NotificationService then
        NotificationService.Send(src, string.format('%s: $%d (Всего за смену: $%d)', timeStatus, finalPay, ActiveWorkers[src].pendingMoney), 'success', 5000)
    end
    
    print(string.format(
        '^2[Pizza Delivery] %s completed delivery #%d - Distance: %.2fm, Time: %.1fs (%.0f%% remaining), Pay: $%d (x%.1f)^0',
        GetPlayerName(src),
        ActiveWorkers[src].deliveries,
        distance,
        timeSpent,
        timePercentage,
        finalPay,
        timeMultiplier
    ))
end)

--- Завершение смены и выплата
RegisterNetEvent('pizza:server:finishShift')
AddEventHandler('pizza:server:finishShift', function()
    local src = source
    local Player = exports['gypsy-core']:GetPlayer(src)
    
    if not ActiveWorkers[src] then return end
    
    local totalEarned = ActiveWorkers[src].pendingMoney or 0
    
    if totalEarned > 0 then
        Player.Functions.AddMoney('cash', totalEarned, 'pizza-shift-payment')
    end
    
    -- Установить откат
    ActiveWorkers[src].cooldown = os.time() + (Config.Job.CooldownMinutes * 60)
    ActiveWorkers[src].vehicle = nil
    ActiveWorkers[src].pendingMoney = 0
    
    TriggerClientEvent('pizza:client:endShift', src)
    
    local NotificationService = exports['gypsy-core']:GetService('Notification')
    if NotificationService then
        NotificationService.Send(src, string.format('Смена окончена! Вы заработали $%d. Отдыхайте %d мин.', totalEarned, Config.Job.CooldownMinutes), 'success', 6000)
    end
    
    print('^2[Pizza Delivery] ' .. GetPlayerName(src) .. ' finished shift. Earned: $' .. totalEarned .. '^0')
end)

--- Запрос следующего заказа
RegisterNetEvent('pizza:server:requestNextOrder')
AddEventHandler('pizza:server:requestNextOrder', function()
    local src = source
    if not ActiveWorkers[src] or not ActiveWorkers[src].vehicle then return end
    
    if ActiveWorkers[src].deliveries >= Config.Job.DeliveriesPerShift then
        local NotificationService = exports['gypsy-core']:GetService('Notification')
        if NotificationService then
            NotificationService.Send(src, 'Смена завершена', 'error')
        end
        return
    end
    
    -- Выбираем случайную точку доставки
    local deliveryPoint = Config.DeliveryPoints[math.random(#Config.DeliveryPoints)]
    local distance = #(Config.Pizzeria.coords - deliveryPoint)
    local deliveryTime = CalculateDeliveryTime(distance)
    
    -- Отправляем клиенту с точкой и временем
    TriggerClientEvent('pizza:client:newDelivery', src, ActiveWorkers[src].deliveries + 1, deliveryPoint, deliveryTime)
end)

--- Фургон уничтожен
RegisterNetEvent('pizza:server:vehicleDestroyed')
AddEventHandler('pizza:server:vehicleDestroyed', function()
    local src = source
    local Player = exports['gypsy-core']:GetPlayer(src)
    if not Player or not ActiveWorkers[src] then return end
    
    Player.Functions.RemoveMoney('cash', Config.Payment.VehicleDestroyFine, 'pizza-vehicle-destroyed')
    
    ActiveWorkers[src].cooldown = os.time() + (Config.Job.CooldownMinutes * 60)
    ActiveWorkers[src].vehicle = nil
    
    local NotificationService = exports['gypsy-core']:GetService('Notification')
    if NotificationService then
        NotificationService.Send(src, 'Фургон уничтожен! Штраф $' .. Config.Payment.VehicleDestroyFine, 'error', 5000)
    end
    
    print('^1[Pizza Delivery] ' .. GetPlayerName(src) .. ' destroyed vehicle - fined $' .. Config.Payment.VehicleDestroyFine .. '^0')
end)

--- Игрок уволился
RegisterNetEvent('pizza:server:quitJob')
AddEventHandler('pizza:server:quitJob', function()
    local src = source
    if ActiveWorkers[src] then
        ActiveWorkers[src].vehicle = nil
        ActiveWorkers[src].pendingMoney = 0
        ActiveWorkers[src] = nil
    end
end)

--- Игрок отключился
AddEventHandler('playerDropped', function()
    local src = source
    if ActiveWorkers[src] then
        ActiveWorkers[src] = nil
    end
end)

print('^2[Pizza Delivery] Server loaded^0')
