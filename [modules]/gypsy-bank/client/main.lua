local Gypsy = exports['gypsy-core']:GetCoreObject()
local currentAccount = nil

print('[Bank] Client script loaded')

-- Update account info
RegisterNetEvent('gypsy-bank:client:updateAccountInfo', function(data)
    print('[Bank Client] Received account update - Cash: ' .. tostring(data.cash) .. ', Bank: ' .. tostring(data.bank) .. ', Savings: ' .. tostring(data.savings))
    currentAccount = data
    SendNUIMessage({
        action = 'updateAccount',
        data = data
    })
end)

-- Show error notification
RegisterNetEvent('gypsy-bank:client:showError', function(message)
    SendNUIMessage({
        action = 'showError',
        message = message
    })
end)

-- Open ATM/Bank
local function OpenATM(locationType)
    locationType = locationType or 'atm' -- default to ATM
    SetNuiFocus(true, true)
    
    if locationType == 'bank' then
        -- Open bank UI
        SendNUIMessage({
            action = 'openBank'
        })
    else
        -- Open ATM UI
        SendNUIMessage({
            action = 'openATM',
            locationType = 'atm'
        })
    end
    
    -- Request account info
    TriggerServerEvent('gypsy-bank:server:getAccountInfo')
end

-- Close ATM
local function CloseATM()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeATM'
    })
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CloseATM()
    cb('ok')
end)

RegisterNUICallback('withdrawCash', function(data, cb)
    TriggerServerEvent('gypsy-bank:server:withdrawCash', data.amount)
    cb('ok')
end)

RegisterNUICallback('depositCash', function(data, cb)
    TriggerServerEvent('gypsy-bank:server:depositCash', data.amount)
    cb('ok')
end)

RegisterNUICallback('depositSavings', function(data, cb)
    TriggerServerEvent('gypsy-bank:server:depositSavings', data.amount)
    cb('ok')
end)

RegisterNUICallback('withdrawSavings', function(data, cb)
    TriggerServerEvent('gypsy-bank:server:withdrawSavings', data.amount)
    cb('ok')
end)

-- ATM Interaction Points
CreateThread(function()
    Wait(2000) -- Wait for resources to load
    
    -- Create blips for ATMs
    for i, atmCoords in ipairs(Config.ATMLocations) do
        local blip = AddBlipForCoord(atmCoords.x, atmCoords.y, atmCoords.z)
        SetBlipSprite(blip, 277) -- ATM icon
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.6)
        SetBlipColour(blip, 2) -- Green
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("ATM")
        EndTextCommandSetBlipName(blip)
    end
    
    -- Create blips for Banks
    for i, bankCoords in ipairs(Config.BankLocations) do
        local blip = AddBlipForCoord(bankCoords.x, bankCoords.y, bankCoords.z)
        SetBlipSprite(blip, 108) -- Bank icon
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 5) -- Yellow
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Fleeca Bank")
        EndTextCommandSetBlipName(blip)
    end
    
    print('^2[Bank] ATM and Bank blips created on map^0')
    
    -- Interaction thread
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local nearLocation = false
            local locationType = nil
            
            -- Check ATMs
            for _, atmCoords in pairs(Config.ATMLocations) do
                local dist = #(coords - atmCoords)
                if dist < Config.InteractionDistance then
                    nearLocation = true
                    locationType = 'atm'
                    DrawText3D(atmCoords.x, atmCoords.y, atmCoords.z + 0.5, '[E] Банкомат')
                    
                    if IsControlJustReleased(0, 38) then -- E
                        OpenATM('atm')
                    end
                    break
                end
            end
            
            -- Check Banks (only if not near ATM)
            if not nearLocation then
                for _, bankCoords in pairs(Config.BankLocations) do
                    local dist = #(coords - bankCoords)
                    if dist < Config.BankInteractionDistance then
                        nearLocation = true
                        locationType = 'bank'
                        DrawText3D(bankCoords.x, bankCoords.y, bankCoords.z + 0.5, '[E] Fleeca Bank')
                        
                        if IsControlJustReleased(0, 38) then -- E
                            OpenATM('bank')
                        end
                        break
                    end
                end
            end
            
            Wait(nearLocation and 0 or 500)
        end
    end)
    
    print('^2[Bank] ATM and Bank interactions ready^0')
end)

-- Helper function for 3D text
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- ESC to close
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustReleased(0, 322) then -- ESC
            CloseATM()
        end
    end
end)
