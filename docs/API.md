# Gypsy Framework - API Reference

> Полная документация API для разработчиков

---

## 📋 Содержание

- [gypsy-core](#gypsy-core)
  - [Service Locator](#service-locator)
  - [Event Bus](#event-bus)
  - [Player Functions](#player-functions)
- [gypsy-garage](#gypsy-garage)
- [gypsy-impound](#gypsy-impound)
- [gypsy-notifications](#gypsy-notifications)
- [gypsy-interact](#gypsy-interact)
- [gypsy-inventory](#gypsy-inventory)

---

## gypsy-core

Ядро фреймворка, предоставляющее базовую функциональность.

### Service Locator

Централизованная система управления сервисами.

#### RegisterService

Регистрирует новый сервис в Service Locator.

**Server-side:**
```lua
exports['gypsy-core']:RegisterService(serviceName, serviceObject, metadata)
```

**Параметры:**
- `serviceName` (string) — уникальное имя сервиса
- `serviceObject` (table) — объект с методами сервиса
- `metadata` (table, optional) — метаданные сервиса

**Пример:**
```lua
local MyService = {
    DoSomething = function(param)
        print('Doing something with: ' .. param)
        return true
    end,
    
    GetData = function()
        return {value = 42}
    end
}

exports['gypsy-core']:RegisterService('MyService', MyService, {
    version = '1.0.0',
    description = 'My custom service'
})
```

---

#### GetService

Получает зарегистрированный сервис.

**Server-side / Client-side:**
```lua
local service = exports['gypsy-core']:GetService(serviceName)
```

**Параметры:**
- `serviceName` (string) — имя сервиса

**Возвращает:**
- `table` — объект сервиса или `nil`

**Пример:**
```lua
local GarageService = exports['gypsy-core']:GetService('Garage')
if GarageService then
    GarageService.ParkVehicle(plate, citizenid)
end
```

---

#### HasService

Проверяет наличие сервиса.

**Server-side:**
```lua
local exists = exports['gypsy-core']:HasService(serviceName)
```

**Параметры:**
- `serviceName` (string) — имя сервиса

**Возвращает:**
- `boolean` — `true` если сервис существует

---

### Event Bus

Система событий для слабосвязанной коммуникации.

#### Emit

Публикует событие.

**Server-side:**
```lua
exports['gypsy-core']:Emit(eventName, ...)
```

**Параметры:**
- `eventName` (string) — имя события
- `...` — любые аргументы для передачи слушателям

**Пример:**
```lua
exports['gypsy-core']:Emit('player:moneyChanged', source, 'cash', 1000)
```

---

#### On

Подписывается на событие.

**Server-side:**
```lua
exports['gypsy-core']:On(eventName, callback, priority)
```

**Параметры:**
- `eventName` (string) — имя события
- `callback` (function) — функция-обработчик
- `priority` (number, optional) — приоритет (по умолчанию 0)

**Пример:**
```lua
exports['gypsy-core']:On('player:spawn', function(playerData)
    print('Player spawned: ' .. playerData.citizenid)
end, 10)
```

---

#### Once

Подписывается на событие один раз.

**Server-side:**
```lua
exports['gypsy-core']:Once(eventName, callback)
```

**Пример:**
```lua
exports['gypsy-core']:Once('server:ready', function()
    print('Server is ready!')
end)
```

---

#### Off

Отписывается от события.

**Server-side:**
```lua
exports['gypsy-core']:Off(eventName, callback)
```

---

### Player Functions

Функции для работы с игроками.

#### GetPlayer

Получает данные игрока по source.

**Server-side:**
```lua
local Player = Gypsy.Functions.GetPlayer(source)
```

**Возвращает:**
```lua
{
    citizenid = "ABC12345",
    license = "license:xxxxx",
    name = "Player Name",
    money = {
        cash = 5000,
        bank = 10000,
        savings = 50000
    },
    job = {
        name = "unemployed",
        label = "Unemployed",
        grade = 0
    },
    charinfo = {
        firstname = "John",
        lastname = "Doe",
        birthdate = "1990-01-01"
    },
    metadata = {
        hunger = 100,
        thirst = 100
    },
    Functions = {
        SetMoney = function(type, amount, reason) end,
        AddMoney = function(type, amount, reason) end,
        RemoveMoney = function(type, amount, reason) end,
        GetMoney = function(type) end
    }
}
```

---

#### Player Money Functions

**SetMoney** — устанавливает количество денег
```lua
Player.Functions.SetMoney('cash', 5000, 'admin-give')
```

**AddMoney** — добавляет деньги
```lua
Player.Functions.AddMoney('bank', 1000, 'salary')
```

**RemoveMoney** — убирает деньги
```lua
local success = Player.Functions.RemoveMoney('cash', 500, 'purchase')
if success then
    print('Payment successful')
end
```

**GetMoney** — получает количество денег
```lua
local cash = Player.Functions.GetMoney('cash')
```

**Типы валюты:**
- `cash` — наличные
- `bank` — банковский счет
- `savings` — сбережения

---

## gypsy-garage

Система гаражей для хранения транспорта.

### GarageService

#### ParkVehicle

Паркует транспорт в гараж.

**Server-side:**
```lua
local GarageService = exports['gypsy-core']:GetService('Garage')
GarageService.ParkVehicle(plate, citizenid, garage, fuel, engine, body, mods)
```

**Параметры:**
- `plate` (string) — номер транспорта
- `citizenid` (string) — ID владельца
- `garage` (string) — название гаража
- `fuel` (number) — уровень топлива (0-100)
- `engine` (number) — здоровье двигателя (0-1000)
- `body` (number) — здоровье кузова (0-1000)
- `mods` (string) — JSON с модификациями

---

#### SpawnVehicle

Достает транспорт из гаража.

**Server-side:**
```lua
GarageService.SpawnVehicle(plate, citizenid)
```

**Параметры:**
- `plate` (string) — номер транспорта
- `citizenid` (string) — ID владельца

---

#### ImpoundVehicle

Отправляет транспорт на штрафплощадку.

**Server-side:**
```lua
GarageService.ImpoundVehicle(plate, fee)
```

**Параметры:**
- `plate` (string) — номер транспорта
- `fee` (number, optional) — размер штрафа (по умолчанию 500)

---

#### GetVehiclesByState

Получает список транспорта по состоянию.

**Server-side:**
```lua
local vehicles = GarageService.GetVehiclesByState(citizenid, state)
```

**Параметры:**
- `citizenid` (string) — ID владельца
- `state` (number) — состояние (0 = на улице, 1 = в гараже, 2 = на штрафплощадке)

**Возвращает:**
```lua
{
    {
        vehicle = "adder",
        plate = "ABC123",
        garage = "legion",
        fuel = 75,
        engine = 950,
        body = 980,
        mods = "{...}"
    },
    -- ...
}
```

---

### Events

#### Client Events

**gypsy-garage:client:openGarage**
```lua
TriggerEvent('gypsy-garage:client:openGarage', garageName)
```

**gypsy-garage:client:spawnVehicle**
```lua
-- Автоматически вызывается сервером
```

---

#### Server Events

**gypsy-garage:server:takeVehicle**
```lua
TriggerServerEvent('gypsy-garage:server:takeVehicle', plate)
```

**gypsy-garage:server:parkVehicle**
```lua
TriggerServerEvent('gypsy-garage:server:parkVehicle', plate, garage)
```

---

## gypsy-impound

Система штрафплощадки.

### Commands

#### /impound

Отправляет транспорт на штрафплощадку (админ-команда).

```lua
/impound ABC123
```

---

### Events

#### Client Events

**gypsy-impound:client:openMenu**
```lua
TriggerEvent('gypsy-impound:client:openMenu')
```

**gypsy-impound:client:spawnVehicle**
```lua
-- Автоматически вызывается сервером после оплаты
```

---

#### Server Events

**gypsy-impound:server:getVehicles**
```lua
TriggerServerEvent('gypsy-impound:server:getVehicles')
```

**gypsy-impound:server:retrieveVehicle**
```lua
TriggerServerEvent('gypsy-impound:server:retrieveVehicle', plate)
```

---

## gypsy-notifications

Система уведомлений.

### Notify

Показывает уведомление игроку.

**Client-side:**
```lua
exports['gypsy-notifications']:Notify(message, type, duration)
```

**Параметры:**
- `message` (string) — текст уведомления
- `type` (string) — тип ('success', 'error', 'info', 'warning')
- `duration` (number, optional) — длительность в мс (по умолчанию 3000)

**Пример:**
```lua
exports['gypsy-notifications']:Notify('Транспорт припаркован', 'success', 3000)
```

---

**Server-side (для конкретного игрока):**
```lua
TriggerClientEvent('gypsy-notifications:client:notify', source, {
    message = 'Недостаточно средств',
    type = 'error',
    duration = 3000
})
```

---

## gypsy-interact

Система взаимодействий (target).

### Exports

#### AddTargetModel

Добавляет взаимодействие для конкретной модели.

**Client-side:**
```lua
exports['gypsy-interact']:AddTargetModel(models, options)
```

**Параметры:**
- `models` (string/table) — хеш модели или массив хешей
- `options` (table) — массив опций взаимодействия

**Пример:**
```lua
exports['gypsy-interact']:AddTargetModel('prop_atm_01', {
    {
        label = "Использовать банкомат",
        icon = "fas fa-credit-card",
        action = function(entity)
            -- Открыть UI банкомата
        end
    }
})
```

---

#### AddGlobalVehicle

Добавляет взаимодействие для всех транспортных средств.

**Client-side:**
```lua
exports['gypsy-interact']:AddGlobalVehicle(options)
```

**Пример:**
```lua
exports['gypsy-interact']:AddGlobalVehicle({
    {
        label = "Проверить топливо",
        icon = "fas fa-gas-pump",
        action = function(entity)
            local fuel = GetVehicleFuelLevel(entity)
            exports['gypsy-notifications']:Notify('Топливо: ' .. math.floor(fuel) .. '%', 'info')
        end
    },
    {
        label = "Открыть багажник",
        icon = "fas fa-box-open",
        event = "inventory:openTrunk"
    }
})
```

---

#### AddGlobalPed

Добавляет взаимодействие для всех педов.

**Client-side:**
```lua
exports['gypsy-interact']:AddGlobalPed(options)
```

**Пример:**
```lua
exports['gypsy-interact']:AddGlobalPed({
    {
        label = "Поздороваться",
        icon = "fas fa-hand-wave",
        action = function(entity)
            print('Hello!')
        end
    }
})
```

---

### Option Structure

```lua
{
    label = "Текст опции",           -- Обязательно
    icon = "fas fa-icon-name",       -- Обязательно (Font Awesome)
    
    -- Один из трех вариантов действия:
    action = function(entity) end,   -- Локальная функция
    event = "eventName",              -- Client event
    serverEvent = "eventName"         -- Server event
}
```

---

## gypsy-inventory

Система инвентаря.

### Exports

#### AddItem

Добавляет предмет в инвентарь.

**Server-side:**
```lua
exports['gypsy-inventory']:AddItem(source, item, amount, metadata)
```

**Параметры:**
- `source` (number) — ID игрока
- `item` (string) — название предмета
- `amount` (number) — количество
- `metadata` (table, optional) — дополнительные данные

---

#### RemoveItem

Убирает предмет из инвентаря.

**Server-side:**
```lua
local success = exports['gypsy-inventory']:RemoveItem(source, item, amount)
```

---

#### GetItemCount

Получает количество предмета.

**Server-side:**
```lua
local count = exports['gypsy-inventory']:GetItemCount(source, item)
```

---

## Общие события

### Server Events

**gypsy-core:server:playerLoaded**
```lua
-- Вызывается после полной загрузки игрока
AddEventHandler('gypsy-core:server:playerLoaded', function(source, playerData)
    print('Player loaded: ' .. playerData.citizenid)
end)
```

**gypsy-core:server:playerDropped**
```lua
-- Вызывается при отключении игрока
AddEventHandler('gypsy-core:server:playerDropped', function(source)
    print('Player dropped: ' .. source)
end)
```

---

### Client Events

**gypsy-core:client:playerLoaded**
```lua
-- Вызывается после загрузки данных игрока на клиенте
AddEventHandler('gypsy-core:client:playerLoaded', function(playerData)
    print('My citizenid: ' .. playerData.citizenid)
end)
```

**gypsy:client:coreReady**
```lua
-- Вызывается когда ядро готово к работе
AddEventHandler('gypsy:client:coreReady', function()
    print('Core is ready!')
end)
```

---

## Примеры использования

### Создание собственного модуля с сервисом

```lua
-- server/main.lua
local MyService = {
    ProcessPayment = function(source, amount)
        local Player = Gypsy.Functions.GetPlayer(source)
        if not Player then return false end
        
        if Player.Functions.RemoveMoney('cash', amount, 'my-service') then
            -- Оплата успешна
            return true
        end
        return false
    end
}

-- Регистрируем сервис
exports['gypsy-core']:RegisterService('MyService', MyService)

-- Подписываемся на события
exports['gypsy-core']:On('player:spawn', function(playerData)
    print('Player spawned in my module!')
end)
```

---

### Использование сервисов других модулей

```lua
-- Получаем сервис гаража
local GarageService = exports['gypsy-core']:GetService('Garage')

if GarageService then
    -- Отправляем машину на штрафплощадку
    GarageService.ImpoundVehicle('ABC123', 1000)
end
```

---

### Отправка уведомлений

```lua
-- Client-side
exports['gypsy-notifications']:Notify('Операция выполнена', 'success')

-- Server-side
TriggerClientEvent('gypsy-notifications:client:notify', source, {
    message = 'Недостаточно прав',
    type = 'error'
})
```

---

## Best Practices

### 1. Всегда проверяйте наличие сервиса

```lua
local Service = exports['gypsy-core']:GetService('ServiceName')
if not Service then
    print('Service not available')
    return
end
```

### 2. Используйте Event Bus для слабосвязанной коммуникации

```lua
-- Вместо прямого вызова функций других модулей
exports['gypsy-core']:Emit('myModule:actionCompleted', data)

-- Другой модуль подписывается
exports['gypsy-core']:On('myModule:actionCompleted', function(data)
    -- Обработка
end)
```

### 3. Указывайте причину при работе с деньгами

```lua
Player.Functions.RemoveMoney('cash', 500, 'shop-purchase')
Player.Functions.AddMoney('bank', 1000, 'job-salary')
```

### 4. Используйте локальные конфиги

```lua
-- Избегайте глобального Config
local MyModuleConfig = {
    setting1 = true,
    setting2 = 100
}
```

---

## Troubleshooting

### Сервис не найден

**Проблема:** `GetService` возвращает `nil`

**Решение:**
1. Проверьте порядок загрузки в `server.cfg`
2. Убедитесь, что модуль регистрирует сервис
3. Проверьте имя сервиса (регистрозависимо)

---

### Конфликт глобальных переменных

**Проблема:** `Config` перезаписывается другими модулями

**Решение:** Используйте локальные переменные
```lua
local MyConfig = {}  -- Вместо Config = {}
```

---

## Дополнительные ресурсы

- [Modules Guide](MODULES.md) — описание модулей
- [Development Guide](DEVELOPMENT.md) — создание модулей
- [GitHub Issues](https://github.com/yourusername/gypsy-framework/issues)
