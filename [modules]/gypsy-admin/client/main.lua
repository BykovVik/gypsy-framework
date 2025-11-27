local Gypsy = exports['gypsy-core']:GetCoreObject()

RegisterNetEvent('gypsy:client:coreReady', function()
    QBCore = exports['gypsy-core']:GetCoreObject()
    print('[Admin] Core Ready Event Received. Gypsy Object Updated.')
end)
local noClipEnabled = false
local noClipSpeed = 2.0

RegisterNetEvent('gypsy-admin:client:revive', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    ResurrectPed(ped)
    SetEntityHealth(ped, 200)
    ClearPedTasksImmediately(ped)
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
    
    -- Trigger core event to reset death state (if we had one)
    -- TriggerEvent('gypsy-death:client:revive') 
    
    print("Revived!")
end)

RegisterNetEvent('gypsy-admin:client:toggleNoclip', function()
    noClipEnabled = not noClipEnabled
    local ped = PlayerPedId()
    
    if noClipEnabled then
        SetEntityCollision(ped, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityVisible(ped, false, false)
        print("Noclip Enabled")
    else
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityVisible(ped, true, false)
        print("Noclip Disabled")
    end
end)

-- Noclip Loop
CreateThread(function()
    while true do
        if noClipEnabled then
            local ped = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(ped))
            local camH, camP, camR = table.unpack(GetGameplayCamRot(2))
            local dx, dy, dz = GetCamDirection()
            local speed = noClipSpeed

            SetEntityVelocity(ped, 0.05, 0.05, 0.05)
            SetEntityRotation(ped, 0, 0, 0, 0, false)
            SetEntityHeading(ped, camH)

            -- Forward
            if IsControlPressed(0, 32) then -- W
                x = x + speed * dx
                y = y + speed * dy
                z = z + speed * dz
            end

            -- Backward
            if IsControlPressed(0, 269) then -- S
                x = x - speed * dx
                y = y - speed * dy
                z = z - speed * dz
            end
            
            -- Up
            if IsControlPressed(0, 22) then -- Space
                z = z + speed
            end
            
            -- Down
            if IsControlPressed(0, 36) then -- Ctrl
                z = z - speed
            end

            SetEntityCoordsNoOffset(ped, x, y, z, true, true, true)
        else
            Wait(1000)
        end
        Wait(0)
    end
end)

function GetCamDirection()
    local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
    local pitch = GetGameplayCamRelativePitch()

    local x = -math.sin(heading * math.pi / 180.0)
    local y = math.cos(heading * math.pi / 180.0)
    local z = math.sin(pitch * math.pi / 180.0)

    local len = math.sqrt(x * x + y * y + z * z)
    if len ~= 0 then
        x = x / len
        y = y / len
        z = z / len
    end

    return x, y, z
end

RegisterNetEvent('gypsy-admin:client:tpm', function()
    local waypoint = GetFirstBlipInfoId(8)
    if DoesBlipExist(waypoint) then
        local coords = GetBlipInfoIdCoord(waypoint)
        local ped = PlayerPedId()
        
        -- Find ground Z
        local groundFound = false
        local zVal = 0.0
        
        for i = 0, 1000, 10 do
            SetEntityCoordsNoOffset(ped, coords.x, coords.y, i + 0.0, false, false, false)
            Wait(0)
            local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, i + 0.0)
            if found then
                zVal = z
                groundFound = true
                break
            end
        end
        
        if not groundFound then zVal = 100.0 end
        
        SetEntityCoords(ped, coords.x, coords.y, zVal + 1.0)
        print("Teleported to waypoint")
    else
        print("No waypoint set")
    end
end)

RegisterNetEvent('gypsy-admin:client:teleport', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
end)

-- Спавн машины
RegisterNetEvent('gypsy-admin:client:spawnVehicle', function(model)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Хэш модели
    local hash = GetHashKey(model)
    
    -- Проверяем существование модели
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        print('[Admin] Invalid vehicle model: ' .. model)
        TriggerEvent('chat:addMessage', { args = { '^1SYSTEM', 'Invalid vehicle model: ' .. model } })
        return
    end
    
    -- Загружаем модель
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    
    -- Удаляем старую машину если игрок в ней
    local currentVeh = GetVehiclePedIsIn(ped, false)
    if currentVeh ~= 0 then
        DeleteVehicle(currentVeh)
    end
    
    -- Спавним машину перед игроком
    local forward = GetEntityForwardVector(ped)
    local spawnCoords = vector3(
        coords.x + forward.x * 3.0,
        coords.y + forward.y * 3.0,
        coords.z
    )
    
    local vehicle = CreateVehicle(hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)
    
    -- Настройки машины
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    
    -- Сажаем игрока в машину
    TaskWarpPedIntoVehicle(ped, vehicle, -1)
    
    -- Выдаем ключи (если есть система ключей)
    if GetResourceState('gypsy-vehicle') == 'started' then
        local plate = GetVehicleNumberPlateText(vehicle)
        TriggerServerEvent('gypsy-vehicle:server:giveKeys', plate)
    end
    
    SetModelAsNoLongerNeeded(hash)
    
    print('[Admin] Spawned vehicle: ' .. model)
    TriggerEvent('chat:addMessage', { args = { '^2SYSTEM', 'Spawned vehicle: ' .. model } })
end)
