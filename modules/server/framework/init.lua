assert(IsDuplicityVersion(), 'dk_snippets: módulo "framework" é server-only')

local newHandler = require '@dk_snippets/modules/server/framework/handler'
local notify = require '@dk_snippets/modules/shared/notify'
local request = require '@dk_snippets/modules/shared/request'
local customLoader = require '@dk_snippets/modules/server/framework/custom'

-- Seção `player` do custom do framework detectado (preenchida em resolve()).
---@type table<string, function> | nil
local customPlayer = nil

-- resource ativo → (chave do registro, caminho do módulo register)
local supported = {
    { resource = 'es_extended', key = 'esx',    path = 'modules/server/framework/esx' },
    { resource = 'qb-core',     key = 'qbcore', path = 'modules/server/framework/qbcore' },
    { resource = 'vrp',         key = 'vrp',    path = 'modules/server/framework/vrp/init' },
}

--- Injeta açúcar (notify/hint/request) num Player online, fechando sobre a source.
---@param player table
---@return table
local function decorate(player)
    if type(player) ~= "table" or player.online ~= true or type(player.userSource) ~= "function" then
        return player
    end
    local src = player.userSource()
    player.notify = function(mode, message, duration)
        return notify.send(src, mode, message, duration)
    end
    player.hint = function(action, id, description, control, configs)
        return notify.hint(src, action, id, description, control, configs)
    end
    player.request = function(description, timer, acceptText, denyText)
        return request(src, description, timer, acceptText, denyText)
    end

    if customPlayer then
        player.__original = player.__original or {}
        for name, fn in pairs(customPlayer) do
            player.__original[name] = player[name] -- original (nil se for método novo)
            player[name] = function(...) return fn(player, ...) end
        end
    end

    return player
end

--- Envolve getPlayer/getPlayerById/getPlayersByPermission para decorar os Players.
---@param funcs FWData
---@return FWData
local function wrap(funcs)
    local getPlayer = funcs.getPlayer
    local getPlayerById = funcs.getPlayerById
    local getPlayersByPermission = funcs.getPlayersByPermission

    if getPlayer then
        funcs.getPlayer = function(source)
            local p = getPlayer(source)
            if p == nil then return nil end
            return decorate(p)
        end
    end
    if getPlayerById then
        funcs.getPlayerById = function(user_id)
            return decorate(getPlayerById(user_id))
        end
    end
    if getPlayersByPermission then
        funcs.getPlayersByPermission = function(perm)
            local list = getPlayersByPermission(perm) or {}
            for i = 1, #list do list[i] = decorate(list[i]) end
            return list
        end
    end
    return funcs
end

--- Carrega o custom do framework `fwKey`, aplica `functions` em `funcs` (antes do wrap)
--- e define o upvalue `customPlayer` para o decorate usar.
---@param funcs FWData
---@param fwKey string
local function aplicarCustom(funcs, fwKey)
    local custom = customLoader.load(fwKey)
    if not custom then
        customPlayer = nil
        return
    end
    if custom.functions then
        customLoader.applyFunctions(funcs, custom.functions)
    end
    customPlayer = custom.player
end

--- Detecta o framework ativo, carrega só o módulo correspondente e retorna o FWData decorado.
---@return FWData
local function resolve()
    local FW = newHandler()

    for _, entry in ipairs(supported) do
        if GetResourceState(entry.resource) ~= 'missing' then
            local register = require('@dk_snippets/' .. entry.path)
            register(FW)
            local name, funcs = FW:get(entry.key)
            if type(name) == "string" and type(funcs) == "table" then
                print("[INFO] Framework detectado: " .. name)
                aplicarCustom(funcs, name)
                return wrap(funcs)
            end
            print("[WARN] Framework " .. entry.resource .. " detectado, mas não está online.")
        end
    end

    local register = require('@dk_snippets/modules/server/framework/nofw')
    register(FW)
    local _, funcs = FW:get("_nofw")
    print("[INFO] Framework detectado: _nofw")
    aplicarCustom(funcs, "_nofw")
    return wrap(funcs)
end

return resolve()
