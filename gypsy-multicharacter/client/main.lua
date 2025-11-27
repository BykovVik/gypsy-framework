-- Gypsy Multicharacter - Client Main
-- Character selection and creation system

local cam = nil
local charPed = nil
local inCharSelection = false
local menuOpen = false
local spawned = false

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Prevent FiveM auto-spawn
AddEventHandler("playerSpawned", function()
    if not spawned then
        spawned = true
        Wait(25)
        exports.spawnmanager:setAutoSpawn(false)
    end
end)

-- Initialize on resource start
CreateThread(function()
    if GetResourceState('spawnmanager') == 'started' then
        exports.spawnmanager:setAutoSpawn(false)
        exports.spawnmanager:setAutoSpawnCallback(function() end)
    end

    SetManualShutdownLoadingScreenNui(true)
    DoScreenFadeOut(0)
    DisplayHud(false)
    DisplayRadar(false)

    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)

    Wait(2000)
    TriggerServerEvent('gypsy-multicharacter:server:requestCharacters')
end)

-- ============================================================================
-- CHARACTER SELECTION UI
-- ============================================================================

RegisterNetEvent('gypsy-multicharacter:client:showSelection', function(data)
    inCharSelection = true
    setupCamera()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'show',
        data = data
    })

    menuOpen = true
    TriggerEvent('gypsy-multicharacter:readyToShowMenu')
    Wait(500)
    DisplayHud(false)
    DisplayRadar(false)
end)

function setupCamera()
    if cam then DestroyCam(cam, false) end

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, Config.CameraCoords.x, Config.CameraCoords.y, Config.CameraCoords.z)
    SetCamRot(cam, 0.0, 0.0, Config.CameraCoords.w)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)

    spawnPreviewPed()
end

function spawnPreviewPed()
    if charPed then DeleteEntity(charPed) end

    local model = GetHashKey('mp_m_freemode_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    charPed = CreatePed(4, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z, Config.PedCoords.w, false, true)
    SetEntityInvincible(charPed, true)
    FreezeEntityPosition(charPed, true)
    SetBlockingOfNonTemporaryEvents(charPed, true)
    SetEntityVisible(charPed, false)
end

-- ============================================================================
-- PLAYER SPAWN
-- ============================================================================

RegisterNetEvent('gypsy-multicharacter:client:spawnPlayer', function(data)
    -- Switch model based on gender
    local model = data.charinfo.gender == 0 and GetHashKey('mp_m_freemode_01') or GetHashKey('mp_f_freemode_01')
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    
    local ped = PlayerPedId()
    local coords = data.position

    DoScreenFadeOut(500)
    Wait(500)
    FreezeEntityPosition(ped, true)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    local timeout = 0
    while not HasCollisionLoadedAroundEntity(ped) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end

    local groundFound, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 100.0, false)
    if groundFound then
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, groundZ + 1.0, false, false, false)
    else
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    end

    SetEntityHeading(ped, coords.w or 0.0)
    SetEntityVisible(ped, true, false)

    inCharSelection = false
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })

    if cam then DestroyCam(cam, false); RenderScriptCams(false, false, 0, true, true); cam=nil end
    if charPed then DeleteEntity(charPed); charPed=nil end

    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetPlayerControl(PlayerId(), true, 0)

    DoScreenFadeIn(1000)
    Wait(500)
    DisplayHud(true)
    DisplayRadar(true)

    -- Apply saved appearance if available
    if data.appearance and GetResourceState('gypsy-appearance') == 'started' then
        exports['gypsy-appearance']:ApplyAppearance(ped, data.appearance)
    end

    TriggerEvent('gypsy-core:client:playerLoaded', data)

    -- Periodic position saving
    CreateThread(function()
        while true do
            Wait(30000)
            local currentPed = PlayerPedId()
            if DoesEntityExist(currentPed) then
                local pos = GetEntityCoords(currentPed)
                local heading = GetEntityHeading(currentPed)
                TriggerServerEvent('gypsy-multicharacter:server:updatePosition', {
                    x=pos.x, y=pos.y, z=pos.z, w=heading
                })
            end
        end
    end)
end)

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

RegisterNetEvent('gypsy-multicharacter:client:refreshCharacters', function(characters)
    SendNUIMessage({ action = 'refreshCharacters', characters = characters })
end)

RegisterNetEvent('gypsy-multicharacter:client:characterCreated', function(citizenid)
    TriggerServerEvent('gypsy-multicharacter:server:selectCharacter', citizenid)
end)

RegisterNetEvent('gypsy-multicharacter:client:showError', function(message)
    SendNUIMessage({ action = 'showError', message = message })
end)