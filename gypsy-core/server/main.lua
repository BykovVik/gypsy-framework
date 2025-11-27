-- Gypsy Framework Core
-- Provides player management, Service Locator, and Event Bus
Gypsy = {}
Gypsy.Players = {}
Gypsy.Functions = {}
Gypsy.Callbacks = {}

-- ====================================================================================
--                            SERVICE LOCATOR & EVENT BUS
-- ====================================================================================

-- Модули загружаются через fxmanifest.lua
-- ServiceLocator и EventBus уже доступны как глобальные переменные

print('^2[Gypsy-Core] ServiceLocator and EventBus loaded^0')

-- ====================================================================================
--                                  DATABASE & INIT
-- ====================================================================================

-- Check Database Connection
CreateThread(function()
    local waitLoop = 0
    while GetResourceState('oxmysql') ~= 'started' do
        waitLoop = waitLoop + 1
        if waitLoop > 10 then
            print('^1[Gypsy-Core] CRITICAL: oxmysql is NOT running! Framework halted.^0')
            return
        end
        Wait(1000)
    end
    print('^2[Gypsy-Core] Database driver found.^0')
end)

-- Wrapper for SQL
function Gypsy.Functions.ExecuteSql(query, parameters, callback)
    exports.oxmysql:execute(query, parameters, function(result)
        if callback then callback(result) end
    end)
end

-- ====================================================================================
--                                  PLAYER MANAGER
-- ====================================================================================

function Gypsy.Functions.GetPlayer(source)
    return Gypsy.Players[tonumber(source)]
end

function Gypsy.Functions.CreateCitizenId()
    local uniqueFound = false
    local citizenId = nil
    while not uniqueFound do
        citizenId = tostring(math.random(1,9)) .. tostring(math.random(1,9)) .. tostring(math.random(1,9)) .. tostring(math.random(1,9)) .. tostring(math.random(1,9)) .. tostring(math.random(1,9)) .. tostring(math.random(1,9)) .. tostring(math.random(1,9))
        uniqueFound = true -- TODO: Add uniqueness check
    end
    return citizenId
end

function Gypsy.Functions.Login(source, citizenid, newData)
    local src = source
    
    local function FinishLogin(playerData)
        -- Decode JSON fields
        playerData.money = type(playerData.money) == "string" and json.decode(playerData.money) or playerData.money
        playerData.job = type(playerData.job) == "string" and json.decode(playerData.job) or playerData.job
        playerData.position = type(playerData.position) == "string" and json.decode(playerData.position) or playerData.position
        playerData.metadata = type(playerData.metadata) == "string" and json.decode(playerData.metadata) or playerData.metadata
        playerData.charinfo = type(playerData.charinfo) == "string" and json.decode(playerData.charinfo) or playerData.charinfo

        -- Attach Methods
        playerData.Functions = {}
        
        playerData.Functions.SetMoney = function(type, amount, reason)
            type = type or 'cash'
            amount = tonumber(amount) or 0
            playerData.money[type] = amount
            Gypsy.Functions.SavePlayer(src)
            return true
        end
        
        playerData.Functions.AddMoney = function(type, amount, reason)
            type = type or 'cash'
            amount = tonumber(amount) or 0
            playerData.money[type] = (playerData.money[type] or 0) + amount
            Gypsy.Functions.SavePlayer(src)
            return true
        end
        
        playerData.Functions.RemoveMoney = function(type, amount, reason)
            type = type or 'cash'
            amount = tonumber(amount) or 0
            if (playerData.money[type] or 0) >= amount then
                playerData.money[type] = playerData.money[type] - amount
                Gypsy.Functions.SavePlayer(src)
                return true
            end
            return false
        end
        
        playerData.Functions.GetMoney = function(type)
            return playerData.money[type] or 0
        end

        -- Store in Memory
        Gypsy.Players[src] = playerData
        
        -- Sync to Client
        TriggerClientEvent('gypsy-core:client:playerLoaded', src, playerData)
        
        -- DISABLED: Don't auto-trigger playerLoaded - let gypsy-multicharacter handle it after character selection
        -- TriggerEvent('gypsy-core:server:playerLoaded', src, playerData)
        
        print('^2[Gypsy-Core] Player ' .. playerData.name .. ' (ID: ' .. src .. ') successfully logged in.^0')
    end

    if citizenid then
        Gypsy.Functions.ExecuteSql('SELECT * FROM players WHERE citizenid = ?', {citizenid}, function(result)
            if result and result[1] then
                FinishLogin(result[1])
            else
                print('^1[Gypsy-Core] Login failed: CitizenID ' .. citizenid .. ' not found.^0')
                -- Fallback to creation if needed, or error
            end
        end)
    elseif newData then
        -- Create New Player
        local citizenId = Gypsy.Functions.CreateCitizenId()
        local playerMap = {
            citizenid = citizenId,
            license = GetPlayerIdentifiers(src)[1],
            name = GetPlayerName(src),
            money = json.encode({cash = 1000, bank = 5000}),
            job = json.encode({name = "unemployed", label = "Unemployed", grade = 0}),
            position = json.encode(newData.position or {x = -1037.74, y = -2737.94, z = 20.17}),
            metadata = json.encode(newData.metadata or {hunger = 100, thirst = 100}),
            charinfo = json.encode(newData.charinfo or {firstname = "John", lastname = "Doe"})
        }

        Gypsy.Functions.ExecuteSql('INSERT INTO players (citizenid, license, name, money, job, position, metadata, charinfo) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            playerMap.citizenid, playerMap.license, playerMap.name, playerMap.money, playerMap.job, playerMap.position, playerMap.metadata, playerMap.charinfo
        }, function()
            FinishLogin(playerMap)
        end)
    end
