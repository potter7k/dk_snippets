-- callbacks.lua — callbacks request/response client<->server.
-- Retorna uma tabela; popula apenas as funções do lado atual (server ou client).
--
-- Wire protocol (NÃO alterar — partilhado com o shim encriptado
-- compat/dk_snippets_compat.lua; um peer pode usar o shim e o outro este módulo):
--   client→server : TriggerServerEvent('dk__server_callback:'..name, packedArgs, ticket?)
--   server→client : TriggerClientEvent('dk__client_callback_response:'..name..':'..src, packedRet, ticket?)
--   server→client : TriggerClientEvent('dk__client_callback:'..name, packedArgs, ticket)
--   client→server : TriggerServerEvent('dk__callback_retval:'..srvId..':'..name..':'..ticket, packedRet)
-- O `ticket` em client→server foi adicionado de forma retrocompatível: peers antigos
-- ignoram o arg extra e o lado receptor faz fallback quando ele vem ausente.

-- `prom.state` é campo interno do promise do Citizen (não tipado pelo LSP); a leitura
-- é intencional para detectar expiração/timeout.
---@diagnostic disable: undefined-field

local IS_SERVER = IsDuplicityVersion()

local unpack          = table.unpack
local getinfo         = debug.getinfo
local pack            = msgpack.pack
local unpackMsg       = msgpack.unpack
local gameTimer       = GetGameTimer

-- promise states (Citizen)
local PENDING, REJECTING, REJECTED = 0, 2, 4

---@class dk.callbacks
local M = {}

--- Valida o tipo de um argumento; usa o nome da função chamadora na mensagem.
---@param obj any
---@param expected string
---@param alt? string tipo alternativo aceito (ex.: 'nil')
local function ensure(obj, expected, alt)
    local got = type(obj)
    if expected == 'function' then
        -- function reference do CitizenFX viaja como table com __cfx_functionReference
        if got == 'table' and not rawget(obj, '__cfx_functionReference') then
            error(('%s: esperado function'):format(getinfo(2).name or '?'), 3)
        end
        return
    end
    if got ~= expected and got ~= alt then
        error(('%s: esperado %s%s, recebido %s'):format(
            getinfo(2).name or '?', expected, alt and (' ou ' .. alt) or '', got), 3)
    end
end

--- Agenda o disparo de `timedout` quando o `prom` expira após `timeout` segundos.
--- Rejeita o promise pendente e executa `onExpire` (cleanup) uma vez.
---@param prom table
---@param timeout? number segundos
---@param timedout? fun(state: number)
---@param onExpire? fun()
local function scheduleTimeout(prom, timeout, timedout, onExpire)
    if not (timeout and timedout) then return end
    SetTimeout(timeout * 1000, function()
        local state = prom.state
        if state == PENDING or state == REJECTING or state == REJECTED then
            timedout(state)
            if state == PENDING then prom:reject() end
            if onExpire then onExpire() end
        end
    end)
end

--- Espera o promise e devolve o resultado; se houver eventCallback, o fluxo é
--- assíncrono e não bloqueia (o eventCallback recebe o resultado).
---@param prom table
---@param eventCallback? fun(...)
---@param cleanup? fun()
---@return any ...
local function awaitResult(prom, eventCallback, cleanup)
    if eventCallback then return end ---@diagnostic disable-line: missing-return
    local result = { Citizen.Await(prom) }
    if cleanup then cleanup() end
    return unpack(result)
end

