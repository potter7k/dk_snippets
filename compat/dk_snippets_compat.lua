-- dk_snippets_compat.lua — shim de compatibilidade para scripts encriptados antigos.
-- Concatenação LITERAL dos arquivos do dk_snippets 2.x (utils → callbacks → cooldowns → json).
-- Carregado no CONTEXTO DO CONSUMIDOR via:
--   shared_scripts { '@dk_snippets/compat/dk_snippets_compat.lua' }  -- (primeiro script)
-- Autocontido: não usa require/init.lua. Depende apenas dos eventos dk/notify e dk/hint
-- e dos exports legados request/framework/DB (runtime/*/legacy_exports.lua).
-- A seção de callbacks espelha modules/shared/callbacks.lua (v3): mesmo wire protocol,
-- então um peer que use este shim conversa com outro que use o módulo. Ao mexer em
-- callbacks, altere os DOIS lados juntos. As demais seções são portadas do 2.x.
-- Spec: docs/superpowers/specs/2026-06-10-dk-snippets-compat-encriptados-design.md
-- ========== [2.x] src/shared/utils.lua ==========
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
--- Consulte a documentação completa em `Class`.
---
--- ```lua
--- ---@class Animal : Class
--- ---@field name string
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
---
--- -- Herança
--- ---@class Cat : Animal
--- ---@field lives integer
--- local Cat = Animal:extend({ lives = 9 })
---
--- function Cat:constructor(name)
---     Animal.constructor(self, name)
--- end
---
--- local cat = Cat:new("Mimi")
--- print(cat:greet())            -- Hi, I'm Mimi
--- print(cat.lives)              -- 9
--- print(cat:instanceof(Animal)) -- true
--- ```
---@generic T : table
---@param defaults T Tabela com propriedades e valores padrão da classe.
---@param parent? Class Classe pai para herança (use `:extend()` como alternativa).
---@return T|Class class A nova classe criada.
function Class(defaults, parent)
	local class = {}
	local defaultProps = {}

	-- Herda métodos e defaults do pai
	if parent then
		for key, value in pairs(parent) do
			class[key] = value
		end

		local parentDefaults = rawget(parent, "__defaults")
		if parentDefaults then
			for key, value in pairs(parentDefaults) do
				defaultProps[key] = value
			end
		end
	end

	-- Aplica e registra os defaults da classe
	for key, value in pairs(defaults or {}) do
		class[key] = value
		if type(value) ~= "function" then
			defaultProps[key] = value
		end
	end

	class.__index = class
	class.__parent = parent
	class.__defaults = defaultProps

	--- Deep copy para evitar compartilhamento de referência entre instâncias.
	local function deepCopy(val)
		if type(val) ~= "table" then return val end
		local copy = {}
		for k, v in pairs(val) do
			copy[k] = deepCopy(v)
		end
		return setmetatable(copy, getmetatable(val))
	end

	--- Cria uma nova instância da classe.
	function class:new(...)
		local obj = setmetatable({}, self)

		for key, value in pairs(self.__defaults) do
			obj[key] = deepCopy(value)
		end

		if obj.constructor then
			obj:constructor(...)
		end

		return obj
	end

	--- Cria uma subclasse que herda desta classe.
	function class:extend(childDefaults)
		return Class(childDefaults, self)
	end

	--- Verifica se o objeto é instância de uma determinada classe.
	function class:instanceof(klass)
		local current = getmetatable(self)
		while current do
			if current == klass then return true end
			current = current.__parent
		end
		return false
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
---@param self table?
---@return integer
---@diagnostic disable-next-line: duplicate-set-field
function table.count(self)
	if self == nil then return 0 end
	local count = 0

	for _, _ in pairs(self) do
		count = count + 1
	end

	return count
end

--- Map a function to each element in a table and optionally prevent indexing.
---@param self table?
---@param func function
---@param preventIndex? boolean
---@return table
function table.map(self, func, preventIndex)
	-- `self` nil é tratado como tabela vazia: consumidores (inclusive scripts
	-- encriptados) repassam retornos de rede/callbacks que podem chegar nil, e o
	-- core nunca deve quebrar por causa disso. Retorna {} em vez de iterar nil.
	if self == nil then return {} end
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

--- Iterate over each element in a table and apply a function.
---@param self table
---@param func function
function table.forEach(self, func)
	table.map(self, func, false)
end

--- Find elements in a table that match a function's criteria.
---@param self table?
---@param func function
---@param keepIndex? boolean
---@return table
function table.find(self, func, keepIndex)
	if self == nil then return {} end
	keepIndex = keepIndex and true or false
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
---@param self table?
---@param startIndex integer
---@param endIndex? integer
---@return table
function table.slice(self, startIndex, endIndex)
	if self == nil then return {} end
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

---@param self table
---@param value string | number | boolean
---@return boolean
function table.contains(self, value)
	return table.indexOf(self, value) ~= nil
end
-- ========== [2.x] src/shared/callbacks.lua ==========
-- Callbacks request/response client<->server. Popula globais (_G.*) no contexto do
-- consumidor encriptado. Wire protocol idêntico ao módulo v3
-- (modules/shared/callbacks.lua) — os dois lados conversam entre si, inclusive o
-- ticket ecoado em client→server. NÃO alterar nomes/formato dos eventos dk__*.

local IS_SERVER = IsDuplicityVersion()
local table_unpack = table.unpack
local debug_getinfo = debug.getinfo
local msgpack_pack = msgpack.pack
local msgpack_unpack = msgpack.unpack
local GetGameTimer = GetGameTimer
local PENDING, REJECTING, REJECTED = 0, 2, 4

local function ensure(obj, typeof, opt_typeof)
	local objtype = type(obj)
	local name = debug_getinfo(2).name or 'unknown'
	if typeof == 'function' then
		if objtype == 'table' and not rawget(obj, '__cfx_functionReference') then
			error(('%s expected function, but got %s'):format(name, objtype))
		end
		return
	end
	if objtype ~= typeof and objtype ~= opt_typeof then
		error(('%s expected %s%s, but got %s'):format(
			name, typeof, opt_typeof and (' or ' .. opt_typeof) or '', objtype))
	end
end

-- Dispara timedout na expiração e roda cleanup uma vez.
local function scheduleTimeout(prom, timeout, timedout, onExpire)
	if not (timeout and timedout) then return end
	SetTimeout(timeout * 1000, function()
		local state = prom.state ---@diagnostic disable-line: undefined-field
		if state == PENDING or state == REJECTING or state == REJECTED then
			timedout(state)
			if state == PENDING then prom:reject() end
			if onExpire then onExpire() end
		end
	end)
end

if IS_SERVER then
	_G.RegisterServerCallback = function(eventName, eventCallback)
		ensure(eventName, 'string'); ensure(eventCallback, 'function')

		-- RegisterNetEvent só libera o nome em rede (não devolve handle removível); o
		-- cookie aceito por RemoveEventHandler vem de AddEventHandler.
		RegisterNetEvent('dk__server_callback:'..eventName)
		return AddEventHandler('dk__server_callback:'..eventName, function(packed, src, cb) ---@diagnostic disable-line: missing-return
			local netSource = source
			-- args empacotado no produtor com pack(argsTable); unpack devolve a tabela
			-- diretamente. NÃO envolver em { } (adicionava nível extra → fn recebia {arg}).
			local args = msgpack_unpack(packed) or {}
			if cb then
				-- chamada local (server→server): src e cb explícitos.
				-- Empacota a LISTA de retornos com pack({...}) (ver nota em
				-- RegisterClientCallback): pack_args/unpack são assimétricos e geravam
				-- um nível extra de aninhamento no retorno.
				cb(msgpack_pack({ eventCallback(src, table_unpack(args)) }))
			else
				-- chamada de rede: src é o ticket (string) ou nil
				local ret = msgpack_pack({ eventCallback(netSource, table_unpack(args)) })
				TriggerClientEvent(('dk__client_callback_response:%s:%s'):format(eventName, netSource),
					netSource, ret, src) -- ecoa o ticket
			end
		end)
	end

	_G.UnregisterServerCallback = function(eventData)
		-- eventData nil/inválido faz RemoveEventHandler lançar "Invalid event data".
		if eventData then RemoveEventHandler(eventData) end
	end

	_G.TriggerClientCallback = function(source, eventName, args, eventCallback, timeout, timedout)
		ensure(source, 'string', 'number'); ensure(eventName, 'string'); ensure(args, 'table', 'nil'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')
		if tonumber(source) < 0 then error 'source should be equal too or higher than 0' end

		local ticket = ('%s:%d'):format(source, GetGameTimer())
		local prom = promise.new()
		local removed = false
		-- AddEventHandler (não RegisterNetEvent) devolve o handle aceito por
		-- RemoveEventHandler; RegisterNetEvent apenas libera o nome em rede.
		local evName = ('dk__callback_retval:%s:%s:%s'):format(source, eventName, ticket)
		RegisterNetEvent(evName)
		local eventData = AddEventHandler(evName, function(packed)
			if prom.state ~= PENDING then return end
			local ret = msgpack_unpack(packed) or {}
			if eventCallback then eventCallback(table_unpack(ret)) end
			prom:resolve(table_unpack(ret))
		end)
		local function cleanup()
			-- eventData (cookie do AddEventHandler) pode vir nil em certos timings do
			-- runtime; RemoveEventHandler(nil) lança "Invalid event data" (commit 66688c4).
			if not removed and eventData then removed = true; RemoveEventHandler(eventData) end
		end

		TriggerClientEvent(('dk__client_callback:%s'):format(eventName), source, msgpack_pack(args or {}), ticket)

		scheduleTimeout(prom, timeout, timedout, cleanup)
		if not eventCallback then
			local result = { Citizen.Await(prom) }
			cleanup()
			return table_unpack(result)
		end
	end

	_G.TriggerServerCallback = function(source, eventName, args, eventCallback, timeout, timedout)
		ensure(source, 'string', 'number'); ensure(eventName, 'string'); ensure(args, 'table', 'nil'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')

		local prom = promise.new()
		TriggerEvent('dk__server_callback:'..eventName, msgpack_pack(args or {}), source, function(packed)
			if prom.state ~= PENDING then return end
			local ret = msgpack_unpack(packed) or {}
			if eventCallback then eventCallback(table_unpack(ret)) end
			prom:resolve(table_unpack(ret))
		end)

		scheduleTimeout(prom, timeout, timedout)
		if not eventCallback then return Citizen.Await(prom) end
	end
end

if not IS_SERVER then
	-- O server id NÃO pode ser cacheado no load do recurso: como shared_script, este
	-- arquivo roda antes do player ter um id de sessão válido (GetPlayerServerId devolve
	-- -1/0 nesse instante). Cachear cedo faz o net event de resposta ser registrado com
	-- o id errado (ex.: '...:-1'), e o server responde para '...:<idReal>' — os nomes não
	-- casam, a resposta se perde e o callback bloqueia para sempre. Resolvemos lazy: só
	-- fixa o id quando ele já é válido (> 0).
	local cachedServerId = nil
	local function getServerId()
		if cachedServerId then return cachedServerId end
		local id = GetPlayerServerId(PlayerId())
		if id and id > 0 then cachedServerId = id end
		return id
	end

	_G.RegisterClientCallback = function(eventName, eventCallback)
		ensure(eventName, 'string'); ensure(eventCallback, 'function')

		-- handle removível vem de AddEventHandler; RegisterNetEvent só libera o nome.
		RegisterNetEvent('dk__client_callback:'..eventName)
		return AddEventHandler('dk__client_callback:'..eventName, function(packed, ticket)
			-- args: unpack devolve a tabela de args; table_unpack espalha. ret: pack({...})
			-- (lista de retornos). pack_args/unpack eram assimétricos e geravam nível extra.
			local ret = msgpack_pack({ eventCallback(table_unpack(msgpack_unpack(packed) or {})) })
			if type(ticket) == 'function' then
				ticket(ret)
			else
				TriggerServerEvent(('dk__callback_retval:%s:%s:%s'):format(getServerId(), eventName, ticket), ret)
			end
		end)
	end

	_G.UnregisterClientCallback = function(eventData)
		-- eventData nil/inválido faz RemoveEventHandler lançar "Invalid event data".
		if eventData then RemoveEventHandler(eventData) end
	end

	-- Handler persistente por eventName, roteia respostas por ticket. Evita colisão
	-- entre chamadas concorrentes ao mesmo callback (falha da versão antiga).
	-- O entry só é cacheado quando o server id já é válido: o nome do net event de
	-- resposta embute o id, então registrá-lo cedo (id -1) deixaria o handler surdo
	-- para sempre. Enquanto o id não vale, recriamos o handler a cada chamada.
	local pendingByEvent = {}
	local function ensureResponseHandler(eventName)
		local entry = pendingByEvent[eventName]
		if entry then return entry end
		local serverId = getServerId()
		entry = { tickets = {} }
		-- handle removível vem de AddEventHandler; RegisterNetEvent só libera o nome.
		local respName = ('dk__client_callback_response:%s:%s'):format(eventName, serverId)
		RegisterNetEvent(respName)
		entry.handle = AddEventHandler(respName, function(packed, ticket)
			local tickets = entry.tickets
			local slot = ticket and tickets[ticket]
			if not slot then ticket, slot = next(tickets) end
			if not slot then return end
			tickets[ticket] = nil
			-- ret é a lista de retornos (empacotada com pack({...})); table_unpack devolve
			-- os valores na ordem original.
			local ret = msgpack_unpack(packed) or {}
			if slot.cb then slot.cb(table_unpack(ret)) end
			slot.prom:resolve(table_unpack(ret))
		end)
		-- Só memoiza quando o id é válido; com id inválido o handler nasce surdo e
		-- precisa ser refeito na próxima chamada (quando o id já estiver disponível).
		if serverId and serverId > 0 then
			pendingByEvent[eventName] = entry
		end
		return entry
	end

	_G.TriggerServerCallback = function(eventName, args, eventCallback, timeout, timedout)
		ensure(args, 'table', 'nil'); ensure(eventName, 'string'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')

		local entry = ensureResponseHandler(eventName)
		local ticket = ('%d:%d'):format(getServerId(), GetGameTimer())
		local prom = promise.new()
		entry.tickets[ticket] = { prom = prom, cb = eventCallback }
		local function cleanup() entry.tickets[ticket] = nil end

		TriggerServerEvent('dk__server_callback:'..eventName, msgpack_pack(args or {}), ticket)

		scheduleTimeout(prom, timeout, timedout, cleanup)
		if not eventCallback then
			local result = { Citizen.Await(prom) }
			cleanup()
			return table_unpack(result)
		end
	end

	_G.TriggerClientCallback = function(eventName, args, eventCallback, timeout, timedout)
		ensure(eventName, 'string'); ensure(args, 'table', 'nil'); ensure(timeout, 'number', 'nil'); ensure(timedout, 'function', 'nil'); ensure(eventCallback, 'function', 'nil')

		local prom = promise.new()
		TriggerEvent('dk__client_callback:'..eventName, msgpack_pack(args or {}), function(packed)
			if prom.state ~= PENDING then return end
			local ret = msgpack_unpack(packed) or {}
			if eventCallback then eventCallback(table_unpack(ret)) end
			prom:resolve(table_unpack(ret))
		end)

		scheduleTimeout(prom, timeout, timedout)
		if not eventCallback then return Citizen.Await(prom) end
	end
end
-- ========== [2.x] src/shared/cooldowns.lua ==========
---@class Cooldown
---@field defaultTimer integer Tempo padrão do cooldown em milissegundos.
---@field timer integer Timestamp (ms) de quando o cooldown expira.
---@field new fun(self: Cooldown, timer?: integer): Cooldown Cria uma nova instância de Cooldown.
---@field constructor fun(self: Cooldown, timer?: integer) Construtor interno.
---@field start fun(self: Cooldown, timer?: integer) Inicia o cooldown.
---@field reset fun(self: Cooldown) Reseta o cooldown.
---@field check fun(self: Cooldown): integer|nil Verifica se está ativo; retorna segundos restantes ou nil.
---@field checkAndCreate fun(self: Cooldown, timer?: integer, func?: fun(seconds: integer)): boolean Verifica e cria se inativo.
Cooldown = Class({
    defaultTimer = 0,
    timer = 0
})

--- Construtor do Cooldown.
---@param timer integer|nil Tempo em segundos (será convertido para ms internamente).
function Cooldown:constructor(timer)
    self.defaultTimer = (timer or 0) * 1000
    self.timer = 0
end

--- Start a cooldown.
---@param timer integer|nil
function Cooldown:start(timer)
    self.timer = GetGameTimer() + ParseInt(timer or self.defaultTimer)
end

--- Reset the cooldown.
function Cooldown:reset()
    self.timer = 0
end

--- Check if the cooldown is active, if so, return the remaining time.
---@return integer|nil
function Cooldown:check()
    local currentTimer = GetGameTimer()
    if self.timer > currentTimer then
        return ParseInt((self.timer - currentTimer) / 1000)
    end

    return nil
end

--- Check if cooldown is active, and create cooldown if not. 
---@param timer integer|nil
---@param func function|nil
---@return boolean
function Cooldown:checkAndCreate(timer, func)
    local seconds = self:check()
    if seconds then
        if type(func) == "function" then
            func(seconds)
        end
        return false
    end
    self:start(timer)
    return true
end

-- ========== [2.x] src/server/json.lua (server-only) ==========
if IsDuplicityVersion() then
---@class JSON
---@field nextId table<string, integer> A table to keep track of the next auto-increment ID for each key.
---@field target table Contains the directory and path for the JSON file.
---@field datas table The actual data loaded from the JSON file.
JSON = {
    nextId = {},
    target = {
        dir = nil,
        path = nil
    },
    datas = {}
}
JSON.__index = JSON

--- Fetch data from a JSON file and initialize the object.
---@param filePath string The path to the JSON file.
---@return JSON
function JSON:fetch(filePath)
    local obj = setmetatable({}, self)

    obj.nextId = {}

    obj.target = {
        dir = GetCurrentResourceName(),
        path = filePath
    }

    local resFile = LoadResourceFile(obj.target.dir, obj.target.path..".json")
    if type(resFile) ~= "string" then
        error("Erro ao carregar JSON, arquivo "..obj.target.path.." não encontrado.")
    end

    obj.datas = json.decode(resFile) or {}

    -- Initialize nextId with the highest existing ID + 1
    table.forEach(obj.datas, function(records, key)
        if not obj:hasColumn(key, "id") then return end

        if not obj.nextId[key] then
            obj.nextId[key] = 1
        end
        table.forEach(records, function(item)
            if not item.id then return end

            if item.id >= obj.nextId[key] then
                obj.nextId[key] = item.id + 1
            end
        end)
    end)

    return obj
end

--- Save data to the JSON file.
---@param datas table The data to be saved.
function JSON:set(datas)
    Ensure(datas, {"table"})

    SaveResourceFile(self.target.dir, self.target.path..".json", json.encode(datas, {indent = true}), -1)
end

--- Filter data based on criteria.
---@param key string The key to search within.
---@param data table The criteria to match.
---@param keepIndex boolean Whether to keep the original index.
---@return table
function JSON:where(key, data, keepIndex)
    Ensure(key, {"string", "number"}) Ensure(data, {"table"})

    if not self.datas[key] then return {} end

    return table.find(self.datas[key], function(item)
        for targetKey, targetVal in pairs(data) do
            if item[targetKey] ~= targetVal then
                return false
            end
        end
        return true
    end, keepIndex)
end

--- Insert a new record with auto-increment ID.
---@param key string The key to insert into.
---@param data table The data to be inserted.
---@return table
function JSON:insert(key, data, ignoreId)
    if not self.datas[key] then
        self.datas[key] = {}
    end
    local tableDatas = self.datas[key]
    if table.count(tableDatas) < 1 and not ignoreId then
        self.nextId[key] = 1
    end
    if not data.id and self.nextId[key] and not ignoreId then
        data.id = self.nextId[key]
        self.nextId[key] = self.nextId[key] + 1
    end
    table.insert(tableDatas, data)
    self:set(self.datas)
    return {
        affectedRows = 1,
        insertId = data.id
    }
end

--- Increase the default value of a column.
---@param key string The key to update.
---@param column string The column to update.
---@param val any The value to set.
---@param force boolean Whether to force the update.
---@return table
function JSON:increaseDefault(key, column, val, force)
    if not self.datas[key] then return {affectedRows = 0} end

    local itemsToUpdate = self.datas[key]
    if not force then
        itemsToUpdate = table.find(self.datas[key], function(item)
            return item[column] == nil
        end, true)
    end

    local itemsAmount = table.count(itemsToUpdate)
    if itemsAmount < 1 then return {affectedRows = 0} end

    table.forEach(itemsToUpdate, function(_, i)
        self.datas[key][i][column] = val
    end)

    self:set(self.datas)

    return {
        affectedRows = itemsAmount
    }
end

--- Update existing records based on criteria.
---@param key string The key to update within.
---@param data table The criteria to match.
---@param newData table The new data to set.
---@param replace boolean Whether to replace the entire record.
---@return table
function JSON:update(key, data, newData, replace)
    if not self.datas[key] then return {affectedRows = 0} end

    local itemsToUpdate = self:where(key, data, true)
    local itemsAmount = table.count(itemsToUpdate)
    if itemsAmount < 1 then return {affectedRows = 0} end

    table.forEach(itemsToUpdate, function(_, i)
        if replace then
            self.datas[key][i] = newData
        else
            for k, v in pairs(newData) do
                self.datas[key][i][k] = v
            end
        end
    end)

    self:set(self.datas)

    return {
        affectedRows = itemsAmount
    }
end

--- Delete records based on criteria.
---@param key string The key to delete from.
---@param data table The criteria to match.
---@return table
function JSON:delete(key, data)
    if not self.datas[key] then return {affectedRows = 0} end

    local itemsToDelete = self:where(key, data, true)
    local itemsAmount = table.count(itemsToDelete)
    if itemsAmount < 1 then return {affectedRows = 0} end

    local indicesToDelete = {}
    for i, _ in pairs(itemsToDelete) do
        table.insert(indicesToDelete, i)
    end

    table.sort(indicesToDelete, function(a, b) return a > b end)

    for _, i in ipairs(indicesToDelete) do
        table.remove(self.datas[key], i)
    end

    self:set(self.datas)

    return {
        affectedRows = itemsAmount
    }
end

--- Check if a column exists in a table.
---@param key string The key to check.
---@param column string The column to check for.
---@return boolean
function JSON:hasColumn(key, column)
    if not self.datas[key] then return false end

    local _, firstVal = next(self.datas[key])
    if not firstVal then return true end
    return firstVal[column] ~= nil
end

--- Check if a table exists for the given key.
---@param key string The key to check.
---@return boolean
function JSON:tableExists(key)
    return type(self.datas[key]) == "table"
end

--- Create a table if it does not exist.
---@param key string The key to create a table for.
function JSON:createTableIfNotExists(key)
    if self:tableExists(key) then
        return
    end
    self.datas[key] = {}
    self:set(self.datas)
end

--- Empty a table's contents.
---@param key string The key to empty.
---@return table
function JSON:empty(key)
    local itemsAmount = table.count(self.datas[key])
    self.datas[key] = {}
    self:set(self.datas)
    return {
        affectedRows = itemsAmount
    }
end

--- Find all records for a given key.
---@param key string The key to find records for.
---@return table
function JSON:findAll(key)
    return self.datas[key] or {}
end

end -- IsDuplicityVersion (json.lua)
