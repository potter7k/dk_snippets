FW:set("vrp.crv5", function()
    local funcs = {}

    --- Retornar a lista de usuários
    ---@return table
    function funcs.userList()
        return vRP.userList()
    end

    --- Retornar a source do usuário
    ---@param user_id integer
    ---@return integer|nil
    function funcs.userSource(user_id)
        return vRP.userSource(user_id)
    end

    --- Pegar identificador do usuário pela source
    ---@param source integer
    ---@return integer|nil
    function funcs.userId(source)
        return vRP.getUserId(source)
    end

    --- Retornar o datatable do usuário
    ---@param user_id integer
    ---@return table|nil
    function funcs.getDatatable(user_id)
        return vRP.getDatatable(user_id)
    end

    --- Obter dados específicos do usuário do banco de dados
    ---@param user_id integer
    ---@param name string
    ---@return any
    function funcs.userData(user_id, name)
        if not user_id or not name then return end

        return vRP.userData(user_id,name)
    end

    --- Definir dados para o usuário
    ---@param user_id integer
    ---@param key string
    ---@param data any
    function funcs.setData(user_id, key, data)
        if not user_id or not key or not data then return end
        if type(data) == "table" then
            data = json.encode(data)
        end
        vRP.execute("playerdata/setUserdata", { user_id = user_id, key = key, value = data })
    end

    --- Retornar permissões do usuário
    ---@param perm string
    ---@return table
    function funcs.numPermission(perm)
        return vRP.numPermission(perm) or {}
    end

    --- Pegar identidade do usuário
    ---@param user_id integer
    ---@return table
    function funcs.userIdentity(user_id)
        local identity = vRP.userIdentity(user_id)

        if type(identity) == "table" then
            identity.name = identity.name or identity.nome or identity.Name or " "
            identity.name2 = identity.name2 or identity.sobrenome or identity.firstname or identity.Lastname or " "
            identity.phone = identity.phone or identity.Phone or " "
            return identity
        else
            return {name = "Unknown", name2 = "Unknown", phone = "XXX-XXX"}
        end
    end

    --- Verificar se o player possui determinada permissão
    ---@param user_id integer|nil
    ---@param perm string
    ---@return boolean
    function funcs.hasPermission(user_id, perm)
        if not user_id or not perm then return false end
        return vRP.hasPermission(user_id, perm)
    end

    --- Retornar quantidade de determinado item
    ---@param ... any
    ---@return integer
    function funcs.itemAmount(...)
        return vRP.itemAmount(...) or 0
    end

    --- Remover item do inventário
    ---@param ... any
    ---@return boolean
    function funcs.takeItem(...)
        return vRP.tryGetInventoryItem(...)
    end

    --- Adicionar item ao inventário
    ---@param ... any
    function funcs.giveItem(...)
        vRP.generateItem(...)
    end

    --- Pagar usando dinheiro do banco
    ---@param user_id integer
    ---@param amount integer
    ---@return boolean
    function funcs.paymentBank(user_id, amount)
        return vRP.paymentBank(user_id,amount)
    end

    --- Adicionar dinheiro ao banco
    ---@param user_id integer
    ---@param amount integer
    function funcs.giveBank(user_id, amount)
        vRP.addBank(user_id,amount,"Private")
    end

    --- Verificar se o player é admin
    ---@param source integer
    ---@return boolean
    function funcs.isAdmin(source)
        local user_id = funcs.userId(source)
        return funcs.hasPermission(user_id, "Admin")
    end

    return funcs
end)
