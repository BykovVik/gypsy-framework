fx_version 'cerulean'
game 'gta5'

description 'Gypsy Framework - Interaction System (Target)'
version '1.0.0'

ui_page 'html/index.html'

client_scripts {
    'client/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

exports {
    'AddTargetModel',
    'AddTargetEntity',
    'AddGlobalVehicle',
    'AddGlobalPed'
}
