local Gypsy = exports['gypsy-core']:GetCoreObject()

-- Helper to check admin permissions
-- Проверяем несколько вариантов для максимальной совместимости:
-- 1. Специфичный ACE для админских команд (gypsy.admin)
-- 2. Общий ACE на команды (command)
-- 3. Выполнение из консоли (source == 0)
local function IsAdmin(source)
    if source == 0 then return true end -- Console always admin
    
    -- 1. Check Config.SuperAdmins (Hardcoded fallback)
    if Config.SuperAdmins then
        local identifiers = GetPlayerIdentifiers(source)
        for _, id in ipairs(identifiers) do
            for _, adminId in ipairs(Config.SuperAdmins) do
                if string.find(id, adminId) then
                    return true
                end
            end
        end
    end

    -- 2. Check ACE permissions
    return IsPlayerAceAllowed(source, 'gypsy.admin') or 
           IsPlayerAceAllowed(source, 'command')
end

RegisterCommand('revive', function(source, args)
    if source == 0 then -- Console
        if args[1] then
            local target = tonumber(args[1])
            
            -- Используем DeathService если доступен
            if exports['gypsy-core']:HasService('Death') then
                local DeathService = exports['gypsy-core']:GetService('Death')
                DeathService.Revive(target)
            else
                -- Fallback
                TriggerClientEvent('gypsy-admin:client:revive', target)
            end
            
            -- Restore Status через прямой export
            if exports['gypsy-core'] then
                exports['gypsy-core']:SetStatus(target, 'hunger', 100)
                exports['gypsy-core']:SetStatus(target, 'thirst', 100)
            end
        end
        return
    end

    if IsAdmin(source) then
        local target = source
        if args[1] then
            target = tonumber(args[1])
        end
        
        -- Используем DeathService если доступен
        if exports['gypsy-core']:HasService('Death') then
            local DeathService = exports['gypsy-core']:GetService('Death')
            DeathService.Revive(target)
        else
            -- Fallback
            TriggerClientEvent('gypsy-admin:client:revive', target)
        end
        
        -- Restore Status через прямой export
        exports['gypsy-core']:SetStatus(target, 'hunger', 100)
        exports['gypsy-core']:SetStatus(target, 'thirst', 100)
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'You do not have permission.' } })
    end
end)

RegisterCommand('noclip', function(source, args)
    if IsAdmin(source) then
        TriggerClientEvent('gypsy-admin:client:toggleNoclip', source)
    end
end)

RegisterCommand('tpm', function(source, args)
    if IsAdmin(source) then
        TriggerClientEvent('gypsy-admin:client:tpm', source)
    end
end)

RegisterCommand('tp', function(source, args)
    if IsAdmin(source) then
        local arg1 = args[1]
        
        -- Если первый аргумент число, значит это координаты
        if tonumber(arg1) then
            local x = tonumber(args[1])
            local y = tonumber(args[2])
            local z = tonumber(args[3])
            
            if x and y and z then
                TriggerClientEvent('gypsy-admin:client:teleport', source, vector3(x, y, z))
            else
                TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Usage: /tp [x] [y] [z]' } })
            end
        else
            -- Иначе ищем локацию по имени
            local location = arg1
            if location and Config.Locations[location] then
                TriggerClientEvent('gypsy-admin:client:teleport', source, Config.Locations[location])
            else
                TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Location not found! Available: sandy, paleto, city, hospital, police, prison, casino, airport OR use /tp [x] [y] [z]' } })
            end
        end
    end
end)

RegisterCommand('setmoney', function(source, args)
    if IsAdmin(source) then
        local target = tonumber(args[1])
        local amount = tonumber(args[2])
        local type = args[3] or 'cash'

        if not target or not amount then
            TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Usage: /setmoney [id] [amount] [type]' } })
            return
        end

        local player = exports['gypsy-core']:GetPlayer(target)
        if player then
            player.Functions.SetMoney(type, amount, "Admin Command")
            TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Set ' .. type .. ' of ' .. player.charinfo.firstname .. ' to ' .. amount } })
        else
            TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Player not found.' } })
        end
    end
end)

RegisterCommand('givemoney', function(source, args)
    if IsAdmin(source) then
        local target = tonumber(args[1])
        local amount = tonumber(args[2])
        local type = args[3] or 'cash'

        if not target or not amount then
            TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Usage: /givemoney [id] [amount] [type]' } })
            return
        end

        local player = exports['gypsy-core']:GetPlayer(target)
        if player then
            player.Functions.AddMoney(type, amount, "Admin Command")
            TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Gave ' .. amount .. ' ' .. type .. ' to ' .. player.charinfo.firstname } })
        else
            TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Player not found.' } })
        end
    end
end)

-- Команда для спавна машин
RegisterCommand('car', function(source, args)
    if source == 0 then
        print('[Admin] Cannot spawn vehicle from console')
        return
    end

    if not IsAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'You do not have permission.' } })
        return
    end

    if not args[1] then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Usage: /car [model]' } })
        return
    end

    local model = args[1]
    TriggerClientEvent('gypsy-admin:client:spawnVehicle', source, model)
end)

-- Команда для получения координат
RegisterCommand('coords', function(source, args)
    if source == 0 then
        print('[Admin] Cannot get coords from console')
        return
    end

    if not IsAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'You do not have permission.' } })
        return
    end

    TriggerClientEvent('gypsy-admin:client:showCoords', source)
end)

-- ====================================================================================
--                              ADMIN SERVICE
-- ====================================================================================

local AdminService = {
    version = '1.0.0',
    
    --- Возрождает игрока
    Revive = function(target)
        if exports['gypsy-core']:HasService('Death') then
            local DeathService = exports['gypsy-core']:GetService('Death')
            DeathService.Revive(target)
        else
            TriggerClientEvent('gypsy-admin:client:revive', target)
        end
        
        exports['gypsy-core']:SetStatus(target, 'hunger', 100)
        exports['gypsy-core']:SetStatus(target, 'thirst', 100)
        return true
    end,
    
    --- Телепортирует игрока
    Teleport = function(source, location)
        if Config.Locations[location] then
            TriggerClientEvent('gypsy-admin:client:teleport', source, Config.Locations[location])
            return true
        end
        return false
    end,
    
    --- Включает/выключает noclip
    ToggleNoclip = function(source)
        TriggerClientEvent('gypsy-admin:client:toggleNoclip', source)
        return true
    end,
    
    --- Выдает деньги
    GiveMoney = function(target, amount, moneyType)
        local player = exports['gypsy-core']:GetPlayer(target)
        if player then
            player.Functions.AddMoney(moneyType or 'cash', amount, "Admin Command")
            return true
        end
        return false
    end,
    
    --- Устанавливает деньги
    SetMoney = function(target, amount, moneyType)
        local player = exports['gypsy-core']:GetPlayer(target)
        if player then
            player.Functions.SetMoney(moneyType or 'cash', amount, "Admin Command")
            return true
        end
        return false
    end
}

-- Регистрируем сервис в ServiceLocator
CreateThread(function()
    Wait(1000)
    exports['gypsy-core']:RegisterService('Admin', AdminService, {
        version = '1.0.0',
        description = 'Gypsy Admin System'
    })
    print('^2[Admin] Service registered in ServiceLocator^0')
end)
