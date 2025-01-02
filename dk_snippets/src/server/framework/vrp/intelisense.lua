FW:set("vrp", function()
    -- CONEXÃO BD
    local SQL = DB()
    -- 

    -- COLETAR FUNÇÕES DA VRP
    vRP = {}
    vRP.__callbacks = {}
    vRP.__index = function(self, name)
        self[name] = function(...)
            local p = promise.new()
            table.insert(self.__callbacks,p)
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
    -- 

    -- DETECTAR VERSÃO VRP
    local fwName = "vrp."
    if SQL.hasTable('vrp_infos') and SQL.hasTable('vrp_permissions') then
        fwName = fwName.."crv3"
    elseif GetResourceMetadata('vrp', 'creative_network') or vRP.Groups() then
        fwName = fwName.."crnetwork"
    elseif SQL.hasTable('summerz_characters') or SQL.hasTable('characters') then
        fwName = fwName.."crv5"
    elseif SQL.hasTable('vrp_user_data') then
        fwName = fwName.."vrpex"
    else
        error("[ERRO] versão do framework vRP não identificada.")
    end
    --

    -- NÃO ALTERAR
    local funcs = FW:get(fwName)
    function funcs._custom(name, ...)
        return vRP[name] (...)
    end
    -- 

    return fwName, funcs
end)


