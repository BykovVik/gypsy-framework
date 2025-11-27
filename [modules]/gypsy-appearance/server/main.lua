-- Gypsy Appearance - Server Main
-- Server-side logic for appearance system

-- Register with gypsy-core
CreateThread(function()
    while not exports['gypsy-core']:HasService('Core') do
        Wait(100)
    end
    
end)

-- Save appearance to database (called by multicharacter or other systems)
RegisterServerEvent('gypsy-appearance:saveAppearance')
AddEventHandler('gypsy-appearance:saveAppearance', function(citizenid, appearanceData)
    local src = source
    
    if not citizenid or not appearanceData then
        return
    end
    
    -- Save to database - update charinfo.appearance field using JSON_SET
    exports.oxmysql:execute('UPDATE players SET charinfo = JSON_SET(charinfo, "$.appearance", ?) WHERE citizenid = ?', {
        json.encode(appearanceData),
        citizenid
    }, function(affectedRows)
        if affectedRows > 0 then
        else
        end
    end)
end)
