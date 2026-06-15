-- snippets.lua — agregador central. Carrega módulos sob demanda e cacheia.
local map = {
    -- shared
    table     = 'modules/shared/table',
    string    = 'modules/shared/string',
    number    = 'modules/shared/number',
    class     = 'modules/shared/class',
    cooldown  = 'modules/shared/cooldown',
    callbacks = 'modules/shared/callbacks', -- API base (compat/encriptados)
    callback  = 'modules/shared/callback',  -- API enxuta (recomendada)
    notify    = 'modules/shared/notify',
    request   = 'modules/shared/request',
    -- server
    json      = 'modules/server/json',
    db        = 'modules/server/db',
    framework = 'modules/server/framework/init',
}

return setmetatable({}, {
    __index = function(self, key)
        local path = map[key]
        if not path then
            error(("dk_snippets: módulo '%s' inexistente"):format(tostring(key)), 2)
        end
        local mod = require('@dk_snippets/' .. path)
        rawset(self, key, mod)
        return mod
    end,
    __newindex = function()
        error('dk_snippets: snippets é somente leitura', 2)
    end,
})
