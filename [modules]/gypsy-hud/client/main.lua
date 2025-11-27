local Gypsy = exports['gypsy-core']:GetCoreObject()

RegisterNetEvent('gypsy:client:coreReady', function()
    Gypsy = exports['gypsy-core']:GetCoreObject()
    
end)

-- Update HUD Loop
CreateThread(function()
    while true do
        Wait(200)
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped) - 100
        if health < 0 then health = 0 end
        if health > 100 then health = 100 end
        local armor = GetPedArmour(ped)
        local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
        
        SendNUIMessage({
            action = "updateStats",
            health = health,
            armor = armor,
            stamina = stamina
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

RegisterNetEvent('gypsy-hud:client:updateVehicle', function(data)
    SendNUIMessage({
        action = "updateVehicle",
        speed = data.speed,
        fuel = data.fuel,
        engine = data.engine,
        locked = data.locked
    })
end)

-- Check if player left vehicle to hide HUD
CreateThread(function()
    local wasInVehicle = false
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped, false)
        
        if wasInVehicle and not inVehicle then
            SendNUIMessage({ action = "hideVehicle" })
        end
        
        wasInVehicle = inVehicle
    end
end)

local isSpawned = false

-- HUD will only show after gypsy-core:client:playerLoaded event
-- This prevents HUD from showing during character creation

RegisterNetEvent('gypsy-core:client:playerLoaded', function()
    isSpawned = true
    
end)

RegisterCommand('showhud', function()
    isSpawned = true
    
end)

-- Hide HUD when paused or in UI
CreateThread(function()
    while true do
        Wait(500)
        -- Hide HUD if: not spawned, paused, or in appearance editor
        if isSpawned and not IsPauseMenuActive() and not _G.IsInAppearanceEditor then
            SendNUIMessage({ action = "show" })
        else
            SendNUIMessage({ action = "hide" })
        end
    end
end)

-- Hide Default HUD Components
CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)

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
