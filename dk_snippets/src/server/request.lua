---Envia um request para a source informada.
---@param source string|integer
---@param ... any
---@return boolean
local function loadRequest(source, ...)
    local args = {...}
    local timer = args[2] or 20
    local timeout = (timer + 10) * 1000
    local result = nil
    local finished = false

    CreateThread(function()
        result = TriggerClientCallback(source, "dk_snippets/loadRequest", args)
        finished = true
    end)

    local startTime = GetGameTimer()
    while not finished do
        if GetGameTimer() - startTime > timeout then
            return false
        end
        Wait(100)
    end

    return result or false
end

exports("request", loadRequest)
