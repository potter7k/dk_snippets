---@class dk.number
local number = {}

--- Parse a value to an integer.
---@param v any
---@return integer
function number.ParseInt(v)
    local n = tonumber(v)
    if n == nil then return 0 end
    return math.floor(n)
end

--- Round a number to a specified number of decimal places (Half-Up).
---@param value number
---@param decimals integer
---@return number
function number.Round(value, decimals)
    local factor = 10 ^ (decimals or 0)
    return math.floor(value * factor + 0.5) / factor
end

return number
