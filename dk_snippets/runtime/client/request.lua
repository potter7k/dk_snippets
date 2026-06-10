local tbl = require '@dk_snippets/modules/shared/table'
local number = require '@dk_snippets/modules/shared/number'
local callbacks = require '@dk_snippets/modules/shared/callbacks'

local success = false
local active = {}

--- Retorna o resultado do request (client).
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
        request = true,
        new = true,
        params = {
            id = currentId,
            title = "Solicitação",
            description = description,
            timer = requestTimer,
            acceptText = acceptText,
            denyText = denyText
        }
    })

    local timedOut = false
    SetTimeout(requestTimer * 1000, function()
        local index = tbl.indexOf(active, currentId)
        if index then
            timedOut = true
            success = false
            table.remove(active, number.ParseInt(index))
        end
    end)

    while active[currentId] and not timedOut do
        Wait(1)
    end

    return success
end

--- Responde à requisição ativa.
---@param bool boolean
local function sendRequestResponse(bool)
    local first = active[1]
    if first then
        SendNUIMessage({
            request = true,
            response = bool and "accept" or "deny",
            params = { id = first }
        })
    end
end

RegisterNUICallback("requestResponse", function(data)
    success = data.success
    local index = tbl.indexOf(active, data.id)
    if not index then return end
    table.remove(active, number.ParseInt(index))
end)

RegisterCommand("dk/requestAccept", function() sendRequestResponse(true) end)
RegisterCommand("dk/requestDecline", function() sendRequestResponse(false) end)

RegisterKeyMapping("dk/requestAccept", "Aceitar requisições.", "keyboard", "Y")
RegisterKeyMapping("dk/requestDecline", "Rejeitar requisições.", "keyboard", "U")

callbacks.RegisterClientCallback("dk_snippets/loadRequest", loadRequest)

-- Export legado (modelo 2.x) — usado pelo DkRequest do shim compat no client.
-- Reusa a loadRequest local (o fluxo de NUI/resposta vive neste arquivo).
exports('request', loadRequest)
