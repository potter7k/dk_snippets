assert(IsDuplicityVersion(), 'dk_snippets: módulo "db" é server-only')

local tbl = require '@dk_snippets/modules/shared/table'

---@class SQL
local SQL = {}
setmetatable(SQL, SQL)

SQL.drivers = {}

--- Registra um novo driver SQL.
---@param name string
---@param callback function
function SQL.registerDriver(name, callback)
    table.insert(SQL.drivers, { name, callback })
end

SQL.tables = {}

--- Verifica se uma tabela existe.
---@param name string
---@return boolean
function SQL.hasTable(name)
    return SQL.tables[name] ~= nil
end

--- Verifica se uma coluna existe numa tabela.
---@param table string
---@param column string
---@return boolean
function SQL.columnExists(table, column)
    return SQL.tables[table] and SQL.tables[table][column]
end

--- Registra uma tabela e suas colunas.
---@param name string
---@param columns table
function SQL.registerTable(name, columns)
    SQL.tables[name] = {}
    tbl.forEach(columns, function(column)
        SQL.tables[name][column] = true
    end)
end

SQL.hasColumn = SQL.columnExists

local handlers = {}

--- Constrói a cláusula WHERE.
---@param conditions table
---@param params table
---@return string
local function buildWhereClause(conditions, params)
    local clauses = {}

    tbl.forEach(conditions, function(condition)
        local currentClauses = {}
        tbl.forEach(condition, function(value, column)
            table.insert(currentClauses, string.format("%s = ?", SQL.escape(column)))
            table.insert(params, value)
        end)
        if #currentClauses > 0 then
            table.insert(clauses, '(' .. table.concat(currentClauses, ' AND ') .. ')')
        end
    end)
    return #clauses > 0 and (' WHERE ' .. table.concat(clauses, ' OR ')) or ''
end

--- Executa uma query SQL.
---@param sql string
---@param params table
---@return any
function SQL.execute(sql, params)
    return SQL.silent(sql, params)
end

--- Executa uma query SQL sem levantar erros silenciosamente.
---@param sql string
---@param params? table
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

--- Escapa um valor para uso numa query.
---@param value any
---@return string
function SQL.escape(value)
    local safe = tostring(value):gsub("'", "''"):gsub("\\", "\\\\")
    return string.format("`%s`", safe)
end

--- Insere dados numa tabela.
---@param tableName string
---@param data table
---@param operation? string
---@return table
function SQL.insert(tableName, data, operation)
    assert(type(tableName) == 'string', "Table name deve ser uma string")
    assert(type(data) == 'table', "Data deve ser uma tabela")
    assert(SQL.hasTable(tableName), "Tabela não existe: " .. tableName)

    local columns, values = {}, {}
    local params = {}

    local context = { table = tableName, data = data }
    if handlers[tableName] then
        handlers[tableName](context)
    end

    tbl.forEach(context.data, function(value, column)
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
    return success and result or { affectedRows = 0 }
end

--- Atualiza dados numa tabela.
---@param tableName string
---@param data table
---@param where table
---@return table
function SQL.update(tableName, data, where)
    assert(type(tableName) == 'string', "Table name deve ser uma string")
    assert(type(data) == 'table', "Data deve ser uma tabela")
    assert(type(where) == 'table', "Where deve ser uma tabela")
    assert(SQL.hasTable(tableName), "Tabela não existe: " .. tableName)

    local sets = {}
    local params = {}

    local context = { table = tableName, data = data, where = where }
    if handlers[tableName] then
        handlers[tableName](context)
    end

    tbl.forEach(context.data, function(value, column)
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
    return success and result or { affectedRows = 0 }
end

--- Seleciona dados de uma tabela com condições.
---@param tableName string
---@param conditions table
---@param columns? string|table
---@param limit? number
---@param offset? number
---@param order_by? string
---@param order_direction? string
---@return table
function SQL.select(tableName, conditions, columns, limit, offset, order_by, order_direction)
    assert(type(tableName) == 'string', "Table name deve ser uma string")
    assert(type(conditions) == 'table', "Conditions deve ser uma tabela")
    assert(SQL.hasTable(tableName), "Tabela não existe: " .. tableName)

    local params = {}
    local where_str = buildWhereClause(conditions, params)

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

    if order_by and SQL.columnExists(tableName, order_by) then
        local direction = order_direction and string.upper(order_direction) == 'DESC' and 'DESC' or 'ASC'
        code = code .. string.format(' ORDER BY %s %s', SQL.escape(order_by), direction)
    end

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

--- Alias para SQL.select.
---@param tableName string
---@param conditions table
---@param columns? string|table
---@param limit? number
---@param offset? number
---@param order_by? string
---@param order_direction? string
---@return table
function SQL.where(tableName, conditions, columns, limit, offset, order_by, order_direction)
    return SQL.select(tableName, conditions, columns, limit, offset, order_by, order_direction)
end

--- Deleta dados de uma tabela com condições.
---@param tableName string
---@param conditions table
---@return table
function SQL.delete(tableName, conditions)
    assert(type(tableName) == 'string', "Table name deve ser uma string")
    assert(type(conditions) == 'table', "Conditions deve ser uma tabela")
    assert(SQL.hasTable(tableName), "Tabela não existe: " .. tableName)

    local params = {}
    local context = { table = tableName, where = conditions }
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

--- Driver oxmysql.
SQL.registerDriver('oxmysql', function(promise, sql, params)
    promise:resolve(exports["oxmysql"]:query_async(sql, params))
end)

--- Driver ghmattimysql.
SQL.registerDriver('ghmattimysql', function(promise, sql, params)
    exports["ghmattimysql"]:execute(sql, params, function(result)
        promise:resolve(result)
    end)
end)

--- Driver GHMattiMySQL.
SQL.registerDriver('GHMattiMySQL', function(promise, sql, params)
    exports["GHMattiMySQL"]:QueryResultAsync(sql, params, function(result)
        promise:resolve(result)
    end)
end)

--- Driver mysql-async.
SQL.registerDriver('mysql-async', function(promise, sql, params)
    exports['mysql-async']:mysql_fetch_all(sql, params, function(result)
        promise:resolve(result)
    end)
end)

--- Carrega as tabelas e colunas do banco.
local function loadTables()
    local rows = SQL.silent("SELECT TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()")

    if not rows or #rows == 0 then
        print("[SQL Warning] Nenhuma tabela encontrada no banco de dados.")
        return
    end

    for _, row in ipairs(rows) do
        local tableName = row.TABLE_NAME
        local columnName = row.COLUMN_NAME
        if tableName and columnName then
            if not SQL.tables[tableName] then
                SQL.tables[tableName] = {}
            end
            SQL.tables[tableName][columnName] = true
        end
    end
end

--- Inicializa o driver SQL e retorna a interface SQL.
---@return SQL
local function DB()
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

return DB
