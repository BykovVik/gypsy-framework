SpawnManager = {}

-- Spawn player by citizenid
function SpawnManager.SpawnPlayer(src, citizenid)
    local playerData = CharacterManager.GetCharacter(citizenid)
    if not playerData then
        return false
    end

    local coords = playerData.position or Config.SpawnPoints[1].coords
    if not coords.w then coords.w = Config.SpawnPoints[1].heading or 0.0 end

    -- Update global players table
    _G.Gypsy = _G.Gypsy or {}
    _G.Gypsy.Players = _G.Gypsy.Players or {}
    _G.Gypsy.Players[src] = {
        citizenid = citizenid,
        license = GetPlayerIdentifierByType(src,'license'),
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