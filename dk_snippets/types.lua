---@meta

-- Definições LuaLS do dk_snippets (somente editor; o runtime nunca carrega este
-- arquivo — ele NÃO está no fxmanifest).
--
-- USO NOS CONSUMIDORES: o LuaLS não resolve a convenção `@recurso/` do FiveM,
-- então anote o require explicitamente (uma linha):
--   ---@type dk.snippets
--   local snippets = require '@dk_snippets/snippets'
--
-- MANUTENÇÃO: ao criar um módulo novo são 3 toques:
--   1. entrada no `map` do snippets.lua
--   2. `---@field` na classe dk.snippets abaixo
--   3. `---@class`/`---@alias` no próprio módulo (fonte da verdade do tipo)

--- Classe base criada por `snippets.class(...)`.
--- Todas as classes criadas herdam esses métodos automaticamente.
---@class Class
local class = {}

--- Cria uma nova instância da classe. Chama `constructor(...)` se definido.
---@generic T
---@param self T
---@param ... any
---@return T instance
function class:new(...) end

--- Cria uma subclasse que herda métodos e defaults desta classe.
---@generic T
---@param self T
---@param defaults? table
---@return T|Class child
function class:extend(defaults) end

--- Verifica se o objeto é instância de uma determinada classe.
---@param klass table
---@return boolean
function class:instanceof(klass) end

--- Construtor da classe. Sobrescreva nas suas classes.
---@param ... any
function class:constructor(...) end

--- Objeto de jogador retornado pelo framework.
--- Os campos `notify`/`hint`/`request` só existem quando `online == true`
--- (açúcar injetado pelo framework, já conhecendo a source).
---@class Player
---@field online boolean
---@field userId fun(): string|integer|nil
---@field userSource fun(): integer
---@field isAdmin fun(): boolean
---@field hasPermission fun(permission: string): boolean
---@field paymentBank fun(amount: integer): boolean
---@field giveBank fun(amount: integer): boolean
---@field paymentCash? fun(amount: integer): boolean
---@field giveCash? fun(amount: integer): boolean
---@field itemAmount fun(item: string): integer
---@field takeItem fun(item: string, amount: integer, notify: boolean): boolean
---@field giveItem fun(item: string, amount: integer, notify: boolean)
---@field notify fun(mode: string, message: string, duration?: number) Açúcar (online): notifica este jogador.
---@field hint fun(action: string, id: string, description: string, control?: string, configs?: table) Açúcar (online).
---@field request fun(description: string, timer?: number, acceptText?: string, denyText?: string): boolean Açúcar (online).

--- Tabela de funções do framework detectado (retorno de `snippets.framework`).
---@class FWData
---@field getFramework fun(): string
---@field getPlayer fun(source: integer): Player
---@field getPlayerById fun(user_id: string|integer): Player
---@field getPlayersByPermission fun(perm: string): Player[]
---@field _custom? fun(name: string, ...): any

--- Agregador retornado por `require '@dk_snippets/snippets'`.
--- Os tipos dos campos vivem nos próprios módulos (pasta modules/).
---@class dk.snippets
---@field table dk.table          # helpers de tabela (isolados da table nativa)
---@field string dk.string        # helpers de string
---@field number dk.number        # ParseInt / Round
---@field class dk.class          # construtor de classes com herança
---@field cooldown Cooldown       # classe de cooldown (use :new(segundos))
---@field callbacks dk.callbacks  # callbacks client<->server
---@field notify dk.notify        # notify/hint (lado-ciente)
---@field request dk.request      # confirmação com UI (lado-ciente)
---@field json JSON               # storage JSON em arquivo (server-only)
---@field db fun(): SQL           # driver SQL (server-only)
---@field framework FWData        # framework detectado, players decorados (server-only)
local snippets

--- Requer um módulo do dk_snippets ou outro recurso (polyfill ox_lib).
---@param modName string
---@return any
function require(modName) end

return snippets
