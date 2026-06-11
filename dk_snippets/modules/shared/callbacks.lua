--[[
    -- CREDITS:
    https://github.com/pitermcflebor/pmc-callbacks
    MIT License — Copyright (c) 2020 PiterMcFlebor
]]
-- Porta sem _G: retorna uma tabela; popula só as funções do lado atual.

local IS_SERVER = IsDuplicityVersion()
local table_unpack = table.unpack
local debug = debug
local debug_getinfo = debug.getinfo
local msgpack = msgpack
local msgpack_pack = msgpack.pack
local msgpack_unpack = msgpack.unpack
local msgpack_pack_args = msgpack.pack_args
local PENDING = 0
local REJECTING = 2
local REJECTED = 4

---@class dk.callbacks
local M = {}

local function ensure(obj, typeof, opt_typeof, errMessage)
    local objtype = type(obj)
    local di = debug_getinfo(2)
    local diName = di.name or 'unknown'
    local errMessage = errMessage or (opt_typeof == nil and ((diName) .. ' expected %s, but got %s') or ((diName) .. ' expected %s or %s, but got %s'))
    if typeof ~= 'function' then
        if objtype ~= typeof and objtype ~= opt_typeof then
            error((errMessage):format(typeof, (opt_typeof == nil and objtype or opt_typeof), objtype))
        end
    else
        if objtype == 'table' and not rawget(obj, '__cfx_functionReference') then
            error((errMessage):format(typeof, (opt_typeof == nil and objtype or opt_typeof), objtype))
        end
    end
end

