FW:set("vrp", function()
    -- CONEXÃO BD
    ---@type SQL
    local SQL = DB()

    -- COLETAR FUNÇÕES DA VRP
    ---@diagnostic disable-next-line: lowercase-global
    vRP = {}
    vRP.__callbacks = {}
    ---@diagnostic disable-next-line: duplicate-set-field
    vRP.__index = function(self, name)
        self[name] = function(...)
            local p = promise.new()
            table.insert(self.__callbacks, p)
            TriggerEvent('vRP:proxy', name, {...}, GetCurrentResourceName(), #self.__callbacks)
            return table.unpack(Citizen.Await(p))
        end
        return self[name]
    end

    AddEventHandler('vRP:'..GetCurrentResourceName()..':proxy_res', function(id, args)
        if not id or id == 0 or type(vRP.__callbacks) ~= "table" then return end

        local p = vRP.__callbacks[id]
        if not p then return end

        p:resolve(args)
        vRP.__callbacks[id] = nil
    end)

    setmetatable(vRP, vRP)

    -- DETECTAR VERSÃO VRP
    ---@type string|nil
    local version = nil

    if SQL.hasTable('vrp_infos') and SQL.hasTable('vrp_permissions') then
        version = "vrp.crv3"
    elseif GetResourceMetadata('vrp', 'creative_network') or vRP.Groups() then
        version = "vrp.crnetwork"
    elseif SQL.hasTable('summerz_characters') or SQL.hasTable('characters') then
        version = "vrp.crv5"
    elseif SQL.hasTable('vrp_user_data') then
        version = "vrp.vrpex"
    end

    if not version then
        error("[dk_snippets] Versão do vRP não encontrada automaticamente. Entre em contato com a nossa equipe no discord para suporte.")
    end

    local funcs = FW:getVersion(version)

    function funcs.getFramework()
        return version
    end

    function funcs._custom(name, ...)
        return vRP[name](...)
    end

    return version, funcs
end)


