-- TESTES — FRAMEWORK SYSTEM (nova API)
-- READ-ONLY: não altera dados de jogadores.
---@type dk.snippets
local snippets = require '@dk_snippets/snippets'

local passed, failed, skipped, total = 0, 0, 0, 0
local function test(name, condition, got, expected)
    total = total + 1
    if condition then
        passed = passed + 1
        print(("^2[PASS]^7 %s"):format(name))
    else
        failed = failed + 1
        print(("^1[FAIL]^7 %s — got: %s | expected: %s"):format(name, tostring(got), tostring(expected)))
    end
end
local function skip(name, reason)
    total = total + 1
    skipped = skipped + 1
    print(("^3[SKIP]^7 %s — %s"):format(name, reason))
end

CreateThread(function()
    Wait(5000)
    print("^3=============================================^7")
    print("^3  dk_snippets — Testes de Framework          ^7")
    print("^3=============================================^7")

    -- ETAPA 1: estrutura do FWData
    local fw = snippets.framework
    test("framework — é tabela (FWData)", type(fw) == "table", type(fw), "table")
    test("framework — getPlayer função", type(fw.getPlayer) == "function", type(fw.getPlayer), "function")
    test("framework — getPlayerById função", type(fw.getPlayerById) == "function", type(fw.getPlayerById), "function")
    test("framework — getPlayersByPermission função", type(fw.getPlayersByPermission) == "function", type(fw.getPlayersByPermission), "function")
    test("framework — getFramework função", type(fw.getFramework) == "function", type(fw.getFramework), "function")
    print(("^5[INFO]^7 Framework detectado: ^2%s^7"):format(fw.getFramework()))

    Wait(500)

    -- ETAPA 2: Player online + açúcar
    local players = GetPlayers()
    local targetSource
    for _, p in ipairs(players) do
        local s = tonumber(p)
        if s and s > 0 then targetSource = s break end
    end

    if not targetSource then
        skip("Player + açúcar", "nenhum jogador online")
    else
        print(("^5[INFO]^7 Jogador alvo: source %d"):format(targetSource))
        local player = fw.getPlayer(targetSource)
        test("Player — tabela", type(player) == "table", type(player), "table")
        if type(player) == "table" then
            test("Player — online true", player.online == true, player.online, true)
            test("Player — userSource bate", player.userSource() == targetSource, player.userSource(), targetSource)
            test("Player — açúcar notify presente (online)", type(player.notify) == "function", type(player.notify), "function")
            test("Player — açúcar hint presente (online)", type(player.hint) == "function", type(player.hint), "function")
            test("Player — açúcar request presente (online)", type(player.request) == "function", type(player.request), "function")
            local ok = pcall(function() player.notify("green", "teste açúcar", 1000) end)
            test("Player — notify açúcar não erra", ok, ok, true)
        end
    end

    Wait(500)

    -- ETAPA 3: Player offline → sem açúcar
    do
        local offline = fw.getPlayerById("__dk_test_invalid_id_999__")
        test("Player offline — tabela", type(offline) == "table", type(offline), "table")
        if type(offline) == "table" then
            test("Player offline — online false", offline.online == false, offline.online, false)
            test("Player offline — sem açúcar notify", offline.notify == nil, tostring(offline.notify), "nil")
        end
    end

    -- RESULTADO
    print("^3=============================================^7")
    print(("^3  Resultado: %d/%d testes passaram^7"):format(passed, total))
    if skipped > 0 then print(("^3  %d pulados (sem jogador online)^7"):format(skipped)) end
    if failed > 0 then print(("^1  %d falharam!^7"):format(failed)) else print("^2  Todos passaram!^7") end
    print("^3=============================================^7")
end)
