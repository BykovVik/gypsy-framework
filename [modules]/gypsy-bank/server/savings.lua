-- ============================================================================
-- SAVINGS MODULE - Логика накопительных счетов
-- ============================================================================

-- AccountManager is loaded before this file
-- Config is shared script

Savings = {} -- Global

-- ============================================================================
-- ФУНКЦИИ ПРОЦЕНТОВ
-- ============================================================================

--- Рассчитать и применить проценты
--- @param citizenid string
--- @return number - сумма начисленных процентов
function Savings.ApplyInterest(citizenid)
    local savingsData = AccountManager.GetSavingsData(citizenid)
    local currentTime = os.time()
    local timeDiff = currentTime - savingsData.lastInterest
    
    -- Рассчитываем прошедшие часы
    local hoursPassed = timeDiff / 3600
    
    if hoursPassed >= 1 and savingsData.balance > 0 then
        -- Рассчитываем проценты (0.5% в день, пропорционально)
        local dailyRate = Config.InterestRate / 100
        local hourlyRate = dailyRate / 24
        local interest = math.floor(savingsData.balance * hourlyRate * hoursPassed)
        
        if interest > 0 then
            local newBalance = savingsData.balance + interest
            AccountManager.UpdateSavings(citizenid, newBalance)
            AccountManager.UpdateLastInterest(citizenid, currentTime)
            

            return interest
        end
    end
    
    return 0
end

-- ============================================================================
-- ОПЕРАЦИИ С ВКЛАДАМИ
-- ============================================================================

--- Внести деньги на вклад
--- @param src number
--- @param amount number
--- @return boolean, string - успех, сообщение об ошибке
function Savings.Deposit(src, amount)
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
    
    local savingsData = AccountManager.GetSavingsData(citizenid)
    
    if savingsData.balance + amount > Config.MaximumBalance then
        return false, "Превышен максимальный баланс"
    end
    
    -- Выполняем операцию
    player.Functions.RemoveMoney('bank', amount, "Savings Deposit")
    local newBalance = savingsData.balance + amount
    AccountManager.UpdateSavings(citizenid, newBalance)
    

    
    -- Синхронизируем с клиентом
    AccountManager.SyncToClient(src, citizenid)
    
    return true, "Deposited $" .. amount .. " to savings"
end

--- Снять деньги с вклада
--- @param src number
--- @param amount number
--- @return boolean, string - успех, сообщение об ошибке
function Savings.Withdraw(src, amount)
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then return false, "Player not found" end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        return false, "Неверная сумма"
    end
    
    local citizenid = player.citizenid
    local savingsData = AccountManager.GetSavingsData(citizenid)
    
    if savingsData.balance < amount then
        return false, "Недостаточно средств на вкладе"
    end
    
    -- Применяем проценты перед снятием
    Savings.ApplyInterest(citizenid)
    
    -- Выполняем операцию
    local newBalance = savingsData.balance - amount
    AccountManager.UpdateSavings(citizenid, newBalance)
    player.Functions.AddMoney('bank', amount, "Savings Withdrawal")
    

    
    -- Синхронизируем с клиентом
    AccountManager.SyncToClient(src, citizenid)
    
    return true, "Withdrew $" .. amount .. " from savings"
end


