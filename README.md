# Gypsy Framework

Модульный, легкий и оптимизированный фреймворк для FiveM.

## Установка

1.  **Требования:**
    *   FiveM Server (последняя версия)
    *   `oxmysql` (для работы с базой данных)

2.  **Установка ресурсов:**
    *   Поместите папку `[gypsy-framework]` в директорию `resources`.
    *   Добавьте в `server.cfg`:
        ```ini
        ensure oxmysql
        ensure gypsy-core
        ensure gypsy-spawn
        ```

3.  **База данных:**
    *   Создайте базу данных (например, `qbcore` или `gypsy`).
    *   Импортируйте файл `gypsy-core/gypsy.sql`.
    *   Настройте подключение в `server.cfg`:
        ```ini
        set mysql_connection_string "mysql://user:password@localhost/database?charset=utf8mb4"
        ```

## API Разработчика (Core)

Для получения объекта ядра в ваших скриптах используйте экспорт:

```lua
local Gypsy = exports['gypsy-core']:GetCoreObject()
```

### Серверные Функции

#### `Gypsy.Functions.GetPlayer(source)`
Возвращает объект игрока по ID источника.

```lua
local Player = Gypsy.Functions.GetPlayer(source)
if Player then
    print(Player.PlayerData.money.cash)
end
```

#### `Gypsy.Functions.ExecuteSql(query, params, callback)`
Выполняет SQL запрос (обертка над oxmysql).

### Клиентские События

#### `gypsy-core:client:playerLoaded`
Вызывается, когда персонаж полностью загружен и заспавнен.

```lua
RegisterNetEvent('gypsy-core:client:playerLoaded', function(PlayerData)
    print("Игрок загружен!", PlayerData.citizenid)
end)
```

### Серверные События

#### `gypsy-core:server:playerLoaded`
Вызывается на сервере после успешной загрузки игрока.

```lua
RegisterNetEvent('gypsy-core:server:playerLoaded', function(source, PlayerData)
    print("Игрок зашел:", source)
end)
```

## Модули

Фреймворк построен на модульной системе. Каждый модуль (например, `gypsy-spawn`) является отдельным ресурсом и может быть отключен или заменен.
