---@enum NotifyModes
NotifyModes = {
	GREEN = "green",
	RED = "red",
	YELLOW = "yellow",
	BLUE = "blue"
}

--- Sends a notification to a player.
---
--- **Client-side:**
--- ```lua
--- DkNotify(NotifyModes.GREEN, "Compra efetuada com sucesso!", 4000)
--- ```
---
--- **Server-side** (requires the player source as the first argument):
--- ```lua
--- DkNotify(source, NotifyModes.GREEN, "Compra efetuada com sucesso!", 4000)
--- ```
---@overload fun(mode: NotifyModes, message: string, duration?: number) — Client-side
---@overload fun(source: number, mode: NotifyModes, message: string, duration?: number) — Server-side
function DkNotify(...)
	if IsDuplicityVersion() then
		TriggerClientEvent("dk/notify", ...)
	else
		TriggerEvent("dk/notify", ...)
	end
end

--- Sends a request notification to a player, which can be used for confirmations.
---
--- **Client-side:**
--- ```lua
--- DkRequest(description, timer, acceptText, denyText)
--- ```
---
--- **Server-side** (requires the player source as the first argument):
--- ```lua
--- DkRequest(source, description, timer, acceptText, denyText)
--- ```
---@overload fun(description: string, timer?: number, acceptText?: string, denyText?: string) — Client-side
---@overload fun(source: number, description: string, timer?: number, acceptText?: string, denyText?: string) — Server-side
function DkRequest(...)
	return exports["dk_snippets"]:request(...)
end

---@class HintConfig
---@field infoIcon boolean? Indicates whether to display an information icon in the hint.
---@field time number? Duration in milliseconds for which the hint should be displayed. If not specified, the hint will remain until removed.

---@alias HintAction "create" | "remove"

--- Hint function to display hints on both client and server sides.
---
--- **Client-side:**
--- ```lua
--- DkHint(action, id, description, control, configs)
--- ```
---
--- **Server-side** (requires the player source as the first argument):
--- ```lua
--- DkHint(source, action, id, description, control, configs)
--- ```
---@overload fun(action: HintAction, id: string, description: string, control?: string, configs?: HintConfig) — Client-side
---@overload fun(source: number, action: HintAction, id: string, description: string, control?: string, configs?: HintConfig) — Server-side
function DkHint(...)
	if IsDuplicityVersion() then
		TriggerClientEvent("dk/hint", ...)
	else
		TriggerEvent("dk/hint", ...)
	end
end

--- Parse a value to an integer.
---@param v any
---@return integer
function ParseInt(v)
	local n = tonumber(v)
	if n == nil then
		return 0
	else
		return math.floor(n)
	end
end

--- Função para criar classes com metatable.
--- Retorna uma classe com suporte a herança, construtores e instanciação via `:new(...)`.
---
--- ```lua
--- local Animal = Class({ name = "Unknown" })
---
--- function Animal:constructor(name)
---     self.name = name
--- end
---
--- function Animal:greet()
---     return "Hi, I'm " .. self.name
--- end
---
--- local dog = Animal:new("Rex")
--- print(dog:greet()) -- Hi, I'm Rex
--- ```
---@generic T : table
---@param defaults T Tabela com propriedades e valores padrão da classe.
---@return T|{ new: fun(self: T, ...): T, constructor: fun(self: T, ...) }
function Class(defaults)
	local class = {}

	for key, value in pairs(defaults or {}) do
		class[key] = value
	end

	class.__index = class

	function class:new(...)
		local obj = setmetatable({}, self)

		for key, value in pairs(self) do
			if key ~= "__index" and key ~= "new" and type(value) ~= "function" then
				obj[key] = value
			end
		end

		-- Chama o construtor se existir
		if obj.constructor then
			obj:constructor(...)
		end

		return obj
	end

	return class
end

local sanitize_tmp = {}

--- Sanitize a string based on allowed or disallowed characters.
---@param str string
---@param strchars string
---@param allow_policy boolean
---@return string
function SanitizeString(str, strchars, allow_policy)
	local r = ""
	local chars = sanitize_tmp[strchars]
	if not chars then
		chars = {}
		local size = string.len(strchars)
		for i = 1, size do
			local char = string.sub(strchars, i, i)
			chars[char] = true
		end

		sanitize_tmp[strchars] = chars
	end

	local size = string.len(str)
	for i = 1, size do
		local char = string.sub(str, i, i)
		if (allow_policy and chars[char]) or (not allow_policy and not chars[char]) then
			r = r .. char
		end
	end

	return r
end

