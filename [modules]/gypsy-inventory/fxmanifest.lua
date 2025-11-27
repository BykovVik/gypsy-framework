fx_version 'cerulean'
game 'gta5'

author 'Antigravity'
description 'Gypsy Framework Inventory'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/js/Api.js',
    'html/js/QuantityDialog.js',
    'html/js/ContextMenu.js',
    'html/js/DragDrop.js',
    'html/js/Inventory.js',
    'html/js/app.js',
    'html/icon/water.png',
    'html/icon/bread.png',
    'html/icon/burger.png',
    'html/icon/bandage.png'
}

exports {
    'AddItem',
    'CreateUseableItem'
}
