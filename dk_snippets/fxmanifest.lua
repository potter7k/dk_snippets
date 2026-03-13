fx_version 'adamant'
game 'gta5'

author 'potter7k'
description 'Scripts desenvolvidos por DK Development. Discord: https://discord.gg/NJjUn8Ad3P'

lua54 'yes'

version '2.3.0'

ui_page 'web/index.html'

shared_scripts {
    'src/shared/utils.lua',
    'src/shared/require.lua',
    'src/shared/callbacks.lua',
    'src/shared/cooldowns.lua'
}

server_scripts {
    'src/server/*',
    -- 'test/test-ui-sv.lua', -- Testar interfaces, descomente para usar
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
