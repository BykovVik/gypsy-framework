-- Gypsy Appearance - Camera System
-- Camera controls for appearance editor

local camera = nil
local currentView = 'body'

-- ============================================================================
-- CAMERA SETUP
-- ============================================================================

function SetupCamera(view, ped)
    if camera then
        CleanupCamera()
    end
    
    currentView = view or 'body'
    
    -- Use passed ped or fallback to PlayerPedId
    local targetPed = ped or PlayerPedId()
    
    if not DoesEntityExist(targetPed) then 
        return 
    end
    
    -- Calculate camera position relative to ped (Front view)
    -- offsets: right, forward, up
    local offsets = {
        face = { y = 0.8, z = 0.6 },  -- Close up, high
        body = { y = 2.5, z = 0.2 },  -- Full body, slightly up
        legs = { y = 2.0, z = -0.5 }  -- Lower body
    }
    
    local offset = offsets[currentView] or offsets.body
    
    -- Get position in front of ped
    local camCoords = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, offset.y, offset.z)
    
    -- Create camera
    camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(camera, camCoords.x, camCoords.y, camCoords.z)
    
    -- Point at specific bone or offset
    if currentView == 'face' then
        -- Point at head (SKEL_Head = 31086)
        local headCoords = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
        PointCamAtCoord(camera, headCoords.x, headCoords.y, headCoords.z)
    else
        -- Point at center of ped
        PointCamAtEntity(camera, targetPed, 0.0, 0.0, 0.0, true)
    end
    
    SetCamFov(camera, 40.0) -- Standard FOV
    SetCamActive(camera, true)
    RenderScriptCams(true, true, 500, true, true)
    
end

-- ============================================================================
-- CAMERA CLEANUP
-- ============================================================================

function CleanupCamera()
    if camera then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(camera, false)
        camera = nil
    end
end

-- ============================================================================
-- CAMERA ROTATION (for future use)
-- ============================================================================

function RotateCamera(direction)
    if not camera or not currentPed then return end
    
    local pedHeading = GetEntityHeading(currentPed)
    local newHeading = pedHeading + (direction * 5.0) -- Rotate 5 degrees
    
    SetEntityHeading(currentPed, newHeading)
end
