local hasSpawned = false

RegisterNetEvent('gypsy-spawn:client:spawnPlayer', function()
    print("=== SPAWN REQUEST RECEIVED ===")
    print("Stack trace:", debug.traceback())
    print("hasSpawned:", hasSpawned)
    
    -- Защита от двойного спавна
    if hasSpawned then
        print("^3Gypsy Spawn: Already spawned, ignoring duplicate spawn request^0")
        return
    end
    
    print("^2Gypsy Spawn: Starting spawn process...^0")
    hasSpawned = true
    
    -- 1. Load Default Model (Using a simple NPC for test to avoid invisible freemode ped)
    local defaultModel = `a_m_y_beach_01` 
    RequestModel(defaultModel)
    while not HasModelLoaded(defaultModel) do
        Wait(10)
    end
    
    -- 2. Set Player Model
    SetPlayerModel(PlayerId(), defaultModel)
    SetModelAsNoLongerNeeded(defaultModel)
    
    -- Wait for model to apply
    while GetEntityModel(PlayerPedId()) ~= defaultModel do
        Wait(0)
    end

    -- 3. Teleport and Setup
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped) -- Give him clothes
    SetEntityCoords(ped, Config.SpawnLocation.x, Config.SpawnLocation.y, Config.SpawnLocation.z)
    SetEntityHeading(ped, Config.SpawnLocation.w)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true)
    
    -- 4. Shutdown Loading Screen
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    
    -- 5. Fade In
    DoScreenFadeIn(500)
    print("Gypsy Spawn: Spawn complete.")
end)

RegisterCommand('spawn', function()
    print("Manual spawn triggered")
    hasSpawned = false -- Сбрасываем флаг для ручного спавна
    TriggerEvent('gypsy-spawn:client:spawnPlayer')
end)

-- Сбрасываем флаг при отключении ресурса
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        hasSpawned = false
    end
end)
