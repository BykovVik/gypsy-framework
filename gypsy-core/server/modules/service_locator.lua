-- Service Locator Pattern
-- Центральный реестр сервисов для слабой связанности модулей

ServiceLocator = {
    services = {},
    metadata = {}
}

--- Регистрирует сервис в локаторе
--- @param name string Уникальное имя сервиса
--- @param service table Объект сервиса с методами
--- @param metadata table Опциональные метаданные (version, description)
function ServiceLocator:Register(name, service, metadata)
    if self.services[name] then
        print('^3[ServiceLocator] Warning: Service "' .. name .. '" already registered, overwriting^0')
    end
    
    self.services[name] = service
    self.metadata[name] = metadata or {}
    
    print('^2[ServiceLocator] Registered service: ' .. name .. '^0')
    
    -- Emit событие о регистрации
    if EventBus then
        EventBus:Emit('service:registered', name, service)
    end
end

--- Получает сервис по имени
--- @param name string Имя сервиса
--- @return table|nil Объект сервиса или nil если не найден
function ServiceLocator:Get(name)
    return self.services[name]
end

--- Проверяет наличие сервиса
--- @param name string Имя сервиса
--- @return boolean
function ServiceLocator:Has(name)
    return self.services[name] ~= nil
end

--- Удаляет сервис из реестра
--- @param name string Имя сервиса
function ServiceLocator:Unregister(name)
    if not self.services[name] then
        print('^3[ServiceLocator] Warning: Service "' .. name .. '" not found^0')
        return
    end
    
    self.services[name] = nil
    self.metadata[name] = nil
    
    print('^3[ServiceLocator] Unregistered service: ' .. name .. '^0')
    
    -- Emit событие об удалении
    if EventBus then
        EventBus:Emit('service:unregistered', name)
    end
end

--- Получает список всех зарегистрированных сервисов
--- @return table Массив имен сервисов
function ServiceLocator:GetAll()
    local names = {}
    for name, _ in pairs(self.services) do
        table.insert(names, name)
    end
    return names
end

--- Получает метаданные сервиса
--- @param name string Имя сервиса
--- @return table|nil Метаданные или nil
function ServiceLocator:GetMetadata(name)
    return self.metadata[name]
end

--- Безопасный вызов метода сервиса
--- @param serviceName string Имя сервиса
--- @param methodName string Имя метода
--- @param ... any Аргументы метода
--- @return boolean success, any result
function ServiceLocator:SafeCall(serviceName, methodName, ...)
    local service = self:Get(serviceName)
    
    if not service then
        return false, 'Service not found: ' .. serviceName
    end
    
    if not service[methodName] then
        return false, 'Method not found: ' .. methodName
    end
    
    local success, result = pcall(service[methodName], ...)
    
    if not success then
        print('^1[ServiceLocator] Error calling ' .. serviceName .. '.' .. methodName .. ': ' .. tostring(result) .. '^0')
        return false, result
    end
    
    return true, result
end