end

-- Create New Player (called by multicharacter)
function Gypsy.Functions.CreatePlayer(source, data)
    local src = source
    local license = GetPlayerIdentifiers(src)[1]
    
    if not license then
        print('^1[Gypsy-Core] CreatePlayer failed: No license found for source ' .. src .. '^0')
        return
    end
    
    print('^3[Gypsy-Core] Creating new character for ' .. GetPlayerName(src) .. ' (license: ' .. license .. ')^0')
    
    -- Prepare character data
    local newData = {
        charinfo = data.charinfo or {firstname = "John", lastname = "Doe", birthdate = "1990-01-01"},
        position = data.position or {x = -1037.74, y = -2737.94, z = 20.17},
        metadata = data.metadata or {hunger = 100, thirst = 100}
    }
    
    -- Call Login with new data to create and login
    Gypsy.Functions.Login(src, nil, newData)
end


--- Save player data to database
--- @param source number Player server ID
--- @param callback function Optional callback(success, result)
function Gypsy.Functions.SavePlayer(source, callback)
    local src = source
    local playerData = Gypsy.Players[src]
    
    if not playerData then
        if callback then callback(false, 'Player not found') end
        return
    end
    
    print('^3[Gypsy-Core] Saving player ' .. playerData.citizenid .. ' to database^0')
    print('^3[Gypsy-Core] Position being saved: ' .. json.encode(playerData.position) .. '^0')
    
    exports.oxmysql:execute('UPDATE players SET money = ?, job = ?, position = ?, metadata = ?, charinfo = ? WHERE citizenid = ?', {
        json.encode(playerData.money),
        json.encode(playerData.job),
        json.encode(playerData.position),
        json.encode(playerData.metadata),
        json.encode(playerData.charinfo),
        playerData.citizenid
    }, function(result)
        local success = result and result.affectedRows and result.affectedRows > 0
        if success then
            print('^2[Gypsy-Core] ✓ Player data saved to database (rows: ' .. result.affectedRows .. ')^0')
        else
            print('^1[Gypsy-Core] ✗ Failed to save player data - 0 rows affected^0')
        end
        
        if callback then callback(success, result) end
    end)
end



-- ====================================================================================
--                                  SESSION MANAGER
-- ====================================================================================

-- Handle New Joins
RegisterNetEvent('gypsy:join', function()
    local src = source
    TriggerEvent('gypsy-core:internal:login', src)
end)

-- Internal Login Handler
AddEventHandler('gypsy-core:internal:login', function(source)
    local src = source
    local identifiers = GetPlayerIdentifiers(src)
    local license = identifiers[1]

    if not license then return end

    -- TODO: Add Multicharacter support check here
    -- For now, Auto-Login based on License
    Gypsy.Functions.ExecuteSql('SELECT citizenid FROM players WHERE license = ?', {license}, function(result)
        if result and result[1] then
            Gypsy.Functions.Login(src, result[1].citizenid)
        else
            Gypsy.Functions.Login(src, nil, {}) -- Create new
        end
    end)
end)

