-- Cable TV Job - Client
print('^2[Cable TV] Client loading...^0')

local isOnShift = false
local currentVehicle = nil
local currentInstall = nil
local installBlip = nil
local installStartTime = 0

-- ====================================================================================
--                              INITIALIZATION
-- ====================================================================================

CreateThread(function()
    local blip = AddBlipForCoord(Config.Company.coords)
    SetBlipSprite(blip, Config.Company.blip.sprite)
    SetBlipColour(blip, Config.Company.blip.color)
    SetBlipScale(blip, Config.Company.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Company.blip.label)
    EndTextCommandSetBlipName(blip)
end)

-- Маркер базы
CreateThread(function()
    while true do
        Wait(0)
        
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(coords - Config.Base.coords)
        
        if distance < 10.0 then
            DrawMarker(1, Config.Base.coords.x, Config.Base.coords.y, Config.Base.coords.z - 1.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0,
                0, 100, 255, 100, false, true, 2, false, nil, nil, false)
            
            if distance < 2.0 then
                if not isOnShift then
                    SetTextComponentFormat("STRING")
                    AddTextComponentString("~INPUT_CONTEXT~ Начать смену")
                    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                    
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('cabletv:server:startShift')
                    end
                elseif isOnShift and not currentInstall then
                    SetTextComponentFormat("STRING")
                    AddTextComponentString("~INPUT_CONTEXT~ Взять следующий заказ")
                    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                    
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('cabletv:server:requestNextOrder')
                    end
                end
            end
        else
            Wait(500)
        end
    end
end)

-- ====================================================================================
--                              VEHICLE & INSTALLATION
-- ====================================================================================

RegisterNetEvent('cabletv:client:spawnVehicle')
AddEventHandler('cabletv:client:spawnVehicle', function()
    local model = GetHashKey(Config.VehicleSpawn.model)
    RequestModel(model)
    
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then
            print('^1[Cable TV] Model loading timeout!^0')
            return
        end
    end
    
    local vehicle = CreateVehicle(model, Config.VehicleSpawn.coords.x, Config.VehicleSpawn.coords.y,
        Config.VehicleSpawn.coords.z, Config.VehicleSpawn.heading, true, false)
    
    if not DoesEntityExist(vehicle) then
        print('^1[Cable TV] Failed to create vehicle!^0')
        return
    end
    
    SetVehicleNumberPlateText(vehicle, "CABLE" .. math.random(100, 999))
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleFuelLevel(vehicle, 100.0)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    
    currentVehicle = vehicle
    isOnShift = true
    
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('cabletv:server:vehicleSpawned', netId)
    
    SetModelAsNoLongerNeeded(model)
end)

RegisterNetEvent('cabletv:client:newInstall')
AddEventHandler('cabletv:client:newInstall', function(installNum)
    local point = Config.InstallPoints[math.random(#Config.InstallPoints)]
    currentInstall = point
    installStartTime = GetGameTimer()
    
    if installBlip then RemoveBlip(installBlip) end
    
    installBlip = AddBlipForCoord(point.coords)
    SetBlipSprite(installBlip, 1)
    SetBlipColour(installBlip, 3)
    SetBlipScale(installBlip, 0.8)
    SetBlipRoute(installBlip, true)
    SetBlipRouteColour(installBlip, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Установка антенны: " .. point.label)
    EndTextCommandSetBlipName(installBlip)
    
    exports['gypsy-notifications']:Notify('Новый заказ: ' .. point.label, 'info', 4000)
end)

-- Проверка установки
CreateThread(function()
    while true do
        Wait(0)
        
        if isOnShift and currentInstall then
            local coords = GetEntityCoords(PlayerPedId())
            local distance = #(coords - currentInstall.coords)
            
            if distance < 50.0 then
                DrawMarker(1, currentInstall.coords.x, currentInstall.coords.y, currentInstall.coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.0,
                    0, 100, 255, 150, false, true, 2, false, nil, nil, false)
            end
            
            if distance < 3.0 then
                SetTextComponentFormat("STRING")
                AddTextComponentString("~INPUT_CONTEXT~ Установить антенну")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                
                if IsControlJustReleased(0, 38) then
                    StartInstallMinigame()
                end
            end
        else
            Wait(500)
        end
    end
end)

-- Мини-игра установки
function StartInstallMinigame()
    local successCount = 0
    local totalChecks = Config.Job.SkillCheckCount
    
    for i = 1, totalChecks do
        local channelName = Config.ChannelNames[math.random(#Config.ChannelNames)]
        exports['gypsy-notifications']:Notify('Настройка канала: ' .. channelName, 'info', 2000)
        
        Wait(500)
        
        -- Запустить skill check
        local checkSuccess = false
        local checkFinished = false
        
        exports['gypsy-minigames']:SkillCheck(Config.Job.SkillCheckDifficulty, function(success)
            checkSuccess = success
            checkFinished = true
        end)
        
        -- Ждём результата (максимум 10 секунд)
        local waited = 0
        while not checkFinished and waited < 10000 do
            Wait(100)
            waited = waited + 100
        end
        
        if checkSuccess then
            successCount = successCount + 1
        end
        
        Wait(500)
    end
    
    local totalDistance = #(Config.Base.coords - currentInstall.coords)
    TriggerServerEvent('cabletv:server:installComplete', totalDistance, successCount)
    
    if installBlip then
        RemoveBlip(installBlip)
        installBlip = nil
    end
    
    currentInstall = nil
end

RegisterNetEvent('cabletv:client:endShift')
AddEventHandler('cabletv:client:endShift', function()
    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
    end
    
    currentVehicle = nil
    isOnShift = false
    currentInstall = nil
    
    if installBlip then
        RemoveBlip(installBlip)
        installBlip = nil
    end
end)

-- Отслеживание уничтожения фургона
CreateThread(function()
    while true do
        Wait(1000)
        
        if isOnShift and currentVehicle then
            if not DoesEntityExist(currentVehicle) or IsEntityDead(currentVehicle) then
                TriggerServerEvent('cabletv:server:vehicleDestroyed')
                isOnShift = false
                currentVehicle = nil
                currentInstall = nil
                
                if installBlip then
                    RemoveBlip(installBlip)
                    installBlip = nil
                end
            end
        end
    end
end)

print('^2[Cable TV] Client loaded^0')
