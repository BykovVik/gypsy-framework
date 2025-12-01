fx_version 'cerulean'
game 'gta5'

description 'Gypsy Framework - Cable TV Technician Job'
version '1.0.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'gypsy-core',
    'gypsy-notifications',
    'gypsy-minigames'
}
