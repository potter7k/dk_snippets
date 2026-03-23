---@meta

--- Classe base criada por `Class()`.
--- Todas as classes criadas herdam esses métodos automaticamente.
---
--- ### Criando uma classe
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
--- ```
---
--- ### Herança com `extend`
--- ```lua
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
---@class Class
local class = {}

--- Cria uma nova instância da classe.
--- Chama `constructor(...)` automaticamente se definido.
---@generic T
---@param self T
---@param ... any Argumentos passados ao `constructor`.
---@return T instance Nova instância da classe.
function class:new(...) end

--- Cria uma subclasse que herda métodos e defaults desta classe.
---@generic T
---@param self T
---@param defaults? table Propriedades e valores padrão da subclasse.
---@return T|Class child Subclasse com herança completa.
function class:extend(defaults) end

--- Verifica se o objeto é instância de uma determinada classe (percorre a cadeia de herança).
---@param klass table A classe a ser verificada.
---@return boolean isInstance `true` se o objeto descende da classe informada.
function class:instanceof(klass) end

--- Construtor da classe. Sobrescreva nas suas classes para inicializar propriedades.
--- Chamado automaticamente por `:new(...)`.
---@param ... any Argumentos recebidos de `:new(...)`.
function class:constructor(...) end

--- Cria uma nova classe com suporte a herança, construtores e instanciação.
---
--- ### Uso básico
--- ```lua
--- ---@class MyClass : Class
--- ---@field hp number
--- local MyClass = Class({ hp = 100 })
---
--- function MyClass:constructor(hp)
---     self.hp = hp
--- end
--- ```
---@generic T : table
---@param defaults T Tabela com propriedades e valores padrão da classe.
---@param parent? Class Classe pai para herança (use `:extend()` como alternativa).
---@return T|Class class A nova classe criada.
function Class(defaults, parent) end

--- `server`
--- Detectar framework, e pegar funções
---@return string, FWData
function exports.dk_snippets:framework() end

--- `server`
--- Pegar funções driver banco de dados
--- @return SQL
function exports.dk_snippets:DB() end