local Gypsy = exports['gypsy-core']:GetCoreObject()

RegisterNetEvent('gypsy:client:coreReady', function()
    Gypsy = exports['gypsy-core']:GetCoreObject()
    print('[Tweaks] Core Ready Event Received. Gypsy Object Updated.')
end)

-- Apply Physics & Damage Settings
CreateThread(function()
    while true do
        Wait(1000) -- Check every second (optimization)
        local ped = PlayerPedId()
        
        -- Weapon Damage Modifier
        SetPlayerWeaponDamageModifier(PlayerId(), Config.Physics.WeaponDamageMultiplier)
        
        -- Melee Force
        SetPlayerMeleeWeaponDamageModifier(PlayerId(), Config.Physics.MeleeForceMultiplier)
        
        -- Vehicle Damage (when in vehicle)
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            SetVehicleDamageModifier(vehicle, Config.Physics.VehicleDamageMultiplier)
        end
        
        -- Health Regen
        if Config.Player.DisableAutoRegen then
            SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
        end
        
        -- Headshots
        if not Config.Player.HeadshotOneTap then
            SetPedSuffersCriticalHits(ped, false)
        end
    end
end)

-- Apply Atmosphere & Density (Every Frame)
CreateThread(function()
    while true do
        Wait(0)
        -- Density
        SetParkedVehicleDensityMultiplierThisFrame(Config.Atmosphere.ParkedCarDensity)
        SetVehicleDensityMultiplierThisFrame(Config.Atmosphere.TrafficDensity)
        SetRandomVehicleDensityMultiplierThisFrame(Config.Atmosphere.TrafficDensity)
        SetPedDensityMultiplierThisFrame(Config.Atmosphere.PedDensity)
        SetScenarioPedDensityMultiplierThisFrame(Config.Atmosphere.PedDensity, Config.Atmosphere.PedDensity)
        
        -- Visuals
        if Config.Atmosphere.EnableTimecycle then
            SetTimecycleModifier(Config.Atmosphere.TimecycleModifier)
        else
            ClearTimecycleModifier()
        end
        
        -- Infinite Stamina
        if Config.Player.InfiniteStamina then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
    end
end)

-- Ragdoll Handling
if Config.Physics.DisableRagdollOnCollision then
    CreateThread(function()
        while true do
            Wait(100)
            local ped = PlayerPedId()
            if IsPedRagdoll(ped) then
                -- If not dead and not falling from height, try to recover faster
                if not IsEntityDead(ped) and not IsPedFalling(ped) then
                    SetPedRagdollOnCollision(ped, false)
                end
            end
        end
    end)
end

print('[Gypsy-Tweaks] Gameplay adjustments loaded.')
