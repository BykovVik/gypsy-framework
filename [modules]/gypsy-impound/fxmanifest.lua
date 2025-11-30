fx_version 'cerulean'
game 'gta5'

author 'Gypsy Framework'
description 'Gypsy Impound System'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'gypsy-core',
    'gypsy-garage',
    'gypsy-notifications'
}
