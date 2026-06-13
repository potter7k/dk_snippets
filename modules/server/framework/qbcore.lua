local tbl = require '@dk_snippets/modules/shared/table'

--- Registra o framework qbcore no handler recebido.
---@param FW FWManager
return function(FW)
    FW:set("qbcore", function()
        local funcs = {}
        local QBCore = exports['qb-core']:GetCoreObject()

        ---Pegar player pela source
        ---@param source integer
        ---@return Player
        function funcs.getPlayer(source)
            local player = QBCore.Functions.GetPlayer(source)
            if not player then
                return { online = false }
            end
            return {
                online = true,

                userId = function()
                    return player.PlayerData.citizenid
                end,

                userSource = function()
                    return source
                end,

                isAdmin = function()
                    return QBCore.Functions.HasPermission(source, 'admin') or IsPlayerAceAllowed(source, "command")
                end,

                hasPermission = function(permission)
                    return QBCore.Functions.HasPermission(source, permission) or IsPlayerAceAllowed(source, permission)
                end,

                paymentBank = function(amount)
                    local bankMoney = player.PlayerData.money['bank'] or 0
                    if bankMoney < amount then
                        return false
                    end
                    player.Functions.RemoveMoney('bank', amount, 'dk_snippets-payment')
                    return true
                end,

                giveBank = function(amount)
                    player.Functions.AddMoney('bank', amount, 'dk_snippets-deposit')
                    return true
                end,

                paymentCash = function(amount)
                    local cashMoney = player.PlayerData.money['cash'] or 0
                    if cashMoney < amount then
                        return false
                    end
                    player.Functions.RemoveMoney('cash', amount, 'dk_snippets-payment')
                    return true
                end,

                giveCash = function(amount)
                    player.Functions.AddMoney('cash', amount, 'dk_snippets-cash')
                    return true
                end,

                itemAmount = function(item)
                    local itemData = player.Functions.GetItemByName(item)
                    if itemData then
                        return itemData.amount or 0
                    end
                    return 0
                end,

                takeItem = function(item, amount, notify)
                    local itemData = player.Functions.GetItemByName(item)
                    if itemData and itemData.amount >= amount then
                        player.Functions.RemoveItem(item, amount)
                        if notify then
                            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], 'remove', amount)
                        end
                        return true
                    end
                    return false
                end,

                giveItem = function(item, amount, notify)
                    player.Functions.AddItem(item, amount)
                    if notify then
                        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], 'add', amount)
                    end
                end,

                getJob = function()
                    return player.PlayerData.job
                end,

                getGang = function()
                    return player.PlayerData.gang
                end,

                hasJob = function(jobName)
                    return player.PlayerData.job.name == jobName
                end,

                isOnDuty = function()
                    return player.PlayerData.job.onduty
                end
            }
        end

        ---Pegar player pelo id (citizenid)
        ---@param user_id string
        ---@return Player
        function funcs.getPlayerById(user_id)
            local player = QBCore.Functions.GetPlayerByCitizenId(user_id)
            if player then
                return funcs.getPlayer(player.PlayerData.source)
            end
            return { online = false }
        end

        ---Pegar players por permissão
        ---@param perm string
        ---@return Player[]
        function funcs.getPlayersByPermission(perm)
            local players = {}
            local qbPlayers = QBCore.Functions.GetQBPlayers()
            for src, _ in pairs(qbPlayers) do
                if QBCore.Functions.HasPermission(src, perm) then
                    table.insert(players, src)
                end
            end

            if type(players) ~= "table" then
                return {}
            end

            return tbl.map(players, function(source)
                return funcs.getPlayer(source)
            end, false)
        end

        ---Pegar players por job
        ---@param jobName string
        ---@return table
        function funcs.getPlayersByJob(jobName)
            local players = {}
            local qbPlayers = QBCore.Functions.GetQBPlayers()
            for src, player in pairs(qbPlayers) do
                if player.PlayerData.job.name == jobName then
                    table.insert(players, src)
                end
            end
            return players
        end

        ---Chamadas dinâmicas ao QBCore
        ---@param name string
        ---@vararg any
        ---@return any
        function funcs._custom(name, ...)
            if QBCore.Functions[name] then
                return QBCore.Functions[name](...)
            end
            print("^3[DK Snippets]^7 Função QBCore não encontrada: " .. name)
            return nil
        end

        function funcs.getFramework()
            return "qbcore"
        end

        return "qbcore", funcs
    end)
end
