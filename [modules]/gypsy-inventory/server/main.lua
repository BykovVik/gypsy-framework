local Gypsy = exports['gypsy-core']:GetCoreObject()
local Inventories = {}

-- ====================================================================================
--                              INVENTORY SERVICE
-- ====================================================================================

local InventoryService = {
    version = '1.0.0',
    
    --- Добавляет предмет в инвентарь
    AddItem = function(source, item, amount, info)
        return AddItem(source, item, amount, info)
    end,
    
    --- Удаляет предмет из инвентаря
    RemoveItem = function(source, slot, amount)
        return RemoveItem(source, slot, amount)
    end,
    
    --- Получает инвентарь игрока
    GetInventory = function(source)
        local player = exports['gypsy-core']:GetPlayer(source)
        if not player then return nil end
        return Inventories[player.citizenid]
    end,
    
    --- Перемещает предмет между слотами
    MoveItem = function(source, fromSlot, toSlot)
        -- Логика уже реализована в RegisterNetEvent
        TriggerEvent('gypsy-inventory:server:moveItem', source, fromSlot, toSlot)
        return true
    end,
    
    --- Регистрирует используемый предмет
    CreateUseableItem = function(itemName, callback)
        if not UsableItems then UsableItems = {} end
        UsableItems[itemName] = callback
    end
}

-- Регистрируем сервис в ServiceLocator
CreateThread(function()
    Wait(1000) -- Ждем загрузки Core
    exports['gypsy-core']:RegisterService('Inventory', InventoryService, {
        version = '1.0.0',
        description = 'Gypsy Inventory System'
    })
    print('^2[Inventory] Service registered in ServiceLocator^0')
end)

-- Initialize DB Table
CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `gypsy_inventory` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(50) NOT NULL,
            `items` longtext DEFAULT NULL,
            `maxweight` int(11) DEFAULT 100000,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- Load Inventory Function
function LoadInventory(src, citizenid)
    exports.oxmysql:execute('SELECT items FROM gypsy_inventory WHERE identifier = ?', {citizenid}, function(result)
        if result and result[1] then
            print('[Inventory] Found inventory for ' .. citizenid)
            local rawItems = json.decode(result[1].items) or {}
            Inventories[citizenid] = {}
            -- Normalize keys to numbers
            for k, v in pairs(rawItems) do
                Inventories[citizenid][tonumber(k)] = v
            end
        else
            print('[Inventory] Creating new inventory for ' .. citizenid)
            Inventories[citizenid] = {}
            -- Give starter items
            Inventories[citizenid][1] = {name = "water", amount = 2, info = {}, slot = 1}
            Inventories[citizenid][2] = {name = "burger", amount = 2, info = {}, slot = 2}
            SaveInventory(citizenid)
        end
        print('[Inventory] Sending data to client: ' .. json.encode(Inventories[citizenid]))
        TriggerClientEvent('gypsy-inventory:client:setInventory', src, Inventories[citizenid])
    end)
end

-- Event: Player Loaded
RegisterNetEvent('gypsy-core:server:playerLoaded', function(playerData)
    local src = source
    
    -- Debug print
    print('[Inventory] PlayerLoaded event triggered. Type of playerData: ' .. type(playerData))

    -- Handle case where playerData is just the source ID
    if type(playerData) == 'number' then
        print('[Inventory] playerData is a number, fetching player data from Core...')
        local player = exports['gypsy-core']:GetPlayer(playerData)
        if player then
            playerData = { citizenid = player.citizenid }
        else
            print('^1[Inventory] Error: Could not find player for ID ' .. playerData .. '^0')
            return
        end
    end

    if playerData and playerData.citizenid then
        LoadInventory(src, playerData.citizenid)
    else
        print('^1[Inventory] Error: Invalid playerData received in playerLoaded^0')
    end
end)