if IS_SERVER then
    --- (server) Registra um callback que clients (ou o próprio server) acionam.
    ---@param eventName string
    ---@param fn fun(source: number, ...): ...
    ---@return table handle  para UnregisterServerCallback
    function M.RegisterServerCallback(eventName, fn)
        ensure(eventName, 'string'); ensure(fn, 'function')

        return RegisterNetEvent('dk__server_callback:' .. eventName, function(packed, src, cb)
            -- `source` (global do CitizenFX) > 0 quando vem da rede; nil/0 quando é
            -- uma chamada server→server local, que passa `src` e `cb` explícitos.
            local netSource = source
            -- args foi empacotado no produtor com pack(argsTable) — uma tabela. unpackMsg
            -- devolve essa tabela diretamente; NÃO envolver em { } (isso adicionava um
            -- nível extra, fazendo fn receber {arg} em vez de arg). unpack espalha os args.
            local args = unpackMsg(packed) or {}

            if cb then
                -- chamada local: devolve o retorno pelo callback recebido.
                -- Empacota a LISTA de retornos com pack({...}), não pack_args: no msgpack
                -- do FiveM, pack_args + unpack são assimétricos e introduziam um nível
                -- extra de aninhamento no retorno (quebrava quem fazia table.unpack do
                -- resultado). pack({...}) ↔ unpack→table_unpack é simétrico.
                cb(pack({ fn(src, unpack(args)) }))
            else
                -- chamada de rede: `src` aqui é o ticket (string) ou nil
                local ret = pack({ fn(netSource, unpack(args)) })
                TriggerClientEvent(
                    ('dk__client_callback_response:%s:%s'):format(eventName, netSource),
                    netSource, ret, src) -- ecoa o ticket para o client filtrar
            end
        end)
    end

    --- (server) Remove um callback registrado.
    ---@param handle table
    function M.UnregisterServerCallback(handle)
        RemoveEventHandler(handle)
    end

    --- (server) Aciona um callback registrado num client.
    --- Sem eventCallback bloqueia e retorna o resultado; com ele, é assíncrono.
    ---@param source number|string
    ---@param eventName string
    ---@param args? table
    ---@param eventCallback? fun(...)
    ---@param timeout? number segundos
    ---@param timedout? fun(state: number)
    ---@return any ...
    function M.TriggerClientCallback(source, eventName, args, eventCallback, timeout, timedout)
        ensure(source, 'string', 'number'); ensure(eventName, 'string')
        ensure(args, 'table', 'nil'); ensure(timeout, 'number', 'nil')
        ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')

        if tonumber(source) < 0 then error('source deve ser >= 0', 2) end

        -- ticket único por chamada → isola respostas concorrentes ao mesmo eventName
        local ticket = ('%s:%d'):format(source, gameTimer())
        local prom = promise.new()

        local handle = RegisterNetEvent(
            ('dk__callback_retval:%s:%s:%s'):format(source, eventName, ticket),
            function(packed)
                if prom.state ~= PENDING then return end
                local ret = unpackMsg(packed) or {} -- lista de retornos (pack({...}))
                if eventCallback then eventCallback(unpack(ret)) end
                prom:resolve(unpack(ret))
            end)

        local removed = false
        local function cleanup()
            if not removed then removed = true; RemoveEventHandler(handle) end
        end

        TriggerClientEvent('dk__client_callback:' .. eventName, source, pack(args or {}), ticket)

        scheduleTimeout(prom, timeout, timedout, cleanup)
        return awaitResult(prom, eventCallback, cleanup)
    end

    --- (server) Aciona um callback do próprio server (uso interno/local).
    ---@param source number|string
    ---@param eventName string
    ---@param args? table
    ---@param eventCallback? fun(...)
    ---@param timeout? number segundos
    ---@param timedout? fun(state: number)
    ---@return any ...
    function M.TriggerServerCallback(source, eventName, args, eventCallback, timeout, timedout)
        ensure(source, 'string', 'number'); ensure(eventName, 'string')
        ensure(args, 'table', 'nil'); ensure(timeout, 'number', 'nil')
        ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')

        local prom = promise.new()

        TriggerEvent('dk__server_callback:' .. eventName, pack(args or {}), source, function(packed)
            if prom.state ~= PENDING then return end
            local ret = unpackMsg(packed) or {} -- lista de retornos (pack({...}))
            if eventCallback then eventCallback(unpack(ret)) end
            prom:resolve(unpack(ret))
        end)

        scheduleTimeout(prom, timeout, timedout)
        return awaitResult(prom, eventCallback)
    end
