-- Local storage for keys
local MyKeys = {}

-- Helper: Normalize Plate
local function Trim(value)
    if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

-- Event: Update Keys
RegisterNetEvent('gypsy-vehicle:client:updateKeys', function(plate)
    local trimmed = Trim(plate)
    MyKeys[trimmed] = true
end)

-- Function: Has Keys
function HasKeys(plate)
    local trimmed = Trim(plate)
    return MyKeys[trimmed] == true
end

-- Interaction Setup
CreateThread(function()
    print('[Vehicle] Initializing vehicle module...')
    -- Wait for interact to start
    Wait(1000)
    
    -- Проверяем доступность gypsy-interact
    if GetResourceState('gypsy-interact') ~= 'started' then
        print('^3[Vehicle] Warning: gypsy-interact not available, vehicle interactions disabled^0')
        return
    end
    
    exports['gypsy-interact']:AddGlobalVehicle({
        {
            label = "Toggle Lock",
            icon = "fas fa-lock",
            action = function(entity)
                local netId = NetworkGetNetworkIdFromEntity(entity)
                TriggerServerEvent('gypsy-vehicle:server:toggleLock', netId)
            end
        },
        {
            label = "Toggle Engine",
            icon = "fas fa-power-off",
            action = function(entity)
                local plate = Trim(GetVehicleNumberPlateText(entity))
                if HasKeys(plate) then
                    local engine = GetIsVehicleEngineRunning(entity)
                    SetVehicleEngineOn(entity, not engine, false, true)
                    print('Engine toggled')
                else
                    print('No keys!')
                    TriggerEvent('chat:addMessage', {args = {'^1System', 'You do not have keys.'}})
                end
            end
        },
        {
            label = "Check Info",
            icon = "fas fa-info-circle",
            action = function(entity)
                local plate = GetVehicleNumberPlateText(entity)
                local fuel = GetVehicleFuelLevel(entity)
                print('Vehicle: ' .. plate .. ' Fuel: ' .. fuel)
            end
        }
    })
    
    print('^2[Vehicle] Interactions registered successfully^0')
end)

-- Lock Animation
RegisterNetEvent('gypsy-vehicle:client:animateLock', function()
    local ped = PlayerPedId()
    RequestAnimDict("anim@mp_player_intmenu@key_fob@")
    while not HasAnimDictLoaded("anim@mp_player_intmenu@key_fob@") do Wait(10) end
    TaskPlayAnim(ped, "anim@mp_player_intmenu@key_fob@", "fob_click", 8.0, 8.0, -1, 48, 1, false, false, false)
end)

-- Keybind for Lock (L)
RegisterCommand('togglelock', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        -- Try to find closest vehicle
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end

    if vehicle ~= 0 then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent('gypsy-vehicle:server:toggleLock', netId)
    else
        TriggerEvent('chat:addMessage', {args = {'^1System', 'No vehicle found nearby.'}})
    end
end)
RegisterKeyMapping('togglelock', 'Toggle Vehicle Lock', 'keyboard', 'U')

-- ==================================================================================
-- REALISM LOGIC (Fuel & Damage)
-- ==================================================================================

local function GetFuelConsumption(vehicle)
    local rpm = GetVehicleCurrentRpm(vehicle)
    local consumption = 0.0
    
    -- Base consumption
    if rpm > 0.9 then consumption = 1.0
    elseif rpm > 0.8 then consumption = 0.8
    elseif rpm > 0.7 then consumption = 0.7
    elseif rpm > 0.6 then consumption = 0.5
    elseif rpm > 0.5 then consumption = 0.4
    elseif rpm > 0.4 then consumption = 0.3
    elseif rpm > 0.3 then consumption = 0.2
    elseif rpm > 0.2 then consumption = 0.1
    else consumption = 0.0 end -- Idle
    
    return consumption / 20.0 -- Adjust this divisor to change global fuel rate
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(vehicle, -1) == ped then -- Driver only
                
                -- 1. Fuel Logic
                if GetIsVehicleEngineRunning(vehicle) then
                    local currentFuel = GetVehicleFuelLevel(vehicle)
                    local consumption = GetFuelConsumption(vehicle)
                    
                    local newFuel = currentFuel - consumption
                    if newFuel < 0 then newFuel = 0 end
                    
                    SetVehicleFuelLevel(vehicle, newFuel)
                    
                    if newFuel <= 0 then
                        SetVehicleEngineOn(vehicle, false, true, true)
                        TriggerEvent('chat:addMessage', {args = {'^1Vehicle', 'Out of fuel!'}})
                    end
                end
                
                -- 2. Damage Logic
                local engineHealth = GetVehicleEngineHealth(vehicle)
                
                if engineHealth < 100 then
                    SetVehicleEngineOn(vehicle, false, true, true)
                elseif engineHealth < 300 then
                    -- Chance to stall
                    if math.random(1, 100) < 5 then -- 5% chance per tick (every 1s)
                        SetVehicleEngineOn(vehicle, false, true, true)
                        TriggerEvent('chat:addMessage', {args = {'^1Vehicle', 'Engine stalled!'}})
                    end
                end
                
                -- 3. HUD Update
                local data = {
                    speed = GetEntitySpeed(vehicle) * 2.236936, -- MPH
                    fuel = GetVehicleFuelLevel(vehicle),
                    engine = engineHealth,
                    locked = GetVehicleDoorLockStatus(vehicle)
                }
                TriggerEvent('gypsy-hud:client:updateVehicle', data)
                
            end
        end
        Wait(1000) -- Run every second
    end
end)

-- DEBUG COMMANDS (For testing persistence)
RegisterCommand('setfuel', function(source, args)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 and args[1] then
        local amount = tonumber(args[1])
        if amount then
            SetVehicleFuelLevel(vehicle, amount + 0.0)
            print('Fuel set to: ' .. amount)
        end
    end
end)

RegisterCommand('setdamage', function(source, args)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 and args[1] then
        local amount = tonumber(args[1])
        if amount then
            SetVehicleEngineHealth(vehicle, amount + 0.0)
            print('Engine Health set to: ' .. amount)
        end
    end
end)
