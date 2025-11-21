--- Verificar se o player possui determinada permissão
---@param user_id integer|nil
---@param perm string
---@return boolean
local function hasPermission(user_id, perm)
    if not user_id or not perm then return false end
    return vRP.hasPermission(user_id, perm)
end

---Pegar id do usuário pela source
---@param source integer
---@return integer | nil
local function userId(source)
    return vRP.getUserId(source)
end

---pegar source do usuário pelo id
---@param user_id integer
---@return integer | nil
local function userSource(user_id)
    return vRP.userSource(user_id)
end

FW:set("vrp.vrpex", function()
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
                return hasPermission(user_id, "admin.permissao")
            end,

            --- Pagar usando dinheiro do banco
            ---@param amount integer
            ---@return boolean
            paymentBank = function(amount)
                return vRP.tryFullPayment(user_id,amount)
            end,

            --- Adicionar dinheiro ao banco
            ---@param amount integer
            giveBank = function(amount)
                vRP.giveBankMoney(user_id,amount)
            end,

            --- Pegar quantidade de um item
            --- @param item string
            --- @return integer
            itemAmount = function(item)
                return vRP.getInventoryItemAmount(user_id, item) or 0
            end,

            --- Remover item do inventário
            --- @param item string
            --- @param amount integer
            --- @param notify boolean
            --- @return boolean
            takeItem = function(item, amount, notify)
                return vRP.tryGetInventoryItem(user_id, item, amount, notify)
            end,

            --- Gerar item no inventário
            --- @param item string
            --- @param amount integer
            --- @param notify boolean
            generateItem = function(item, amount, notify)
                vRP.giveInventoryItem(user_id, item, amount, notify)
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

    ---Pegar players por permissão
    ---@param perm string
    ---@return table 
    function funcs.getPlayersByPermission(perm)
        local players = {}
        local list = vRP.getUsersByPermission(perm) or {}
        for _, id in pairs(list) do
            table.insert(players, userSource(id))
        end
        return players
    end

    return funcs
end)
