-- Street Musician Job - Server
print('^2[Musician] Loading...^0')

local ActivePerformers = {}

-- ====================================================================================
--                              HELPER FUNCTIONS
-- ====================================================================================

local function CanStartPerformance(source)
    if ActivePerformers[source] and ActivePerformers[source].cooldown then
        local timeLeft = ActivePerformers[source].cooldown - os.time()
        if timeLeft > 0 then
            return false, timeLeft
        end
    end
    
    return true, 0
end

-- ====================================================================================
--                                  EVENTS
-- ====================================================================================

RegisterNetEvent('musician:server:startPerformance')
AddEventHandler('musician:server:startPerformance', function(locationIndex, instrument)
    local src = source
    local canStart, timeLeft = CanStartPerformance(src)
    
    if not canStart then
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = string.format('Откат: %d мин', math.ceil(timeLeft / 60)),
            type = 'error'
        })
        return
    end
    
    local location = Config.Locations[locationIndex]
    if not location then return end
    
    local instrumentData = Config.Instruments[instrument or Config.DefaultInstrument]
    
    ActivePerformers[src] = {
        performing = true,
        location = location,
        instrument = instrument or Config.DefaultInstrument,
        startTime = os.time(),
        totalEarned = 0,
        cooldown = nil
    }
    
    TriggerClientEvent('musician:client:startPerformance', src, locationIndex)
    
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = string.format('Выступление началось! (%s, %s)', location.label, instrumentData.label),
        type = 'success',
        duration = 3000
    })
    
    print(string.format('^2[Musician] %s started performance at %s with %s^0', 
        GetPlayerName(src), location.label, instrumentData.label))
end)

RegisterNetEvent('musician:server:giveTip')
AddEventHandler('musician:server:giveTip', function()
    local src = source
    local Player = exports['gypsy-core']:GetPlayer(src)
    if not Player or not ActivePerformers[src] or not ActivePerformers[src].performing then return end
    
    -- Случайная сумма чаевых
    local baseTip = math.random(Config.Performance.MinTip, Config.Performance.MaxTip)
    local multiplier = ActivePerformers[src].location.multiplier or 1.0
    local tip = math.floor(baseTip * multiplier)
    
    Player.Functions.AddMoney('cash', tip, 'musician-tip')
    
    ActivePerformers[src].totalEarned = ActivePerformers[src].totalEarned + tip
    
    TriggerClientEvent('gypsy-notifications:client:notify', src, {
        message = string.format('Чаевые: +$%d', tip),
        type = 'success',
        duration = 2000
    })
end)

RegisterNetEvent('musician:server:endPerformance')
AddEventHandler('musician:server:endPerformance', function(completed)
    local src = source
    if not ActivePerformers[src] then return end
    
    local totalEarned = ActivePerformers[src].totalEarned
    
    -- Установить откат
    ActivePerformers[src].cooldown = os.time() + (Config.Performance.CooldownMinutes * 60)
    ActivePerformers[src].performing = false
    
    if completed then
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = string.format('Выступление завершено! Заработано: $%d', totalEarned),
            type = 'success',
            duration = 5000
        })
        
        print(string.format('^2[Musician] %s completed performance: $%d^0', GetPlayerName(src), totalEarned))
    else
        TriggerClientEvent('gypsy-notifications:client:notify', src, {
            message = string.format('Выступление прервано. Заработано: $%d', totalEarned),
            type = 'warning',
            duration = 5000
        })
        
        print(string.format('^3[Musician] %s interrupted performance: $%d^0', GetPlayerName(src), totalEarned))
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if ActivePerformers[src] then
        ActivePerformers[src] = nil
    end
end)

print('^2[Musician] Server loaded^0')
