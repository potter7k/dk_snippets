FW:set("esx", function()
    local funcs = {}
    local ESX = exports.es_extended:getSharedObject()

    function funcs.getPlayer(source)
        local player = ESX.GetPlayerFromId(source)
        if not player then
            return nil
        end
        return {
            online = true,

            --- Pegar identificador do usuário.
            ---@return integer|nil
            userId = function()
                return player.getIdentifier()
            end,

            ---pegar source
            ---@return integer
            userSource = function()
                return source
            end,

            --- Verificar se o player é admin.
            ---@return boolean
            isAdmin = function()
                return IsPlayerAceAllowed(source, "command")
            end,

            --- Pagar usando dinheiro do banco
            ---@param amount integer
            ---@return boolean
            paymentBank = function(amount)
                if player.getAccount('bank').money < amount then
                    return false
                end
                player.removeAccountMoney('bank', amount)
                return true
            end,

            --- Adicionar dinheiro ao banco
            ---@param amount integer
            giveBank = function(amount)
                player.addAccountMoney('bank', amount)
                return true
            end
        }
    end

    function funcs.getPlayerById(user_id)
        local xPlayers = ESX.GetPlayers()
        for _, source in ipairs(xPlayers) do
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer and xPlayer.identifier == user_id then
                return funcs.getPlayer(source)
            end
        end
        return {
            online = false
        }
    end

    return "esx", funcs
end)