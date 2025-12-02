fx_version 'cerulean'
game 'gta5'

description 'Gypsy Framework - Pizza Delivery Job'
version '1.0.0'

shared_scripts {
    'config.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/pizza.svg'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'gypsy-core',
    'gypsy-notifications'
}
