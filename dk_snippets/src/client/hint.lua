--- Loads and displays a hint on the user interface.
--- @param id string The unique identifier for the hint
--- @param description string The text description to display in the hint
--- @param control? string The control/key binding associated with the hint
--- @param configs? table Additional configuration options for the hint display
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

--- Removes a hint from the user interface.
--- @param id string The unique identifier of the hint to remove
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