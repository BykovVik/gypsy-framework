fx_version 'cerulean'
game 'gta5'

author 'Gypsy Framework'
description 'Position Tracking Service'
version '1.0.0'

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
