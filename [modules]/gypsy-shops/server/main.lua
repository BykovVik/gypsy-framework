local Gypsy = exports['gypsy-core']:GetCoreObject()

RegisterNetEvent('gypsy-shops:server:buyItem', function(shopId, itemIndex)
    local src = source
    print('[Shops] Buy request from ' .. src .. ' for shop ' .. tostring(shopId))
    local player = exports['gypsy-core']:GetPlayer(src)
    
    if not player then 
        print('[Shops] Player not found')
        return 
    end
    
    local shop = Config.Shops[shopId]
    if not shop then 
        print('[Shops] Shop not found: ' .. tostring(shopId))
        return 
    end
    
    local item = shop.items[itemIndex]
    if not item then 
        print('[Shops] Item not found index: ' .. tostring(itemIndex))
        return 
    end
    
    local price = item.price
    local money = player.Functions.GetMoney('cash')
    print('[Shops] Player money: ' .. money .. ' Price: ' .. price)
    
    if money >= price then
        if player.Functions.RemoveMoney('cash', price, "Shop Purchase") then
            local itemAdded = false
            
            -- Пробуем использовать InventoryService через ServiceLocator
            if exports['gypsy-core']:HasService('Inventory') then
                local InventoryService = exports['gypsy-core']:GetService('Inventory')
                local status, result = pcall(function()
                    return InventoryService.AddItem(src, item.name, 1)
                end)
                
                if status and result then
                    itemAdded = true
                    print('[Shops] Item added via InventoryService')
                else
                    print('[Shops] InventoryService failed:', tostring(result))
                end
            end
            
            -- Fallback: прямой вызов (для обратной совместимости)
            if not itemAdded and GetResourceState('gypsy-inventory') == 'started' then
                local status, result = pcall(function()
                    return exports['gypsy-inventory']:AddItem(src, item.name, 1)
                end)
                
                if status and result then
                    itemAdded = true
                    print('[Shops] Item added via direct export (fallback)')
                else
                    print('[Shops] Direct export failed:', tostring(result))
                end
            end
            
            -- Fallback 2: простая клиентская система
            if not itemAdded then
                print('[Shops] No inventory system available, using client fallback')
                TriggerClientEvent('gypsy:client:addItem', src, item.name, 1)
                itemAdded = true
            end
            
            if itemAdded then
                TriggerClientEvent('chat:addMessage', src, {args = {'Shop', 'You bought ' .. item.label .. ' for $' .. price}})
            else
                -- Refund if failed
                player.Functions.AddMoney('cash', price, "Refund")
                TriggerClientEvent('chat:addMessage', src, {args = {'Shop', 'Purchase failed!'}})
            end
        end
    else
        TriggerClientEvent('chat:addMessage', src, {args = {'Shop', 'Not enough cash!'}})
    end
end)

-- ====================================================================================
--                              EVENT BUS SUBSCRIPTIONS
-- ====================================================================================

-- Подписываемся на события инвентаря (опционально)
CreateThread(function()
    Wait(2000) -- Ждем загрузки Core и Inventory
    
    -- Слушаем события добавления предметов
    exports['gypsy-core']:On('inventory:itemAdded', function(source, itemName, amount, slot, type)
        print('[Shops] Player ' .. source .. ' received ' .. amount .. 'x ' .. itemName .. ' in slot ' .. slot)
        -- Можно добавить дополнительную логику, например статистику покупок
    end)
    
    print('^2[Shops] Subscribed to inventory events^0')
end)

-- ====================================================================================
--                              HOT-RELOAD SUPPORT
-- ====================================================================================

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^3[Shops] Resource started/restarted^0')
    
    -- Переподписываемся на события
    Wait(2000)
    exports['gypsy-core']:On('inventory:itemAdded', function(source, itemName, amount, slot, type)
        print('[Shops] Player ' .. source .. ' received ' .. amount .. 'x ' .. itemName .. ' in slot ' .. slot)
    end)
    
    print('^2[Shops] Re-subscribed to events after restart^0')
end)

-- ====================================================================================
--                              SHOPS SERVICE
-- ====================================================================================

local ShopsService = {
    version = '1.0.0',
    
    --- Покупает предмет в магазине
    BuyItem = function(source, shopId, itemIndex)
        local player = exports['gypsy-core']:GetPlayer(source)
        if not player then return false end
        
        local shop = Config.Shops[shopId]
        if not shop then return false end
        
        local item = shop.items[itemIndex]
        if not item then return false end
        
        local price = item.price
        local money = player.Functions.GetMoney('cash')
        
        if money >= price then
            if player.Functions.RemoveMoney('cash', price, "Shop Purchase") then
                -- Используем InventoryService
                if exports['gypsy-core']:HasService('Inventory') then
                    local InventoryService = exports['gypsy-core']:GetService('Inventory')
                    if InventoryService.AddItem(source, item.name, 1) then
                        TriggerClientEvent('chat:addMessage', source, {args = {'Shop', 'You bought ' .. item.label .. ' for $' .. price}})
                        return true
                    else
                        -- Refund
                        player.Functions.AddMoney('cash', price, "Refund")
                        return false
                    end
                end
            end
        end
        return false
    end,
    
    --- Получает список магазинов
    GetShops = function()
        return Config.Shops
    end,
    
    --- Получает магазин по ID
    GetShop = function(shopId)
        return Config.Shops[shopId]
    end
}

-- Регистрируем сервис в ServiceLocator
CreateThread(function()
    Wait(1000)
    exports['gypsy-core']:RegisterService('Shops', ShopsService, {
        version = '1.0.0',
        description = 'Gypsy Shops System'
    })
    print('^2[Shops] Service registered in ServiceLocator^0')
end)
