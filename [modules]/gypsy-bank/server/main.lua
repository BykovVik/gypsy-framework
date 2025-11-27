-- ============================================================================
-- GYPSY BANK - Main Server Entry Point
-- ============================================================================

-- Modules are loaded automatically by fxmanifest.lua
-- AccountManager, Savings, and Transactions are global



-- ============================================================================
-- PLAYER LIFECYCLE EVENTS
-- ============================================================================

-- Preload account when player joins
RegisterNetEvent('gypsy-core:server:playerLoaded', function(src, citizenid)

    AccountManager.PreloadAccount(src, citizenid)
end)

-- Save and clear cache when player disconnects
AddEventHandler('playerDropped', function(reason)
    local src = source
    local player = exports['gypsy-core']:GetPlayer(src)
    if player then

        AccountManager.ClearCache(player.citizenid)
    end
end)

-- ============================================================================
-- CLIENT REQUESTS
-- ============================================================================

-- Get account info (called when opening ATM/Bank)
RegisterNetEvent('gypsy-bank:server:getAccountInfo', function()
    local src = source
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then return end
    

    AccountManager.SyncToClient(src, player.citizenid)
end)

-- ============================================================================
-- CASH TRANSACTIONS
-- ============================================================================

-- Withdraw cash from ATM
RegisterNetEvent('gypsy-bank:server:withdrawCash', function(amount)
    local src = source
    local success, message = Transactions.WithdrawCash(src, amount)
    
    if not success then
        TriggerClientEvent('chat:addMessage', src, { args = { '^1ATM', message } })
        TriggerClientEvent('gypsy-bank:client:showError', src, message)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '^2ATM', message } })
    end
end)

-- Deposit cash to ATM
RegisterNetEvent('gypsy-bank:server:depositCash', function(amount)
    local src = source
    local success, message = Transactions.DepositCash(src, amount)
    
    if not success then
        TriggerClientEvent('chat:addMessage', src, { args = { '^1ATM', message } })
        TriggerClientEvent('gypsy-bank:client:showError', src, message)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '^2ATM', message } })
    end
end)

-- ============================================================================
-- SAVINGS OPERATIONS
-- ============================================================================

-- Deposit to savings
RegisterNetEvent('gypsy-bank:server:depositSavings', function(amount)
    local src = source
    local success, message = Savings.Deposit(src, amount)
    
    if not success then
        TriggerClientEvent('chat:addMessage', src, { args = { '^1Bank', message } })
        TriggerClientEvent('gypsy-bank:client:showError', src, message)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '^2Bank', message } })
    end
end)

-- Withdraw from savings
RegisterNetEvent('gypsy-bank:server:withdrawSavings', function(amount)
    local src = source
    local success, message = Savings.Withdraw(src, amount)
    
    if not success then
        TriggerClientEvent('chat:addMessage', src, { args = { '^1Bank', message } })
        TriggerClientEvent('gypsy-bank:client:showError', src, message)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '^2Bank', message } })
    end
end)

-- ============================================================================
-- INTEREST SYSTEM
-- ============================================================================

-- Apply interest every hour
CreateThread(function()
    while true do
        Wait(Config.InterestInterval)
        
        local Gypsy = exports['gypsy-core']:GetCoreObject()
        for _, player in pairs(Gypsy.Players) do
            if player and player.citizenid then
                local interest = Savings.ApplyInterest(player.citizenid)
                if interest > 0 then
                    TriggerClientEvent('chat:addMessage', player.source, {
                        args = { '^2Bank', 'Interest earned: $' .. interest }
                    })
                    AccountManager.SyncToClient(player.source, player.citizenid)
                end
            end
        end
    end
end)


