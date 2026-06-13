local Class = require '@dk_snippets/modules/shared/class'
local number = require '@dk_snippets/modules/shared/number'

---@class Cooldown
--- defaultTimer: tempo padrão do cooldown em milissegundos.
--- timer: timestamp (ms) de quando o cooldown expira.
local Cooldown = Class({
    defaultTimer = 0,
    timer = 0
})

--- Construtor do Cooldown.
---@param timer integer|nil Tempo em segundos (convertido para ms internamente).
function Cooldown:constructor(timer)
    self.defaultTimer = (timer or 0) * 1000
    self.timer = 0
end

--- Inicia o cooldown.
---@param timer integer|nil
function Cooldown:start(timer)
    self.timer = GetGameTimer() + number.ParseInt(timer or self.defaultTimer)
end

--- Reseta o cooldown.
function Cooldown:reset()
    self.timer = 0
end

--- Verifica se está ativo; retorna segundos restantes ou nil.
---@return integer|nil
function Cooldown:check()
    local currentTimer = GetGameTimer()
    if self.timer > currentTimer then
        return number.ParseInt((self.timer - currentTimer) / 1000)
    end
    return nil
end

--- Verifica e cria o cooldown se inativo.
---@param timer integer|nil
---@param func function|nil
---@return boolean
function Cooldown:checkAndCreate(timer, func)
    local seconds = self:check()
    if seconds then
        if type(func) == "function" then func(seconds) end
        return false
    end
    self:start(timer)
    return true
end

return Cooldown
