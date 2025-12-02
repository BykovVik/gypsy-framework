-- Pizza Delivery Job - Client
print('^2[Pizza Delivery] Client loading...^0')

-- Состояние
local isOnShift = false
local currentVehicle = nil
local currentDelivery = nil
local deliveryBlip = nil
local deliveryStartTime = 0
local deliveriesDone = 0
local currentDeliveryTimeLimit = 0  -- Динамическое время для текущей доставки

-- ====================================================================================
--                              INITIALIZATION
-- ====================================================================================

CreateThread(function()
    -- Блип пиццерии на карте
    local blip = AddBlipForCoord(Config.Pizzeria.coords)
    SetBlipSprite(blip, Config.Pizzeria.blip.sprite)
    SetBlipColour(blip, Config.Pizzeria.blip.color)
    SetBlipScale(blip, Config.Pizzeria.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Pizzeria.blip.label)
    EndTextCommandSetBlipName(blip)
end)

-- ====================================================================================
--                              NPC & INTERACTION
-- ====================================================================================

local npcEntity = nil

-- Спавн NPC
CreateThread(function()
    print('^3[Pizza Job] Attempting to spawn NPC...^0')
    if not Config.NPC then 
        print('^1[Pizza Job] Config.NPC is missing!^0') 
        return 
    end

    local model = GetHashKey(Config.NPC.model)
    print('^3[Pizza Job] Requesting model: ' .. Config.NPC.model .. '^0')
    
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do 
        Wait(10) 
        timeout = timeout + 10
        if timeout > 5000 then
            print('^1[Pizza Job] Model load timeout!^0')
            return
        end
    end
    
    print('^3[Pizza Job] Model loaded. Creating ped at: ' .. json.encode(Config.NPC.coords) .. '^0')
    
    npcEntity = CreatePed(4, model, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.heading, false, true)
    
    if DoesEntityExist(npcEntity) then
        print('^2[Pizza Job] NPC Created successfully. ID: ' .. npcEntity .. '^0')
        
        -- Оптимизация и настройка NPC
        SetEntityInvincible(npcEntity, true) -- Бессмертие
        FreezeEntityPosition(npcEntity, true) -- Заморозка позиции
        SetBlockingOfNonTemporaryEvents(npcEntity, true) -- Игнорирование событий
        SetPedDiesWhenInjured(npcEntity, false) -- Не умирать от ранений
        SetPedCanPlayAmbientAnims(npcEntity, false) -- Отключить анимации ожидания
        SetPedCanRagdollFromPlayerImpact(npcEntity, false) -- Не падать от толчков
        SetEntityCanBeDamaged(npcEntity, false) -- Отключить урон
        SetPedFleeAttributes(npcEntity, 0, 0) -- Не убегать
        SetPedCombatAttributes(npcEntity, 17, 1) -- Игнорировать бой
        SetPedAlertness(npcEntity, 0) -- Нулевая бдительность
        
        -- Регистрация в gypsy-interact
        print('^3[Pizza Job] Registering target...^0')
        exports['gypsy-interact']:AddTargetModel(model, {
            {
                label = "Начать смену / Взять заказ",
                icon = "fas fa-pizza-slice",
                event = "pizza:client:interactStartOrNext"
            },
            {
                label = "Закончить смену и получить оплату",
                icon = "fas fa-money-bill-wave",
                serverEvent = "pizza:server:finishShift"
            },
            {
                label = "Прекратить работу",
                icon = "fas fa-door-open",
                event = "pizza:client:quitJob"
            }
        })
        print('^2[Pizza Job] Target registered.^0')
    else
        print('^1[Pizza Job] Failed to create NPC entity!^0')
    end
end)

-- Обработка "Начать смену / Взять заказ"
RegisterNetEvent('pizza:client:interactStartOrNext')
AddEventHandler('pizza:client:interactStartOrNext', function()
    if not isOnShift then
        TriggerServerEvent('pizza:server:startShift')
    else
        if deliveriesDone < Config.Job.DeliveriesPerShift then
            if not currentDelivery then
                TriggerServerEvent('pizza:server:requestNextOrder')
            else
                exports['gypsy-notifications']:Notify('У вас уже есть активный заказ!', 'error')
            end
        else
            exports['gypsy-notifications']:Notify('Лимит доставок исчерпан. Сдайте смену.', 'warning')
        end
    end
end)

-- Обработка "Прекратить работу"
RegisterNetEvent('pizza:client:quitJob')
AddEventHandler('pizza:client:quitJob', function()
    if isOnShift then
        -- Просто сбрасываем состояние, сервер сам разберется при следующем логине или через таймаут
        -- Но лучше уведомить сервер
        TriggerServerEvent('pizza:server:quitJob') -- Нужно добавить на сервер
        
        if currentVehicle and DoesEntityExist(currentVehicle) then
            DeleteVehicle(currentVehicle)
        end
        currentVehicle = nil
        isOnShift = false
        currentDelivery = nil
        if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip = nil end
        
        exports['gypsy-notifications']:Notify('Вы уволились с работы.', 'info')
    else
        exports['gypsy-notifications']:Notify('Вы не работаете.', 'error')
    end
end)

-- ====================================================================================
--                              VEHICLE & DELIVERY
-- ====================================================================================