RegisterNetEvent('gypsy-inventory:server:requestSync', function()
    local src = source
    print('[Inventory] Sync requested by ' .. src)
    
    -- Try to get player data
    local player = exports['gypsy-core']:GetPlayer(src)
    if player then
        print('[Inventory] Player found, loading inventory for citizenid: ' .. player.citizenid)
        LoadInventory(src, player.citizenid)
    else
        -- Player data not ready yet, retry after delay
        print('[Inventory] Player data not ready, retrying in 500ms...')
        SetTimeout(500, function()
            player = exports['gypsy-core']:GetPlayer(src)
            if player then
                print('[Inventory] Player found on retry, loading inventory for citizenid: ' .. player.citizenid)
                LoadInventory(src, player.citizenid)
            else
                print('^1[Inventory] Error: Player still not found after retry for source ' .. src .. '^0')
            end
        end)
    end
end)

-- Event: Resource Start (Hot-load fix)
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    Wait(1000)
    for _, src in ipairs(GetPlayers()) do
        local player = exports['gypsy-core']:GetPlayer(tonumber(src))
        if player then
            print('[Inventory] Hot-loading inventory for ' .. GetPlayerName(src))
            LoadInventory(tonumber(src), player.citizenid)
        end
    end
end)

-- Event: Core Ready (Hot-load fix for gypsy-core restart)
AddEventHandler('gypsy:server:coreReady', function()
    print('[Inventory] Core restarted, reloading all inventories...')
    Wait(1000) -- Wait for core to fully initialize
    for _, src in ipairs(GetPlayers()) do
        local player = exports['gypsy-core']:GetPlayer(tonumber(src))
        if player then
            print('[Inventory] Reloading inventory for ' .. GetPlayerName(src) .. ' (citizenid: ' .. player.citizenid .. ')')
            LoadInventory(tonumber(src), player.citizenid)
        end
    end
end)

-- Command: Give Item
RegisterCommand('giveitem', function(source, args)
    local src = source
    print('[Inventory] giveitem command called by ' .. src)
    local item = args[1]
    local amount = tonumber(args[2]) or 1
    
    if not item then 
        print('[Inventory] Usage: /giveitem [item] [amount]')
        TriggerClientEvent('chat:addMessage', src, {args = {'System', 'Usage: /giveitem [item] [amount]'}})
        return 
    end
    
    local player = exports['gypsy-core']:GetPlayer(tonumber(src))
    if not player then 
        print('[Inventory] Error: Player not found in Core. Try relogging.')
        TriggerClientEvent('chat:addMessage', src, {args = {'System', 'Error: Player not found. Try relogging.'}})
        return 
    end
    
    -- Find empty slot
    local slot = nil
    for i=1, Config.MaxSlots do
        if not Inventories[player.citizenid][i] then
            slot = i
            break
        end
    end
    
    if slot then
        Inventories[player.citizenid][slot] = {name = item, amount = amount, info = {}, slot = slot}
        SaveInventory(player.citizenid)
        TriggerClientEvent('gypsy-inventory:client:setInventory', src, Inventories[player.citizenid])
        print('Gave ' .. amount .. 'x ' .. item .. ' to slot ' .. slot)
    else
        print('Inventory full!')
    end
end)

-- Export: Add Item
function AddItem(source, item, amount, info)
    local src = source
    
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then return false end
    
    -- Auto-initialize inventory if not loaded
    if not Inventories[player.citizenid] then
        print('[Inventory] Warning: Inventory not loaded for ' .. player.citizenid .. ', initializing...')
        Inventories[player.citizenid] = {}
        -- Try to load from database synchronously
        local result = exports.oxmysql:executeSync('SELECT items FROM gypsy_inventory WHERE identifier = ?', {player.citizenid})
        if result and result[1] then
            local rawItems = json.decode(result[1].items) or {}
            for k, v in pairs(rawItems) do
                Inventories[player.citizenid][tonumber(k)] = v
            end
            print('[Inventory] Loaded existing inventory from database')
        else
            print('[Inventory] No existing inventory found, creating new one')
        end
        -- Sync to client immediately after initialization
        TriggerClientEvent('gypsy-inventory:client:setInventory', src, Inventories[player.citizenid])
    end

    -- Check for existing stack
    local foundSlot = nil
    for slot, itemData in pairs(Inventories[player.citizenid]) do
        if itemData.name == item then
            foundSlot = slot
            break
        end
    end

    if foundSlot then
        Inventories[player.citizenid][foundSlot].amount = Inventories[player.citizenid][foundSlot].amount + amount
        SaveInventory(player.citizenid)
        TriggerClientEvent('gypsy-inventory:client:setInventory', src, Inventories[player.citizenid])
        
        -- Emit event через EventBus
        exports['gypsy-core']:Emit('inventory:itemAdded', src, item, amount, foundSlot, 'stacked')
        
        return true
    end

    -- Find empty slot
    local slot = nil
    for i=1, Config.MaxSlots do
        if not Inventories[player.citizenid][i] then
            slot = i
            break
        end
    end
    
    if slot then
        Inventories[player.citizenid][slot] = {name = item, amount = amount, info = info or {}, slot = slot}
        SaveInventory(player.citizenid)
        TriggerClientEvent('gypsy-inventory:client:setInventory', src, Inventories[player.citizenid])
        
        -- Emit event через EventBus
        exports['gypsy-core']:Emit('inventory:itemAdded', src, item, amount, slot, 'new')
        
        return true
    else
        return false
    end
