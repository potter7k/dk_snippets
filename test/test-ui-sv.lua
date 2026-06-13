-- TESTES — UI dispatch (notify / hint / request)
---@type dk.snippets
local snippets = require '@dk_snippets/snippets'

local passed, failed, total = 0, 0, 0
local function test(name, condition)
    total = total + 1
    if condition then
        passed = passed + 1
        print(("^2[PASS]^7 %s"):format(name))
    else
        failed = failed + 1
        print(("^1[FAIL]^7 %s"):format(name))
    end
end

CreateThread(function()
    Wait(2000)
    print("^3==== dk_snippets — Testes de UI (dispatch) ====^7")

    local notify = snippets.notify
    test("notify.send é função", type(notify.send) == "function")
    test("notify.hint é função", type(notify.hint) == "function")
    test("notify.modes existe", type(notify.modes) == "table" and notify.modes.GREEN == "green")
    test("request é callable", type(snippets.request) == "function")

    -- Dispatch real só funciona com uma source de cliente válida.
    -- source 0 = console (não é cliente) → TriggerClientEvent falha legitimamente.
    -- Então testamos com um jogador online; sem jogador, pulamos.
    local targetSource
    for _, p in ipairs(GetPlayers()) do
        local s = tonumber(p)
        if s and s > 0 then targetSource = s break end
    end

    if targetSource then
        local ok = pcall(function() notify.send(targetSource, "green", "teste dispatch", 5000) end)
        test("notify.send(player,...) não erra", ok)
        local okHint = pcall(function() notify.hint(targetSource, "create", "dk_test", "Aperte E", "E") end)
        test("notify.hint(player,...) não erra", okHint)
        Wait(2000)
        pcall(function() notify.hint(targetSource, "remove", "dk_test") end)
        snippets.request(targetSource, "Teste dasjnduashnduasdas?", 10)
    else
        total = total + 1
        print("^3[SKIP]^7 notify dispatch — nenhum jogador online (entre no servidor para testar)")
    end

    print(("^3UI dispatch: %d/%d^7"):format(passed, total))
    if failed > 0 then print(("^1%d falharam^7"):format(failed)) else print("^2OK^7") end
end)
