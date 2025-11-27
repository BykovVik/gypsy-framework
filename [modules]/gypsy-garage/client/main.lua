local Gypsy = exports['gypsy-core']:GetCoreObject()

RegisterNetEvent('gypsy:client:coreReady', function()
    Gypsy = exports['gypsy-core']:GetCoreObject()
    
end)

-- Blips
CreateThread(function()
    for garage, data in pairs(Config.Garages) do
        local blip = AddBlipForCoord(data.putVehicle.x, data.putVehicle.y, data.putVehicle.z)
        SetBlipSprite(blip, data.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, data.blip.scale)
        SetBlipColour(blip, data.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(data.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

-- Open Garage Menu
local function OpenGarageMenu(garage)
    
    TriggerServerEvent('gypsy-garage:server:getMyVehicles', garage)
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('spawn', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('gypsy-garage:server:spawnVehicle', data.plate)
    cb('ok')
end)

-- Interaction Loop
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local sleep = 1000
        
        for garage, data in pairs(Config.Garages) do
            -- Park Zone
            local distPark = #(coords - data.putVehicle)
            if distPark < 15.0 then
                sleep = 0
                DrawMarker(1, data.putVehicle.x, data.putVehicle.y, data.putVehicle.z - 1.0, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                
                if distPark < 5.0 then
                    if IsPedInAnyVehicle(ped, false) then
                        SetTextComponentFormat("STRING")
                        AddTextComponentString("Press ~INPUT_CONTEXT~ (E) to Park")
                        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                        
                        if IsControlJustPressed(0, 38) then -- E
                            
                            local veh = GetVehiclePedIsIn(ped, false)
                            if veh ~= 0 then
                                local plate = GetVehicleNumberPlateText(veh)
                                plate = string.gsub(plate, "^%s*(.-)%s*$", "%1")
                                local props = Gypsy.Functions.GetVehicleProperties(veh)
                                
                                TriggerServerEvent('gypsy-garage:server:parkVehicle', plate, props)
                            end
                        end
                    end
                end
            end
            
            -- Spawn Zone (Take Vehicle)
            local takeCoords = vector3(data.takeVehicle.x, data.takeVehicle.y, data.takeVehicle.z)
            local distSpawn = #(coords - takeCoords)
            if distSpawn < 15.0 then
                sleep = 0
                DrawMarker(36, takeCoords.x, takeCoords.y, takeCoords.z, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)
                
                if distSpawn < 2.0 then
                    if not IsPedInAnyVehicle(ped, false) then
                        SetTextComponentFormat("STRING")
                        AddTextComponentString("Press ~INPUT_CONTEXT~ (E) to Open Garage")
                        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                        
                        if IsControlJustPressed(0, 38) then -- E
                            
                            OpenGarageMenu(garage)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Events
RegisterNetEvent('gypsy-garage:client:parkSuccess', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
        if DoesEntityExist(veh) then DeleteEntity(veh) end
    end
end)

RegisterNetEvent('gypsy-garage:client:openMenu', function(vehicles)
    
    if vehicles then
        SetNuiFocus(true, true)
        
        
        SendNUIMessage({
            action = "openGarage",
            vehicles = vehicles
        })
    else
        
    end
end)

RegisterNetEvent('gypsy-garage:client:spawnVehicleCallback', function(vehData)
    
    
    local ped = PlayerPedId()
    -- Find spawn point (Legion for now, or based on garage)
    local spawn = Config.Garages['legion'].spawnPoint
    
    
    local hash = GetHashKey("adder")
    if vehData.vehicle ~= 'unknown' then 
        -- Check if it's a number (hash) or a string name
        if tonumber(vehData.vehicle) then
            hash = tonumber(vehData.vehicle)
            
        else
            hash = GetHashKey(vehData.vehicle)
            
        end
    end
    
    
    RequestModel(hash)
    local attempts = 0
    while not HasModelLoaded(hash) do 
        Wait(10) 
        attempts = attempts + 1
        if attempts > 500 then -- Increased to 5 seconds
            
            return
        end
    end
    
    
    local veh = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    
    
    SetPedIntoVehicle(ped, veh, -1)
    SetVehicleNumberPlateText(veh, vehData.plate)
    
    if vehData.mods then
        local props = json.decode(vehData.mods)
        
        
        -- Attempt 1: Immediate Core Apply
        if Gypsy and Gypsy.Functions then
            Gypsy.Functions.SetVehicleProperties(veh, props)
        end
        
        -- Aggressive Sync Loop (5 times over 2.5 seconds)
        CreateThread(function()
            for i = 1, 5 do
                Wait(500)
                if DoesEntityExist(veh) then
                    -- Force Fuel Native directly
                    if props.fuelLevel then
                        SetVehicleFuelLevel(veh, props.fuelLevel + 0.0)
                    end
                    
                    -- Force Engine Health Native directly
                    if props.engineHealth then
                        SetVehicleEngineHealth(veh, props.engineHealth + 0.0)
                    end
                    
                    
                else
                    break
                end
            end
        end)
    end

    TriggerEvent('gypsy-vehicle:client:giveKeys', vehData.plate)
    
end)
