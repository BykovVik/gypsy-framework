fx_version 'cerulean'
game 'gta5'

description 'Gypsy Framework - Garage System'
version '1.0.0'


shared_scripts {
    'config.lua'
}

client_scripts {
    'config.lua',
    'client/main.lua'
}

server_scripts {
    'config.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}


