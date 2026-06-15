-- callback.lua — API enxuta sobre modules/shared/callbacks.lua.
-- Camada de ergonomia: zero lógica de rede própria, só repassa para a API base
-- (que detém o wire protocol e o compat com os scripts encriptados). A API antiga
-- (callbacks.RegisterServerCallback / TriggerServerCallback / ...) segue intacta.
--
-- Uso — tudo via `snippets.callback`:
--   CLIENT
--     local items = snippets.callback('shop:getItems', a, b)       -- bloqueia, retorna direto
--     snippets.callback.async('shop:getItems', function(items) end, a, b)
--     local h = snippets.callback.on('shop:near', function(...) return ... end)
--     snippets.callback.off(h)
--   SERVER
--     local ok = snippets.callback(source, 'shop:confirm', a, b)    -- bloqueia, retorna direto
--     snippets.callback.async(source, 'shop:confirm', function(ok) end, a, b)
--     local h = snippets.callback.on('shop:canPay', function(src, ...) return ... end)
--     snippets.callback.off(h)
--
-- Args vão soltos (varargs) — sem a tabela `{ }` da API antiga. Múltiplos retornos
-- chegam direto (sem table.unpack).

local IS_SERVER = IsDuplicityVersion()
local base = require '@dk_snippets/modules/shared/callbacks'

-- A superfície é a mesma palavra `snippets.callback` nos dois lados; o que muda é a
-- presença do `source` (server aciona um client específico). Os overloads abaixo
-- cobrem ambos — o LuaLS exibe os dois e o lado errado simplesmente não é usado.
---@class dk.callback
---@field on fun(name: string, fn: function): table        # registra um callback; retorna handle p/ off
---@field off fun(handle: table)                            # remove um callback registrado
---@field async fun(...)                                    # versão assíncrona (resultado via fn) — ver overloads abaixo
---@overload fun(name: string, ...): ...                    # CLIENT: chama o server, bloqueia e retorna
---@overload fun(source: number|string, name: string, ...): ...  # SERVER: chama o client de source, bloqueia e retorna

-- O agregador (snippets.lua) cacheia o módulo, então `callback` é singleton: a tabela
-- abaixo é o próprio callable. Chamá-la dispara; os métodos (.on/.async/.off) ficam nela.
local callback = {}

if IS_SERVER then
    --- Registra um callback que clients (ou o próprio server) acionam.
    ---@param name string
    ---@param fn fun(source: number, ...): ...
    ---@return table handle  para callback.off
    function callback.on(name, fn)
        return base.RegisterServerCallback(name, fn)
    end

    --- Remove um callback registrado por callback.on.
    ---@param handle table
    function callback.off(handle)
        base.UnregisterServerCallback(handle)
    end

    --- Aciona um callback no client de `source`, sem bloquear: `fn` recebe o resultado.
    ---@param source number|string
    ---@param name string
    ---@param fn fun(...)
    ---@param ... any  argumentos do callback
    function callback.async(source, name, fn, ...)
        base.TriggerClientCallback(source, name, { ... }, fn)
    end

    --- (interno) Aciona o callback no client e bloqueia até o retorno.
    ---@param source number|string
    ---@param name string
    ---@param ... any
    ---@return any ...
    local function call(_, source, name, ...)
        return base.TriggerClientCallback(source, name, { ... })
    end
    setmetatable(callback, { __call = call })
else
    --- Registra um callback que o server (ou o próprio client) aciona.
    ---@param name string
    ---@param fn fun(...): ...
    ---@return table handle  para callback.off
    function callback.on(name, fn)
        return base.RegisterClientCallback(name, fn)
    end

    --- Remove um callback registrado por callback.on.
    ---@param handle table
    function callback.off(handle)
        base.UnregisterClientCallback(handle)
    end

    --- Aciona um callback no server sem bloquear: `fn` recebe o resultado.
    ---@param name string
    ---@param fn fun(...)
    ---@param ... any  argumentos do callback
    function callback.async(name, fn, ...)
        base.TriggerServerCallback(name, { ... }, fn)
    end

    --- (interno) Aciona o callback no server e bloqueia até o retorno.
    ---@param name string
    ---@param ... any
    ---@return any ...
    local function call(_, name, ...)
        return base.TriggerServerCallback(name, { ... })
    end
    setmetatable(callback, { __call = call })
end

return callback