end

exports('AddItem', AddItem)

RegisterCommand('myitems', function(source)
    local src = source
    local player = exports['gypsy-core']:GetPlayer(src)
    if player then
        TriggerClientEvent('chat:addMessage', src, {args = {'Inv', 'Checking inventory for ' .. player.citizenid}})
        if Inventories[player.citizenid] then
            local count = 0
            for slot, item in pairs(Inventories[player.citizenid]) do
                count = count + 1
                local msg = 'Slot ' .. slot .. ': ' .. item.amount .. 'x ' .. item.name
                print(msg)
                TriggerClientEvent('chat:addMessage', src, {args = {'Inv', msg}})
            end
            if count == 0 then
                TriggerClientEvent('chat:addMessage', src, {args = {'Inv', 'Inventory is empty.'}})
            end
        else
            TriggerClientEvent('chat:addMessage', src, {args = {'Inv', 'No inventory data found!'}})
        end
    end
end)

-- Save Inventory
function SaveInventory(citizenid)
    if Inventories[citizenid] then
        print('[Inventory] Saving inventory for ' .. citizenid)
        exports.oxmysql:execute('INSERT INTO gypsy_inventory (identifier, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = ?', {
            citizenid, json.encode(Inventories[citizenid]), json.encode(Inventories[citizenid])
        }, function()
            print('[Inventory] Saved.')
        end)
    end
end

AddEventHandler('playerDropped', function()
    local src = source
    local player = exports['gypsy-core']:GetPlayer(src)
    if player then
        SaveInventory(player.citizenid)
        Inventories[player.citizenid] = nil
    end
end)

-- Usable Items System
local UsableItems = {}

exports('CreateUseableItem', function(item, cb)
    UsableItems[item] = cb
end)

RegisterNetEvent('gypsy-inventory:server:useItem', function(slot, amount)
    local src = source
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then return end
    
    amount = amount or 1
    
    local inventory = Inventories[player.citizenid]
    local itemData = inventory[slot] or inventory[tostring(slot)]
    
    if itemData then
        if itemData.amount < amount then
            print('[Inventory] Not enough items. Has: ' .. itemData.amount .. ', Requested: ' .. amount)
            return
        end
        
        if UsableItems[itemData.name] then
            -- Use the item 'amount' times
            for i = 1, amount do
                UsableItems[itemData.name](src, itemData)
            end
        end
    end
end)

