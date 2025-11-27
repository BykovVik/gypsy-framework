-- ============================================================================
-- ACCOUNT MANAGER - Централизованное управление балансами
-- ============================================================================
-- Этот модуль отвечает за:
-- 1. Кэширование всех балансов игрока (cash, bank, savings)
-- 2. Гарантию атомарности операций
-- 3. Синхронизацию с клиентом после каждого изменения
-- ============================================================================

AccountManager = {} -- Global

-- Кэш балансов игроков: [citizenid] = { cash, bank, savings, lastUpdate }
local PlayerAccounts = {}

-- ============================================================================
-- ПРИВАТНЫЕ ФУНКЦИИ
-- ============================================================================

-- Загрузить savings из БД
local function LoadSavingsFromDB(citizenid)
    local result = exports.oxmysql:executeSync('SELECT * FROM players WHERE citizenid = ?', {citizenid})
    
    if result and result[1] then
        local metadata = type(result[1].metadata) == "string" and json.decode(result[1].metadata) or result[1].metadata
        return {
            balance = metadata.savings or 0,
            lastInterest = metadata.lastInterest or os.time()
        }
    end
    
    return {
        balance = 0,
        lastInterest = os.time()
    }
end

-- Сохранить savings в БД
local function SaveSavingsToDB(citizenid, savingsData)
    local player = nil
    for _, p in pairs(exports['gypsy-core']:GetCoreObject().Players) do
        if p.citizenid == citizenid then
            player = p
            break
        end
    end
    
    if player then
        player.metadata.savings = savingsData.balance
        player.metadata.lastInterest = savingsData.lastInterest
        exports['gypsy-core']:GetCoreObject().Functions.SavePlayer(player.source)
    end
end

-- ============================================================================
-- ПУБЛИЧНЫЕ ФУНКЦИИ
-- ============================================================================

--- Получить полный аккаунт игрока (cash, bank, savings)
--- @param src number - source игрока
--- @param citizenid string - citizenid игрока
--- @return table|nil - { cash, bank, savings } или nil если игрок не найден
function AccountManager.GetAccount(src, citizenid)
    local player = exports['gypsy-core']:GetPlayer(src)
    if not player then 
        print('[AccountManager] ERROR: Player not found for source ' .. src)
        return nil 
    end
    
    -- Проверяем кэш
    if not PlayerAccounts[citizenid] then
        -- Загружаем из БД и кэшируем
        local savingsData = LoadSavingsFromDB(citizenid)
        PlayerAccounts[citizenid] = {
            savings = savingsData.balance,
            lastInterest = savingsData.lastInterest,
            lastUpdate = os.time()
        }
    end
    
    -- Получаем актуальные cash и bank из gypsy-core
    local cash = player.Functions.GetMoney('cash')
    local bank = player.Functions.GetMoney('bank')
    

    
    -- Обновляем кэш
    PlayerAccounts[citizenid].lastUpdate = os.time()
    
    return {
        cash = cash or 0,
        bank = bank or 0,
        savings = PlayerAccounts[citizenid].savings,
        lastInterest = PlayerAccounts[citizenid].lastInterest
    }
end

--- Обновить savings баланс
--- @param citizenid string
--- @param newBalance number
--- @return boolean - успех операции
function AccountManager.UpdateSavings(citizenid, newBalance)
    if not PlayerAccounts[citizenid] then
        PlayerAccounts[citizenid] = {
            savings = 0,
            lastInterest = os.time(),
            lastUpdate = os.time()
        }
    end
    
    PlayerAccounts[citizenid].savings = newBalance
    PlayerAccounts[citizenid].lastUpdate = os.time()
    
    -- Сохраняем в БД
    SaveSavingsToDB(citizenid, {
        balance = newBalance,
        lastInterest = PlayerAccounts[citizenid].lastInterest
    })
    
    return true
end

--- Обновить lastInterest
--- @param citizenid string
--- @param timestamp number
function AccountManager.UpdateLastInterest(citizenid, timestamp)
    if PlayerAccounts[citizenid] then
        PlayerAccounts[citizenid].lastInterest = timestamp
        SaveSavingsToDB(citizenid, {
            balance = PlayerAccounts[citizenid].savings,
            lastInterest = timestamp
        })
    end
end

--- Синхронизировать данные с клиентом
--- @param src number - source игрока
--- @param citizenid string
function AccountManager.SyncToClient(src, citizenid)
    local account = AccountManager.GetAccount(src, citizenid)
    if not account then return end
    

    
    TriggerClientEvent('gypsy-bank:client:updateAccountInfo', src, {
        cash = account.cash,
        bank = account.bank,
        savings = account.savings,
        interestEarned = 0
    })
end

--- Предзагрузить аккаунт при входе игрока
--- @param src number
--- @param citizenid string
function AccountManager.PreloadAccount(src, citizenid)

    local savingsData = LoadSavingsFromDB(citizenid)
    PlayerAccounts[citizenid] = {
        savings = savingsData.balance,
        lastInterest = savingsData.lastInterest,
        lastUpdate = os.time()
    }
end

--- Очистить кэш при выходе игрока
--- @param citizenid string
function AccountManager.ClearCache(citizenid)
    if PlayerAccounts[citizenid] then
        -- Сохраняем перед очисткой
        SaveSavingsToDB(citizenid, {
            balance = PlayerAccounts[citizenid].savings,
            lastInterest = PlayerAccounts[citizenid].lastInterest
        })
        PlayerAccounts[citizenid] = nil

    end
end

--- Получить savings данные
--- @param citizenid string
--- @return table - { balance, lastInterest }
function AccountManager.GetSavingsData(citizenid)
    if not PlayerAccounts[citizenid] then
        local savingsData = LoadSavingsFromDB(citizenid)
        PlayerAccounts[citizenid] = {
            savings = savingsData.balance,
            lastInterest = savingsData.lastInterest,
            lastUpdate = os.time()
        }
    end
    
    return {
        balance = PlayerAccounts[citizenid].savings,
        lastInterest = PlayerAccounts[citizenid].lastInterest
    }
end


