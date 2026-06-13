--- Registra o fallback "sem framework" no handler recebido.
---@param FW FWManager
return function(FW)
    FW:set("_nofw", function()
        local funcs = {}

        ---Pegar player pela source
        ---@param source integer
        ---@return Player
        function funcs.getPlayer(source)
            return {
                online = true,

                userId = function()
                    local identifiers = GetPlayerIdentifiers(source)
                    return identifiers["fivem"]:gsub("fivem:", "") or nil
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
                    return false
                end,

                giveBank = function(amount)
                    return false
                end,

                paymentCash = function(amount)
                    return false
                end,

                giveCash = function(amount)
                    return false
                end,

                itemAmount = function(item)
                    return 0
                end,

                takeItem = function(item, amount, notify)
                    return false
                end,

                giveItem = function(item, amount, notify)
                end,
            }
        end

        ---Pegar player pelo id (citizenid)
        ---@param user_id string
        ---@return Player
        function funcs.getPlayerById(user_id)
            local playerList = GetPlayers()
            for _, src in ipairs(playerList) do
                local identifiers = GetPlayerIdentifiers(src)
                if identifiers.fivem and identifiers.fivem == "fivem:" .. user_id then
                    return funcs.getPlayer(tonumber(src) or 0)
                end
            end
            return { online = false }
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

        function funcs.getFramework()
            return "_nofw"
        end

        return "_nofw", funcs
    end)
end
