-- TESTES — Shim de compatibilidade (compat/dk_snippets_compat.lua)
-- Carrega o shim num ambiente isolado e confere a superfície da API antiga
-- consumida pelos scripts encriptados (dk_races, dk_animations_ext, dk_trunkin, dk_lapdance).
---@diagnostic disable: undefined-field, inject-field -- testes sondam campos dinamicamente
---@diagnostic disable: missing-return, missing-return-value
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
    print("^3==== dk_snippets — Shim compat ====^7")

    local code = LoadResourceFile('dk_snippets', 'compat/dk_snippets_compat.lua')
    check("arquivo compat/dk_snippets_compat.lua existe", code ~= nil)
    if not code then return end

    -- Ambiente isolado: simula o contexto de um consumidor sem poluir o dk_snippets.
    -- env._G = env → o `_G.RegisterServerCallback = ...` do callbacks.lua escreve no env.
    -- env.table → cópia com __index para a table nativa; o utils.lua estende essa cópia.
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.table = setmetatable({}, { __index = table })

    local fn, err = load(code, '@dk_snippets/compat/dk_snippets_compat.lua', 't', env)
    check("shim compila sem erro", fn ~= nil)
    if not fn then print("^1" .. tostring(err) .. "^7") return end

    local ok, runErr = pcall(fn)
    check("shim executa sem erro", ok)
    if not ok then print("^1" .. tostring(runErr) .. "^7") return end

    -- utils.lua
    check("DkNotify definido", type(env.DkNotify) == "function")
    check("DkRequest definido", type(env.DkRequest) == "function")
    check("DkHint definido", type(env.DkHint) == "function")
    check("Class definido", type(env.Class) == "function")
    check("ParseInt definido", type(env.ParseInt) == "function")
    check("Round definido", type(env.Round) == "function")
    check("Match definido", type(env.Match) == "function")
    check("SanitizeString definido", type(env.SanitizeString) == "function")
    check("SplitString definido", type(env.SplitString) == "function")
    check("ParseFormat definido", type(env.ParseFormat) == "function")
    check("Join definido", type(env.Join) == "function")
    check("Ensure definido", type(env.Ensure) == "function")
    check("Dump definido", type(env.Dump) == "function")
    check("NotifyModes definido", type(env.NotifyModes) == "table")
    check("table.count definido", type(env.table.count) == "function")
    check("table.map definido", type(env.table.map) == "function")
    check("table.forEach definido", type(env.table.forEach) == "function")
    check("table.find definido", type(env.table.find) == "function")
    check("table.slice definido", type(env.table.slice) == "function")
    check("table.indexOf definido", type(env.table.indexOf) == "function")
    check("table.contains definido", type(env.table.contains) == "function")

    -- callbacks.lua (lado server)
    check("RegisterServerCallback definido", type(env.RegisterServerCallback) == "function")
    check("UnregisterServerCallback definido", type(env.UnregisterServerCallback) == "function")
    check("TriggerClientCallback definido", type(env.TriggerClientCallback) == "function")
    check("TriggerServerCallback definido", type(env.TriggerServerCallback) == "function")

    -- cooldowns.lua
    check("Cooldown definido", type(env.Cooldown) == "table")

    -- json.lua (server-only; este teste roda no server → deve existir)
    check("JSON definido", type(env.JSON) == "table")

    -- Isolamento: nada vazou para o contexto do dk_snippets
    check("não poluiu _G", rawget(_G, 'DkNotify') == nil and rawget(_G, 'Class') == nil
        and rawget(_G, 'RegisterServerCallback') == nil and rawget(_G, 'JSON') == nil)
    check("não poluiu table nativa", rawget(table, 'map') == nil and rawget(table, 'count') == nil)

    -- Comportamento básico
    check("ParseInt('7.9') == 7", env.ParseInt("7.9") == 7)
    check("Round(1.5) == 2 (half-up)", env.Round(1.5, 0) == 2)
    check("Round(2.25, 1) == 2.3", env.Round(2.25, 1) == 2.3)
    check("SplitString('a-b-c')[2] == 'b'", env.SplitString("a-b-c")[2] == "b")
    check("Match com default", env.Match("x", { default = 42 }) == 42)
    local C = env.Class({ x = 1 })
    local inst = C:new()
    check("Class:new aplica defaults", inst.x == 1)
    local cd = env.Cooldown:new(10)
    check("Cooldown:new instancia", type(cd.checkAndCreate) == "function")

    print(("^3Shim compat: %d/%d^7"):format(passed, total))
    if failed > 0 then print(("^1%d falharam^7"):format(failed)) else print("^2OK^7") end
end)
