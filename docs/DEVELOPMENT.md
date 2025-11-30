# Gypsy Framework - Development Guide

> Руководство по созданию собственных модулей

---

## 📋 Содержание

- [Начало работы](#начало-работы)
- [Структура модуля](#структура-модуля)
- [Service Locator](#service-locator)
- [Event Bus](#event-bus)
- [Best Practices](#best-practices)
- [Примеры](#примеры)
- [Отладка](#отладка)

---

## 🚀 Начало работы

### Требования

- Базовые знания Lua
- Понимание FiveM API
- Установленный Gypsy Framework

### Создание нового модуля

1. **Создайте директорию модуля**
   ```
   resources/[gypsy-framework]/[modules]/gypsy-mymodule/
   ```

2. **Создайте fxmanifest.lua**
   ```lua
   fx_version 'cerulean'
   game 'gta5'
   
   description 'My Custom Module'
   version '1.0.0'
   
   client_scripts {
       'client/main.lua'
   }
   
   server_scripts {
       'server/main.lua'
   }
   
   dependencies {
       'gypsy-core'
   }
   ```

3. **Добавьте в server.cfg**
   ```cfg
   ensure gypsy-mymodule
   ```

---

## 📁 Структура модуля

### Рекомендуемая структура

```
gypsy-mymodule/
├── fxmanifest.lua          # Манифест ресурса
├── config.lua              # Конфигурация (опционально)
├── client/
│   └── main.lua            # Клиентская логика
├── server/
│   └── main.lua            # Серверная логика
└── html/                   # UI (если нужен)
    ├── index.html
    ├── style.css
    └── script.js
```

### Минимальный модуль

**fxmanifest.lua:**
```lua
fx_version 'cerulean'
game 'gta5'

description 'My Module'
version '1.0.0'

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'gypsy-core'
}
```

**server.lua:**
```lua
print('[MyModule] Server started')

-- Ваша логика здесь
```

**client.lua:**
```lua
print('[MyModule] Client started')

-- Ваша логика здесь
```

---

## 🔧 Service Locator

### Регистрация сервиса

Сервисы позволяют другим модулям использовать ваш функционал.

**server/main.lua:**
```lua
-- Создаем объект сервиса
local MyService = {}

-- Добавляем методы
MyService.DoSomething = function(param1, param2)
    print('Doing something with:', param1, param2)
    return true
end

MyService.GetData = function(source)
    local Player = Gypsy.Functions.GetPlayer(source)
    if not Player then return nil end
    
    return {
        citizenid = Player.citizenid,
        name = Player.name
    }
end

-- Регистрируем сервис
exports['gypsy-core']:RegisterService('MyService', MyService, {
    version = '1.0.0',
    description = 'My custom service'
})

print('[MyModule] Service registered')
```

### Использование сервисов

**В другом модуле:**
```lua
-- Получаем сервис
local MyService = exports['gypsy-core']:GetService('MyService')

-- Проверяем наличие
if not MyService then
    print('MyService not available')
    return
end

-- Используем методы
MyService.DoSomething('hello', 'world')
local data = MyService.GetData(source)
```

### Проверка наличия сервиса

```lua
-- Безопасный вызов
local MyService = exports['gypsy-core']:GetService('MyService')
if MyService and MyService.DoSomething then
    MyService.DoSomething('test')
end

-- Или через HasService
if exports['gypsy-core']:HasService('MyService') then
    local MyService = exports['gypsy-core']:GetService('MyService')
    MyService.DoSomething('test')
end
```

---

## 📡 Event Bus

### Публикация событий

```lua
-- Server-side
exports['gypsy-core']:Emit('mymodule:playerJoined', source, playerData)

-- С несколькими параметрами
exports['gypsy-core']:Emit('mymodule:actionCompleted', {
    player = source,
    action = 'purchase',
    amount = 500
})
```

### Подписка на события

```lua
-- Server-side
exports['gypsy-core']:On('mymodule:playerJoined', function(source, playerData)
    print('Player joined:', playerData.citizenid)
end)

-- С приоритетом (выше = раньше выполнится)
exports['gypsy-core']:On('player:spawn', function(playerData)
    print('High priority handler')
end, 100)

exports['gypsy-core']:On('player:spawn', function(playerData)
    print('Low priority handler')
end, 1)
```

### Одноразовая подписка

```lua
-- Выполнится только один раз
exports['gypsy-core']:Once('server:ready', function()
    print('Server is ready, initializing module...')
    -- Инициализация
end)
```

### Отписка от событий

```lua
local handler = function(data)
    print('Event received:', data)
end

-- Подписываемся
exports['gypsy-core']:On('mymodule:event', handler)

-- Отписываемся
exports['gypsy-core']:Off('mymodule:event', handler)
```

---

## 💡 Best Practices

### 1. Используйте локальные конфиги

**❌ Плохо:**
```lua
Config = {}  -- Глобальная переменная, конфликтует с другими модулями
Config.Setting = true
```

**✅ Хорошо:**
```lua
local MyModuleConfig = {}
MyModuleConfig.Setting = true
```

### 2. Проверяйте наличие игрока

**❌ Плохо:**
```lua
RegisterNetEvent('mymodule:doSomething', function()
    local Player = Gypsy.Functions.GetPlayer(source)
    Player.Functions.AddMoney('cash', 100)  -- Может быть nil!
end)
```

**✅ Хорошо:**
```lua
RegisterNetEvent('mymodule:doSomething', function()
    local Player = Gypsy.Functions.GetPlayer(source)
    if not Player then 
        print('[MyModule] Player not found')
        return 
    end
    
    Player.Functions.AddMoney('cash', 100)
end)
```

### 3. Указывайте причину при работе с деньгами

**✅ Хорошо:**
```lua
Player.Functions.RemoveMoney('cash', 500, 'mymodule-purchase')
Player.Functions.AddMoney('bank', 1000, 'mymodule-reward')
```

### 4. Используйте уведомления

```lua
-- Server-side
local function Notify(source, message, type)
    TriggerClientEvent('gypsy-notifications:client:notify', source, {
        message = message,
        type = type or 'info',
        duration = 3000
    })
end

-- Использование
Notify(source, 'Операция выполнена', 'success')
Notify(source, 'Недостаточно средств', 'error')
```

### 5. Обрабатывайте ошибки

```lua
-- С защитой от ошибок
local success, result = pcall(function()
    return exports['gypsy-core']:GetService('MyService')
end)

if not success then
    print('[MyModule] Error getting service:', result)
    return
end
```

### 6. Оптимизируйте циклы

**❌ Плохо:**
```lua
CreateThread(function()
    while true do
        Wait(0)  -- Каждый кадр!
        -- Тяжелая логика
    end
end)
```

**✅ Хорошо:**
```lua
CreateThread(function()
    while true do
        Wait(1000)  -- Раз в секунду
        -- Логика
    end
end)
```

### 7. Используйте Event Bus для коммуникации

**❌ Плохо:**
```lua
-- Прямая зависимость от другого модуля
exports['other-module']:DoSomething()
```

**✅ Хорошо:**
```lua
-- Слабосвязанная коммуникация
exports['gypsy-core']:Emit('mymodule:needsAction', data)

-- В другом модуле
exports['gypsy-core']:On('mymodule:needsAction', function(data)
    -- Обработка
end)
```

---

## 📝 Примеры

### Пример 1: Простой модуль с сервисом

**server/main.lua:**
```lua
local RewardService = {}

RewardService.GiveReward = function(source, amount)
    local Player = Gypsy.Functions.GetPlayer(source)
    if not Player then return false end
    
    Player.Functions.AddMoney('cash', amount, 'reward-service')
    
    TriggerClientEvent('gypsy-notifications:client:notify', source, {
        message = 'Вы получили награду: $' .. amount,
        type = 'success'
    })
    
    exports['gypsy-core']:Emit('reward:given', source, amount)
    return true
end

-- Регистрируем сервис
exports['gypsy-core']:RegisterService('Reward', RewardService)

-- Команда для теста
RegisterCommand('reward', function(source, args)
    local amount = tonumber(args[1]) or 100
    RewardService.GiveReward(source, amount)
end)
```

### Пример 2: Модуль с UI

**fxmanifest.lua:**
```lua
fx_version 'cerulean'
game 'gta5'

ui_page 'html/index.html'

client_script 'client/main.lua'
server_script 'server/main.lua'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
```

**client/main.lua:**
```lua
local isMenuOpen = false

-- Открыть меню
RegisterCommand('mymenu', function()
    if isMenuOpen then return end
    
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = {
            title = 'My Menu',
            items = {'Item 1', 'Item 2', 'Item 3'}
        }
    })
end)

-- NUI Callback
RegisterNUICallback('close', function(data, cb)
    isMenuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('selectItem', function(data, cb)
    print('Selected item:', data.item)
    TriggerServerEvent('mymodule:itemSelected', data.item)
    cb('ok')
end)
```

**html/script.js:**
```javascript
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === 'open') {
        document.getElementById('menu').style.display = 'block';
        // Заполнить меню
    }
});

function closeMenu() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        body: JSON.stringify({})
    });
    document.getElementById('menu').style.display = 'none';
}

function selectItem(item) {
    fetch(`https://${GetParentResourceName()}/selectItem`, {
        method: 'POST',
        body: JSON.stringify({item: item})
    });
}
```

### Пример 3: Интеграция с gypsy-interact

**client/main.lua:**
```lua
CreateThread(function()
    -- Добавляем взаимодействие для банкомата
    exports['gypsy-interact']:AddTargetModel('prop_atm_01', {
        {
            label = "Использовать банкомат",
            icon = "fas fa-credit-card",
            action = function(entity)
                -- Открыть UI банкомата
                TriggerEvent('mymodule:openATM')
            end
        }
    })
    
    -- Добавляем взаимодействие для всех машин
    exports['gypsy-interact']:AddGlobalVehicle({
        {
            label = "Проверить топливо",
            icon = "fas fa-gas-pump",
            action = function(entity)
                local fuel = GetVehicleFuelLevel(entity)
                exports['gypsy-notifications']:Notify(
                    'Топливо: ' .. math.floor(fuel) .. '%',
                    'info'
                )
            end
        }
    })
end)
```

---

## 🐛 Отладка

### Логирование

```lua
-- Простое логирование
print('[MyModule] Something happened')

-- С данными
print('[MyModule] Player data:', json.encode(playerData))

-- Условное логирование
local DEBUG = true
if DEBUG then
    print('[MyModule] Debug info:', data)
end
```

### Проверка загрузки модуля

```lua
-- В начале server/main.lua
print('^2[MyModule] Server script loaded^0')

-- В начале client/main.lua
print('^2[MyModule] Client script loaded^0')
```

### Отладка событий

```lua
-- Логирование всех событий
exports['gypsy-core']:On('*', function(eventName, ...)
    print('[EventBus] Event fired:', eventName)
end)
```

### Проверка сервисов

```lua
-- Список всех сервисов
local services = exports['gypsy-core']:GetAllServices()
for name, service in pairs(services) do
    print('Service:', name)
end
```

---

## 🔍 Частые ошибки

### 1. Сервис не найден

**Проблема:**
```lua
local MyService = exports['gypsy-core']:GetService('MyService')
-- MyService = nil
```

**Решение:**
- Проверьте порядок загрузки в `server.cfg`
- Убедитесь, что сервис зарегистрирован
- Проверьте имя сервиса (регистрозависимо)

### 2. Конфликт глобальных переменных

**Проблема:**
```lua
Config = {}  -- Перезаписывается другими модулями
```

**Решение:**
```lua
local MyConfig = {}  -- Локальная переменная
```

### 3. NUI не отвечает

**Проблема:** Callback не срабатывает

**Решение:**
```lua
-- Всегда вызывайте cb()
RegisterNUICallback('action', function(data, cb)
    -- Ваш код
    cb('ok')  -- Обязательно!
end)
```

### 4. Игрок не найден

**Проблема:**
```lua
local Player = Gypsy.Functions.GetPlayer(source)
Player.Functions.AddMoney(...)  -- Error: attempt to index nil
```

**Решение:**
```lua
local Player = Gypsy.Functions.GetPlayer(source)
if not Player then return end
Player.Functions.AddMoney(...)
```

---

## 📚 Дополнительные ресурсы

- [API Reference](API.md)
- [Modules Guide](MODULES.md)
- [FiveM Docs](https://docs.fivem.net/)
- [Lua Documentation](https://www.lua.org/manual/5.4/)

---

## 🤝 Вклад в проект

Если вы создали полезный модуль:

1. Убедитесь, что он следует best practices
2. Добавьте документацию
3. Создайте Pull Request
4. Опишите функционал и зависимости

---

## 📄 Шаблон модуля

Используйте этот шаблон для быстрого старта:

```lua
-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

description 'My Module'
version '1.0.0'

client_script 'client/main.lua'
server_script 'server/main.lua'

dependencies {
    'gypsy-core'
}
```

```lua
-- server/main.lua
local MyService = {}

MyService.DoSomething = function(source, param)
    local Player = Gypsy.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- Ваша логика
    
    return true
end

exports['gypsy-core']:RegisterService('MyService', MyService)
print('^2[MyModule] Server loaded^0')
```

```lua
-- client/main.lua
CreateThread(function()
    print('^2[MyModule] Client loaded^0')
    
    -- Ваша логика
end)
```

---

<p align="center">Удачи в разработке! 🚀</p>
