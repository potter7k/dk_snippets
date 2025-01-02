---@class JSON

JSON = {}
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
    obj.datas = json.decode(LoadResourceFile(obj.target.dir, obj.target.path..".json")) or {}

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

    SaveResourceFile(self.target.dir, self.target.path..".json", json.encode(datas), -1)
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
function JSON:insert(key, data)
    if not self.datas[key] then
        self.datas[key] = {}
    end
    if not data.id and self.nextId[key] then
        data.id = self.nextId[key]
        self.nextId[key] = self.nextId[key] + 1
    end
    table.insert(self.datas[key], data)
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
