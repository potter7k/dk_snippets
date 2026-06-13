-- Modos de notificação disponíveis (use via snippets.notify.modes.GREEN etc.).
local NotifyModes = { GREEN = "green", RED = "red", YELLOW = "yellow", BLUE = "blue" }

---@class dk.notify
local M = { modes = NotifyModes }

--- Envia uma notificação a um jogador.
---
--- **Client:** `send(mode, message, duration?)`
--- **Server:** `send(source, mode, message, duration?)`
---@param ... any
---@overload fun(mode: string, message: string, duration?: number)
---@overload fun(source: number, mode: string, message: string, duration?: number)
function M.send(...)
    if IsDuplicityVersion() then
        TriggerClientEvent("dk/notify", ...)
    else
        TriggerEvent("dk/notify", ...)
    end
end

--- Exibe/remove um hint na UI.
---
--- **Client:** `hint(action, id, description, control?, configs?)`
--- **Server:** `hint(source, action, id, description, control?, configs?)`
---@param ... any
---@overload fun(action: 'create'|'remove', id: string, description: string, control?: string, configs?: { infoIcon?: boolean, time?: number })
---@overload fun(source: number, action: 'create'|'remove', id: string, description: string, control?: string, configs?: { infoIcon?: boolean, time?: number })
function M.hint(...)
    if IsDuplicityVersion() then
        TriggerClientEvent("dk/hint", ...)
    else
        TriggerEvent("dk/hint", ...)
    end
end

return M
