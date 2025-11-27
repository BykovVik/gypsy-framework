local Gypsy = exports['gypsy-core']:GetCoreObject()

RegisterNetEvent('gypsy:client:coreReady', function()
    Gypsy = exports['gypsy-core']:GetCoreObject()
    print('[Shops] Core Ready Event Received. Gypsy Object Updated.')
end)

-- Create Blips
CreateThread(function()
    for shopId, shop in pairs(Config.Shops) do
        if shop.blip then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, shop.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, shop.blip.scale)
            SetBlipColour(blip, shop.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(shop.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Interaction
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local sleep = 1000
        
        for shopId, shop in pairs(Config.Shops) do
            local dist = #(coords - shop.coords)
            if dist < 5.0 then
                sleep = 0
                DrawMarker(21, shop.coords.x, shop.coords.y, shop.coords.z, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)
                
                if dist < 1.5 then
                    -- Simple Text UI for now
                    SetTextComponentFormat("STRING")
                    AddTextComponentString("Press ~INPUT_CONTEXT~ to open " .. shop.label)
                    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                    
                    if IsControlJustPressed(0, 38) then -- E
                        print('[Shops] E pressed for shop: ' .. shopId)
                        OpenShop(shopId)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function OpenShop(shopId)
    local shop = Config.Shops[shopId]
    if not shop then 
        print('[Shops] Shop data not found for ' .. shopId)
        return 
    end
    
    print('[Shops] Opening NUI for ' .. shop.label)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
        shopId = shopId,
        label = shop.label,
        items = shop.items
    })
end

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buy', function(data, cb)
    TriggerServerEvent('gypsy-shops:server:buyItem', data.shopId, data.itemIndex)
    cb('ok')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    SetNuiFocus(false, false)
    print('[Shops] Resource stopped, NUI focus released.')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    print('^3[Shops] Client restarted, reinitializing...^0')
    
    -- Переполучаем Core Object
    Wait(500)
    Gypsy = exports['gypsy-core']:GetCoreObject()
    print('[Shops] Core Object refreshed after restart')
end)
