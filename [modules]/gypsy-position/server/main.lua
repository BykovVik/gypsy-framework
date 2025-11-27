-- Gypsy Position Tracking Service - Server
-- Receives position updates and saves to player data

print('^2[Gypsy-Position] Server initialized^0')

-- Register with Service Locator
CreateThread(function()
    while GetResourceState('gypsy-core') ~= 'started' do
        Wait(100)
    end
    
    exports['gypsy-core']:RegisterService('PositionService', {
        name = 'PositionService',
        version = '1.0.0'
    })
    
    print('^2[Gypsy-Position] Registered with Service Locator^0')
end)

-- Handle position updates from client
RegisterNetEvent('gypsy-position:server:updatePosition', function(position)
    local src = source
    
    -- Get player from gypsy-core
    local Player = exports['gypsy-core']:GetPlayer(src)
    
    print('^3[Gypsy-Position] Update request from source=' .. src .. '^0')
    print('^3[Gypsy-Position] Player object type: ' .. type(Player) .. '^0')
    
    if Player then
        print('^3[Gypsy-Position] Player.citizenid = ' .. tostring(Player.citizenid) .. '^0')
        print('^3[Gypsy-Position] Player.position type = ' .. type(Player.position) .. '^0')
    end
    
    if Player and position then
        -- Update position in player data
        Player.position = position
        
        -- Debug logging
        print('^2[Gypsy-Position] Updating position for citizenid=' .. Player.citizenid .. ': x=' .. position.x .. ', y=' .. position.y .. ', z=' .. position.z .. '^0')
        
        local posJson = json.encode(position)
        print('^3[Gypsy-Position] Position JSON: ' .. posJson .. '^0')
        print('^3[Gypsy-Position] Executing SQL: UPDATE players SET position = \'' .. posJson .. '\' WHERE citizenid = \'' .. Player.citizenid .. '\''^0')
        
        -- Save to database immediately with callback
        MySQL.execute('UPDATE players SET position = ? WHERE citizenid = ?', {
            json.encode(position),
            Player.citizenid
        }, function(result)
            print('^3[Gypsy-Position] SQL callback received, result type: ' .. type(result) .. '^0')
            if type(result) == 'table' then
                for k, v in pairs(result) do
                    print('^3[Gypsy-Position] result.' .. k .. ' = ' .. tostring(v) .. '^0')
                end
            end
            
            -- oxmysql returns a table with affectedRows
            local affected = result and result.affectedRows or result or 0
            if affected > 0 then
                print('^2[Gypsy-Position] ✓ Position saved to DB for citizenid=' .. Player.citizenid .. '^0')
            else
                print('^1[Gypsy-Position] ✗ WARNING: Update affected 0 rows for citizenid=' .. Player.citizenid .. '!^0')
            end
        end)
    else
        if not Player then
            print('^1[Gypsy-Position] ERROR: Player not found for source ' .. src .. '^0')
        end
        if not position then
            print('^1[Gypsy-Position] ERROR: No position data received^0')
        end
    end
end)
