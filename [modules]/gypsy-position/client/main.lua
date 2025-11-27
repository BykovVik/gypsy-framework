-- Gypsy Position Tracking Service - Client
-- Tracks player position and sends updates to server

local PositionService = {}
local isTracking = false

print('^2[Gypsy-Position] Client initialized^0')

-- Start tracking player position
function PositionService:StartTracking()
    if isTracking then return end
    
    isTracking = true
    
    CreateThread(function()
        local Gypsy = exports['gypsy-core']:GetCoreObject()
        
        while isTracking do
            Wait(5000) -- Update every 5 seconds
            
            -- Check if player is loaded
            if Gypsy and Gypsy.PlayerData and Gypsy.PlayerData.citizenid then
                local ped = PlayerPedId()
                if DoesEntityExist(ped) then
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    
                    -- Send position update to server
                    TriggerServerEvent('gypsy-position:server:updatePosition', {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        w = heading
                    })
                end
            end
        end
    end)
end

-- Stop tracking
function PositionService:StopTracking()
    isTracking = false
end

-- Auto-start when player loads
RegisterNetEvent('gypsy-core:client:playerLoaded', function()
    print('^2[Gypsy-Position] Player loaded, starting position tracking^0')
    PositionService:StartTracking()
end)

-- Export service
exports('GetPositionService', function()
    return PositionService
end)
