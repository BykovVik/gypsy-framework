-- Listen for core player load event
RegisterNetEvent('gypsy-core:server:playerLoaded', function(source)
    TriggerClientEvent('gypsy-spawn:client:spawnPlayer', source)
end)
