-- Gypsy Jobs System
-- Provides job management and salary system

print('^2[Gypsy-Jobs] Loading...^0')

-- Wait for core to be ready
CreateThread(function()
    while GetResourceState('gypsy-core') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    
    print('^2[Gypsy-Jobs] Core detected, initializing...^0')
end)

-- ====================================================================================
--                                  JOB SERVICE
-- ====================================================================================

local JobService = {}

--- Get job configuration
--- @param jobName string
--- @return table|nil
JobService.GetJob = function(jobName)
    return Config.Jobs[jobName]
end

--- Get all jobs
--- @return table
JobService.GetAllJobs = function()
    return Config.Jobs
end

--- Set player job
--- @param source number
--- @param jobName string
--- @param grade number
--- @return boolean
JobService.SetJob = function(source, jobName, grade)
    local Player = exports['gypsy-core']:GetPlayer(source)
    if not Player then 
        print('^1[Gypsy-Jobs] SetJob failed: Player not found (source: ' .. source .. ')^0')
        return false 
    end
    
    local job = Config.Jobs[jobName]
    if not job then 
        print('^1[Gypsy-Jobs] SetJob failed: Job not found (' .. jobName .. ')^0')
        return false 
    end
    
    grade = grade or 0
    local gradeData = job.grades[grade]
    if not gradeData then 
        print('^1[Gypsy-Jobs] SetJob failed: Grade not found (' .. grade .. ')^0')
        return false 
    end
    
    -- Update player job
    Player.job = {
        name = jobName,
        label = job.label,
        grade = grade,
        gradeLabel = gradeData.label,
        salary = gradeData.salary,
        onduty = job.defaultDuty or false
    }
    
    -- Save to database
    exports['gypsy-core']:GetCoreObject().Functions.SavePlayer(source)
    
    -- Sync to client
    TriggerClientEvent('gypsy-core:client:playerLoaded', source, Player)
    
    -- Emit event via Event Bus
    exports['gypsy-core']:Emit('job:changed', source, jobName, grade)
    
    print('^2[Gypsy-Jobs] Job set: ' .. Player.name .. ' -> ' .. job.label .. ' (Grade ' .. grade .. ')^0')
    
    return true
end

--- Promote player to next grade
--- @param source number
--- @return boolean
JobService.PromotePlayer = function(source)
    local Player = exports['gypsy-core']:GetPlayer(source)
    if not Player then return false end
    
    local job = Config.Jobs[Player.job.name]
    if not job then return false end
    
    local newGrade = Player.job.grade + 1
    if not job.grades[newGrade] then 
        print('^3[Gypsy-Jobs] Cannot promote: Max grade reached^0')
        return false 
    end
    
    return JobService.SetJob(source, Player.job.name, newGrade)
end

--- Demote player to previous grade
--- @param source number
--- @return boolean
JobService.DemotePlayer = function(source)
    local Player = exports['gypsy-core']:GetPlayer(source)
    if not Player then return false end
    
    local newGrade = Player.job.grade - 1
    if newGrade < 0 then 
        print('^3[Gypsy-Jobs] Cannot demote: Already at lowest grade^0')
        return false 
    end
    
    return JobService.SetJob(source, Player.job.name, newGrade)
end

--- Toggle duty status
--- @param source number
--- @return boolean
JobService.ToggleDuty = function(source)
    local Player = exports['gypsy-core']:GetPlayer(source)
    if not Player then return false end
    
    Player.job.onduty = not Player.job.onduty
    
    -- Sync to client
    TriggerClientEvent('gypsy-core:client:playerLoaded', source, Player)
    
    -- Emit event
    exports['gypsy-core']:Emit('job:dutyChanged', source, Player.job.onduty)
    
    return Player.job.onduty
end

-- Register service in Service Locator
exports['gypsy-core']:RegisterService('Jobs', JobService, {
    version = '1.0.0',
    description = 'Job management system'
})

print('^2[Gypsy-Jobs] JobService registered in Service Locator^0')

-- ====================================================================================
--                                  SALARY SYSTEM
-- ====================================================================================

