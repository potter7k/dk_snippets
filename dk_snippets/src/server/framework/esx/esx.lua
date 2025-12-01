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
            end,

            --- Pegar quantidade de um item
            --- @param item string
            --- @return integer
            itemAmount = function(item)
                local itemData = player.getInventoryItem(item)
                if itemData then
                    return itemData.count or 0
                end
                return 0
            end,

            --- Remover item do inventário
            --- @param item string
            --- @param amount integer
            --- @param notify boolean
            --- @return boolean
            takeItem = function(item, amount, notify)
                local itemData = player.getInventoryItem(item)
                if itemData and itemData.count >= amount then
                    player.removeInventoryItem(item, amount)
                    return true
                end
                return false
            end,

            --- Gerar item no inventário
            --- @param item string
            --- @param amount integer
            --- @param notify boolean
            giveItem = function(item, amount, notify)
                player.addInventoryItem(item, amount)
            end
        }
    end

    ---Pegar player pelo id
    ---@param user_id integer
    ---@return table | nil
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

    ---Pegar players por permissão
    ---@param perm string
    ---@return table
    function funcs.getPlayersByPermission(perm)
        local players = {}
        local xPlayers = ESX.GetPlayers()
        for _, source in ipairs(xPlayers) do
            if IsPlayerAceAllowed(source, perm) then
                table.insert(players, source)
            end
        end
        return players
    end

    return "esx", funcs
end)