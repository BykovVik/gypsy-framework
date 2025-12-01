-- Warehouse Job - Client
print('^2[Warehouse] Client loading...^0')

local isWorking = false
local currentWarehouse = nil
local carryingBox = false
local boxProp = nil
local isIllegal = false
local boxesDelivered = 0

-- Очистка при перезагрузке ресурса
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Удалить ящик если есть
    if boxProp and DoesEntityExist(boxProp) then
        DeleteObject(boxProp)
    end
    
    -- Очистить анимацию
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end)

-- ====================================================================================
--                              INITIALIZATION
-- ====================================================================================

CreateThread(function()
    Wait(1000) -- Ждём загрузки конфига
    
    print('^2[Warehouse] Creating blip at: ' .. tostring(Config.Warehouse.coords) .. '^0')
    
    local blip = AddBlipForCoord(Config.Warehouse.coords)
    SetBlipSprite(blip, Config.Warehouse.blip.sprite)
    SetBlipColour(blip, Config.Warehouse.blip.color)
    SetBlipScale(blip, Config.Warehouse.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Warehouse.blip.label)
    EndTextCommandSetBlipName(blip)
    
    print('^2[Warehouse] Blip created successfully^0')
end)

-- Маркер начала работы
CreateThread(function()
    while true do
        Wait(0)
        
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(coords - Config.Warehouse.coords)
        
        if distance < 10.0 then
            DrawMarker(1, Config.Warehouse.coords.x, Config.Warehouse.coords.y, Config.Warehouse.coords.z - 1.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0,
                255, 200, 0, 100, false, true, 2, false, nil, nil, false)
            
            if distance < 2.0 and not isWorking then
                SetTextComponentFormat("STRING")
                AddTextComponentString("~INPUT_CONTEXT~ Начать смену")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent('warehouse:server:startShift')
                end
            end
        else
            Wait(500)
        end
    end
end)

-- ====================================================================================
--                              WORK LOGIC
-- ====================================================================================

RegisterNetEvent('warehouse:client:startShift')
AddEventHandler('warehouse:client:startShift', function(illegal)
    isWorking = true
    isIllegal = illegal
    boxesDelivered = 0
    
    -- Выбираем случайный склад
    currentWarehouse = Config.Warehouses[math.random(#Config.Warehouses)]
    
    -- Создаём блипы для точек погрузки и разгрузки
    CreateWarehouseBlips()
    
    -- Показываем первую точку погрузки
    ShowLoadPoint()
end)

function CreateWarehouseBlips()
    if not currentWarehouse then return end
    
    -- Блип точки погрузки (зелёный)
    local loadBlip = AddBlipForCoord(currentWarehouse.loadPoint)
    SetBlipSprite(loadBlip, 478)
    SetBlipColour(loadBlip, 2)  -- Green
    SetBlipScale(loadBlip, 0.7)
    SetBlipAsShortRange(loadBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Погрузка")
    EndTextCommandSetBlipName(loadBlip)
    
    -- Блип точки разгрузки (красный)
    local unloadBlip = AddBlipForCoord(currentWarehouse.unloadPoint)
    SetBlipSprite(unloadBlip, 478)
    SetBlipColour(unloadBlip, 1)  -- Red
    SetBlipScale(unloadBlip, 0.7)
    SetBlipAsShortRange(unloadBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Разгрузка")
    EndTextCommandSetBlipName(unloadBlip)
end

function ShowLoadPoint()
    if not isWorking then return end
    
    CreateThread(function()
        while isWorking and not carryingBox do
            Wait(0)
            
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local distance = #(coords - currentWarehouse.loadPoint)
            
            if distance < 20.0 then
                -- Маркер точки погрузки
                DrawMarker(1, currentWarehouse.loadPoint.x, currentWarehouse.loadPoint.y, currentWarehouse.loadPoint.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0,
                    0, 255, 0, 150, false, true, 2, false, nil, nil, false)
                
                if distance < 2.0 then
                    SetTextComponentFormat("STRING")
                    AddTextComponentString("~INPUT_CONTEXT~ Взять ящик")
                    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                    
                    if IsControlJustReleased(0, 38) then
                        PickupBox()
                        break
                    end
                end
            else
                Wait(500)
            end
        end
    end)
end

function PickupBox()
    local ped = PlayerPedId()
    
    -- Загрузить анимацию
    RequestAnimDict(Config.Animations.carry.dict)
    while not HasAnimDictLoaded(Config.Animations.carry.dict) do
        Wait(10)
    end
    
    -- Проп ящика
    local propModel = isIllegal and Config.Props.illegal or Config.Props.normal
    local propHash = GetHashKey(propModel)
    
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do
        Wait(10)
    end
    
    -- Создать ящик в руках
    local coords = GetEntityCoords(ped)
    boxProp = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, true)
    
    AttachEntityToEntity(boxProp, ped, GetPedBoneIndex(ped, 60309), 
        0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, true, 1, true)
    
    -- Анимация переноски
    TaskPlayAnim(ped, Config.Animations.carry.dict, Config.Animations.carry.anim, 
        8.0, -8.0, -1, Config.Animations.carry.flag, 0, false, false, false)
    
    carryingBox = true
    
    -- Показать точку разгрузки
    ShowUnloadPoint()
end

function ShowUnloadPoint()
    if not isWorking then return end
    
    CreateThread(function()
        while isWorking and carryingBox do
            Wait(0)
            
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local distance = #(coords - currentWarehouse.unloadPoint)
            
            if distance < 20.0 then
                -- Маркер точки разгрузки
                DrawMarker(1, currentWarehouse.unloadPoint.x, currentWarehouse.unloadPoint.y, currentWarehouse.unloadPoint.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0,
                    255, 0, 0, 150, false, true, 2, false, nil, nil, false)
                
                if distance < 2.0 then
                    SetTextComponentFormat("STRING")
                    AddTextComponentString("~INPUT_CONTEXT~ Разгрузить ящик")
                    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                    
                    if IsControlJustReleased(0, 38) then
                        UnloadBox()
                        break
                    end
                end
            else
                Wait(500)
            end
        end
    end)
end

function UnloadBox()
    local ped = PlayerPedId()
    
    -- Удалить проп
    if boxProp and DoesEntityExist(boxProp) then
        DeleteObject(boxProp)
        boxProp = nil
    end
    
    -- Остановить анимацию
    ClearPedTasks(ped)
    
    carryingBox = false
    boxesDelivered = boxesDelivered + 1
    
    -- Уведомить сервер
    TriggerServerEvent('warehouse:server:boxDelivered')
end

RegisterNetEvent('warehouse:client:nextBox')
AddEventHandler('warehouse:client:nextBox', function()
    -- Показать следующую точку погрузки
    Wait(1000)
    ShowLoadPoint()
end)

RegisterNetEvent('warehouse:client:endShift')
AddEventHandler('warehouse:client:endShift', function()
    -- Очистка
    if boxProp and DoesEntityExist(boxProp) then
        DeleteObject(boxProp)
        boxProp = nil
    end
    
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    
    isWorking = false
    carryingBox = false
    currentWarehouse = nil
    isIllegal = false
    boxesDelivered = 0
end)

print('^2[Warehouse] Client loaded^0')
