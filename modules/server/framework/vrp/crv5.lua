local tbl = require '@dk_snippets/modules/shared/table'

--- Registra a variante vrp.crv5.
---@param FW FWManager
---@param vRP table
return function(FW, vRP)
    local function hasPermission(user_id, perm)
        if not user_id or not perm then return false end
        return vRP.hasPermission(user_id, perm)
    end

    local function userId(source)
        return vRP.getUserId(source)
    end

    local function userSource(user_id)
        return vRP.userSource(user_id)
    end

    FW:setVersion("vrp.crv5", function()
        local funcs = {}

        function funcs.getPlayer(source)
            local user_id = userId(source)
            if not user_id then
                return { online = false }
            end
            return {
                online = true,
                userId = function() return user_id end,
                userSource = function() return source end,
                isAdmin = function() return hasPermission(user_id, "Admin") end,
                hasPermission = function(permission) return hasPermission(user_id, permission) end,
                paymentBank = function(amount) return vRP.paymentBank(user_id, amount) end,
                giveBank = function(amount) vRP.addBank(user_id, amount, "Private") end,
                itemAmount = function(item) return vRP.itemAmount(user_id, item) or 0 end,
                takeItem = function(item, amount, notify)
                    return vRP.tryGetInventoryItem(user_id, item, amount, notify)
                end,
                giveItem = function(item, amount, notify)
                    vRP.generateItem(user_id, item, amount, notify)
                end
            }
        end

        function funcs.getPlayerById(user_id)
            local source = userSource(user_id)
            if source then
                return funcs.getPlayer(source)
            end
            return { online = false }
        end

        function funcs.getPlayersByPermission(perm)
            local players = vRP.numPermission(perm) or {}
            if type(players) ~= "table" then return {} end
            return tbl.map(players, function(source)
                return funcs.getPlayer(source)
            end, false)
        end

        return funcs
    end)
end
