local Gypsy = exports['gypsy-core']:GetCoreObject()

RegisterNetEvent('gypsy:client:coreReady', function()
    Gypsy = exports['gypsy-core']:GetCoreObject()
    print('[Inventory] Core Ready Event Received. Gypsy Object Updated.')
    TriggerServerEvent('gypsy-inventory:server:requestSync')
end)

-- Request sync on resource start (for restarts)
CreateThread(function()
    Wait(2000) -- Increased delay to ensure server is ready
    if Gypsy then
        print('[Inventory] Requesting initial sync from server...')
        TriggerServerEvent('gypsy-inventory:server:requestSync')
    end
end)
local Inventory = {}
local isVisible = false

RegisterNetEvent('gypsy-inventory:client:setInventory', function(items)
    print('[Inventory] Received items: ' .. json.encode(items))
    
    -- Enrich items with Config data
    local enrichedItems = {}
    for slot, item in pairs(items) do
        local itemInfo = Config.Items[item.name]
        if itemInfo then
            item.label = itemInfo.label
            item.image = itemInfo.image
            item.description = itemInfo.description
            item.type = itemInfo.type
            item.weight = itemInfo.weight
        else
            print('[Inventory] WARNING: No config found for item: ' .. tostring(item.name))
        end
        enrichedItems[slot] = item
    end
    
    print('[Inventory] Enriched items: ' .. json.encode(enrichedItems))
    Inventory = enrichedItems
    
    if isVisible then
        SendNUIMessage({
            action = "open",
            inventory = Inventory,
            slots = Config.MaxSlots
        })
    end
end)

RegisterCommand('inventory', function()
    if not isVisible then
        OpenInventory()
    else
        CloseInventory()
    end
end)
RegisterKeyMapping('inventory', 'Open Inventory', 'keyboard', 'TAB')

function OpenInventory()
    isVisible = true
    SetNuiFocus(true, true)
    SetNuiFocus(true, true)
    -- SetNuiFocusKeepInput(true) -- Disabled to test standard focus
    SendNUIMessage({
        action = "open",
        inventory = Inventory,
        slots = Config.MaxSlots
    })
end

function CloseInventory()
    print('[Inventory] Closing inventory...')
    isVisible = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = "close"
    })
end

RegisterNUICallback('close', function(data, cb)
    CloseInventory()
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('gypsy-inventory:server:useItem', data.slot, data.amount or 1)
    cb('ok')
end)

RegisterNUICallback('moveItem', function(data, cb)
    print('[Inventory] Client received moveItem request: ' .. json.encode(data))
    TriggerServerEvent('gypsy-inventory:server:moveItem', data.fromSlot, data.toSlot)
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    print('[Inventory] Client received dropItem request: ' .. json.encode(data))
    TriggerServerEvent('gypsy-inventory:server:dropItem', data.slot, data.amount or 1)
    cb('ok')
end)

-- Handle Item Usage Effects (Visuals/Sound)
RegisterNetEvent('gypsy-inventory:client:itemUsed', function(itemName)
    -- Simple notification
    print("Used " .. itemName)
end)
