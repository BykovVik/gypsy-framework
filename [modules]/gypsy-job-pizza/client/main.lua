-- Pizza Delivery Job - Client
print('^2[Pizza Delivery] Client loading...^0')

-- Состояние
local isOnShift = false
local currentVehicle = nil
local currentDelivery = nil
local deliveryBlip = nil
local deliveryStartTime = 0

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

-- Маркер взаимодействия у базы (пиццерии)
CreateThread(function()
    while true do
        Wait(0)
        
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(coords - Config.Base.coords)
        
        if distance < 10.0 then
            -- Показать маркер
            DrawMarker(
                1, -- Тип маркера (цилиндр)
                Config.Base.coords.x,
                Config.Base.coords.y,
                Config.Base.coords.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.5, 1.5, 1.0,
                255, 165, 0, 100, -- Оранжевый
                false, true, 2, false, nil, nil, false
            )
            
            if distance < 2.0 then
                if not isOnShift then
                    -- Начать смену
                    SetTextComponentFormat("STRING")
                    AddTextComponentString("~INPUT_CONTEXT~ Начать смену доставки")
                    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                    
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('pizza:server:startShift')
                    end
                elseif isOnShift and not currentDelivery then
                    -- Взять следующий заказ
                    SetTextComponentFormat("STRING")
                    AddTextComponentString("~INPUT_CONTEXT~ Взять следующий заказ")
                    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                    
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('pizza:server:requestNextOrder')
                    end
                end
            end
        else
            Wait(500)
        end
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
    
    -- Отправить netId на сервер
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    print('^3[Pizza Delivery] Sending netId to server: ' .. netId .. '^0')
    TriggerServerEvent('pizza:server:vehicleSpawned', netId)
    
    SetModelAsNoLongerNeeded(model)
end)

--- Новая доставка
RegisterNetEvent('pizza:client:newDelivery')
AddEventHandler('pizza:client:newDelivery', function(deliveryNum)
    -- Случайная точка доставки
    local point = Config.DeliveryPoints[math.random(#Config.DeliveryPoints)]
    currentDelivery = point
    deliveryStartTime = GetGameTimer()
    
    -- Убрать старый блип
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
    end
    
    -- Создать блип доставки
    deliveryBlip = AddBlipForCoord(point)
    SetBlipSprite(deliveryBlip, 1)  -- Marker
    SetBlipColour(deliveryBlip, 5)  -- Yellow
    SetBlipScale(deliveryBlip, 0.8)
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Доставка пиццы")
    EndTextCommandSetBlipName(deliveryBlip)
    
    exports['gypsy-notifications']:Notify(
        string.format('Новый заказ #%d! Доставьте пиццу по адресу', deliveryNum),
        'info',
        4000
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
                    local totalDistance = #(Config.Base.coords - currentDelivery)
                    
                    TriggerServerEvent('pizza:server:deliveryComplete', totalDistance, timeSpent)
                    
                    -- Убрать блип
                    if deliveryBlip then
                        RemoveBlip(deliveryBlip)
                        deliveryBlip = nil
                    end
                    
                    currentDelivery = nil
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
