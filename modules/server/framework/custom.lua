assert(IsDuplicityVersion(), 'dk_snippets: módulo "framework/custom" é server-only')

local RESOURCE = 'dk_snippets'
local CUSTOM_DIR = 'modules/server/framework/custom'

-- Mapeia a chave do framework detectado para o nome base do arquivo custom.
-- vRP e suas variantes (vrp.crv3, vrp.crv5, ...) usam o mesmo custom/vrp.lua.
---@param fwKey string  -- "esx" | "qbcore" | "vrp" | "vrp.crv3" | "_nofw"
---@return string fileBaseName  -- "esx" | "qbcore" | "vrp" | "nofw"
local function fileFor(fwKey)
    if fwKey == '_nofw' then return 'nofw' end
    -- normaliza qualquer "vrp.<variante>" para "vrp"
    local base = fwKey:match('^([^%.]+)') or fwKey
    return base
end

--- Carrega o custom do framework (se o arquivo existir) e retorna { functions, player }.
--- Retorna nil quando não há custom (caso normal — custom é opcional).
---@param fwKey string
---@return { functions?: table<string, function>, player?: table<string, function> } | nil
local function load(fwKey)
    local file = fileFor(fwKey)
    local path = ('%s/%s.lua'):format(CUSTOM_DIR, file)

    -- Existência: LoadResourceFile retorna nil se o arquivo não existe.
    -- (No server, lê qualquer arquivo do recurso, independente de files{}.)
    if not LoadResourceFile(RESOURCE, path) then
        return nil
    end

    local mod = require(('@%s/%s/%s'):format(RESOURCE, CUSTOM_DIR, file))
    if type(mod) ~= 'table' then
        print(('^3[dk_snippets]^7 custom/%s.lua deve retornar uma tabela { functions?, player? }.'):format(file))
        return nil
    end

    return {
        functions = type(mod.functions) == 'table' and mod.functions or nil,
        player = type(mod.player) == 'table' and mod.player or nil,
    }
end

--- Aplica a seção `functions` sobre o FWData: substitui ou adiciona em funcs.
--- Cada função custom recebe (fw, ...) — `fw` é o próprio FWData.
---@param funcs FWData
---@param functions table<string, function>
local function applyFunctions(funcs, functions)
    for name, fn in pairs(functions) do
        funcs[name] = function(...)
            return fn(funcs, ...)
        end
    end
end

return {
    load = load,
    applyFunctions = applyFunctions,
}