--- Спавн фургона
RegisterNetEvent('pizza:client:spawnVehicle')
AddEventHandler('pizza:client:spawnVehicle', function()
    print('^3[Pizza Delivery] Client received spawnVehicle event^0')
    
    local model = GetHashKey(Config.VehicleSpawn.model)
    print('^3[Pizza Delivery] Model hash: ' .. model .. '^0')
    
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then
            print('^1[Pizza Delivery] Model loading timeout!^0')
            return
        end
    end
    
    print('^3[Pizza Delivery] Model loaded, creating vehicle...^0')
    
    local vehicle = CreateVehicle(
        model,
        Config.VehicleSpawn.coords.x,
        Config.VehicleSpawn.coords.y,
        Config.VehicleSpawn.coords.z,
        Config.VehicleSpawn.heading,
        true,
        false
    )
    
    if not DoesEntityExist(vehicle) then
        print('^1[Pizza Delivery] Failed to create vehicle!^0')
        return
    end
    
    print('^2[Pizza Delivery] Vehicle created: ' .. vehicle .. '^0')
    
    SetVehicleNumberPlateText(vehicle, "PIZZA" .. math.random(100, 999))
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleFuelLevel(vehicle, 100.0)
    
    -- Посадить игрока
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    
    currentVehicle = vehicle
    isOnShift = true
    deliveriesDone = 0
    
    -- Отправить netId на сервер
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    print('^3[Pizza Delivery] Sending netId to server: ' .. netId .. '^0')
    TriggerServerEvent('pizza:server:vehicleSpawned', netId)
    
    SetModelAsNoLongerNeeded(model)
end)

--- Новая доставка
RegisterNetEvent('pizza:client:newDelivery')
AddEventHandler('pizza:client:newDelivery', function(deliveryNum, deliveryPoint, deliveryTime)
    -- Получаем точку доставки и время от сервера
    currentDelivery = deliveryPoint
    currentDeliveryTimeLimit = deliveryTime
    deliveryStartTime = GetGameTimer()
    
    -- Убрать старый блип
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
    end
    
    -- Создать блип доставки
    deliveryBlip = AddBlipForCoord(currentDelivery)
    SetBlipSprite(deliveryBlip, 1)  -- Marker
    SetBlipColour(deliveryBlip, 5)  -- Yellow
    SetBlipScale(deliveryBlip, 0.8)
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Доставка пиццы")
    EndTextCommandSetBlipName(deliveryBlip)
    
    -- Показать таймер с динамическим временем
    SendNUIMessage({
        action = 'showTimer',
        duration = currentDeliveryTimeLimit
    })
    
    -- Форматируем время для уведомления
    local minutes = math.floor(currentDeliveryTimeLimit / 60)
    local seconds = currentDeliveryTimeLimit % 60
    local distance = math.floor(#(Config.Pizzeria.coords - currentDelivery))
    
    exports['gypsy-notifications']:Notify(
        string.format('Заказ #%d! Доставьте за %d:%02d (~%dм)', deliveryNum, minutes, seconds, distance),
        'info',
        5000
    )
end)

--- Проверка доставки
CreateThread(function()
    while true do
        Wait(0)
        
        if isOnShift and currentDelivery then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local distance = #(coords - currentDelivery)
            
            -- Показать маркер у точки доставки
            if distance < 50.0 then
                DrawMarker(
                    1,
                    currentDelivery.x,
                    currentDelivery.y,
                    currentDelivery.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0,
                    255, 255, 0, 150, -- Желтый
                    false, true, 2, false, nil, nil, false
                )
            end
            
            -- Доставка - нужно нажать E
            if distance < 3.0 then
                -- Подсказка
                SetTextComponentFormat("STRING")
                AddTextComponentString("~INPUT_CONTEXT~ Доставить пиццу")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                
                -- Нажатие E
                if IsControlJustReleased(0, 38) then -- E key
                    local timeSpent = (GetGameTimer() - deliveryStartTime) / 1000
                    local totalDistance = #(Config.NPC.coords - currentDelivery)
                    
                    -- Получить процент оставшегося времени (используем динамическое время)
                    local timePercentage = 100
                    if currentDeliveryTimeLimit > 0 then
                        local timeRemaining = currentDeliveryTimeLimit - timeSpent
                        timePercentage = math.max(0, (timeRemaining / currentDeliveryTimeLimit) * 100)
                    end
                    
                    TriggerServerEvent('pizza:server:deliveryComplete', totalDistance, timeSpent, timePercentage)
                    
                    -- Убрать блип и таймер
                    if deliveryBlip then
                        RemoveBlip(deliveryBlip)
                        deliveryBlip = nil
                    end
                    
                    SendNUIMessage({ action = 'hideTimer' })
                    
                    currentDelivery = nil
                    currentDeliveryTimeLimit = 0
                    deliveriesDone = deliveriesDone + 1
                end
            end
        else
            Wait(500)
        end
    end
end)

--- Завершение смены
RegisterNetEvent('pizza:client:endShift')
AddEventHandler('pizza:client:endShift', function()
    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
    end
    
    currentVehicle = nil
    isOnShift = false
    currentDelivery = nil
    
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
end)

--- Отслеживание уничтожения фургона
CreateThread(function()
    while true do
        Wait(1000)
        
        if isOnShift and currentVehicle then
            if not DoesEntityExist(currentVehicle) or IsEntityDead(currentVehicle) then
                TriggerServerEvent('pizza:server:vehicleDestroyed')
                isOnShift = false
                currentVehicle = nil
                currentDelivery = nil
                
                if deliveryBlip then
                    RemoveBlip(deliveryBlip)
                    deliveryBlip = nil
                end
            end
        end
    end
end)

print('^2[Pizza Delivery] Client loaded^0')
