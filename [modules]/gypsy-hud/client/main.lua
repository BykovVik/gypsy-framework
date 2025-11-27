local Gypsy = exports['gypsy-core']:GetCoreObject()

RegisterNetEvent('gypsy:client:coreReady', function()
    Gypsy = exports['gypsy-core']:GetCoreObject()
    
end)

-- Initialize: Hide radar on start
CreateThread(function()
    DisplayRadar(false)
end)

-- Debug command to check HUD state
RegisterCommand('checkhud', function()
    print('isInAppearanceEditor:', isInAppearanceEditor)
    print('IsPauseMenuActive:', IsPauseMenuActive())
end, false)

-- Update HUD Loop (Player Stats)
CreateThread(function()
    while true do
        Wait(200)
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped) - 100
        if health < 0 then health = 0 end
        if health > 100 then health = 100 end
        local armor = GetPedArmour(ped)
        local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
        
        -- Microphone indicator (voice activity)
        local isTalking = NetworkIsPlayerTalking(PlayerId())
        local micLevel = isTalking and 100 or 0
        
        SendNUIMessage({
            action = "updateStats",
            health = health,
            armor = armor,
            stamina = stamina,
            microphone = micLevel
        })
    end
end)

RegisterNetEvent('gypsy-hud:client:updateStatus', function(metadata)
    SendNUIMessage({
        action = "updateStatus",
        hunger = metadata.hunger,
        thirst = metadata.thirst
    })
end)

-- Vehicle HUD Loop (High Frequency for Smoothness)
CreateThread(function()
    local wasInVehicle = false
    
    while true do
        local ped = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped, false)
        
        if inVehicle then
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            -- If just entered, ensure HUD is shown
            if not wasInVehicle then
                SendNUIMessage({
                    action = "updateVehicle",
                    speed = 0,
                    fuel = GetVehicleFuelLevel(vehicle),
                    engine = GetVehicleEngineHealth(vehicle),
                    locked = GetVehicleDoorLockStatus(vehicle)
                })
            end
            
            -- Continuous update
            SendNUIMessage({
                action = "updateVehicle",
                speed = GetEntitySpeed(vehicle) * 2.236936, -- MPH
                fuel = GetVehicleFuelLevel(vehicle),
                engine = GetVehicleEngineHealth(vehicle),
                locked = GetVehicleDoorLockStatus(vehicle)
            })
            
            Wait(50) -- 50ms update rate for smooth animation
        else
            -- If just left, hide HUD
            if wasInVehicle then
                SendNUIMessage({ action = "hideVehicle" })
            end
            
            Wait(1000) -- Check less frequently when not in vehicle
        end
        
        wasInVehicle = inVehicle
    end
end)

-- Local flag for appearance editor state
local isInAppearanceEditor = false

-- Get Gypsy Core EventBus
CreateThread(function()
    Wait(500) -- Wait for core to load
    local Gypsy = exports['gypsy-core']:GetCoreObject()
    
    if Gypsy and Gypsy.EventBus then
        -- Subscribe to appearance editor events via EventBus
        Gypsy.EventBus:On('appearance:editor:opened', function()
            isInAppearanceEditor = true
            print('[HUD] Appearance editor opened (via EventBus)')
        end)
        
        Gypsy.EventBus:On('appearance:editor:closed', function()
            isInAppearanceEditor = false
            print('[HUD] Appearance editor closed (via EventBus)')
        end)
        
        print('[HUD] Subscribed to appearance editor events via EventBus')
    else
        print('^3[HUD] Warning: EventBus not available, falling back to direct events^0')
        
        -- Fallback to direct events if EventBus not available
        RegisterNetEvent('gypsy-hud:client:hideForEditor', function()
            isInAppearanceEditor = true
            print('[HUD] Received hide event (fallback)')
        end)
        
        RegisterNetEvent('gypsy-hud:client:showAfterEditor', function()
            isInAppearanceEditor = false
            print('[HUD] Received show event (fallback)')
        end)
    end
end)

-- Hide HUD when paused or in appearance editor
CreateThread(function()
    while true do
        Wait(500)
        
        -- Hide HUD only if: paused or in appearance editor
        if not IsPauseMenuActive() and not isInAppearanceEditor then
            SendNUIMessage({ action = "show" })
        else
            SendNUIMessage({ action = "hide" })
        end
    end
end)

-- Hide Default HUD Components
CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")

    while true do
        Wait(0)
        -- Hide Health & Armor
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()

        -- Hide other components
        HideHudComponentThisFrame(3) -- Cash
        HideHudComponentThisFrame(4) -- MP Cash
        HideHudComponentThisFrame(6) -- Vehicle Name
        HideHudComponentThisFrame(7) -- Area Name
        HideHudComponentThisFrame(8) -- Vehicle Class
        HideHudComponentThisFrame(9) -- Street Name
    end
end)

-- NUI Callbacks for Radar Control
RegisterNUICallback('showRadar', function(data, cb)
    DisplayRadar(true)
    cb('ok')
end)

RegisterNUICallback('hideRadar', function(data, cb)
    DisplayRadar(false)
    cb('ok')
end)

-- Listen for time updates from gypsy-weather
RegisterNetEvent('gypsy-weather:client:timeUpdate', function(hour, minute)
    local isNight = (hour >= 21 or hour < 6)
    SendNUIMessage({
        action = "updateTime",
        isNight = isNight
    })
end)