else
    -- O server id NÃO pode ser cacheado no load do módulo: como o require corre na
    -- inicialização do recurso (antes do spawn), GetPlayerServerId devolve -1/0 nesse
    -- instante. O nome do net event de resposta embute esse id; fixá-lo cedo faz o
    -- handler nascer surdo (server responde para o id real e os nomes não casam),
    -- bloqueando o callback. Resolvemos lazy: só memoiza quando o id já é válido (> 0).
    local cachedServerId = nil
    local function getServerId()
        if cachedServerId then return cachedServerId end
        local id = GetPlayerServerId(PlayerId())
        if id and id > 0 then cachedServerId = id end
        return id
    end

    --- (client) Registra um callback que o server (ou o próprio client) aciona.
    ---@param eventName string
    ---@param fn fun(...): ...
    ---@return table handle  para UnregisterClientCallback
    function M.RegisterClientCallback(eventName, fn)
        ensure(eventName, 'string'); ensure(fn, 'function')

        return RegisterNetEvent('dk__client_callback:' .. eventName, function(packed, ticket)
            -- args: unpackMsg devolve a tabela de args; unpack espalha. ret: pack({...})
            -- (lista de retornos). Ver nota em RegisterServerCallback sobre a assimetria.
            local ret = pack({ fn(unpack(unpackMsg(packed) or {})) })
            if type(ticket) == 'function' then
                -- chamada local: devolve pelo callback recebido
                ticket(ret)
            else
                TriggerServerEvent(
                    ('dk__callback_retval:%s:%s:%s'):format(getServerId(), eventName, ticket), ret)
            end
        end)
    end

    --- (client) Remove um callback registrado.
    ---@param handle table
    function M.UnregisterClientCallback(handle)
        RemoveEventHandler(handle)
    end

    -- Um único handler persistente por eventName roteia as respostas do server por
    -- ticket. Evita registrar/remover um net event a cada chamada (o ponto fraco da
    -- versão antiga, que colidia entre chamadas concorrentes do mesmo callback).
    -- Cada ticket guarda { prom, cb } — sem injetar campos no promise.
    ---@class dk.cbPending
    ---@field handle table
    ---@field tickets table<string, { prom: table, cb?: fun(...) }>
    local pendingByEvent = {} ---@type table<string, dk.cbPending>

    local function ensureResponseHandler(eventName)
        local entry = pendingByEvent[eventName]
        if entry then return entry end

        -- O nome do net event embute o server id; se ele ainda não é válido, o handler
        -- nasce surdo. Por isso só memoizamos com id válido — caso contrário recriamos
        -- na próxima chamada (quando o id já estiver disponível, após o spawn).
        local serverId = getServerId()
        entry = { tickets = {} } ---@diagnostic disable-line: missing-fields
        entry.handle = RegisterNetEvent(
            ('dk__client_callback_response:%s:%s'):format(eventName, serverId),
            function(packed, ticket)
                local tickets = entry.tickets
                -- Roteia por ticket; se o peer (shim antigo) respondeu sem ticket,
                -- resolve a primeira pendente — fallback seguro.
                local slot = ticket and tickets[ticket]
                if not slot then
                    ticket, slot = next(tickets) ---@diagnostic disable-line: cast-local-type
                end
                if not slot then return end
                tickets[ticket] = nil

                local ret = unpackMsg(packed) or {} -- lista de retornos (pack({...}))
                if slot.cb then slot.cb(unpack(ret)) end
                slot.prom:resolve(unpack(ret))
            end)
        if serverId and serverId > 0 then
            pendingByEvent[eventName] = entry
        end
        return entry
    end

    --- (client) Aciona um callback registrado no server.
    --- Sem eventCallback bloqueia e retorna o resultado; com ele, é assíncrono.
    ---@param eventName string
    ---@param args? table
    ---@param eventCallback? fun(...)
    ---@param timeout? number segundos
    ---@param timedout? fun(state: number)
    ---@return any ...
    function M.TriggerServerCallback(eventName, args, eventCallback, timeout, timedout)
        ensure(eventName, 'string'); ensure(args, 'table', 'nil')
        ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil')
        ensure(eventCallback, 'function', 'nil')

        local entry = ensureResponseHandler(eventName)
        local ticket = ('%d:%d'):format(getServerId(), gameTimer())

        local prom = promise.new()
        entry.tickets[ticket] = { prom = prom, cb = eventCallback }

        local function cleanup() entry.tickets[ticket] = nil end

        TriggerServerEvent('dk__server_callback:' .. eventName, pack(args or {}), ticket)

        scheduleTimeout(prom, timeout, timedout, cleanup)
        return awaitResult(prom, eventCallback, cleanup)
    end

    --- (client) Aciona um callback do próprio client (uso interno/local).
    ---@param eventName string
    ---@param args? table
    ---@param eventCallback? fun(...)
    ---@param timeout? number segundos
    ---@param timedout? fun(state: number)
    ---@return any ...
    function M.TriggerClientCallback(eventName, args, eventCallback, timeout, timedout)
        ensure(eventName, 'string'); ensure(args, 'table', 'nil')
        ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil')
        ensure(eventCallback, 'function', 'nil')

        local prom = promise.new()

        TriggerEvent('dk__client_callback:' .. eventName, pack(args or {}), function(packed)
            if prom.state ~= PENDING then return end
            local ret = unpackMsg(packed) or {} -- lista de retornos (pack({...}))
            if eventCallback then eventCallback(unpack(ret)) end
            prom:resolve(unpack(ret))
        end)

        scheduleTimeout(prom, timeout, timedout)
        return awaitResult(prom, eventCallback)
    end
end

return M
