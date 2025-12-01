-- Street Musician Job - Client
print('^2[Musician] Client loading...^0')

local isPerforming = false
local currentLocation = nil
local instrumentProp = nil
local performanceStartTime = 0
local tipTimer = 0

-- Очистка при перезагрузке ресурса
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Удалить инструмент если есть
    if instrumentProp and DoesEntityExist(instrumentProp) then
        DeleteObject(instrumentProp)
    end
    
    -- Очистить анимацию
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end)

-- ====================================================================================
--                              INITIALIZATION
-- ====================================================================================

CreateThread(function()
    Wait(1000)
    
    -- Создать блипы для всех локаций
    for i, location in ipairs(Config.Locations) do
        local blip = AddBlipForCoord(location.coords)
        SetBlipSprite(blip, location.blip.sprite)
        SetBlipColour(blip, location.blip.color)
        SetBlipScale(blip, location.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("🎸 " .. location.label)
        EndTextCommandSetBlipName(blip)
    end
    
    print('^2[Musician] Created ' .. #Config.Locations .. ' location blips^0')
end)

-- ====================================================================================
--                              LOCATION MARKERS
-- ====================================================================================

local selectedInstrument = nil

CreateThread(function()
    while true do
        Wait(0)
        
        if not isPerforming then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            
            for i, location in ipairs(Config.Locations) do
                local distance = #(coords - location.coords)
                
                if distance < 10.0 then
                    -- Маркер
                    DrawMarker(1, location.coords.x, location.coords.y, location.coords.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0,
                        138, 43, 226, 100, false, true, 2, false, nil, nil, false)
                    
                    if distance < 2.0 then
                        SetTextComponentFormat("STRING")
                        AddTextComponentString("~INPUT_CONTEXT~ Выбрать инструмент")
                        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                        
                        if IsControlJustReleased(0, 38) then
                            ShowInstrumentMenu(i)
                        end
                    end
                end
            end
        else
            Wait(500)
        end
    end
end)

-- Меню выбора инструмента
function ShowInstrumentMenu(locationIndex)
    local elements = {}
    
    for key, instrument in pairs(Config.Instruments) do
        table.insert(elements, {
            label = instrument.label,
            value = key
        })
    end
    
    -- Простое текстовое меню через уведомления
    exports['gypsy-notifications']:Notify('Выберите инструмент: 1-Гитара, 2-Барабаны, 3-Скрипка', 'info', 5000)
    
    -- Ждём выбора (1, 2, 3)
    CreateThread(function()
        local timeout = GetGameTimer() + 5000
        
        while GetGameTimer() < timeout do
            Wait(0)
            
            if IsControlJustReleased(0, 157) then -- 1
                selectedInstrument = "guitar"
                StartPerformanceWithInstrument(locationIndex, selectedInstrument)
                break
            elseif IsControlJustReleased(0, 158) then -- 2
                selectedInstrument = "drums"
                StartPerformanceWithInstrument(locationIndex, selectedInstrument)
                break
            elseif IsControlJustReleased(0, 160) then -- 3
                selectedInstrument = "violin"
                StartPerformanceWithInstrument(locationIndex, selectedInstrument)
                break
            end
        end
    end)
end

function StartPerformanceWithInstrument(locationIndex, instrument)
    selectedInstrument = instrument
    TriggerServerEvent('musician:server:startPerformance', locationIndex, instrument)
end

-- ====================================================================================
--                              PERFORMANCE LOGIC
-- ====================================================================================

RegisterNetEvent('musician:client:startPerformance')
AddEventHandler('musician:client:startPerformance', function(locationIndex)
    local location = Config.Locations[locationIndex]
    if not location then return end
    
    isPerforming = true
    currentLocation = location
    performanceStartTime = GetGameTimer()
    tipTimer = 0
    
    -- Телепортировать к точке и заморозить
    local ped = PlayerPedId()
    SetEntityCoords(ped, location.coords.x, location.coords.y, location.coords.z)
    FreezeEntityPosition(ped, true)
    
    -- Создать инструмент и анимацию
    StartPlaying()
    
    -- Таймер выступления
    CreateThread(function()
        local duration = Config.Performance.DurationMinutes * 60 * 1000
        
        while isPerforming do
            Wait(1000)
            
            local elapsed = GetGameTimer() - performanceStartTime
            
            -- Проверка чаевых
            tipTimer = tipTimer + 1
            if tipTimer >= Config.Performance.TipInterval then
                TriggerServerEvent('musician:server:giveTip')
                tipTimer = 0
            end
            
            -- Проверка завершения
            if elapsed >= duration then
                StopPerformance(true)
                break
            end
            
            -- Проверка движения (прерывание)
            if IsControlPressed(0, 32) or IsControlPressed(0, 33) or 
               IsControlPressed(0, 34) or IsControlPressed(0, 35) then
                StopPerformance(false)
                break
            end
        end
    end)
end)

function StartPlaying()
    local ped = PlayerPedId()
    local instrumentKey = selectedInstrument or Config.DefaultInstrument
    local instrument = Config.Instruments[instrumentKey]
    
    if not instrument then
        print('^1[Musician] Invalid instrument: ' .. tostring(instrumentKey) .. '^0')
        return
    end
    
    -- Загрузить анимацию
    RequestAnimDict(instrument.animDict)
    while not HasAnimDictLoaded(instrument.animDict) do
        Wait(10)
    end
    
    -- Загрузить проп
    local propHash = GetHashKey(instrument.prop)
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do
        Wait(10)
    end
    
    -- Создать инструмент
    local coords = GetEntityCoords(ped)
    instrumentProp = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, true)
    
    AttachEntityToEntity(instrumentProp, ped, GetPedBoneIndex(ped, instrument.boneIndex),
        instrument.offset.x, instrument.offset.y, instrument.offset.z,
        instrument.rotation.x, instrument.rotation.y, instrument.rotation.z,
        true, true, false, true, 1, true)
    
    -- Анимация
    TaskPlayAnim(ped, instrument.animDict, instrument.animName,
        8.0, -8.0, -1, 1, 0, false, false, false)
end

function StopPerformance(completed)
    local ped = PlayerPedId()
    
    -- Удалить инструмент
    if instrumentProp and DoesEntityExist(instrumentProp) then
        DeleteObject(instrumentProp)
        instrumentProp = nil
    end
    
    -- Остановить анимацию
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    
    isPerforming = false
    currentLocation = nil
    
    -- Уведомить сервер
    TriggerServerEvent('musician:server:endPerformance', completed)
end

-- Прерывание по ESC
CreateThread(function()
    while true do
        Wait(0)
        
        if isPerforming then
            if IsControlJustReleased(0, 322) then -- ESC
                StopPerformance(false)
            end
        else
            Wait(500)
        end
    end
end)

print('^2[Musician] Client loaded^0')
