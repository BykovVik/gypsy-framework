local Gypsy = exports['gypsy-core']:GetCoreObject()

RegisterNetEvent('gypsy:client:coreReady', function()
    Gypsy = exports['gypsy-core']:GetCoreObject()
    print('[Death] Core Ready Event Received. Gypsy Object Updated.')
end)
local isDead = false
local deathTime = 0

-- Configuration
local RespawnTime = 10 -- Seconds
local HospitalCoords = vector3(299.0, -584.0, 43.0)
local HospitalHeading = 74.0

-- Death Loop
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        
        if IsEntityDead(ped) and not isDead then
            sleep = 0
            OnDeath()
        end
        
        if isDead then
            sleep = 0
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true) -- Camera Look
            EnableControlAction(0, 2, true) -- Camera Look
            EnableControlAction(0, 245, true) -- Chat
            EnableControlAction(0, 38, true) -- E (Respawn)
        end
        
        Wait(sleep)
    end
end)

function OnDeath()
    isDead = true
    deathTime = RespawnTime
    
    SendNUIMessage({
        action = "open",
        time = deathTime
    })
    
    SetNuiFocus(false, false) -- Focus false so we can use game controls (E to respawn)
    
    -- Timer Loop
    CreateThread(function()
        while isDead and deathTime > 0 do
            Wait(1000)
            deathTime = deathTime - 1
            SendNUIMessage({
                action = "updateTime",
                time = deathTime
            })
        end
    end)
    
    -- Respawn Key Loop
    CreateThread(function()
        while isDead do
            Wait(0)
            if deathTime <= 0 then
                if IsControlJustPressed(0, 38) then -- E
                    RespawnPlayer()
                end
            end
        end
    end)
end

function RespawnPlayer()
    local ped = PlayerPedId()
    
    -- Revive logic
    DoScreenFadeOut(500)
    Wait(500)
    
    NetworkResurrectLocalPlayer(HospitalCoords.x, HospitalCoords.y, HospitalCoords.z, HospitalHeading, true, false)
    SetEntityHealth(ped, 200)
    ClearPedTasksImmediately(ped)
    
    isDead = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "close"
    })
    
    DoScreenFadeIn(500)
    print("Respawned at hospital")
end

-- Admin Revive Support
RegisterNetEvent('gypsy-death:client:revive', function()
    if isDead then
        isDead = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = "close"
        })
    end
end)
