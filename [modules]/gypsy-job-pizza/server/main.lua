-- Pizza Delivery Job - Server
print('^2[Pizza Delivery] Loading...^0')

-- Состояние работников
local ActiveWorkers = {}  -- {source = {vehicle, deliveries, startTime, cooldown}}

-- ====================================================================================
--                              HELPER FUNCTIONS
-- ====================================================================================

--- Проверка доступности смены
--- @param source number
--- @return boolean canStart
--- @return number timeLeft (seconds)
local function CanStartShift(source)
    -- Проверка отката
    if ActiveWorkers[source] and ActiveWorkers[source].cooldown then
        local timeLeft = ActiveWorkers[source].cooldown - os.time()
        if timeLeft > 0 then
            return false, timeLeft
        end
    end
    
    -- Проверка лимита фургонов
    local activeCount = 0
    for _, worker in pairs(ActiveWorkers) do
        if worker.vehicle then
            activeCount = activeCount + 1
        end
    end
    
    if activeCount >= Config.Job.MaxVehicles then
        return false, 0
    end
    
    return true, 0
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
        if timeLeft > 0 then
            local minutes = math.ceil(timeLeft / 60)
            TriggerClientEvent('gypsy-notifications:client:notify', src, {
                message = string.format('Откат: %d мин', minutes),
                type = 'error'
            })
        else
            TriggerClientEvent('gypsy-notifications:client:notify', src, {
                message = 'Все фургоны заняты (макс 3)',
                type = 'error'
            })
        end
        return
    end
    
    -- Спавн фургона на клиенте
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
        cooldown = nil
    }
    
    -- Дать первый заказ
    TriggerClientEvent('pizza:client:newDelivery', src, 1)
    
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = 'Смена началась! Доставьте 5 пицц',
        type = 'success',
        duration = 5000
    })
end)

--- Доставка завершена
RegisterNetEvent('pizza:server:deliveryComplete')
AddEventHandler('pizza:server:deliveryComplete', function(distance, timeSpent)
    local src = source
    local Player = exports['gypsy-core']:GetPlayer(src)
    if not Player or not ActiveWorkers[src] then return end
    
    -- Расчёт оплаты
    local payment = math.floor(distance * Config.Payment.BaseRate)
    
    -- Бонус за скорость (если доставка < 3 минут)
    local bonusApplied = false
    if timeSpent < Config.Job.SpeedBonusTime then
        payment = math.floor(payment * (1 + Config.Payment.SpeedBonus))
        bonusApplied = true
    end
    
    -- Выплата
    Player.Functions.AddMoney('cash', payment, 'pizza-delivery')
    
    -- Увеличить счётчик
    ActiveWorkers[src].deliveries = ActiveWorkers[src].deliveries + 1
    
    -- Уведомление
    local bonusText = bonusApplied and ' (⚡ бонус!)' or ''
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = string.format('Доставка %d/5: +$%d%s', ActiveWorkers[src].deliveries, payment, bonusText),
        type = 'success'
    })
    
    print(string.format('^2[Pizza Delivery] %s completed delivery %d/5: $%d (%.0fm, %.0fs)^0', 
        GetPlayerName(src), ActiveWorkers[src].deliveries, payment, distance, timeSpent))
    
    -- Проверка завершения смены
    if ActiveWorkers[src].deliveries >= Config.Job.DeliveriesPerShift then
        -- Установить откат
        ActiveWorkers[src].cooldown = os.time() + Config.Job.CooldownTime
        ActiveWorkers[src].vehicle = nil
        
        -- Удалить фургон на клиенте
        TriggerClientEvent('pizza:client:endShift', src)
        
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = 'Смена завершена! Откат 30 минут',
            type = 'info',
            duration = 5000
        })
        
        print('^2[Pizza Delivery] ' .. GetPlayerName(src) .. ' completed shift^0')
    else
        -- Уведомление о возврате на базу
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = 'Вернитесь на базу за следующим заказом',
            type = 'info',
            duration = 4000
        })
    end
end)

--- Запрос следующего заказа (на базе)
RegisterNetEvent('pizza:server:requestNextOrder')
AddEventHandler('pizza:server:requestNextOrder', function()
    local src = source
    if not ActiveWorkers[src] or not ActiveWorkers[src].vehicle then return end
    
    -- Проверка что не превышен лимит
    if ActiveWorkers[src].deliveries >= Config.Job.DeliveriesPerShift then
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = 'Смена завершена',
            type = 'error'
        })
        return
    end
    
    -- Дать следующий заказ
    TriggerClientEvent('pizza:client:newDelivery', src, ActiveWorkers[src].deliveries + 1)
end)

--- Фургон уничтожен
RegisterNetEvent('pizza:server:vehicleDestroyed')
AddEventHandler('pizza:server:vehicleDestroyed', function()
    local src = source
    local Player = exports['gypsy-core']:GetPlayer(src)
    if not Player or not ActiveWorkers[src] then return end
    
    -- Штраф
    Player.Functions.RemoveMoney('cash', Config.Payment.VehicleDestroyFine, 'pizza-vehicle-destroyed')
    
    -- Установить откат
    ActiveWorkers[src].cooldown = os.time() + Config.Job.CooldownTime
    ActiveWorkers[src].vehicle = nil
    
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = 'Фургон уничтожен! Штраф $' .. Config.Payment.VehicleDestroyFine,
        type = 'error',
        duration = 5000
    })
    
    print('^1[Pizza Delivery] ' .. GetPlayerName(src) .. ' destroyed vehicle - fined $' .. Config.Payment.VehicleDestroyFine .. '^0')
end)

--- Игрок отключился
AddEventHandler('playerDropped', function()
    local src = source
    if ActiveWorkers[src] then
        ActiveWorkers[src] = nil
    end
end)

print('^2[Pizza Delivery] Server loaded^0')
