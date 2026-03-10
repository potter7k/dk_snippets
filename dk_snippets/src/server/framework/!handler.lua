---@class Player
---@field online boolean
---@field userId fun(): string | nil
---@field userSource fun(): integer
---@field isAdmin fun(): boolean
---@field paymentBank fun(amount: integer): boolean
---@field giveBank fun(amount: integer): boolean
---@field paymentCash fun(amount: integer): boolean
---@field giveCash fun(amount: integer): boolean
---@field itemAmount fun(item: string): integer
---@field takeItem fun(item: string, amount: integer, notify: boolean): boolean
---@field giveItem fun(item: string, amount: integer, notify: boolean): boolean

---@class FWData
---@field getFramework fun(): string
---@field getPlayer fun(source: integer): Player | nil
---@field getPlayerById fun(user_id: string): Player | nil
---@field getPlayersByPermission fun(perm: string): Player[]
---@field _custom? fun(...): any

FW = {
    list = {},
    versions = {},
}

---@type nil|{[1]: string, [2]: FWData}
local fwFallback = nil

local supportedFrameworks = {
    ["vrp"] = function() return FW:get("vrp") end,
    ["es_extended"] = function() return FW:get("esx") end,
    ["qb-core"] = function() return FW:get("qbcore") end
}

--- Register a top-level framework handler.
--- The callback must return (string, FWData).
---@param name string
---@param func fun(): string, FWData
function FW:set(name, func)
    self.list[name] = func
end

--- Get a top-level framework by name.
---@param name string
---@return string, FWData
function FW:get(name)
    assert(self.list[name], "[FW] Framework não registrado: " .. name)
    return self.list[name]()
end

--- Register a framework version/variant handler.
--- The callback must return only FWData.
---@param name string
---@param func fun(): FWData
function FW:setVersion(name, func)
    self.versions[name] = func
end

--- Get a framework version/variant by name.
---@param name string
---@return FWData
function FW:getVersion(name)
    assert(self.versions[name], "[FW] Versão de framework não registrada: " .. name)
    return self.versions[name]()
end

---@return {[1]: string, [2]: FWData}
local function getFramework()
    for name, handler in pairs(supportedFrameworks) do
        if GetResourceState(name) ~= 'missing' then
            local fwName, data = handler()

            if type(fwName) ~= "string" or type(data) ~= "table" then
                print("[WARN] Framework " .. name .. " detectado, mas não está online.")
                goto continue
            end

            return {fwName, data}
        end

        ::continue::
    end

    local name, data = FW:get("_nofw")
    return {name, data}
end

function Framework()
    if fwFallback then
        return table.unpack(fwFallback)
    end

    fwFallback = getFramework()

    print("[INFO] Framework detectado: " .. fwFallback[1])

    return table.unpack(fwFallback)
end

exports("framework", Framework)
