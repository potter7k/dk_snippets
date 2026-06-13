assert(IsDuplicityVersion(), 'dk_snippets: módulo "json" é server-only')

local A = require '@dk_snippets/modules/shared/assert'
local tbl = require '@dk_snippets/modules/shared/table'

---@class JSON
local JSON = {
    nextId = {},
    target = { dir = nil, path = nil },
    datas = {}
}
JSON.__index = JSON

--- Carrega dados de um arquivo JSON e inicializa o objeto.
---@param filePath string
---@return JSON
function JSON:fetch(filePath)
    local obj = setmetatable({}, self)

    obj.nextId = {}
    obj.target = {
        dir = GetCurrentResourceName(),
        path = filePath
    }

    local resFile = LoadResourceFile(obj.target.dir, obj.target.path .. ".json")
    if type(resFile) ~= "string" then
        error("Erro ao carregar JSON, arquivo " .. obj.target.path .. " não encontrado.")
    end

    obj.datas = json.decode(resFile) or {}

    -- Inicializa nextId com o maior id existente + 1
    tbl.forEach(obj.datas, function(records, key)
        if not obj:hasColumn(key, "id") then return end

        if not obj.nextId[key] then
            obj.nextId[key] = 1
        end
        tbl.forEach(records, function(item)
            if not item.id then return end
            if item.id >= obj.nextId[key] then
                obj.nextId[key] = item.id + 1
            end
        end)
    end)

    return obj
end

--- Salva dados no arquivo JSON.
---@param datas table
function JSON:set(datas)
    A.Ensure(datas, { "table" })
    SaveResourceFile(self.target.dir, self.target.path .. ".json", json.encode(datas, { indent = true }), -1)
end

--- Filtra dados por critério.
---@param key string
---@param data table
---@param keepIndex boolean
---@return table
function JSON:where(key, data, keepIndex)
    A.Ensure(key, { "string", "number" }) A.Ensure(data, { "table" })

    if not self.datas[key] then return {} end

    return tbl.find(self.datas[key], function(item)
        for targetKey, targetVal in pairs(data) do
            if item[targetKey] ~= targetVal then
                return false
            end
        end
        return true
    end, keepIndex)
end

--- Insere um registro com id auto-incremento.
---@param key string
---@param data table
---@param ignoreId? boolean
---@return table
function JSON:insert(key, data, ignoreId)
    if not self.datas[key] then
        self.datas[key] = {}
    end
    local tableDatas = self.datas[key]
    if tbl.count(tableDatas) < 1 and not ignoreId then
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

--- Aumenta o valor default de uma coluna.
---@param key string
---@param column string
---@param val any
---@param force boolean
---@return table
function JSON:increaseDefault(key, column, val, force)
    if not self.datas[key] then return { affectedRows = 0 } end

    local itemsToUpdate = self.datas[key]
    if not force then
        itemsToUpdate = tbl.find(self.datas[key], function(item)
            return item[column] == nil
        end, true)
    end

    local itemsAmount = tbl.count(itemsToUpdate)
    if itemsAmount < 1 then return { affectedRows = 0 } end

    tbl.forEach(itemsToUpdate, function(_, i)
        self.datas[key][i][column] = val
    end)

    self:set(self.datas)
    return { affectedRows = itemsAmount }
end

--- Atualiza registros por critério.
---@param key string
---@param data table
---@param newData table
---@param replace boolean
---@return table
function JSON:update(key, data, newData, replace)
    if not self.datas[key] then return { affectedRows = 0 } end

    local itemsToUpdate = self:where(key, data, true)
    local itemsAmount = tbl.count(itemsToUpdate)
    if itemsAmount < 1 then return { affectedRows = 0 } end

    tbl.forEach(itemsToUpdate, function(_, i)
        if replace then
            self.datas[key][i] = newData
        else
            for k, v in pairs(newData) do
                self.datas[key][i][k] = v
            end
        end
    end)

    self:set(self.datas)
    return { affectedRows = itemsAmount }
end

--- Deleta registros por critério.
---@param key string
---@param data table
---@return table
function JSON:delete(key, data)
    if not self.datas[key] then return { affectedRows = 0 } end

    local itemsToDelete = self:where(key, data, true)
    local itemsAmount = tbl.count(itemsToDelete)
    if itemsAmount < 1 then return { affectedRows = 0 } end

    local indicesToDelete = {}
    for i, _ in pairs(itemsToDelete) do
        table.insert(indicesToDelete, i)
    end

    table.sort(indicesToDelete, function(a, b) return a > b end)

    for _, i in ipairs(indicesToDelete) do
        table.remove(self.datas[key], i)
    end

    self:set(self.datas)
    return { affectedRows = itemsAmount }
end

--- Verifica se uma coluna existe.
---@param key string
---@param column string
---@return boolean
function JSON:hasColumn(key, column)
    if not self.datas[key] then return false end
    local _, firstVal = next(self.datas[key])
    if not firstVal then return true end
    return firstVal[column] ~= nil
end

--- Verifica se uma tabela existe para a key.
---@param key string
---@return boolean
function JSON:tableExists(key)
    return type(self.datas[key]) == "table"
end

--- Cria uma tabela se não existir.
---@param key string
function JSON:createTableIfNotExists(key)
    if self:tableExists(key) then return end
    self.datas[key] = {}
    self:set(self.datas)
end

--- Esvazia o conteúdo de uma tabela.
---@param key string
---@return table
function JSON:empty(key)
    local itemsAmount = tbl.count(self.datas[key])
    self.datas[key] = {}
    self:set(self.datas)
    return { affectedRows = itemsAmount }
end

--- Retorna todos os registros de uma key.
---@param key string
---@return table
function JSON:findAll(key)
    return self.datas[key] or {}
end

return JSON