if Config.Salary.Enabled then
    CreateThread(function()
        while true do
            Wait(Config.Salary.Interval)
            
            local Gypsy = exports['gypsy-core']:GetCoreObject()
            local players = Gypsy.Players
            
            for src, player in pairs(players) do
                if player and player.job then
                    -- Check if player should receive salary
                    local shouldPay = true
                    
                    if Config.Salary.OnDutyOnly and not player.job.onduty then
                        shouldPay = false
                    end
                    
                    if shouldPay and player.job.salary > 0 then
                        -- Add salary to bank account
                        player.Functions.AddMoney('bank', player.job.salary, 'salary-' .. player.job.name)
                        
                        -- Notify player
                        TriggerClientEvent('gypsy-notifications:client:notify', src, {
                            message = string.format('Зарплата: $%d (%s)', player.job.salary, player.job.gradeLabel),
                            type = 'success',
                            duration = 5000
                        })
                        
                        print('^2[Gypsy-Jobs] Salary paid: ' .. player.name .. ' -> $' .. player.job.salary .. '^0')
                    end
                end
            end
        end
    end)
    
    print('^2[Gypsy-Jobs] Salary system enabled (Interval: ' .. (Config.Salary.Interval / 60000) .. ' minutes)^0')
end

-- ====================================================================================
--                                  COMMANDS
-- ====================================================================================

-- /setjob [id] [job] [grade] - Set player job
RegisterCommand('setjob', function(source, args)
    local targetId = tonumber(args[1])
    local jobName = args[2]
    local grade = tonumber(args[3]) or 0
    
    if not targetId or not jobName then
        if source == 0 then
            print('Usage: setjob [player_id] [job_name] [grade]')
        else
            TriggerClientEvent('gypsy-notifications:client:notify', source, {
                message = 'Использование: /setjob [id] [работа] [ранг]',
                type = 'error'
            })
        end
        return
    end
    
    if JobService.SetJob(targetId, jobName, grade) then
        if source == 0 then
            print('^2Job set successfully^0')
        else
            TriggerClientEvent('gypsy-notifications:client:notify', source, {
                message = 'Работа установлена',
                type = 'success'
            })
        end
    else
        if source == 0 then
            print('^1Failed to set job^0')
        else
            TriggerClientEvent('gypsy-notifications:client:notify', source, {
                message = 'Ошибка установки работы',
                type = 'error'
            })
        end
    end
end, false)

-- /jobinfo - Show current job info
RegisterCommand('jobinfo', function(source)
    local Player = exports['gypsy-core']:GetPlayer(source)
    if not Player then return end
    
    -- Safety checks for job fields
    local jobLabel = Player.job.label or 'Unknown'
    local gradeLabel = Player.job.gradeLabel or 'Unknown'
    local salary = Player.job.salary or 0
    local onduty = Player.job.onduty or false
    local dutyStatus = onduty and 'На смене' or 'Не на смене'
    
    TriggerClientEvent('gypsy-notifications:client:notify', source, {
        message = string.format('%s\n%s\nЗарплата: $%d/30мин\n%s', 
            jobLabel, 
            gradeLabel,
            salary,
            dutyStatus
        ),
        type = 'info',
        duration = 6000
    })
end, false)

-- /duty - Toggle duty status
RegisterCommand('duty', function(source)
    local Player = exports['gypsy-core']:GetPlayer(source)
    if not Player then return end
    
    -- Don't allow duty toggle for unemployed
    if Player.job.name == 'unemployed' then
        TriggerClientEvent('gypsy-notifications:client:notify', source, {
            message = 'У вас нет работы',
            type = 'error'
        })
        return
    end
    
    local onDuty = JobService.ToggleDuty(source)
    
    TriggerClientEvent('gypsy-notifications:client:notify', source, {
        message = onDuty and 'Вы начали смену' or 'Вы закончили смену',
        type = onDuty and 'success' or 'info'
    })
end, false)

-- /jobs - List all available jobs (debug)
RegisterCommand('jobs', function(source)
    if source ~= 0 then return end
    
    print('=== Available Jobs ===')
    for jobName, jobData in pairs(Config.Jobs) do
        print(string.format('- %s (%s)', jobName, jobData.label))
        for grade, gradeData in pairs(jobData.grades) do
            print(string.format('  [%d] %s - $%d', grade, gradeData.label, gradeData.salary))
        end
    end
end, false)

print('^2[Gypsy-Jobs] Module loaded successfully^0')
