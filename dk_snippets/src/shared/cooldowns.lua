---@class Cooldown
Cooldown = {}
Cooldown.__index = Cooldown

--- Create a cooldown class.
---@param timer integer|nil
---@return Cooldown
function Cooldown:new(timer)
    local obj = setmetatable({}, self)

    obj.defaultTimer = (timer or 0) * 1000
    obj.timer = 0

    return obj
end

--- Start a cooldown.
---@param timer integer|nil
function Cooldown:start(timer)
    self.timer = GetGameTimer() + ParseInt(timer or self.defaultTimer)
end

--- Reset the cooldown.
function Cooldown:reset()
    self.timer = 0
end

--- Check if the cooldown is active, if so, return the remaining time.
---@return integer|nil
function Cooldown:check()
    local currentTimer = GetGameTimer()
    if self.timer > currentTimer then
        return ParseInt((self.timer - currentTimer) / 1000)
    end

    return nil
end

--- Check if cooldown is active, and create cooldown if not. 
---@param timer integer|nil
---@param func function|nil
---@return boolean
function Cooldown:checkAndCreate(timer, func)
    local seconds = self:check()
    if seconds then
        if type(func) == "function" then
            func(seconds)
        end
        return false
    end
    self:start(timer)
    return true
end