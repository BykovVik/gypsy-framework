-- ============================================================================
-- GYPSY MULTICHARACTER - NUI CALLBACKS
-- ============================================================================
-- Handles all NUI communication for character selection and creation
-- ============================================================================

-- ============================================================================
-- CHARACTER SELECTION
-- ============================================================================

RegisterNUICallback('selectCharacter', function(data, cb)
    TriggerServerEvent('gypsy-multicharacter:server:selectCharacter', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    TriggerServerEvent('gypsy-multicharacter:server:deleteCharacter', data.citizenid)
    cb('ok')
end)

-- ============================================================================
-- CHARACTER CREATION WITH APPEARANCE
-- ============================================================================

RegisterNUICallback('createCharacter', function(data, cb)
    -- Check if appearance module is available
    if GetResourceState('gypsy-appearance') == 'started' then
        -- Close multicharacter UI
        SetNuiFocus(false, false)
        SendNUIMessage({action = 'hide'})
        
        -- Listen for appearance completion (one-time)
        local appearanceHandler
        appearanceHandler = AddEventHandler('gypsy-appearance:appearanceSaved', function(appearance)
            RemoveEventHandler(appearanceHandler)
            
            -- Add appearance to character data
            data.data.appearance = appearance
            
            -- Show spawn selection
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'showSpawnSelection',
                data = {
                    spawnPoints = Config.SpawnPoints,
                    characterData = data
                }
            })
        end)
        
        -- Listen for cancellation
        local cancelHandler
        cancelHandler = AddEventHandler('gypsy-appearance:cancelled', function()
            RemoveEventHandler(cancelHandler)
            RemoveEventHandler(appearanceHandler)
            
            -- Return to character selection
            TriggerServerEvent('gypsy-multicharacter:server:requestCharacters')
        end)
        
        -- Trigger appearance editor
        TriggerEvent('gypsy-appearance:client:start', {
            gender = data.data.gender
        })
    else
        -- Create character without appearance
        TriggerServerEvent('gypsy-multicharacter:server:createCharacter', data)
    end
    
    cb('ok')
end)

-- ============================================================================
-- SPAWN LOCATION SELECTION
-- ============================================================================

RegisterNUICallback('selectSpawnLocation', function(data, cb)
    -- Add spawn point to character data
    data.characterData.data.spawnPoint = data.spawnPoint
    
    -- Create character with appearance and spawn point
    TriggerServerEvent('gypsy-multicharacter:server:createCharacter', data.characterData)
    
    -- Hide spawn selection
    SetNuiFocus(false, false)
    
    cb('ok')
end)