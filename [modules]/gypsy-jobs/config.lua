Config = {}

-- Все доступные работы в системе
Config.Jobs = {
    unemployed = {
        label = "Безработный",
        defaultDuty = true,
        grades = {
            [0] = {
                label = "Безработный",
                salary = 0
            }
        }
    },
    
    pizza = {
        label = "Доставщик пиццы",
        defaultDuty = false,
        grades = {
            [0] = {
                label = "Стажёр",
                salary = 50
            },
            [1] = {
                label = "Курьер",
                salary = 100
            },
            [2] = {
                label = "Старший курьер",
                salary = 150
            }
        }
    },
    
    arcade = {
        label = "Техник аркад",
        defaultDuty = false,
        grades = {
            [0] = {
                label = "Помощник",
                salary = 75
            },
            [1] = {
                label = "Техник",
                salary = 125
            },
            [2] = {
                label = "Мастер",
                salary = 200
            }
        }
    },
    
    videorental = {
        label = "Работник видеопроката",
        defaultDuty = false,
        grades = {
            [0] = {
                label = "Кассир",
                salary = 60
            },
            [1] = {
                label = "Старший кассир",
                salary = 110
            },
            [2] = {
                label = "Менеджер",
                salary = 180
            }
        }
    }
}

-- Настройки зарплаты
Config.Salary = {
    Enabled = true,
    Interval = 30 * 60 * 1000,  -- 30 минут в миллисекундах
    OnDutyOnly = true            -- Платить только тем, кто на смене
}
