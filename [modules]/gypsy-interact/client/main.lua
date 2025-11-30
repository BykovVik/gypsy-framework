local Targets = {}
local GlobalVehicleOptions = {}
local GlobalPedOptions = {}
local CurrentTarget = nil
local IsTargeting = false
local IsMenuOpen = false

-- Local Config (to avoid conflicts with gypsy-core and other modules)
local InteractConfig = {
    InteractKey = 19,       -- Left Alt
    MaxDistance = 5.0,
    RayRadius = 0.5,
    Debug = false
}

-- Raycast Function
-- Sphere/Cone Cast Function
-- Raycast Function
local function GetEntityInFront()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, InteractConfig.MaxDistance, 0.0)
    
    -- Start Shape Test (Capsule is better for hitting thin objects)
    -- 10 = Vehicles, Peds, Objects (2 + 4 + 16? No, 10 is usually Vehicles(2) + Peds(8) or similar. Let's use -1 for everything or specific flags)
    -- Flags: 1=Map, 2=Vehicles, 4=Peds, 8=Objects, 16=Unk, 32=Unk, 64=Unk, 128=Unk, 256=Plants
    -- We want Vehicles (2) + Peds (4) + Objects (16) = 22. Or just -1 to hit everything except map?
    -- Let's try 30 (2+4+8+16) or just -1 but exclude map (1).
    -- Actually, 286 is a common flag for interaction (Vehicles, Peds, Objects).
    
    local handle = StartShapeTestCapsule(pos.x, pos.y, pos.z, offset.x, offset.y, offset.z, InteractConfig.RayRadius, 30, ped, 0)
    local _, hit, _, _, entity = GetShapeTestResult(handle)
    
    if InteractConfig.Debug then
        DrawLine(pos.x, pos.y, pos.z, offset.x, offset.y, offset.z, 255, 0, 0, 255)
    end
    
    return hit, entity
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
            -- Check for Interaction Key
            if IsControlPressed(0, InteractConfig.InteractKey) then
                sleep = 0
                if not IsTargeting then
                    IsTargeting = true
                    SendNUIMessage({action = 'showEye'})
                    SetNuiFocus(false, false) -- Just overlay
                end
                
                -- Disable Attack and Aim while targeting
                DisableControlAction(0, 24, true) -- Attack
                DisableControlAction(0, 25, true) -- Aim
    
                local hit, entity = GetEntityInFront()

                if hit == 1 and entity > 0 and DoesEntityExist(entity) then
                    local model = GetEntityModel(entity)
                    local options = Targets[model]
                    
                    -- Check Globals
                    if not options then
                        if IsEntityAVehicle(entity) then 
                            options = GlobalVehicleOptions
                        elseif IsEntityAPed(entity) then 
                            options = GlobalPedOptions
                        end
                    end
                    
                    if options and #options > 0 then
                        -- Valid Target Found
                        SendNUIMessage({action = 'activeEye'})
    
                        -- If clicked (Right Mouse Button)
                        if IsDisabledControlJustReleased(0, 25) then
                            CurrentTarget = {entity = entity, options = options}
                            
                            -- Prepare options for NUI (remove functions)
                            local uiOptions = {}
                            for _, option in ipairs(options) do
                                table.insert(uiOptions, {
                                    label = option.label,
                                    icon = option.icon
                                })
                            end
                            
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
