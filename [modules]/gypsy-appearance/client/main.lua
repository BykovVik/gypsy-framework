-- Gypsy Appearance - Client Main
-- Appearance room system with ped creation and camera

local AppearanceState = {
    active = false,
    ped = nil,
    camera = nil,
    savedCoords = nil,
    currentView = 'body',
    gender = 0
}


-- ============================================================================
-- APPEARANCE ROOM WORKFLOW
-- ============================================================================

-- Start appearance editor
RegisterNetEvent('gypsy-appearance:client:start', function(data)
    if AppearanceState.active then
        return
    end
    
    AppearanceState.active = true
    AppearanceState.gender = data.gender or 0
    AppearanceState.savedCoords = GetEntityCoords(PlayerPedId())
    
    -- Fade out
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Load interior IPL
    RequestIpl("rc12b_default")
    
    -- Teleport to appearance room
    local coords = Config.AppearanceRoom.coords
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
    SetEntityHeading(PlayerPedId(), coords.w)
    
    -- Wait for collision and interior
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    
    -- Get interior ID and refresh
    local interiorId = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if interiorId and interiorId ~= 0 then
        RefreshInterior(interiorId)
    else
    end
    
    local timeout = 0
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    Wait(500) -- Extra wait for interior to fully load
    
    -- Create ped
    CreateAppearancePed(AppearanceState.gender)
    
    -- Place ped on ground (DISABLED - using manual Z coordinate)
    --[[
    Wait(100)
    local ped = AppearanceState.ped
    if ped and DoesEntityExist(ped) then
        local pedCoords = GetEntityCoords(ped)
        local groundFound, groundZ = GetGroundZFor_3dCoord(pedCoords.x, pedCoords.y, pedCoords.z + 5.0, false)
        
        if groundFound then
            SetEntityCoordsNoOffset(ped, pedCoords.x, pedCoords.y, groundZ, false, false, false)
        else
        end
    end
    ]]--
    
    -- Setup camera
    SetupAppearanceCamera('body')
    
    -- Hide HUD
    DisplayHud(false)
    DisplayRadar(false)
    
    -- Fade in
    DoScreenFadeIn(1000)
    Wait(500)
    
    -- Open NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openEditor',
        data = {
            gender = AppearanceState.gender,
            config = {
                hairstyles = Config.Hairstyles,
                hairColors = Config.HairColors,
                eyeColors = Config.EyeColors,
                clothing = Config.Clothing
            }
        }
    })
    
end)

-- ============================================================================
-- PED CREATION
-- ============================================================================

function CreateAppearancePed(gender)
    local model = gender == 1 and `mp_f_freemode_01` or `mp_m_freemode_01`
    
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    
    -- Change player model
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    
    Wait(100)
    AppearanceState.ped = PlayerPedId()
    
    -- Apply default components
    SetPedDefaultComponentVariation(AppearanceState.ped)
    
    -- Apply default clothing
    local defaultClothing = Config.DefaultClothing[gender == 1 and 'female' or 'male']
    SetPedComponentVariation(AppearanceState.ped, 11, defaultClothing.torso.drawable, defaultClothing.torso.texture, 0)
    SetPedComponentVariation(AppearanceState.ped, 4, defaultClothing.legs.drawable, defaultClothing.legs.texture, 0)
    SetPedComponentVariation(AppearanceState.ped, 6, defaultClothing.shoes.drawable, defaultClothing.shoes.texture, 0)
    SetPedComponentVariation(AppearanceState.ped, 3, defaultClothing.arms.drawable, defaultClothing.arms.texture, 0)
    
    -- Make ped visible
    SetEntityVisible(AppearanceState.ped, true, false)
    SetEntityAlpha(AppearanceState.ped, 255, false)
    
    -- Freeze ped
    FreezeEntityPosition(AppearanceState.ped, true)
    
    local coords = GetEntityCoords(AppearanceState.ped)
end

