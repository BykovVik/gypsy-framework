fx_version 'cerulean'
game 'gta5'

author 'Antigravity'
description 'Gypsy Framework Core'
version '1.0.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    'server/modules/service_locator.lua',
    'server/modules/event_bus.lua',
    'server/services/notification_service.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/vehicle.lua'
}

exports {
    'GetCoreObject',
    'GetPlayer',
    'GetPlayerData',
    'CreateCallback',
    -- ServiceLocator
    'RegisterService',
    'GetService',
    'HasService',
    'UnregisterService',
    'GetAllServices',
    -- EventBus
    'On',
    'Once',
    'Off',
    'Emit',
    'GetEventListenerCount'
}
