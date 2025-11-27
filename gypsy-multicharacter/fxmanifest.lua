fx_version 'cerulean'
game 'gta5'

author 'Gypsy Framework'
description 'Multi-Character System'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/callbacks.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/character_manager.lua',
    'server/spawn_manager.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/background.jpg'
}
