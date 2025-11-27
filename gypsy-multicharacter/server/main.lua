-- ============================================================================
-- GYPSY MULTICHARACTER - SERVER MAIN
-- ============================================================================
-- Main server-side logic for character management and position tracking
-- ============================================================================

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local POSITION_SAVE_INTERVAL_CLIENT = 30000  -- 30 seconds
local POSITION_SAVE_INTERVAL_SERVER = 60000  -- 60 seconds (backup)

-- ============================================================================
-- PLAYER CONNECTION
-- ============================================================================

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    if not license then
        deferrals.done('No license found')
        return
    end
    
    deferrals.defer()
    deferrals.update('Loading character data...')
    Wait(500)
    deferrals.done()
end)

-- ============================================================================
-- CHARACTER MANAGEMENT EVENTS
-- ============================================================================

--- Request character list
RegisterNetEvent('gypsy-multicharacter:server:requestCharacters', function()
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then return end
    
    local characters = CharacterManager.GetCharacters(license)
    TriggerClientEvent('gypsy-multicharacter:client:showSelection', src, {
        characters = characters,
        maxSlots = Config.MaxCharacters,
        spawnPoints = Config.SpawnPoints
    })
end)

--- Create new character
RegisterNetEvent('gypsy-multicharacter:server:createCharacter', function(data)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then return end
    
    local success, citizenid = CharacterManager.CreateCharacter(license, data.slot, data.data)
    
    if success then
        Wait(500)
        local spawnSuccess = SpawnManager.SpawnPlayer(src, citizenid)
        if not spawnSuccess then
            TriggerClientEvent('gypsy-multicharacter:client:showError', src, 'Failed to spawn character')
        end
    else
        TriggerClientEvent('gypsy-multicharacter:client:showError', src, 'Character creation failed')
    end
end)

--- Select existing character
RegisterNetEvent('gypsy-multicharacter:server:selectCharacter', function(citizenid)
    local src = source
    local success = SpawnManager.SpawnPlayer(src, citizenid)
    
    if not success then
        TriggerClientEvent('gypsy-multicharacter:client:showError', src, 'Failed to spawn character')
    end
end)

--- Delete character
RegisterNetEvent('gypsy-multicharacter:server:deleteCharacter', function(citizenid)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then return end
    
    local success = CharacterManager.DeleteCharacter(license, citizenid)
    
    if success then
        TriggerClientEvent('gypsy-multicharacter:client:refreshCharacters', src, 
            CharacterManager.GetCharacters(license))
    else
        TriggerClientEvent('gypsy-multicharacter:client:showError', src, 'Failed to delete character')
    end
end)

-- ============================================================================
-- POSITION TRACKING
-- ============================================================================

--- Update player position (from client)
RegisterNetEvent('gypsy-multicharacter:server:updatePosition', function(position)
    local src = source
    if not position then return end
    
    if _G.Gypsy and _G.Gypsy.Players and _G.Gypsy.Players[src] then
        local citizenid = _G.Gypsy.Players[src].citizenid
        _G.Gypsy.Players[src].position = position
        CharacterManager.UpdatePosition(citizenid, position)
    end
end)

--- Get player position from ped
---@param src number Player server ID
---@return table|nil Position coordinates or nil
local function getPlayerPosition(src)
    local ped = GetPlayerPed(src)
    if ped and DoesEntityExist(ped) then
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        return { x = coords.x, y = coords.y, z = coords.z, w = heading }
    end
    return nil
end

--- Player disconnect - save position
AddEventHandler('playerDropped', function(reason)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    if license and _G.Gypsy and _G.Gypsy.Players and _G.Gypsy.Players[src] then
        local player = _G.Gypsy.Players[src]
        
        if player.citizenid then
            local position = getPlayerPosition(src) or player.position
            
            if position then
                CharacterManager.UpdatePosition(player.citizenid, position)
            end
        end
        
        CharacterManager.ClearCache(license)
        _G.Gypsy.Players[src] = nil
    end
end)

--- Periodic server-side position saving (backup)
CreateThread(function()
    while true do
        Wait(POSITION_SAVE_INTERVAL_SERVER)
        
        if _G.Gypsy and _G.Gypsy.Players then
            for src, player in pairs(_G.Gypsy.Players) do
                if player.citizenid then
                    local position = getPlayerPosition(src)
                    if position then
                        _G.Gypsy.Players[src].position = position
                        CharacterManager.UpdatePosition(player.citizenid, position)
                    end
                end
            end
        end
    end
end)