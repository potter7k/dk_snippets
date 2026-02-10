FW:set("qbcore", function()
    local funcs = {}
    local QBCore = exports['qb-core']:GetCoreObject()

    ---Pegar player pela source
    ---@param source integer
    ---@return table | nil
    function funcs.getPlayer(source)
        local player = QBCore.Functions.GetPlayer(source)
        if not player then
            return nil
        end
        return {
            online = true,

            --- Pegar identificador do usuário.
            ---@return string|nil
            userId = function()
                return player.PlayerData.citizenid
            end,

            ---pegar source
            ---@return integer
            userSource = function()
                return source
            end,

            --- Verificar se o player é admin.
            ---@return boolean
            isAdmin = function()
                return QBCore.Functions.HasPermission(source, 'admin') or IsPlayerAceAllowed(source, "command")
            end,

            --- Pagar usando dinheiro do banco
            ---@param amount integer
            ---@return boolean
            paymentBank = function(amount)
                local bankMoney = player.PlayerData.money['bank'] or 0
                if bankMoney < amount then
                    return false
                end
                player.Functions.RemoveMoney('bank', amount, 'dk_snippets-payment')
                return true
            end,

            --- Adicionar dinheiro ao banco
            ---@param amount integer
            ---@return boolean
            giveBank = function(amount)
                player.Functions.AddMoney('bank', amount, 'dk_snippets-deposit')
                return true
            end,

            --- Pagar usando dinheiro em mãos (cash)
            ---@param amount integer
            ---@return boolean
            paymentCash = function(amount)
                local cashMoney = player.PlayerData.money['cash'] or 0
                if cashMoney < amount then
                    return false
                end
                player.Functions.RemoveMoney('cash', amount, 'dk_snippets-payment')
                return true
            end,

            --- Adicionar dinheiro em mãos (cash)
            ---@param amount integer
            ---@return boolean
            giveCash = function(amount)
                player.Functions.AddMoney('cash', amount, 'dk_snippets-cash')
                return true
            end,

            --- Pegar quantidade de um item
            ---@param item string
            ---@return integer
            itemAmount = function(item)
                local itemData = player.Functions.GetItemByName(item)
                if itemData then
                    return itemData.amount or 0
                end
                return 0
            end,

            --- Remover item do inventário
            ---@param item string
            ---@param amount integer
            ---@param notify boolean
            ---@return boolean
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

            --- Gerar item no inventário
            ---@param item string
            ---@param amount integer
            ---@param notify boolean
            giveItem = function(item, amount, notify)
                player.Functions.AddItem(item, amount)
                if notify then
                    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], 'add', amount)
                end
            end,

            --- Pegar job do jogador
            ---@return table
            getJob = function()
                return player.PlayerData.job
            end,

            --- Pegar gang do jogador
            ---@return table
            getGang = function()
                return player.PlayerData.gang
            end,

            --- Verificar se o jogador possui determinado job
            ---@param jobName string
            ---@return boolean
            hasJob = function(jobName)
                return player.PlayerData.job.name == jobName
            end,

            --- Verificar se o jogador está em serviço (on duty)
            ---@return boolean
            isOnDuty = function()
                return player.PlayerData.job.onduty
            end
        }
    end

    ---Pegar player pelo id (citizenid)
    ---@param user_id string
    ---@return table | nil
    function funcs.getPlayerById(user_id)
        local player = QBCore.Functions.GetPlayerByCitizenId(user_id)
        if player then
            return funcs.getPlayer(player.PlayerData.source)
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
        local qbPlayers = QBCore.Functions.GetQBPlayers()
        for src, _ in pairs(qbPlayers) do
            if QBCore.Functions.HasPermission(src, perm) then
                table.insert(players, src)
            end
        end
        return players
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

    --- Função para chamadas dinâmicas ao QBCore
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

    return "qbcore", funcs
end)
