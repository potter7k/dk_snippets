-- Exports legados — compat com os scripts encriptados antigos (dk_races,
-- dk_animations_ext, dk_trunkin, dk_lapdance), que chamam
-- exports['dk_snippets']:request()/:framework()/:DB() (modelo 2.x).
-- Deletável quando os consumidores forem migrados para a API v3.
-- Spec: docs/superpowers/specs/2026-06-10-dk-snippets-compat-encriptados-design.md
---@type dk.snippets
local snippets = require '@dk_snippets/snippets'

-- request(source, description, timer?, acceptText?, denyText?) → boolean
exports('request', function(...)
    return snippets.request(...)
end)

-- framework() → tupla antiga (name: string, FWData)
exports('framework', function()
    local fw = snippets.framework
    return fw.getFramework(), fw
end)

-- DB() → objeto SQL inicializado
exports('DB', function()
    return snippets.db()
end)
