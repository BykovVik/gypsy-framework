-- Cable TV Job - Server
print('^2[Cable TV] Loading...^0')

local ActiveWorkers = {}

-- ====================================================================================
--                              HELPER FUNCTIONS
-- ====================================================================================

local function CanStartShift(source)
    if ActiveWorkers[source] and ActiveWorkers[source].cooldown then
        local timeLeft = ActiveWorkers[source].cooldown - os.time()
        if timeLeft > 0 then
            return false, timeLeft
        end
    end
    
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

RegisterNetEvent('cabletv:server:startShift')
AddEventHandler('cabletv:server:startShift', function()
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
                message = 'Все фургоны заняты (макс 3)',
                type = 'error'
            })
        end
        return
    end
    
    TriggerClientEvent('cabletv:client:spawnVehicle', src)
    print('^2[Cable TV] ' .. GetPlayerName(src) .. ' started shift^0')
end)

RegisterNetEvent('cabletv:server:vehicleSpawned')
AddEventHandler('cabletv:server:vehicleSpawned', function(netId)
    local src = source
    
    ActiveWorkers[src] = {
        vehicle = netId,
        installs = 0,
        startTime = os.time(),
        cooldown = nil,
        accumulatedMoney = 0, -- Накопленные деньги
        hasActiveOrder = true -- Сразу даем заказ
    }
    
    TriggerClientEvent('cabletv:client:newInstall', src, 1)
    
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = 'Смена началась! Установите 5 антенн',
        type = 'success',
        duration = 5000
    })
end)

RegisterNetEvent('cabletv:server:installComplete')
AddEventHandler('cabletv:server:installComplete', function(distance, successCount)
    local src = source
    local Player = exports['gypsy-core']:GetPlayer(src)
    if not Player or not ActiveWorkers[src] then return end
    
    -- Расчёт оплаты (накопление)
    local basePayment = math.floor(distance * Config.Payment.BaseRate)
    local multiplier = Config.Payment.SuccessMultipliers[successCount] or 1.0
    local payment = math.floor(basePayment * multiplier)
    
    ActiveWorkers[src].accumulatedMoney = ActiveWorkers[src].accumulatedMoney + payment
    ActiveWorkers[src].installs = ActiveWorkers[src].installs + 1
    ActiveWorkers[src].hasActiveOrder = false
    
    -- Уведомление
    local qualityText = ""
    if successCount == 3 then qualityText = " (⭐ Отлично!)"
    elseif successCount == 2 then qualityText = " (👍 Хорошо)"
    elseif successCount == 1 then qualityText = " (✓ Нормально)"
    else qualityText = " (❌ Плохо)" end
    
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = string.format('Заработано: +$%d%s (Всего: $%d)', payment, qualityText, ActiveWorkers[src].accumulatedMoney),
        type = 'success'
    })
    
    print(string.format('^2[Cable TV] %s completed install %d/5: +$%d (Total: $%d)^0', 
        GetPlayerName(src), ActiveWorkers[src].installs, payment, ActiveWorkers[src].accumulatedMoney))
    
    -- Проверка лимита установок (просто уведомляем)
    if ActiveWorkers[src].installs >= Config.Job.InstallsPerShift then
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = 'План выполнен! Вернитесь на базу за расчетом.',
            type = 'info',
            duration = 5000
        })
    else
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = 'Вернитесь на базу за следующим заказом или расчетом',
            type = 'info',
            duration = 4000
        })
    end
end)

RegisterNetEvent('cabletv:server:requestNextOrder')
AddEventHandler('cabletv:server:requestNextOrder', function()
    local src = source
    if not ActiveWorkers[src] or not ActiveWorkers[src].vehicle then return end
    
    if ActiveWorkers[src].hasActiveOrder then
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = 'У вас уже есть активный заказ!',
            type = 'error'
        })
        return
    end
    
    if ActiveWorkers[src].installs >= Config.Job.InstallsPerShift then
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = 'Лимит заказов на смену исчерпан. Сдайте смену.',
            type = 'error'
        })
        return
    end
    
    ActiveWorkers[src].hasActiveOrder = true
    TriggerClientEvent('cabletv:client:newInstall', src, ActiveWorkers[src].installs + 1)
end)

RegisterNetEvent('cabletv:server:finishShift')
AddEventHandler('cabletv:server:finishShift', function()
    local src = source
    if not ActiveWorkers[src] then return end
    
    -- Нельзя закончить с активным заказом
    if ActiveWorkers[src].hasActiveOrder then
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = 'Сначала завершите текущий заказ!',
            type = 'error'
        })
        return
    end
    
    local payout = ActiveWorkers[src].accumulatedMoney
    local Player = exports['gypsy-core']:GetPlayer(src)
    
    if Player and payout > 0 then
        Player.Functions.AddMoney('cash', payout, 'cabletv-salary')
    end
    
    -- Установить откат и очистить статус работы
    ActiveWorkers[src].cooldown = os.time() + (Config.Job.CooldownMinutes * 60)
    ActiveWorkers[src].vehicle = nil
    ActiveWorkers[src].installs = 0
    ActiveWorkers[src].accumulatedMoney = 0
    ActiveWorkers[src].hasActiveOrder = false
    
    TriggerClientEvent('cabletv:client:endShift', src)
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = string.format('Смена закончена. Выплачено: $%d', payout),
        type = 'success'
    })
end)

RegisterNetEvent('cabletv:server:emergencyFinish')
AddEventHandler('cabletv:server:emergencyFinish', function()
    local src = source
    if not ActiveWorkers[src] then return end
    
    -- Экстренное завершение: без выплат, установка отката
    ActiveWorkers[src].cooldown = os.time() + (Config.Job.CooldownMinutes * 60)
    ActiveWorkers[src].vehicle = nil
    ActiveWorkers[src].installs = 0
    ActiveWorkers[src].accumulatedMoney = 0
    ActiveWorkers[src].hasActiveOrder = false
    
    TriggerClientEvent('cabletv:client:endShift', src)
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = 'Экстренное завершение смены. Выплаты аннулированы.',
        type = 'error'
    })
    
    print('^1[Cable TV] ' .. GetPlayerName(src) .. ' performed emergency finish^0')
end)

RegisterNetEvent('cabletv:server:vehicleDestroyed')
AddEventHandler('cabletv:server:vehicleDestroyed', function()
    local src = source
    local Player = exports['gypsy-core']:GetPlayer(src)
    if not Player or not ActiveWorkers[src] then return end
    
    Player.Functions.RemoveMoney('cash', Config.Payment.VehicleDestroyFine, 'cabletv-vehicle-destroyed')
    
    -- Установить откат (конвертируем минуты в секунды)
    ActiveWorkers[src].cooldown = os.time() + (Config.Job.CooldownMinutes * 60)
    ActiveWorkers[src].vehicle = nil
    
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = 'Фургон уничтожен! Штраф $' .. Config.Payment.VehicleDestroyFine,
        type = 'error',
        duration = 5000
    })
    
    print('^1[Cable TV] ' .. GetPlayerName(src) .. ' destroyed vehicle - fined $' .. Config.Payment.VehicleDestroyFine .. '^0')
end)

AddEventHandler('playerDropped', function()
    local src = source
    if ActiveWorkers[src] then
        ActiveWorkers[src] = nil
    end
end)

print('^2[Cable TV] Server loaded^0')