--- Split a string by a specified delimiter.
---@param fullstr string The string to split.
---@param symbol? string The delimiter character (default: "-").
---@return string[] parts The resulting parts of the split.
function SplitString(fullstr, symbol)
	local tbl = {}

	if not symbol then
		symbol = "-"
	end

	for fullstr in string.gmatch(fullstr, "([^" .. symbol .. "]+)") do
		tbl[#tbl + 1] = fullstr
	end

	return tbl
end

--- Format a number with thousands separators.
---@param val any
---@return string
function ParseFormat(val)
	local value = ParseInt(val)
	local left, number, right = string.match(value, "^([^%d]*%d)(%d*)(.-)$")
	return left .. (number:reverse():gsub("(%d%d%d)", "%1."):reverse()) .. right
end

--- Joins the elements of a table into a string with a separator.
---@param tbl string[] The list of string elements to join.
---@param str string The separator between elements.
---@return string result The resulting concatenated string.
function Join(tbl, str)
	local result = ""
	for i, value in ipairs(tbl) do
		result = result .. value
		if i < #tbl then
			result = result .. str .. " "
		end
	end
	return result
end

--- Round a number to a specified number of decimal places.
---@param value number The number to round.
---@param decimals integer The number of decimal places to keep.
---@return number The rounded number.
function Round(value, decimals)
    local factor = 10 ^ (decimals or 0)
    -- Adicionar 0.5 compensa a imprecisão e faz o arredondamento correto (Half-Up)
    return math.floor(value * factor + 0.5) / factor
end

function Ensure(obj, expected, errMessage)
	local objtype = type(obj)
	local errorMess = errMessage or 'expected %s, but got %s'

	local pass = false
	table.forEach(expected, function(curType)
		if objtype == "function" then
			if objtype == "table" and not rawget(obj, '__cfx_functionReference') then
				pass = true
			end
		elseif curType == objtype then
			pass = true
		end
	end)

	if pass then
		return
	end

	error((errorMess):format(Join(expected, ","), objtype))
end

--- Match a string with a corresponding value in a table.
---@param str string
---@param datas table
---@return any
function Match(str, datas)
	local dataReturn = datas[str]
	if not dataReturn then
		if not datas.default then
			return nil
		end
		dataReturn = datas.default
	end

	if type(dataReturn) == "function" then
		return dataReturn()
	end
	return dataReturn
end

--- Dump the content of a variable in a readable format.
---@param value any
---@param depth? integer
---@param key? any
function Dump(value, depth, key)
	local linePrefix = ""
	local spaces = ""

	if key ~= nil then
		if type(key) == "string" and key:sub(1, 2) == "__" then return end

		linePrefix = "[" .. key .. "] = "
	end

	if not depth then
		depth = 0
	end

	depth = depth + 1

	for i = 1, depth do
		spaces = spaces .. "  "
	end

	if type(value) == "table" then
		local metaTable = getmetatable(value)
		if metaTable ~= nil then
			print(spaces .. linePrefix .. "(metatable) ")
			Dump(metaTable, depth)
		else
			print(spaces .. linePrefix .. "(table) ")
		end
		for tableKey, tableValue in pairs(value) do
			Dump(tableValue, depth, tableKey)
		end
	else
		print(spaces .. linePrefix .. tostring(value) .. " (" .. type(value) .. ")")
	end
end

--- Count the number of elements in a table.
---@param self table
---@return integer
---@diagnostic disable-next-line: duplicate-set-field
function table.count(self)
	local count = 0

	for _, _ in pairs(self) do
		count = count + 1
	end

	return count
end

--- Map a function to each element in a table and optionally prevent indexing.
---@param self table
---@param func function
---@param preventIndex boolean
---@return table
function table.map(self, func, preventIndex)
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

--- Iterate over each element in a table and apply a function.
---@param self table
---@param func function
function table.forEach(self, func)
	table.map(self, func, false)
end

--- Find elements in a table that match a function's criteria.
---@param self table
---@param func function
---@param keepIndex boolean
---@return table
function table.find(self, func, keepIndex)
	keepIndex = keepIndex == true and true or false
	local ret = {}
	for key, value in pairs(self) do
		if func(value, key) then
			if keepIndex then
				ret[key] = value
			else
				table.insert(ret, value)
			end
		end
	end
	return ret
end

--- Extract a slice of a table from a start index to an end index.
---@param self table
---@param startIndex integer
---@param endIndex? integer
---@return table
function table.slice(self, startIndex, endIndex)
	local ret = {}
	local length = #self

	startIndex = startIndex or 1
	endIndex = endIndex or length

	if startIndex < 0 then
		startIndex = length + startIndex + 1
	end

	if endIndex < 0 then
		endIndex = length + endIndex + 1
	elseif endIndex > length then
		endIndex = length
	end

	for i = startIndex, endIndex do
		if self[i] ~= nil then
			table.insert(ret, self[i])
		end
	end

	return ret
end

--- Find the index of an element in a table.
---@param self table
---@param o any
---@return integer|string|nil
---@diagnostic disable-next-line: duplicate-set-field
function table.indexOf(self, o)
	for i, v in pairs(self) do
		if v == o then
			return i
		end
	end
	return nil
end