if IS_SERVER then
    --- (server) Registra um callback que clients chamam via TriggerServerCallback.
    ---@param eventName string
    ---@param eventCallback fun(source: number, ...): ...
    ---@return table eventData handle para UnregisterServerCallback
    function M.RegisterServerCallback(eventName, eventCallback)
        ensure(eventName, 'string'); ensure(eventCallback, 'function')

        local eventCallback = eventCallback
        local eventName = eventName
        local eventData = RegisterNetEvent('dk__server_callback:'..eventName, function(packed, src, cb)
            local source = tonumber(source)
            if not source then
                cb( msgpack_pack_args( eventCallback(src, table_unpack(msgpack_unpack(packed)) ) ) )
            else
                TriggerClientEvent(('dk__client_callback_response:%s:%s'):format(eventName, source), source, msgpack_pack_args( eventCallback(source, table_unpack(msgpack_unpack(packed)) ) ))
            end
        end)
        return eventData
    end

    --- (server) Remove um callback registrado.
    ---@param eventData table
    function M.UnregisterServerCallback(eventData)
        RemoveEventHandler(eventData)
    end

    --- (server) Chama um callback registrado num client. Sem eventCallback, aguarda e retorna o resultado.
    ---@param source number|string
    ---@param eventName string
    ---@param args table|nil
    ---@param eventCallback? fun(...)
    ---@param timeout? number segundos
    ---@param timedout? fun(state: number)
    ---@return any ...
    function M.TriggerClientCallback(source, eventName, args, eventCallback, timeout, timedout)
        ensure(source, 'string', 'number'); ensure(eventName, 'string'); ensure(args, 'table', 'nil'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')
        if tonumber(source) >= 0 then
            local ticket = tostring(source) .. 'x' .. tostring(GetGameTimer())
            local prom = promise.new()
            local eventCallback = eventCallback
            local eventHandlerRemoved = false
            local eventData = RegisterNetEvent(('dk__callback_retval:%s:%s:%s'):format(source, eventName, ticket), function(packed)
                if eventCallback and prom.state == PENDING then eventCallback( table_unpack(msgpack_unpack(packed)) ) end
                prom:resolve( table_unpack(msgpack_unpack(packed)) )
            end)

            local function safeRemoveEventHandler()
                if not eventHandlerRemoved and eventData then
                    eventHandlerRemoved = true
                    RemoveEventHandler(eventData)
                end
            end

            TriggerClientEvent(('dk__client_callback:%s'):format(eventName), source, msgpack_pack(args or {}), ticket)

            if timeout ~= nil and timedout then
                local timedout = timedout
                SetTimeout(timeout * 1000, function()
                    if
                        prom.state == PENDING or
                        prom.state == REJECTED or
                        prom.state == REJECTING
                    then
                        timedout(prom.state)
                        if prom.state == PENDING then prom:reject() end
                        safeRemoveEventHandler()
                    end
                end)
            end

            if not eventCallback then
                local result = Citizen.Await(prom)
                safeRemoveEventHandler()
                return result
            end
        else
            error 'source should be equal too or higher than 0'
        end
    end

    --- (server) Chama um callback do próprio server (uso interno/local).
    ---@param source number|string
    ---@param eventName string
    ---@param args table|nil
    ---@param eventCallback? fun(...)
    ---@param timeout? number segundos
    ---@param timedout? fun(state: number)
    ---@return any ...
    function M.TriggerServerCallback(source, eventName, args, eventCallback, timeout, timedout)
        ensure(source, 'string', 'number'); ensure(eventName, 'string'); ensure(args, 'table', 'nil'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')

        local prom = promise.new()
        local eventCallback = eventCallback
        local eventName = eventName
        TriggerEvent('dk__server_callback:'..eventName, msgpack_pack(args or {}), source,
        function(packed)
            if eventCallback and prom.state == PENDING then eventCallback( table_unpack(msgpack_unpack(packed)) ) end
            prom:resolve( table_unpack(msgpack_unpack(packed)) )
        end)

        if timeout ~= nil and timedout then
            local timedout = timedout
            SetTimeout(timeout * 1000, function()
                if
                    prom.state == PENDING or
                    prom.state == REJECTED or
                    prom.state == REJECTING
                then
                    timedout(prom.state)
                    if prom.state == PENDING then prom:reject() end
                end
            end)
        end

        if not eventCallback then
            return Citizen.Await(prom)
        end
    end
end

if not IS_SERVER then
    local SERVER_ID = GetPlayerServerId(PlayerId())

    --- (client) Registra um callback que o server chama via TriggerClientCallback.
    ---@param eventName string
    ---@param eventCallback fun(...): ...
    ---@return table eventData handle para UnregisterClientCallback
    function M.RegisterClientCallback(eventName, eventCallback)
        ensure(eventName, 'string'); ensure(eventCallback, 'function')

        local eventCallback = eventCallback
        local eventName = eventName
        local eventData = RegisterNetEvent('dk__client_callback:'..eventName, function(packed, ticket)
            if type(ticket) == 'function' then
                ticket( msgpack_pack_args( eventCallback( table_unpack(msgpack_unpack(packed)) ) ) )
            else
                TriggerServerEvent(('dk__callback_retval:%s:%s:%s'):format(SERVER_ID, eventName, ticket), msgpack_pack_args( eventCallback( table_unpack(msgpack_unpack(packed)) ) ))
            end
        end)
        return eventData
    end

    --- (client) Remove um callback registrado.
    ---@param eventData table
    function M.UnregisterClientCallback(eventData)
        RemoveEventHandler(eventData)
    end

    --- (client) Chama um callback registrado no server. Sem eventCallback, aguarda e retorna o resultado.
    ---@param eventName string
    ---@param args table|nil
    ---@param eventCallback? fun(...)
    ---@param timeout? number segundos
    ---@param timedout? fun(state: number)
    ---@return any ...
    function M.TriggerServerCallback(eventName, args, eventCallback, timeout, timedout)
        ensure(args, 'table', 'nil'); ensure(eventName, 'string'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')

        local prom = promise.new()
        local eventCallback = eventCallback
        local eventHandlerRemoved = false
        local eventData = RegisterNetEvent(('dk__client_callback_response:%s:%s'):format(eventName, SERVER_ID),
        function(packed)
            if eventCallback and prom.state == PENDING then eventCallback( table_unpack(msgpack_unpack(packed)) ) end
            prom:resolve( table_unpack(msgpack_unpack(packed)) )
        end)

        local function safeRemoveEventHandler()
            if not eventHandlerRemoved and eventData then
                eventHandlerRemoved = true
                RemoveEventHandler(eventData)
            end
        end

        TriggerServerEvent('dk__server_callback:'..eventName, msgpack_pack( args ))

        if timeout ~= nil and timedout then
            local timedout = timedout
            SetTimeout(timeout * 1000, function()
                if
                    prom.state == PENDING or
                    prom.state == REJECTED or
                    prom.state == REJECTING
                then
                    timedout(prom.state)
                    if prom.state == PENDING then prom:reject() end
                    safeRemoveEventHandler()
                end
            end)
        end

        if not eventCallback then
            local result = Citizen.Await(prom)
            safeRemoveEventHandler()
            return result
        end
    end

    --- (client) Chama um callback do próprio client (uso interno/local).
    ---@param eventName string
    ---@param args table|nil
    ---@param eventCallback? fun(...)
    ---@param timeout? number segundos
    ---@param timedout? fun(state: number)
    ---@return any ...
    function M.TriggerClientCallback(eventName, args, eventCallback, timeout, timedout)
        ensure(eventName, 'string'); ensure(args, 'table', 'nil'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')

        local prom = promise.new()
        local eventCallback = eventCallback
        local eventName = eventName
        TriggerEvent('dk__client_callback:'..eventName, msgpack_pack(args or {}),
        function(packed)
            if eventCallback and prom.state == PENDING then eventCallback( table_unpack(msgpack_unpack(packed)) ) end
            prom:resolve( table_unpack(msgpack_unpack(packed)) )
        end)

        if timeout ~= nil and timedout then
            local timedout = timedout
            SetTimeout(timeout * 1000, function()
                if
                    prom.state == PENDING or
                    prom.state == REJECTED or
                    prom.state == REJECTING
                then
                    timedout(prom.state)
                    if prom.state == PENDING then prom:reject() end
                end
            end)
        end

        if not eventCallback then
            return Citizen.Await(prom)
        end
    end
end

return M
