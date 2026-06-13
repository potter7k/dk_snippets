---@alias dk.class fun(defaults: table, parent?: table): Class

--- Cria uma classe com herança, construtores e instâncias.
---@generic T : table
---@param defaults T Tabela com propriedades e valores padrão da classe.
---@param parent? table Classe pai para herança (use `:extend()` como alternativa).
---@return T|table class A nova classe criada.
local function Class(defaults, parent)
    local class = {}
    local defaultProps = {}

    -- Herda métodos e defaults do pai
    if parent then
        for key, value in pairs(parent) do class[key] = value end
        local parentDefaults = rawget(parent, "__defaults")
        if parentDefaults then
            for key, value in pairs(parentDefaults) do defaultProps[key] = value end
        end
    end

    -- Aplica e registra os defaults da classe
    for key, value in pairs(defaults or {}) do
        class[key] = value
        if type(value) ~= "function" then defaultProps[key] = value end
    end

    class.__index = class
    class.__parent = parent
    class.__defaults = defaultProps

    --- Deep copy para evitar compartilhamento de referência entre instâncias.
    local function deepCopy(val)
        if type(val) ~= "table" then return val end
        local copy = {}
        for k, v in pairs(val) do copy[k] = deepCopy(v) end
        return setmetatable(copy, getmetatable(val))
    end

    --- Cria uma nova instância da classe.
    function class:new(...)
        local obj = setmetatable({}, self)
        for key, value in pairs(self.__defaults) do obj[key] = deepCopy(value) end
        if obj.constructor then obj:constructor(...) end
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

return Class
