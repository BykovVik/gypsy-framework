local CurrentHour = Config.Time.StartHour
local CurrentMinute = Config.Time.StartMinute

-- Time Loop
CreateThread(function()
    while true do
        Wait(Config.Time.TimeStep)
        
        CurrentMinute = CurrentMinute + 1
        if CurrentMinute >= 60 then
            CurrentMinute = 0
            CurrentHour = CurrentHour + 1
            if CurrentHour >= 24 then
                CurrentHour = 0
            end
        end
        
        -- Sync with all clients
        TriggerClientEvent('gypsy-weather:client:syncTime', -1, CurrentHour, CurrentMinute)
    end
end)

-- Sync on request (join)
RegisterNetEvent('gypsy-weather:server:requestSync', function()
    local src = source
    TriggerClientEvent('gypsy-weather:client:syncTime', src, CurrentHour, CurrentMinute)
end)

RegisterCommand('time', function(source)
    local src = source
    print('^2[Gypsy-Weather] Current Time: ' .. string.format("%02d:%02d", CurrentHour, CurrentMinute) .. '^0')
    if src > 0 then
        TriggerClientEvent('chat:addMessage', src, {
            args = {'^2[Weather]', 'Current Time: ' .. string.format("%02d:%02d", CurrentHour, CurrentMinute)}
        })
    end
end)