-- Handle Drop
AddEventHandler('playerDropped', function(reason)
    local src = source
    if Gypsy.Players[src] then
        -- Save all player data (position is updated via gypsy-multicharacter)
        Gypsy.Functions.SavePlayer(src)
        print('^3[Gypsy-Core] Player ' .. src .. ' dropped. Data saved.^0')
        Gypsy.Players[src] = nil
    end
end)

-- HOT RELOAD LOGIC
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    
    print('^3[Gypsy-Core] Core restarting... Initializing Hot-Reload Protocol.^0')
    
    -- Wait for DB to be ready
    Wait(1000)
    
    local players = GetPlayers()
    if #players > 0 then
        print('^3[Gypsy-Core] Found ' .. #players .. ' connected players. Re-authenticating...^0')
        for _, src in ipairs(players) do
            -- НЕ триггерим forceReload на клиенте - это вызывает двойной спавн
            -- Просто переподключаем серверную часть
            
            -- Re-Login Server Side
            TriggerEvent('gypsy-core:internal:login', tonumber(src))
            
            -- Stagger to prevent DB load
            Wait(200) 
        end
    end
    
    -- Signal Readiness
    TriggerEvent('gypsy:server:coreReady')
end)

-- ====================================================================================
--                                  EXPORTS & UTILS
-- ====================================================================================

exports('GetCoreObject', function() return Gypsy end)
exports('GetPlayer', Gypsy.Functions.GetPlayer)

-- Status Loop
CreateThread(function()
    while true do
        Wait(60000)
        for src, player in pairs(Gypsy.Players) do
            if player then
                player.metadata.hunger = (player.metadata.hunger or 100) - 1
                player.metadata.thirst = (player.metadata.thirst or 100) - 2
                if player.metadata.hunger < 0 then player.metadata.hunger = 0 end
                if player.metadata.thirst < 0 then player.metadata.thirst = 0 end
                
                -- TODO: Implement damage system when gypsy-health module is ready
                -- if player.metadata.hunger <= 0 or player.metadata.thirst <= 0 then
                --     TriggerClientEvent('gypsy-health:client:applyDamage', src, 5)
                -- end
                
                TriggerClientEvent('gypsy-core:client:updateStatus', src, player.metadata)
            end
        end
    end
end)

exports('SetStatus', function(source, statusName, value)
    local player = Gypsy.Players[source]
    if player then
        player.metadata[statusName] = value
        TriggerClientEvent('gypsy-core:client:updateStatus', source, player.metadata)
    end
end)

-- ====================================================================================
--                        SERVICE LOCATOR & EVENT BUS EXPORTS
-- ====================================================================================

-- ServiceLocator exports
exports('RegisterService', function(name, service, metadata)
    if not ServiceLocator then
        print('^1[Gypsy-Core] ERROR: ServiceLocator not loaded yet!^0')
        return
    end
    ServiceLocator:Register(name, service, metadata)
end)

exports('GetService', function(name)
    if not ServiceLocator then
        print('^1[Gypsy-Core] ERROR: ServiceLocator not loaded yet!^0')
        return nil
    end
    return ServiceLocator:Get(name)
end)

exports('HasService', function(name)
    if not ServiceLocator then
        return false
    end
    return ServiceLocator:Has(name)
end)

exports('UnregisterService', function(name)
    if not ServiceLocator then
        print('^1[Gypsy-Core] ERROR: ServiceLocator not loaded yet!^0')
        return
    end
    ServiceLocator:Unregister(name)
end)

exports('GetAllServices', function()
    if not ServiceLocator then
        return {}
    end
    return ServiceLocator:GetAll()
end)

-- EventBus exports
exports('On', function(eventName, callback, priority)
    if not EventBus then
        print('^1[Gypsy-Core] ERROR: EventBus not loaded yet!^0')
        return
    end
    EventBus:On(eventName, callback, priority)
end)

exports('Once', function(eventName, callback)
    if not EventBus then
        print('^1[Gypsy-Core] ERROR: EventBus not loaded yet!^0')
        return
    end
    EventBus:Once(eventName, callback)
end)

exports('Off', function(eventName, callback)
    if not EventBus then
        return
    end
    EventBus:Off(eventName, callback)
end)

exports('Emit', function(eventName, ...)
    if not EventBus then
        return
    end
    EventBus:Emit(eventName, ...)
end)

exports('GetEventListenerCount', function(eventName)
    if not EventBus then
        return 0
    end
    return EventBus:GetListenerCount(eventName)
end)
