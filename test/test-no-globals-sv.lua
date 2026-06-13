-- TESTES — Zero Globais
-- Garante que nenhum global do modelo antigo vazou para _G ou para a table nativa.
---@diagnostic disable: undefined-field, inject-field -- testes sondam campos dinamicamente
---@type dk.snippets
local snippets = require '@dk_snippets/snippets'

local passed, failed, total = 0, 0, 0
local function check(name, cond)
    total = total + 1
    if cond then
        passed = passed + 1
        print(("^2[PASS]^7 %s"):format(name))
    else
        failed = failed + 1
        print(("^1[FAIL]^7 %s"):format(name))
    end
end

CreateThread(function()
    Wait(3000)
    print("^3==== dk_snippets — Zero Globais ====^7")

    -- força o carregamento de todos os módulos
    local _ = snippets.number; _ = snippets.string; _ = snippets.table; _ = snippets.class
    _ = snippets.cooldown; _ = snippets.callbacks; _ = snippets.notify
    _ = snippets.json; _ = snippets.db; _ = snippets.request; _ = snippets.framework

    check("ParseInt não em _G", _G.ParseInt == nil)
    check("Class não em _G", _G.Class == nil)
    check("Cooldown não em _G", _G.Cooldown == nil)
    check("JSON não em _G", _G.JSON == nil)
    check("SQL/DB não em _G", _G.SQL == nil and _G.DB == nil)
    check("Framework/FW não em _G", _G.Framework == nil and _G.FW == nil)
    check("RegisterServerCallback não em _G", _G.RegisterServerCallback == nil)
    check("TriggerServerCallback não em _G", _G.TriggerServerCallback == nil)
    check("Dk* não em _G", _G.DkNotify == nil and _G.DkHint == nil and _G.DkRequest == nil)
    check("Join/Round não em _G", rawget(_G, 'Join') == nil and rawget(_G, 'Round') == nil)

    -- as extensões de tabela NÃO devem estar na table nativa (módulo é isolado)
    check("table.map não na table nativa", rawget(table, 'map') == nil)
    check("table.forEach não na table nativa", rawget(table, 'forEach') == nil)
    check("table.find não na table nativa", rawget(table, 'find') == nil)

    -- mas o módulo isolado tem os helpers
    check("snippets.table.map existe", type(snippets.table.map) == "function")

    print(("^3Zero-globais: %d/%d^7"):format(passed, total))
    if failed > 0 then print(("^1%d falharam^7"):format(failed)) else print("^2OK^7") end
end)
