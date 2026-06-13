--- Exibe um hint na UI.
---@param id string
---@param description string
---@param control? string
---@param configs? table
local function loadHint(id, description, control, configs)
    SendNUIMessage({
        hint = {
            action = "create",
            id = id,
            description = description,
            control = control,
            configs = configs or {}
        }
    })
end

--- Remove um hint da UI.
---@param id string
local function removeHint(id)
    SendNUIMessage({
        hint = {
            action = "remove",
            id = id
        }
    })
end

RegisterNetEvent('dk/hint')
AddEventHandler('dk/hint', function(action, ...)
    if action == "create" then
        loadHint(...)
    elseif action == "remove" then
        removeHint(...)
    end
end)
