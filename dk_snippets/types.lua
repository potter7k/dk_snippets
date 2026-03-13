---@meta

---@class Class
---@field new fun(self: Class, ...: any): table
---@field constructor fun(self: table, ...: any)

--- `server`
--- Detectar framework, e pegar funções
---@return string, FWData
function exports.dk_snippets:framework() end

--- `server`
--- Pegar funções driver banco de dados
--- @return SQL
function exports.dk_snippets:DB() end