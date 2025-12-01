-- Gypsy Minigames Library
print('^2[Gypsy Minigames] Loading...^0')

local currentMinigame = nil

-- ====================================================================================
--                              SKILL CHECK
-- ====================================================================================

--- Запустить Skill Check мини-игру
--- @param difficulty number Сложность (1-5)
--- @param callback function Callback с результатом (success: boolean)
function StartSkillCheck(difficulty, callback)
    if currentMinigame then
        print('^3[Gypsy Minigames] Minigame already active^0')
        return
    end
    
    currentMinigame = {
        type = 'skillcheck',
        callback = callback
    }
    
    -- Открыть NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'startSkillCheck',
        difficulty = difficulty or 3
    })
end

-- Результат от NUI
RegisterNUICallback('skillCheckResult', function(data, cb)
    cb('ok')
    
    SetNuiFocus(false, false)
    
    if currentMinigame and currentMinigame.callback then
        currentMinigame.callback(data.success)
    end
    
    currentMinigame = nil
end)

-- Закрыть мини-игру
RegisterNUICallback('closeMinigame', function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
    
    if currentMinigame and currentMinigame.callback then
        currentMinigame.callback(false)
    end
    
    currentMinigame = nil
end)

-- ====================================================================================
--                              EXPORTS
-- ====================================================================================

exports('SkillCheck', StartSkillCheck)

print('^2[Gypsy Minigames] Loaded^0')
