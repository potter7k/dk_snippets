-- TESTES — require: carga concorrente do mesmo módulo + ciclo verdadeiro
-- Regressão do "circular-dependency occurred when loading module
-- '@dk_snippets/modules/server/framework/init'": duas coroutines requerendo o
-- mesmo módulo ainda não carregado, com load que yielda (ex.: detecção vRP/SQL),
-- não é ciclo — a segunda deve aguardar. Ciclo real (mesma coroutine) segue erro.
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
    print("^3==== dk_snippets — require: race e ciclo ====^7")

    -- 1) Módulo sintético cujo load yielda: duas threads requerem ao mesmo tempo.
    local sentinel = {}
    package.preload['dk_test_slow'] = function()
        Wait(300)
        return sentinel
    end

    local results = {}
    local done = 0
    for i = 1, 2 do
        CreateThread(function()
            local ok, res = pcall(require, 'dk_test_slow')
            results[i] = { ok = ok, res = res }
            done = done + 1
        end)
    end
    while done < 2 do Wait(10) end

    check("require concorrente — thread 1 ok", results[1].ok)
    check("require concorrente — thread 2 ok (sem falso ciclo)", results[2].ok)
    check("require concorrente — mesmo módulo para ambas",
        results[1].res == sentinel and results[2].res == sentinel)

    -- 2) Ciclo verdadeiro (mesma coroutine) continua detectado.
    package.preload['dk_test_cycle_a'] = function() return require('dk_test_cycle_b') end
    package.preload['dk_test_cycle_b'] = function() return require('dk_test_cycle_a') end
    local okCycle, errCycle = pcall(require, 'dk_test_cycle_a')
    check("ciclo verdadeiro — erra", not okCycle)
    check("ciclo verdadeiro — mensagem de circular-dependency",
        not okCycle and tostring(errCycle):find('circular%-dependency') ~= nil)

    -- 3) Load que falha não deixa a sentinela '__loading' presa.
    package.preload['dk_test_fail'] = function() error('boom') end
    local ok1 = pcall(require, 'dk_test_fail')
    local ok2, err2 = pcall(require, 'dk_test_fail')
    check("load com erro — primeira falha propaga", not ok1)
    check("load com erro — retry não vira falso ciclo",
        not ok2 and tostring(err2):find('circular%-dependency') == nil)

    print(("^3require race/ciclo: %d/%d^7"):format(passed, total))
    if failed > 0 then print(("^1%d falharam^7"):format(failed)) else print("^2OK^7") end
end)
