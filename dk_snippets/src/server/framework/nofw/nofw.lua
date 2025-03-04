FW:set("_nofw", function()
    local funcs = {}

    function funcs.userId(source)
        for i = 0, GetNumPlayerIdentifiers(source) - 1 do
            local id = GetPlayerIdentifier(source, i)
            if string.find(id, "discord") then
                return id:gsub("discord:","")
            end
        end
    
        return nil
    end

    function funcs.isAdmin(source)
        return IsPlayerAceAllowed(source, "group.admin")
    end

    return "_nofw", funcs
end)