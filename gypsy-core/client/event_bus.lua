-- Client Event Bus Pattern
-- Pub/Sub система для развязки модулей на клиенте

Gypsy.EventBus = {
    listeners = {},
    onceListeners = {}
}

--- Подписывается на событие
--- @param eventName string Имя события
--- @param callback function Функция-обработчик
--- @param priority number Приоритет (больше = раньше выполняется)
function Gypsy.EventBus:On(eventName, callback, priority)
    if not self.listeners[eventName] then
        self.listeners[eventName] = {}
    end
    
    table.insert(self.listeners[eventName], {
        callback = callback,
        priority = priority or 0
    })
    
    -- Сортируем по приоритету
    table.sort(self.listeners[eventName], function(a, b)
        return a.priority > b.priority
    end)
end

--- Подписывается на событие (выполнится только один раз)
--- @param eventName string Имя события
--- @param callback function Функция-обработчик
function Gypsy.EventBus:Once(eventName, callback)
    if not self.onceListeners[eventName] then
        self.onceListeners[eventName] = {}
    end
    
    table.insert(self.onceListeners[eventName], callback)
end

--- Отписывается от события
--- @param eventName string Имя события
--- @param callback function Функция-обработчик для удаления
function Gypsy.EventBus:Off(eventName, callback)
    if not self.listeners[eventName] then
        return
    end
    
    for i = #self.listeners[eventName], 1, -1 do
        if self.listeners[eventName][i].callback == callback then
            table.remove(self.listeners[eventName], i)
        end
    end
end

--- Генерирует событие
--- @param eventName string Имя события
--- @param ... any Аргументы для передачи обработчикам
function Gypsy.EventBus:Emit(eventName, ...)
    local args = {...}
    
    -- Выполняем once listeners
    if self.onceListeners[eventName] then
        for _, callback in ipairs(self.onceListeners[eventName]) do
            local success, err = pcall(callback, table.unpack(args))
            if not success then
                print('^1[EventBus] Error in once listener for "' .. eventName .. '": ' .. tostring(err) .. '^0')
            end
        end
        self.onceListeners[eventName] = nil
    end
    
    -- Выполняем обычные listeners
    if self.listeners[eventName] then
        for _, listener in ipairs(self.listeners[eventName]) do
            local success, err = pcall(listener.callback, table.unpack(args))
            if not success then
                print('^1[EventBus] Error in listener for "' .. eventName .. '": ' .. tostring(err) .. '^0')
            end
        end
    end
end

--- Удаляет все подписки на событие
--- @param eventName string Имя события
function Gypsy.EventBus:RemoveAllListeners(eventName)
    self.listeners[eventName] = nil
    self.onceListeners[eventName] = nil
end

--- Получает количество подписчиков на событие
--- @param eventName string Имя события
--- @return number Количество подписчиков
function Gypsy.EventBus:GetListenerCount(eventName)
    local count = 0
    
    if self.listeners[eventName] then
        count = count + #self.listeners[eventName]
    end
    
    if self.onceListeners[eventName] then
        count = count + #self.onceListeners[eventName]
    end
    
    return count
end
