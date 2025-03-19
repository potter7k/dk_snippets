--- Verificar se o player possui determinada permissão
---@param user_id integer|nil
---@param perm string
---@return boolean
local function hasPermission(user_id, perm)
    if not user_id or not perm then return false end
    return vRP.HasGroup(user_id, perm)
end

---Pegar id do usuário pela source
---@param source integer
---@return any
local function userId(source)
    return vRP.Passport(source)
end

---pegar source do usuário pelo id
---@param user_id integer
---@return any
local function userSource(user_id)
    return vRP.Source(user_id)
end

FW:set("vrp.crnetwork", function()
    local funcs = {}

    ---Pegar player pela source
    ---@param source integer
    ---@return table | nil
    function funcs.getPlayer(source)
        local user_id = userId(source)
        if not user_id then
            return nil
        end
        return {
            online = true,

            --- Pegar identificador do usuário.
            ---@return integer|nil
            userId = function()
                return user_id
            end,

            ---pegar source
            ---@return integer
            userSource = function()
                return source
            end,

            --- Verificar se o player é admin.
            ---@return boolean
            isAdmin = function()
                return hasPermission(user_id, "Admin")
            end,

            --- Pagar usando dinheiro do banco
            ---@param amount integer
            ---@return boolean
            paymentBank = function(amount)
                return vRP.PaymentBank(user_id,amount)
            end,

            --- Adicionar dinheiro ao banco
            ---@param amount integer
            giveBank = function(amount)
                vRP.GiveBank(user_id,amount)
            end
        }
    end

    ---Pegar player pelo id
    ---@param user_id integer
    ---@return table | nil
    function funcs.getPlayerById(user_id)
        local source = userSource(user_id)
        if source then
            return funcs.getPlayer(source)
        end
        return {
            online = false
        }
    end

    return funcs
end)