RegisterNetEvent('gypsy-inventory:server:moveItem', function(fromSlot, toSlot)
    local src = source
    print('[Inventory] Server received moveItem event from ' .. src .. '. From: ' .. tostring(fromSlot) .. ' To: ' .. tostring(toSlot))
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then return end
    local citizenid = player.citizenid
    
    if not Inventories[citizenid] then return end
    
    local fromItem = Inventories[citizenid][fromSlot]
    local toItem = Inventories[citizenid][toSlot]
    
    if not fromItem then return end -- Nothing to move
    
    print('[Inventory] Moving item from ' .. fromSlot .. ' to ' .. toSlot)
    
    if toItem then
        -- Swap or Stack
        if fromItem.name == toItem.name then
            -- Stack
            print('[Inventory] Stacking ' .. fromItem.name)
            Inventories[citizenid][toSlot].amount = Inventories[citizenid][toSlot].amount + fromItem.amount
            Inventories[citizenid][fromSlot] = nil
        else
            -- Swap
            print('[Inventory] Swapping items')
            Inventories[citizenid][toSlot] = fromItem
            Inventories[citizenid][toSlot].slot = toSlot
            
            Inventories[citizenid][fromSlot] = toItem
            Inventories[citizenid][fromSlot].slot = fromSlot
        end
    else
        -- Move to empty
        print('[Inventory] Moving to empty slot')
        Inventories[citizenid][toSlot] = fromItem
        Inventories[citizenid][toSlot].slot = toSlot
        Inventories[citizenid][fromSlot] = nil
    end
    
    SaveInventory(citizenid)
    TriggerClientEvent('gypsy-inventory:client:setInventory', src, Inventories[citizenid])
end)

RegisterNetEvent('gypsy-inventory:server:dropItem', function(slot, amount)
    local src = source
    print('[Inventory] Server received dropItem event from ' .. src .. '. Slot: ' .. tostring(slot) .. ', Amount: ' .. tostring(amount))
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then return end
    local citizenid = player.citizenid
    
    amount = amount or 1
    
    if not Inventories[citizenid] or not Inventories[citizenid][slot] then 
        print('[Inventory] No item in slot ' .. slot)
        return 
    end
    
    local item = Inventories[citizenid][slot]
    
    if item.amount < amount then
        print('[Inventory] Not enough items. Has: ' .. item.amount .. ', Requested: ' .. amount)
        return
    end
    
    print('[Inventory] Dropping item: ' .. item.name .. ' x' .. amount)
    
    -- Remove specified amount
    if item.amount <= amount then
        -- Remove entire stack
        Inventories[citizenid][slot] = nil
    else
        -- Reduce amount
        Inventories[citizenid][slot].amount = item.amount - amount
    end
    
    SaveInventory(citizenid)
    TriggerClientEvent('gypsy-inventory:client:setInventory', src, Inventories[citizenid])
    
    -- Notify player
    TriggerClientEvent('chat:addMessage', src, {args = {'^3Inventory', 'Выброшен предмет: ' .. item.name .. ' x' .. amount}})
end)

-- Item Logic (Remove Item)
function RemoveItem(source, slot, amount)
    local src = source
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then return end
    local citizenid = player.citizenid
    
    print('[Inventory] RemoveItem called for slot ' .. tostring(slot) .. ', amount ' .. tostring(amount))

    if Inventories[citizenid] and Inventories[citizenid][slot] then
        local currentAmount = Inventories[citizenid][slot].amount
        print('[Inventory] Current amount: ' .. currentAmount)
        
        Inventories[citizenid][slot].amount = currentAmount - amount
        
        if Inventories[citizenid][slot].amount <= 0 then
            print('[Inventory] Item removed completely from slot ' .. slot)
            Inventories[citizenid][slot] = nil
        else
            print('[Inventory] New amount: ' .. Inventories[citizenid][slot].amount)
        end
        
        SaveInventory(citizenid)
        -- Sync to client
        TriggerClientEvent('gypsy-inventory:client:setInventory', src, Inventories[citizenid])
    else
        print('[Inventory] Error: Slot ' .. tostring(slot) .. ' is empty or inventory missing!')
    end
end

-- Register Basic Items
CreateThread(function()
    Wait(1000) -- Wait for exports
    exports['gypsy-inventory']:CreateUseableItem("water", function(source, item)
        local src = source
        exports['gypsy-core']:SetStatus(src, "thirst", 100)
        RemoveItem(src, item.slot, 1)
        TriggerClientEvent('gypsy-inventory:client:itemUsed', src, "water")
    end)
    
    exports['gypsy-inventory']:CreateUseableItem("burger", function(source, item)
        local src = source
        exports['gypsy-core']:SetStatus(src, "hunger", 100)
        RemoveItem(src, item.slot, 1)
        TriggerClientEvent('gypsy-inventory:client:itemUsed', src, "burger")
    end)
end)
