-- TESTES — Exports legados (runtime/server/legacy_exports.lua)
-- Os scripts encriptados antigos chamam exports['dk_snippets']:framework()/:DB()/:request().
-- `request` (server) exige um player conectado → validado in-game, não aqui.
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
    print("^3==== dk_snippets — Exports legados ====^7")

    -- framework() → tupla antiga (name, FWData)
    local okFw, name, fw = pcall(function()
        return exports['dk_snippets']:framework()
    end)
    check("export framework() responde", okFw)
    if okFw then
        check("framework() retorna name string", type(name) == "string")
        check("framework() retorna FWData table", type(fw) == "table")
        check("FWData.getPlayer presente", fw ~= nil and fw.getPlayer ~= nil)
        check("FWData.getFramework presente", fw ~= nil and fw.getFramework ~= nil)
    end

    -- DB() → objeto SQL (exige um driver SQL iniciado, ex.: oxmysql/ghmattimysql)
    local okDb, db = pcall(function()
        return exports['dk_snippets']:DB()
    end)
    check("export DB() responde (exige driver SQL iniciado)", okDb and type(db) == "table")

    print(("^3Exports legados: %d/%d^7"):format(passed, total))
    if failed > 0 then print(("^1%d falharam^7"):format(failed)) else print("^2OK^7") end
end)
