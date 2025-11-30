-- Test notification from garage
RegisterCommand('testgaragenotify', function()
    print('^3[Garage] Testing notification system...^0')
    
    -- Test 1: Direct export call
    local success1, err1 = pcall(function()
        exports['gypsy-notifications']:Notify('Test from garage', 'info', 3000)
    end)
    print('^3[Test 1] Direct export: ' .. tostring(success1) .. ' | Error: ' .. tostring(err1) .. '^0')
    
    Wait(1000)
    
    -- Test 2: Via helper
    Notify('Test via helper', 'success', 3000)
    
    Wait(1000)
    
    -- Test 3: Via event
    TriggerEvent('gypsy-notifications:client:notify', {
        message = 'Test via event',
        type = 'warning',
        duration = 3000
    })
end, false)
