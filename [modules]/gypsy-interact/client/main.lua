local Targets = {}
local GlobalVehicleOptions = {}
local GlobalPedOptions = {}
local CurrentTarget = nil
local IsTargeting = false
local IsMenuOpen = false

-- Raycast Function
-- Sphere/Cone Cast Function
local function GetEntityInFront()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local maxDist = 5.0
    local closestEntity = 0
    local closestDist = maxDist
    
    -- Helper to check pool
    local function CheckPool(pool)
        for _, entity in ipairs(pool) do
            if entity ~= ped then
                local entPos = GetEntityCoords(entity)
                local dist = #(pos - entPos)
                
                if dist < closestDist then
                    -- Check angle (Dot Product)
                    local dir = entPos - pos
                    local dirNorm = dir / dist
                    local dot = dot(forward, dirNorm)
                    
                    -- 0.5 is roughly 60 degrees, 0.8 is roughly 35 degrees
                    if dot > 0.5 then 
                        closestEntity = entity
                        closestDist = dist
                    end
                end
            end
        end
    end
    
    CheckPool(GetGamePool('CVehicle'))
    CheckPool(GetGamePool('CPed'))
    
    if closestEntity > 0 then
        return 1, closestEntity
    else
        return 0, 0
    end
end

-- Main Loop
-- Main Loop
CreateThread(function()
    while true do
        local sleep = 200
        
        -- If menu is open, stop processing target logic
        if IsMenuOpen then
            Wait(500)
        else
            -- Check for Alt key (19 = Left Alt)
            if IsControlPressed(0, 19) then
                sleep = 0
                if not IsTargeting then
                    IsTargeting = true
                    SendNUIMessage({action = 'showEye'})
                    SetNuiFocus(false, false) -- Just overlay
                end
                
                -- Disable Attack and Aim while targeting
                DisableControlAction(0, 24, true) -- Attack
                DisableControlAction(0, 25, true) -- Aim
    
                -- Debug Input
                -- if IsDisabledControlJustPressed(0, 25) then
                --     print('[Interact] DEBUG: RMB Pressed (Disabled)')
                -- end
    
                local hit, entity = GetEntityInFront()
                
                -- Debug Raw Raycast
                -- if GetGameTimer() % 1000 < 20 then
                --    print('[Interact] Raycast: Hit=' .. tostring(hit) .. ' Entity=' .. tostring(entity))
                -- end

                if hit == 1 and entity > 0 then
                    local model = GetEntityModel(entity)
                    local options = Targets[model]
                    
                    -- Check Globals
                    if not options then
                        if IsEntityAVehicle(entity) then 
                            options = GlobalVehicleOptions 
                            print('[Interact] Using Global Vehicle Options. Count: ' .. (options and #options or 0)) 
                        end
                        if IsEntityAPed(entity) then 
                            options = GlobalPedOptions 
                            print('[Interact] Using Global Ped Options. Count: ' .. (options and #options or 0))
                        end
                    end
                    
                    if options then
                        -- Valid Target Found
                        SendNUIMessage({action = 'activeEye'})
                        
                        -- Debug: Print every second to confirm we see the entity
                        -- if GetGameTimer() % 1000 < 20 then
                        --     print('[Interact] Targeting Entity: ' .. entity .. ' | Options: YES')
                        -- end
    
                        -- If clicked (Right Mouse Button)
                        -- Use IsDisabledControlJustReleased because we disabled the control above
                        if IsDisabledControlJustReleased(0, 25) then
                            print('[Interact] Right Click detected on entity: ' .. entity)
                            CurrentTarget = {entity = entity, options = options}
                            
                            -- Prepare options for NUI (remove functions)
                            local uiOptions = {}
                            for _, option in ipairs(options) do
                                table.insert(uiOptions, {
                                    label = option.label,
                                    icon = option.icon
                                })
                            end
                            print('[Interact] Sending ' .. #uiOptions .. ' options to NUI')
                            
                            -- print('[Interact] Sending options to NUI') -- Safe print
                            SendNUIMessage({
                                action = 'setOptions',
                                options = uiOptions
                            })
                            SetNuiFocus(true, true)
                            IsMenuOpen = true -- Stop the loop from closing it
                        end
                    else
                        SendNUIMessage({action = 'inactiveEye'})
                    end
                else
                    SendNUIMessage({action = 'inactiveEye'})
                end
    
            else
                if IsTargeting then
                    IsTargeting = false
                    SendNUIMessage({action = 'hideEye'})
                    SetNuiFocus(false, false)
                end
            end
        end
        
        Wait(sleep)
    end
end)

RegisterNetEvent('gypsy-interact:client:closeMenu')
AddEventHandler('gypsy-interact:client:closeMenu', function()
    IsMenuOpen = false
    IsTargeting = false
    SendNUIMessage({action = 'hideEye'})
    SetNuiFocus(false, false)
end)

RegisterCommand('resetinteract', function()
    IsMenuOpen = false
    IsTargeting = false
    SendNUIMessage({action = 'hideEye'})
    SetNuiFocus(false, false)
    print('[Interact] Menu state reset.')
end)

-- Exports
function AddTargetModel(models, options)
    if type(models) ~= 'table' then models = {models} end
    for _, model in pairs(models) do
        if type(model) == 'string' then model = GetHashKey(model) end
        Targets[model] = options
    end
end

function AddGlobalVehicle(options)
    for _, option in ipairs(options) do
        table.insert(GlobalVehicleOptions, option)
    end
    print('[Interact] Registered ' .. #options .. ' global vehicle options.')
end

function AddGlobalPed(options)
    for _, option in ipairs(options) do
        table.insert(GlobalPedOptions, option)
    end
    print('[Interact] Registered ' .. #options .. ' global ped options.')
end

exports('AddTargetModel', AddTargetModel)
exports('AddGlobalVehicle', AddGlobalVehicle)
exports('AddGlobalPed', AddGlobalPed)

-- TEST INTERACTION
CreateThread(function()
    AddGlobalVehicle({
        {
            label = "Check Vehicle Info",
            icon = "fas fa-car",
            action = function(entity)
                local plate = GetVehicleNumberPlateText(entity)
                local fuel = GetVehicleFuelLevel(entity)
                print('Vehicle Checked: ' .. plate .. ' | Fuel: ' .. fuel)
                TriggerEvent('chat:addMessage', {
                    args = {'^2[Interact]', 'Vehicle: ' .. plate .. ' | Fuel: ' .. math.floor(fuel) .. '%'}
                })
            end
        },
        {
            label = "Toggle Engine",
            icon = "fas fa-key",
            action = function(entity)
                local engine = GetIsVehicleEngineRunning(entity)
                SetVehicleEngineOn(entity, not engine, false, true)
                print('Engine toggled')
            end
        }
    })
    
    AddGlobalPed({
        {
            label = "Say Hello",
            icon = "fas fa-user",
            action = function(entity)
                print('Said hello to ped')
                TriggerEvent('chat:addMessage', {
                    args = {'^2[Interact]', 'You said hello to the stranger.'}
                })
            end
        }
    })
end)

-- NUI Callbacks
RegisterNUICallback('selectOption', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'hideEye'})
    TriggerEvent('gypsy-interact:client:closeMenu')
    
    if CurrentTarget and CurrentTarget.options and CurrentTarget.options[data.index + 1] then
        local option = CurrentTarget.options[data.index + 1]
        if option.event then
            TriggerEvent(option.event, CurrentTarget.entity)
        elseif option.serverEvent then
            TriggerServerEvent(option.serverEvent, NetworkGetNetworkIdFromEntity(CurrentTarget.entity))
        elseif option.action then
            option.action(CurrentTarget.entity)
        end
    end
    
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'hideEye'})
    TriggerEvent('gypsy-interact:client:closeMenu')
    cb('ok')
end)
