Config = {}

-- Позиция уведомлений на экране
Config.Position = 'top-right' -- 'top-right', 'top-left', 'bottom-right', 'bottom-left', 'top-center'

-- Длительность по умолчанию (миллисекунды)
Config.DefaultDuration = 3000

-- Максимальное количество одновременных уведомлений
Config.MaxNotifications = 5

-- Включить звуки
Config.EnableSounds = false

-- Цвета для каждого типа уведомлений
Config.Colors = {
    success = {
        primary = '#00ff88',
        secondary = '#00cc66',
        glow = 'rgba(0, 255, 136, 0.6)'
    },
    error = {
        primary = '#ff3333',
        secondary = '#cc0000',
        glow = 'rgba(255, 51, 51, 0.6)'
    },
    warning = {
        primary = '#ffb000',
        secondary = '#ff8800',
        glow = 'rgba(255, 176, 0, 0.6)'
    },
    info = {
        primary = '#75bfcc',
        secondary = '#5a9faa',
        glow = 'rgba(117, 191, 204, 0.6)'
    }
}

-- Иконки для типов (терминальный стиль)
Config.Icons = {
    success = '[OK]',
    error = '[ERR]',
    warning = '[!]',
    info = '[i]'
}
