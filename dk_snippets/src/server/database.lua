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

--- Register a table and its columns.
---@param name string The name of the table.
---@param columns table The list of columns in the table.
function SQL.registerTable(name, columns)
    SQL.tables[name] = {}
    table.forEach(columns, function(column)
        SQL.tables[name][column] = true
    end)
end

SQL.hasColumn = SQL.columnExists

local handlers = {}

--- Build WHERE clause from conditions.
---@param conditions table The conditions for the WHERE clause.
---@param params table The parameters array to add values to.
---@return string The WHERE clause string.
local function buildWhereClause(conditions, params)
    local clauses = {}

    table.forEach(conditions, function(condition)
        local currentClauses = {}
        table.forEach(condition, function(value, column)
            table.insert(currentClauses, string.format("%s = ?", SQL.escape(column)))
            table.insert(params, value)
        end)
        if #currentClauses > 0 then
            table.insert(clauses, '(' .. table.concat(currentClauses, ' AND ') .. ')')
        end
    end)
    return #clauses > 0 and (' WHERE ' .. table.concat(clauses, ' OR ')) or ''
end

--- Execute a SQL query.
---@param sql string The SQL query to execute.
---@param params table The parameters for the query.
---@return any
function SQL.execute(sql, params)
    return SQL.silent(sql, params)
end

--- Execute a SQL query without raising errors.
---@param sql string The SQL query to execute.
---@param params? table The parameters for the query.
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
---@param tableName string The name of the table.
---@param data table The data to insert.
---@param operation string The SQL operation to perform (default is 'INSERT').
---@return table
function SQL.insert(tableName, data, operation)
    assert(type(tableName) == 'string', "Table name deve ser uma string")
    assert(type(data) == 'table', "Data deve ser uma tabela")
    assert(SQL.hasTable(tableName), "Tabela não existe: " .. tableName)

    local columns, values = {}, {}
    local params = {}

    local context = {table = tableName, data = data}
    if handlers[tableName] then
        handlers[tableName](context)
    end

    table.forEach(context.data, function(value, column)
        if SQL.columnExists(tableName, column) then
            table.insert(columns, SQL.escape(column))
            table.insert(values, '?')
            table.insert(params, value)
        end
    end)

    assert(#columns > 0, "Nenhuma coluna válida encontrada para inserção")

    local columns_str = table.concat(columns, ', ')
    local values_str = table.concat(values, ', ')

    local code = string.format('%s INTO %s (%s) VALUES (%s)',
        operation or 'INSERT',
        SQL.escape(context.table),
        columns_str,
        values_str
    )
    local success, result = pcall(function()
        return SQL.execute(code, params)
    end)
    if not success then
        print("Erro ao inserir dados na tabela:", tableName, data, result)
    end
    return success and result or {
        affectedRows = 0
    }
end

--- Update data in a table.
---@param tableName string The name of the table.
---@param data table The data to update.
---@param where table The conditions for the update.
---@return table
function SQL.update(tableName, data, where)
    assert(type(tableName) == 'string', "Table name deve ser uma string")
    assert(type(data) == 'table', "Data deve ser uma tabela")
    assert(type(where) == 'table', "Where deve ser uma tabela")
    assert(SQL.hasTable(tableName), "Tabela não existe: " .. tableName)

    local sets = {}
    local params = {}

    local context = {table = tableName, data = data, where = where}
    if handlers[tableName] then
        handlers[tableName](context)
    end

    table.forEach(context.data, function(value, column)
        if SQL.columnExists(tableName, column) then
            table.insert(sets, string.format("%s = ?", SQL.escape(column)))
            table.insert(params, value)
        end
    end)

    assert(#sets > 0, "Nenhuma coluna válida encontrada para atualização")

    local where_str = buildWhereClause(context.where, params)

    local sets_str = table.concat(sets, ', ')
    local code = string.format('UPDATE %s SET %s%s',
        SQL.escape(context.table),
        sets_str,
        where_str
    )

    local success, result = pcall(function()
        return SQL.execute(code, params)
    end)
    return success and result or {
        affectedRows = 0
    }
end

--- Select data from a table with conditions.
---@param tableName string The name of the table.
---@param conditions table The conditions for the selection.
---@param columns? string|table The columns to select (default is '*').
---@param limit? number The maximum number of rows to return.
---@param offset? number The number of rows to skip.
---@param order_by? string The column to order by.
---@param order_direction? string The direction to order ('ASC' or 'DESC').
---@return table
function SQL.select(tableName, conditions, columns, limit, offset, order_by, order_direction)
    assert(type(tableName) == 'string', "Table name deve ser uma string")
    assert(type(conditions) == 'table', "Conditions deve ser uma tabela")
    assert(SQL.hasTable(tableName), "Tabela não existe: " .. tableName)

    local params = {}
    local where_str = buildWhereClause(conditions, params)

    -- Build SELECT statement
    local columns_str = '*'
    if columns then
        if type(columns) == 'string' then
            columns_str = columns
        elseif type(columns) == 'table' then
            local escaped_columns = {}
            for _, column in ipairs(columns) do
                if SQL.columnExists(tableName, column) then
                    table.insert(escaped_columns, SQL.escape(column))
                end
            end
            columns_str = table.concat(escaped_columns, ', ')
        end
    end

    local code = string.format('SELECT %s FROM %s%s',
        columns_str,
        SQL.escape(tableName),
        where_str
    )

    -- Add ORDER BY clause
    if order_by and SQL.columnExists(tableName, order_by) then
        local direction = order_direction and string.upper(order_direction) == 'DESC' and 'DESC' or 'ASC'
        code = code .. string.format(' ORDER BY %s %s', SQL.escape(order_by), direction)
    end

    -- Add LIMIT and OFFSET
    if limit and type(limit) == 'number' and limit > 0 then
        code = code .. string.format(' LIMIT %d', limit)
        if offset and type(offset) == 'number' and offset >= 0 then
            code = code .. string.format(' OFFSET %d', offset)
        end
    end

    local success, result = pcall(function()
        return SQL.execute(code, params)
    end)
    return success and result or {}
end

--- Select data from a table with conditions (alias for SQL.select).
---@param tableName string The name of the table.
---@param conditions table The conditions for the selection.
---@param columns? string|table The columns to select (default is '*').
---@param limit? number The maximum number of rows to return.
---@param offset? number The number of rows to skip.
---@param order_by? string The column to order by.
---@param order_direction? string The direction to order ('ASC' or 'DESC').
---@return table
function SQL.where(tableName, conditions, columns, limit, offset, order_by, order_direction)
    return SQL.select(tableName, conditions, columns, limit, offset, order_by, order_direction)
end

--- Delete data from a table with conditions.
---@param tableName string The name of the table.
---@param conditions table The conditions for the deletion.
---@return table
function SQL.delete(tableName, conditions)
    assert(type(tableName) == 'string', "Table name deve ser uma string")
    assert(type(conditions) == 'table', "Conditions deve ser uma tabela")
    assert(SQL.hasTable(tableName), "Tabela não existe: " .. tableName)

    local params = {}
    local context = {table = tableName, where = conditions}
    if handlers[tableName] then
        handlers[tableName](context)
    end

    local where_str = buildWhereClause(context.where, params)
    assert(where_str ~= "", "Condições WHERE inválidas")

    local code = string.format('DELETE FROM %s%s',
        SQL.escape(context.table),
        where_str
    )

    local success, result = pcall(function()
        return SQL.execute(code, params)
    end)
    return success and result or {}
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
