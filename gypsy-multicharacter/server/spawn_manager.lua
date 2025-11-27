-- ============================================================================
-- GYPSY MULTICHARACTER - SPAWN MANAGER
-- ============================================================================
-- Handles player spawning and session initialization
-- ============================================================================

SpawnManager = {}

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--- Spawn player with character data
---@param src number Player server ID
---@param citizenid string Character citizen ID
---@return boolean success
function SpawnManager.SpawnPlayer(src, citizenid)
    local playerData = CharacterManager.GetCharacter(citizenid)
    if not playerData then 
        return false 
    end

    -- Prepare spawn coordinates
    local coords = playerData.position or Config.SpawnPoints[1].coords
    if not coords.w then 
        coords.w = Config.SpawnPoints[1].heading or 0.0 
    end

    -- Initialize global player session
    _G.Gypsy = _G.Gypsy or {}
    _G.Gypsy.Players = _G.Gypsy.Players or {}
    _G.Gypsy.Players[src] = {
        citizenid = citizenid,
        license = GetPlayerIdentifierByType(src, 'license'),
        position = coords,
        money = playerData.money,
        job = playerData.job,
        metadata = playerData.metadata,
        charinfo = playerData.charinfo
    }

    -- Send spawn data to client
    TriggerClientEvent('gypsy-multicharacter:client:spawnPlayer', src, {
        citizenid = citizenid,
        position = coords,
        money = playerData.money,
        job = playerData.job,
        metadata = playerData.metadata,
        charinfo = playerData.charinfo,
        appearance = playerData.charinfo.appearance or nil
    })

    return true
end