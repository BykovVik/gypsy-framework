-- ============================================================================
-- TRANSACTIONS MODULE - Операции с наличными
-- ============================================================================

-- AccountManager is loaded before this file

Transactions = {} -- Global

-- ============================================================================
-- ОПЕРАЦИИ С НАЛИЧНЫМИ
-- ============================================================================

--- Снять наличные из банка
--- @param src number
--- @param amount number
--- @return boolean, string - успех, сообщение об ошибке
function Transactions.WithdrawCash(src, amount)
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then return false, "Player not found" end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        return false, "Неверная сумма"
    end
    
    local citizenid = player.citizenid
    local account = AccountManager.GetAccount(src, citizenid)
    
    if account.bank < amount then
        return false, "Недостаточно средств на счету"
    end
    

    
    -- Выполняем операцию
    player.Functions.RemoveMoney('bank', amount, "ATM Withdrawal")
    player.Functions.AddMoney('cash', amount, "ATM Withdrawal")
    

    
    -- Синхронизируем с клиентом
    AccountManager.SyncToClient(src, citizenid)
    
    return true, "Withdrew $" .. amount
end

--- Внести наличные в банк
--- @param src number
--- @param amount number
--- @return boolean, string - успех, сообщение об ошибке
function Transactions.DepositCash(src, amount)
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then return false, "Player not found" end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        return false, "Неверная сумма"
    end
    
    local citizenid = player.citizenid
    local account = AccountManager.GetAccount(src, citizenid)
    
    if account.cash < amount then
        return false, "Недостаточно наличных"
    end
    

    
    -- Выполняем операцию
    player.Functions.RemoveMoney('cash', amount, "ATM Deposit")
    player.Functions.AddMoney('bank', amount, "ATM Deposit")
    

    
    -- Синхронизируем с клиентом
    AccountManager.SyncToClient(src, citizenid)
    
    return true, "Deposited $" .. amount
end


