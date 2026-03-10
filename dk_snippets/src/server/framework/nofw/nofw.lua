FW:set("_nofw", function()
    local funcs = {}

    ---Pegar player pela source
    ---@param source integer
    ---@return Player | nil
    function funcs.getPlayer(source)

        return {
            online = true,

            --- Pegar identificador do usuário.
            ---@return string|nil
            userId = function()
                local identifiers = GetPlayerIdentifiers(source)
                return identifiers["fivem"]:gsub("fivem:", "") or nil
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
                -- Indisponivel
                return false
            end,

            --- Adicionar dinheiro ao banco
            ---@param amount integer
            ---@return boolean
            giveBank = function(amount)
                -- Indisponivel
                return false
            end,

            --- Pagar usando dinheiro em mãos (cash)
            ---@param amount integer
            ---@return boolean
            paymentCash = function(amount)
                -- Indisponivel
                return false
            end,

            --- Adicionar dinheiro em mãos (cash)
            ---@param amount integer
            ---@return boolean
            giveCash = function(amount)
                -- Indisponivel
                return false
            end,

            --- Pegar quantidade de um item
            ---@param item string
            ---@return integer
            itemAmount = function(item)
                -- Indisponivel
                return 0
            end,

            --- Remover item do inventário
            ---@param item string
            ---@param amount integer
            ---@param notify boolean
            ---@return boolean
            takeItem = function(item, amount, notify)
                -- Indisponivel
                return false
            end,

            --- Gerar item no inventário
            ---@param item string
            ---@param amount integer
            ---@param notify boolean
            giveItem = function(item, amount, notify)
                -- Indisponivel
            end,
        }
    end

    ---Pegar player pelo id (citizenid)
    ---@param user_id string
    ---@return Player | nil
    function funcs.getPlayerById(user_id)
        local playerList = GetPlayers()
        for _, src in ipairs(playerList) do
            local identifiers = GetPlayerIdentifiers(src)
            if identifiers.fivem and identifiers.fivem == "fivem:" ..user_id then
                return funcs.getPlayer(src)
            end
        end
        return {
            online = false
        }
    end

    ---Pegar players por permissão
    ---@param perm string
    ---@return Player[]
    function funcs.getPlayersByPermission(perm)
        local playerList = GetPlayers()
        local players = {}
        for _, src in ipairs(playerList) do
            if IsPlayerAceAllowed(src, perm) then
                table.insert(players, funcs.getPlayer(src))
            end
        end
        return players
    end

    ---Pegar nome do framework
    ---@return string
    function funcs.getFramework()
        return "_nofw"
    end

    return "_nofw", funcs
end)
