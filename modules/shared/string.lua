local number = require '@dk_snippets/modules/shared/number'

---@class dk.string
local M = {}

local sanitize_tmp = {}

--- Sanitize a string by allowed/disallowed chars.
---@param str string
---@param strchars string
---@param allow_policy boolean
---@return string
function M.Sanitize(str, strchars, allow_policy)
    local r = ""
    local chars = sanitize_tmp[strchars]
    if not chars then
        chars = {}
        for i = 1, #strchars do chars[strchars:sub(i, i)] = true end
        sanitize_tmp[strchars] = chars
    end
    for i = 1, #str do
        local char = str:sub(i, i)
        if (allow_policy and chars[char]) or (not allow_policy and not chars[char]) then
            r = r .. char
        end
    end
    return r
end

--- Split a string by a delimiter (default "-").
---@param fullstr string
---@param symbol? string
---@return string[]
function M.Split(fullstr, symbol)
    local tbl = {}
    symbol = symbol or "-"
    for part in string.gmatch(fullstr, "([^" .. symbol .. "]+)") do
        tbl[#tbl + 1] = part
    end
    return tbl
end

--- Format a number with thousands separators.
---@param val any
---@return string
function M.ParseFormat(val)
    local value = number.ParseInt(val)
    local left, num, right = string.match(tostring(value), "^([^%d]*%d)(%d*)(.-)$")
    return left .. (num:reverse():gsub("(%d%d%d)", "%1."):reverse()) .. right
end

--- Join elements with a separator.
---@param tbl string[]
---@param sep string
---@return string
function M.Join(tbl, sep)
    local result = ""
    for i, value in ipairs(tbl) do
        result = result .. value
        if i < #tbl then result = result .. sep .. " " end
    end
    return result
end

--- Match a string against a table of handlers/values.
---@param str string
---@param datas table
---@return any
function M.Match(str, datas)
    local dataReturn = datas[str]
    if not dataReturn then
        if not datas.default then return nil end
        dataReturn = datas.default
    end
    if type(dataReturn) == "function" then return dataReturn() end
    return dataReturn
end

--- Dump a value to console (debug).
---@param value any
---@param depth? integer
---@param key? any
function M.Dump(value, depth, key)
    local linePrefix, spaces = "", ""
    if key ~= nil then
        if type(key) == "string" and key:sub(1, 2) == "__" then return end
        linePrefix = "[" .. key .. "] = "
    end
    depth = (depth or 0) + 1
    for _ = 1, depth do spaces = spaces .. "  " end
    if type(value) == "table" then
        local mt = getmetatable(value)
        print(spaces .. linePrefix .. (mt and "(metatable) " or "(table) "))
        if mt then M.Dump(mt, depth) end
        for k, v in pairs(value) do M.Dump(v, depth, k) end
    else
        print(spaces .. linePrefix .. tostring(value) .. " (" .. type(value) .. ")")
    end
end

return M
