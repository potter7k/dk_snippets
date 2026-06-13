local tbl = require '@dk_snippets/modules/shared/table'

--- Registra o framework esx no handler recebido.
---@param FW FWManager
return function(FW)
    FW:set("esx", function()
        local funcs = {}
        local ESX = exports.es_extended:getSharedObject()

        ---Pegar player pela source
        ---@param source integer
        ---@return Player
        function funcs.getPlayer(source)
            local player = ESX.GetPlayerFromId(source)
            if not player then
                return { online = false }
            end
            return {
                online = true,

                userId = function()
                    return player.getIdentifier()
                end,

                userSource = function()
                    return source
                end,

                isAdmin = function()
                    return IsPlayerAceAllowed(source, "command")
                end,

                hasPermission = function(permission)
                    return IsPlayerAceAllowed(source, permission)
                end,

                paymentBank = function(amount)
                    if player.getAccount('bank').money < amount then
                        return false
                    end
                    player.removeAccountMoney('bank', amount)
                    return true
                end,

                giveBank = function(amount)
                    player.addAccountMoney('bank', amount)
                    return true
                end,

                itemAmount = function(item)
                    local itemData = player.getInventoryItem(item)
                    if itemData then
                        return itemData.count or 0
                    end
                    return 0
                end,

                takeItem = function(item, amount, notify)
                    local itemData = player.getInventoryItem(item)
                    if itemData and itemData.count >= amount then
                        player.removeInventoryItem(item, amount)
                        return true
                    end
                    return false
                end,

                giveItem = function(item, amount, notify)
                    player.addInventoryItem(item, amount)
                end
            }
        end

        ---Pegar player pelo id
        ---@param user_id integer
        ---@return Player
        function funcs.getPlayerById(user_id)
            local xPlayers = ESX.GetPlayers()
            for _, source in ipairs(xPlayers) do
                local xPlayer = ESX.GetPlayerFromId(source)
                if xPlayer and xPlayer.identifier == user_id then
                    return funcs.getPlayer(source)
                end
            end
            return { online = false }
        end

        ---Pegar players por permissão
        ---@param perm string
        ---@return Player[]
        function funcs.getPlayersByPermission(perm)
            local players = {}
            local xPlayers = ESX.GetPlayers()
            for _, source in ipairs(xPlayers) do
                if IsPlayerAceAllowed(source, perm) then
                    table.insert(players, source)
                end
            end

            if type(players) ~= "table" then
                return {}
            end

            return tbl.map(players, function(source)
                return funcs.getPlayer(source)
            end, false)
        end

        function funcs.getFramework()
            return "esx"
        end

        return "esx", funcs
    end)
end
