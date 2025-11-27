fx_version 'cerulean'
game 'gta5'

author 'Gypsy Studio Game'
description 'Gypsy Framework Banking System'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/account_manager.lua',
    'server/savings.lua',
    'server/transactions.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/bank.html',
    'html/bank_style.css',
    'html/bank_script.js'
}
