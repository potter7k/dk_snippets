-- Registry de frameworks (substitui o global FW do modelo antigo).

---@class FWData
---@field getFramework fun(): string
---@field getPlayer fun(source: integer): table
---@field getPlayerById fun(user_id: string|integer): table
---@field getPlayersByPermission fun(perm: string): table[]
---@field _custom? fun(...): any

---@class FWManager
---@field list table<string, fun(): string, FWData>
---@field versions table<string, fun(): FWData>

--- Cria um novo registry de frameworks.
---@return FWManager
local function newHandler()
    local FW = { list = {}, versions = {} }

    --- Registra um framework de topo. O callback deve retornar (string, FWData).
    ---@param name string
    ---@param func fun(): string, FWData
    function FW:set(name, func)
        self.list[name] = func
    end

    --- Obtém um framework de topo pelo nome.
    ---@param name string
    ---@return string, FWData
    function FW:get(name)
        assert(self.list[name], "[FW] Framework não registrado: " .. name)
        return self.list[name]()
    end

    --- Registra uma versão/variante. O callback deve retornar apenas FWData.
    ---@param name string
    ---@param func fun(): FWData
    function FW:setVersion(name, func)
        self.versions[name] = func
    end

    --- Obtém uma versão/variante pelo nome.
    ---@param name string
    ---@return FWData
    function FW:getVersion(name)
        assert(self.versions[name], "[FW] Versão não registrada: " .. name)
        return self.versions[name]()
    end

    return FW
end

return newHandler
