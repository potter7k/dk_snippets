fx_version 'adamant'
game 'gta5'

author 'potter7k'
description 'Scripts desenvolvidos por DK Development. Discord: https://discord.gg/NJjUn8Ad3P'

version '1.2.0'

ui_page 'web/index.html'

shared_scripts {
    'src/shared/utils.lua',
    'src/shared/callbacks.lua',
    'src/shared/cooldowns.lua'
}

server_scripts {
    'src/server/*',
    'src/server/framework/**/*'
}

client_scripts {
    'src/client/*'
}

files {
    'web/*',
    'web/**/*',
    'web/**/**/*'
}

