---@class SQL

local SQL = {}
setmetatable(SQL, SQL)

SQL.drivers = {}

--- Register a new SQL driver.
---@param name string The name of the driver.
---@param callback function The callback function to handle the driver.
function SQL.registerDriver(name, callback)
    table.insert(SQL.drivers, {name, callback})
end

SQL.tables = {}

--- Check if a table exists.
---@param name string The name of the table.
---@return boolean
function SQL.hasTable(name)
    return SQL.tables[name] ~= nil
end

--- Check if a column exists in a table.
---@param table string The name of the table.
---@param column string The name of the column.
---@return boolean
function SQL.columnExists(table, column)
    return SQL.tables[table] and SQL.tables[table][column]
end

SQL.hasColumn = SQL.columnExists

local handlers = {}

--- Execute a SQL query.
---@param sql string The SQL query to execute.
---@param params table The parameters for the query.
---@return any
function SQL.execute(sql, params)
    return SQL.silent(sql, params)
end

--- Execute a SQL query without raising errors.
---@param sql string The SQL query to execute.
---@param params table The parameters for the query.
---@return any
function SQL.silent(sql, params)
    if SQL.driver then
        local p = promise.new()
        SQL.driver(p, sql, params or {})
        local result = Citizen.Await(p)
        if not result then
            print('[SQL Error] Query failed:', sql, json.encode(params))
            error('Resultado inesperado no SQL.')
        end
        return result
    end
    error('Driver SQL não encontrado.')
end

--- Escape a value for use in a SQL query.
---@param value any The value to escape.
---@return string
function SQL.escape(value)
    local safe = tostring(value):gsub("'", "''"):gsub("\\", "\\\\")
    return string.format("`%s`", safe)
end

--- Insert data into a table.
---@param table_name string The name of the table.
---@param data table The data to insert.
---@param operation string The SQL operation to perform (default is 'INSERT').
---@return table
function SQL.insert(table_name, data, operation)
    assert(type(data) == 'table', "Data deve ser uma tabela")
    local columns, values = {}, {}
    local params = {}

    local context = {table = table_name, data = data}
    if handlers[table_name] then
        handlers[table_name](context)
    end
    table.forEach(context.data, function(value, column)
        if SQL.columnExists(table_name, column) then
            table.insert(columns, SQL.escape(column))
            table.insert(values, '?')
            table.insert(params, value)
        end
    end)

    local columns_str = table.concat(columns, ', ')
    local values_str = table.concat(values, ', ')

    local code = string.format('%s INTO %s (%s) VALUES (%s)',
        operation or 'INSERT',
        SQL.escape(context.table),
        columns_str,
        values_str
    )

    return SQL.execute(code, params)
end

--- Register a driver for oxmysql.
SQL.registerDriver('oxmysql', function(promise, sql, params)
    promise:resolve(exports["oxmysql"]:query_async(sql, params))
end)

--- Register a driver for ghmattimysql.
SQL.registerDriver('ghmattimysql', function(promise, sql, params)
    exports["ghmattimysql"]:execute(sql, params, function(result)
        promise:resolve(result)
    end)
end)

--- Register a driver for GHMattiMySQL.
SQL.registerDriver('GHMattiMySQL', function(promise, sql, params)
    exports["GHMattiMySQL"]:QueryResultAsync(sql, params, function(result)
        promise:resolve(result)
    end)
end)

--- Register a driver for mysql-async.
SQL.registerDriver('mysql-async', function(promise, sql, params)
    exports['mysql-async']:mysql_fetch_all(sql, params, function(result)
        promise:resolve(result)
    end)
end)

--- Load the tables and their columns from the database.
local function loadTables()
    local tables = SQL.silent([[
        SELECT table_name as t, column_name as c FROM information_schema.columns WHERE 
        table_schema = DATABASE()
    ]])

    table.forEach(tables, function(tbl)
        local table, column = tbl.t, tbl.c

        if not SQL.tables[table] then
            SQL.tables[table] = {}
        end

        SQL.tables[table][column] = true
    end)
end

--- Initialize the SQL driver.
---@return SQL
function DB()
    if SQL.driver then return SQL end

    for _, driver in ipairs(SQL.drivers) do
        if GetResourceState(driver[1]) == 'started' then
            SQL.driver = driver[2]

            loadTables()

            print("[INFO] Driver SQL iniciado:", driver[1])
            return SQL
        end
    end
    error("[ERRO] Nenhum driver SQL compatível encontrado.")
end

exports("DB", DB)
