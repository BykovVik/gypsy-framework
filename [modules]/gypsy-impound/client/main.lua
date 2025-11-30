local Gypsy = exports['gypsy-core']:GetCoreObject()

-- ====================================================================================
--                              INIT & BLIPS
-- ====================================================================================

CreateThread(function()
    local blip = AddBlipForCoord(Config.ImpoundLocation.coords)
    SetBlipSprite(blip, Config.ImpoundLocation.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.ImpoundLocation.blip.scale)
    SetBlipColour(blip, Config.ImpoundLocation.blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.ImpoundLocation.blip.label)
    EndTextCommandSetBlipName(blip)
end)

-- ====================================================================================
--                              INTERACTION
-- ====================================================================================

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - Config.ImpoundLocation.coords)
        
        if dist < 10.0 then
            sleep = 0
            DrawMarker(2, Config.ImpoundLocation.coords.x, Config.ImpoundLocation.coords.y, Config.ImpoundLocation.coords.z, 
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.2, 255, 165, 0, 100, false, true, 2, false, nil, nil, false)
            
            if dist < Config.InteractDistance then
                SetTextComponentFormat("STRING")
                AddTextComponentString("Press ~INPUT_CONTEXT~ to open Impound")
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                
                if IsControlJustPressed(0, 38) then -- E
                    TriggerServerEvent('gypsy-impound:server:getVehicles')
                end
            end
        end
        Wait(sleep)
    end
end)

-- ====================================================================================
--                              EVENTS & NUI
-- ====================================================================================

RegisterNetEvent('gypsy-impound:client:openMenu', function(vehicles)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        vehicles = vehicles
    })
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('retrieve', function(data, cb)
    TriggerServerEvent('gypsy-impound:server:retrieveVehicle', data.plate)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNetEvent('gypsy-impound:client:spawnVehicle', function(data)
    local ped = PlayerPedId()
    local model = data.vehicle
    local plate = data.plate
    local mods = data.mods and json.decode(data.mods) or {}
    
    -- Если модель пришла как число (хеш), убедимся что это number
    if tonumber(model) then
        model = tonumber(model)
    end
    
    if not IsModelInCdimage(model) then
        exports['gypsy-notifications']:Notify('Ошибка модели транспорта', 'error')
        return
    end
    
    -- Load Model
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do 
        Wait(10) 
        timeout = timeout + 1
        if timeout > 500 then -- 5 seconds timeout
            exports['gypsy-notifications']:Notify('Ошибка загрузки модели', 'error')
            return
        end
    end
    
    -- Spawn
    local veh = CreateVehicle(model, Config.SpawnPoint.coords.x, Config.SpawnPoint.coords.y, Config.SpawnPoint.coords.z, Config.SpawnPoint.heading, true, false)
    
    if not DoesEntityExist(veh) then
        exports['gypsy-notifications']:Notify('Ошибка создания транспорта', 'error')
        return
    end
    
    -- Set Properties
    SetVehicleNumberPlateText(veh, plate)
    SetEntityAsMissionEntity(veh, true, true)
    
    -- Apply Mods (Simple version, ideally use a helper from garage or core)
    SetVehicleModKit(veh, 0)
    if mods.colors then
        SetVehicleColours(veh, mods.colors.primary, mods.colors.secondary)
    end
    
    -- Warp Ped
    TaskWarpPedIntoVehicle(ped, veh, -1)
    
    -- Notify
    exports['gypsy-notifications']:Notify('Транспорт получен', 'success')
end)
