-- Helpers de tabela ISOLADOS. NÃO estende a `table` nativa do Lua.
---@class dk.table
local M = {}

--- Count elements in a table.
---@param self table
---@return integer
function M.count(self)
    local count = 0
    for _ in pairs(self) do count = count + 1 end
    return count
end

--- Map a function over a table.
---@param self table
---@param func function
---@param preventIndex? boolean
---@return table
function M.map(self, func, preventIndex)
    preventIndex = preventIndex and true or false
    local response = {}
    for key, value in pairs(self) do
        local data = func(value, key)
        if data ~= nil then
            if not preventIndex then
                table.insert(response, data)
            else
                response[key] = data
            end
        end
    end
    return response
end

--- Iterate over each element.
---@param self table
---@param func function
function M.forEach(self, func)
    M.map(self, func, false)
end

--- Find elements matching a predicate.
---@param self table
---@param func function
---@param keepIndex? boolean
---@return table
function M.find(self, func, keepIndex)
    keepIndex = keepIndex and true or false
    local ret = {}
    for key, value in pairs(self) do
        if func(value, key) then
            if keepIndex then ret[key] = value else table.insert(ret, value) end
        end
    end
    return ret
end

--- Slice a table from startIndex to endIndex (supports negative indices).
---@param self table
---@param startIndex integer
---@param endIndex? integer
---@return table
function M.slice(self, startIndex, endIndex)
    local ret = {}
    local length = #self
    startIndex = startIndex or 1
    endIndex = endIndex or length
    if startIndex < 0 then startIndex = length + startIndex + 1 end
    if endIndex < 0 then endIndex = length + endIndex + 1
    elseif endIndex > length then endIndex = length end
    for i = startIndex, endIndex do
        if self[i] ~= nil then table.insert(ret, self[i]) end
    end
    return ret
end

--- Index of a value in a table.
---@param self table
---@param o any
---@return integer|string|nil
function M.indexOf(self, o)
    for i, v in pairs(self) do
        if v == o then return i end
    end
    return nil
end

--- Whether a table contains a value.
---@param self table
---@param value any
---@return boolean
function M.contains(self, value)
    return M.indexOf(self, value) ~= nil
end

return M
