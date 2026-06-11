---@alias dk.request (fun(description: string, timer?: number, acceptText?: string, denyText?: string): boolean) | (fun(source: number|string, description: string, timer?: number, acceptText?: string, denyText?: string): boolean)

-- request — lado-ciente. Server: dispara via TriggerClientCallback.
-- Client: roda o fluxo de UI local. Retorna uma função callable.
local IS_SERVER = IsDuplicityVersion()

if IS_SERVER then
    local callbacks = require '@dk_snippets/modules/shared/callbacks'

    --- Envia um request para a source informada (server).
    ---@param source string|integer
    ---@param ... any  description, timer?, acceptText?, denyText?
    ---@return boolean
    local function loadRequest(source, ...)
        local args = { ... }
        local timer = args[2] or 20
        local timeout = (timer + 10) * 1000
        local result, finished = nil, false

        CreateThread(function() ---@diagnostic disable-line: missing-return
            result = callbacks.TriggerClientCallback(source, "dk_snippets/loadRequest", args)
            finished = true
        end)

        local startTime = GetGameTimer()
        while not finished do
            if GetGameTimer() - startTime > timeout then return false end
            Wait(100)
        end
        return result or false
    end

    return loadRequest
else
    local active = {}
    local success = false

    --- Dispara o fluxo de request localmente (client).
    ---@param description string
    ---@param timer? number
    ---@param acceptText? string
    ---@param denyText? string
    ---@return boolean
    local function loadRequest(description, timer, acceptText, denyText)
        local currentId = #active + 1
        local requestTimer = timer or 20
        table.insert(active, currentId)
        SendNUIMessage({
            request = true, new = true,
            params = { id = currentId, title = "Solicitação", description = description, timer = requestTimer, acceptText = acceptText, denyText = denyText }
        })
        local timedOut = false
        SetTimeout(requestTimer * 1000, function() ---@diagnostic disable-line: missing-return
            for i, v in ipairs(active) do
                if v == currentId then
                    timedOut = true
                    success = false
                    table.remove(active, i)
                    break
                end
            end
        end)
        while active[currentId] and not timedOut do Wait(1) end
        return success
    end

    return loadRequest
end