-- ============================================================================
-- CAMERA SYSTEM
-- ============================================================================

function SetupAppearanceCamera(view)
    if AppearanceState.camera then
        DestroyCam(AppearanceState.camera, false)
    end
    
    local viewConfig = Config.Camera.views[view]
    local ped = AppearanceState.ped
    
    if not ped or not DoesEntityExist(ped) then
        return
    end
    
    -- Get ped position and heading
    local pedCoords = GetEntityCoords(ped)
    local pedHeading = GetEntityHeading(ped)
    
    
    -- Calculate camera position in front of ped
    local radians = math.rad(pedHeading)
    local camX = pedCoords.x + (viewConfig.offset.y * math.sin(radians))
    local camY = pedCoords.y + (viewConfig.offset.y * math.cos(radians))
    local camZ = pedCoords.z + viewConfig.offset.z
    
    -- Create camera
    AppearanceState.camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(AppearanceState.camera, camX, camY, camZ)
    
    -- Point camera at ped
    if view == 'face' then
        -- Point at head bone
        local headCoords = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
        PointCamAtCoord(AppearanceState.camera, headCoords.x, headCoords.y, headCoords.z)
    else
        -- Point at ped center (lower for full body view including shoes)
        local targetZ = pedCoords.z + 0.2
        PointCamAtCoord(AppearanceState.camera, pedCoords.x, pedCoords.y, targetZ)
    end
    
    SetCamFov(AppearanceState.camera, viewConfig.fov)
    SetCamActive(AppearanceState.camera, true)
    RenderScriptCams(true, true, 500, true, true)
    
    AppearanceState.currentView = view
    
end

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('updateAppearance', function(data, cb)
    if AppearanceState.ped and DoesEntityExist(AppearanceState.ped) then
        ApplyAppearanceToPed(AppearanceState.ped, data)
    end
    cb('ok')
end)

RegisterNUICallback('changeCamera', function(data, cb)
    SetupAppearanceCamera(data.view or 'body')
    cb('ok')
end)

RegisterNUICallback('saveAppearance', function(data, cb)
    
    -- Use appearance data from NUI (already contains all changes)
    local appearance = data
    
    -- Add gender to appearance
    appearance.gender = AppearanceState.gender
    
    
    -- Cleanup
    CleanupAppearanceEditor()
    
    -- Emit event with appearance data
    TriggerEvent('gypsy-appearance:appearanceSaved', appearance)
    
    cb('ok')
end)

RegisterNUICallback('closeEditor', function(data, cb)
    
    CleanupAppearanceEditor()
    TriggerEvent('gypsy-appearance:cancelled')
    
    cb('ok')
end)

-- ============================================================================
-- CLEANUP
-- ============================================================================

function CleanupAppearanceEditor()
    AppearanceState.active = false
    
    -- Close NUI
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'closeEditor'})
    
    -- Destroy camera
    if AppearanceState.camera then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(AppearanceState.camera, false)
        AppearanceState.camera = nil
    end
    
    -- Unfreeze ped
    if AppearanceState.ped and DoesEntityExist(AppearanceState.ped) then
        FreezeEntityPosition(AppearanceState.ped, false)
    end
    
    -- Restore HUD
    DisplayHud(true)
    DisplayRadar(true)
    
    AppearanceState.ped = nil
    
end

-- ============================================================================
-- DEBUG COMMAND
-- ============================================================================

RegisterCommand('appcam', function(source, args)
    if not AppearanceState.active then
        return
    end
    
    local view = args[1] or 'body'
    SetupAppearanceCamera(view)
end, false)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('StartEditor', function(data)
    TriggerEvent('gypsy-appearance:client:start', data)
end)

exports('ApplyAppearance', function(ped, data)
    ApplyAppearanceToPed(ped or PlayerPedId(), data)
end)

exports('GetAppearance', function(ped)
    return GetPedAppearance(ped or PlayerPedId())
end)
