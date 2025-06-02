local success = false
local active = {}

---Retorna o resultado do request
---@return boolean
local function loadRequest(description, timer)
    local currentId = #active + 1
    table.insert(active, currentId)

    SendNUIMessage({
        request = true,
        new = true,
        params = {
            id = currentId,
            title = "Solicitação",
            description = description,
            timer = timer or 20,
        }
    })

    while active[currentId] do
        Wait(1)
    end

    return success
end

---Responder a requisição do request
---@param bool boolean
local function sendRequestResponse(bool)
    local first = active[1]
    if first then
        SendNUIMessage({
            request = true,
            response = bool and "accept" or "deny",
            params = {
                id = first
            }
        })
    end
end

RegisterNUICallback("requestResponse",function(data)
    success = data.success
    local index = table.indexOf(active, data.id)
    table.remove(active, ParseInt(index))
end)

RegisterCommand("dk/requestAccept",function()
    sendRequestResponse(true)
end)

RegisterCommand("dk/requestDecline",function()
	sendRequestResponse(false)
end)

RegisterKeyMapping("dk/requestAccept","Aceitar requisições.","keyboard","Y")
RegisterKeyMapping("dk/requestDecline","Rejeitar requisições.","keyboard","U")

RegisterClientCallback("dk_snippets/loadRequest", loadRequest)

exports("request",loadRequest)