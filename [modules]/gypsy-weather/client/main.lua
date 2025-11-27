local CurrentHour = 12
local CurrentMinute = 0

RegisterNetEvent('gypsy-weather:client:syncTime', function(hour, minute)
    CurrentHour = hour
    CurrentMinute = minute
    
    NetworkOverrideClockTime(CurrentHour, CurrentMinute, 0)
    
    -- Emit event for UI/Other scripts
    TriggerEvent('gypsy-weather:client:timeUpdate', CurrentHour, CurrentMinute)
end)

-- Request sync on load
CreateThread(function()
    TriggerServerEvent('gypsy-weather:server:requestSync')
end)
