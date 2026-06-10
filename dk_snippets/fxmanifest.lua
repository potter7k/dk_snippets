fx_version 'adamant'
game 'gta5'

author 'potter7k'
description 'Scripts desenvolvidos por DK Development. Discord: https://discord.gg/NJjUn8Ad3P'

lua54 'yes'
version '3.0.0'

ui_page 'web/index.html'

shared_script 'init.lua'

client_scripts {
    'runtime/client/*'
}

server_scripts {
    -- 'test/*.lua', -- Testes; descomente para rodar
    'runtime/server/*'
}

files {
    'init.lua',
    'snippets.lua',
    'lib/*.lua',
    'compat/*.lua',
    'modules/**/*.lua',
    'web/*',
    'web/**/*',
    'web/**/**/*'
}
