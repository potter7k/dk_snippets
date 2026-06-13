local tbl = require '@dk_snippets/modules/shared/table'

--- Registra a variante vrp.crnetwork.
---@param FW FWManager
---@param vRP table
return function(FW, vRP)
    local function hasPermission(user_id, perm)
        if not user_id or not perm then return false end
        return vRP.HasGroup(user_id, perm)
    end

    local function userId(source)
        return vRP.Passport(source)
    end

    local function userSource(user_id)
        return vRP.Source(user_id)
    end

    FW:setVersion("vrp.crnetwork", function()
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
                paymentBank = function(amount) return vRP.PaymentBank(user_id, amount) end,
                giveBank = function(amount) vRP.GiveBank(user_id, amount) end,
                itemAmount = function(item) return vRP.ItemAmount(user_id, item) or 0 end,
                takeItem = function(item, amount, notify)
                    local consult = vRP.InventoryItemAmount(user_id, item)
                    if consult[1] >= amount and vRP.TakeItem(user_id, consult[2], amount, notify) then
                        return true
                    end
                    return false
                end,
                giveItem = function(item, amount, notify)
                    vRP.GenerateItem(user_id, item, amount, notify)
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
            local players = vRP.NumPermission(perm) or {}
            if type(players) ~= "table" then return {} end
            return tbl.map(players, function(source)
                return funcs.getPlayer(source)
            end, false)
        end

        return funcs
    end)
end
