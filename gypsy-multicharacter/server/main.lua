-- Gypsy Multicharacter - Server Main
-- Character management server-side

-- Player connecting
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

-- Request characters
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

-- Create character
RegisterNetEvent('gypsy-multicharacter:server:createCharacter', function(data)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then return end
    
    local success, citizenid = CharacterManager.CreateCharacter(license, data.slot, data.data)
    if success then
        -- Auto-spawn the new character
        Wait(500)
        local spawnSuccess = SpawnManager.SpawnPlayer(src, citizenid)
        if not spawnSuccess then
            TriggerClientEvent('gypsy-multicharacter:client:showError', src, 'Failed to spawn character')
        end
    else
        TriggerClientEvent('gypsy-multicharacter:client:showError', src, 'Character creation failed')
    end
end)

-- Select character
RegisterNetEvent('gypsy-multicharacter:server:selectCharacter', function(citizenid)
    local src = source
    local success = SpawnManager.SpawnPlayer(src, citizenid)
    if not success then
        TriggerClientEvent('gypsy-multicharacter:client:showError', src, 'Failed to spawn character')
    end
end)

-- Delete character
RegisterNetEvent('gypsy-multicharacter:server:deleteCharacter', function(citizenid)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then return end
    local success = CharacterManager.DeleteCharacter(license, citizenid)
    if success then
        TriggerClientEvent('gypsy-multicharacter:client:refreshCharacters', src, CharacterManager.GetCharacters(license))
    else
        TriggerClientEvent('gypsy-multicharacter:client:showError', src, 'Failed to delete character')
    end
end)

-- Update position
RegisterNetEvent('gypsy-multicharacter:server:updatePosition', function(position)
    local src = source
    if not position then return end
    if _G.Gypsy and _G.Gypsy.Players and _G.Gypsy.Players[src] then
        local citizenid = _G.Gypsy.Players[src].citizenid
        _G.Gypsy.Players[src].position = position
        CharacterManager.UpdatePosition(citizenid, position)
    end
end)

-- Player disconnect
AddEventHandler('playerDropped', function(reason)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    if license and _G.Gypsy and _G.Gypsy.Players and _G.Gypsy.Players[src] then
        local player = _G.Gypsy.Players[src]
        if player.citizenid then
            -- Try to get actual ped position on disconnect
            local ped = GetPlayerPed(src)
            local position = nil
            if ped and DoesEntityExist(ped) then
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                position = { x = coords.x, y = coords.y, z = coords.z, w = heading }
            elseif player.position then
                position = player.position
            end
            
            if position then
                CharacterManager.UpdatePosition(player.citizenid, position)
            end
        end
        CharacterManager.ClearCache(license)
        _G.Gypsy.Players[src] = nil
    end
end)

-- Periodic server-side position saving (backup to client-side)
CreateThread(function()
    while true do
        Wait(60000) -- Every 60 seconds
        if _G.Gypsy and _G.Gypsy.Players then
            for src, player in pairs(_G.Gypsy.Players) do
                if player.citizenid then
                    local ped = GetPlayerPed(src)
                    if ped and DoesEntityExist(ped) then
                        local coords = GetEntityCoords(ped)
                        local heading = GetEntityHeading(ped)
                        local position = { x = coords.x, y = coords.y, z = coords.z, w = heading }
                        _G.Gypsy.Players[src].position = position
                        CharacterManager.UpdatePosition(player.citizenid, position)
                    end
                end
            end
        end
    end
end)

-- Debug command to check position saving
RegisterCommand('checkpos', function(source, args)
    local src = source
    if _G.Gypsy and _G.Gypsy.Players and _G.Gypsy.Players[src] then
        local player = _G.Gypsy.Players[src]
        print('^3[Debug] Player '..src..' citizenid: '..player.citizenid..'^0')
        if player.position then
            print('^3[Debug] Cached position: '..player.position.x..', '..player.position.y..', '..player.position.z..'^0')
        else
            print('^1[Debug] No cached position!^0')
        end
        
        -- Check DB (must be in async context)
        CreateThread(function()
            local result = MySQL.single.await('SELECT position FROM players WHERE citizenid=?', {player.citizenid})
            if result and result.position then
                local dbPos = json.decode(result.position)
                print('^2[Debug] DB position: '..dbPos.x..', '..dbPos.y..', '..dbPos.z..'^0')
            else
                print('^1[Debug] No position in DB! Result: '..(result and 'exists but no position' or 'nil')..'^0')
            end
        end)
    else
        print('^1[Debug] Player not in Gypsy.Players table!^0')
    end
end, false)