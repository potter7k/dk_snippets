local tbl = require '@dk_snippets/modules/shared/table'
local str = require '@dk_snippets/modules/shared/string'

local M = {}

--- Garante que `obj` seja de um dos tipos esperados; erra caso contrário.
---@param obj any
---@param expected string[]
---@param errMessage? string
function M.Ensure(obj, expected, errMessage)
    local objtype = type(obj)
    local errorMess = errMessage or 'expected %s, but got %s'

    local pass = false
    tbl.forEach(expected, function(curType)
        if objtype == "function" then
            if objtype == "table" and not rawget(obj, '__cfx_functionReference') then
                pass = true
            end
        elseif curType == objtype then
            pass = true
        end
    end)

    if pass then return end

    error((errorMess):format(str.Join(expected, ","), objtype))
end

return M
