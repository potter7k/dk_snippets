-- TESTES — Custom de Framework
---@type dk.snippets
local snippets = require '@dk_snippets/snippets'

local passed, failed, total = 0, 0, 0
local function test(name, cond)
    total = total + 1
    if cond then passed = passed + 1; print(("^2[PASS]^7 %s"):format(name))
    else failed = failed + 1; print(("^1[FAIL]^7 %s"):format(name)) end
end

CreateThread(function()
    Wait(5000)
    print("^3==== dk_snippets — Custom de Framework ====^7")

    local fw = snippets.framework
    -- Caso base: framework resolve normalmente, com ou sem custom.
    test("framework resolve (custom opcional)", type(fw) == "table" and type(fw.getFramework) == "function")
    print(("^5[INFO]^7 Framework: %s"):format(fw.getFramework()))

    -- O helper custom existe e expõe load/applyFunctions.
    local customLoader = require '@dk_snippets/modules/server/framework/custom'
    test("custom.load é função", type(customLoader.load) == "function")
    test("custom.applyFunctions é função", type(customLoader.applyFunctions) == "function")

    -- Detecta se há um custom para o framework atual (informativo, não falha).
    local present = customLoader.load(fw.getFramework())
    if present then
        print("^5[INFO]^7 custom presente para este framework.")
        if present.functions then
            for name in pairs(present.functions) do
                test("custom function aplicada: " .. name, type(fw[name]) == "function")
            end
        end
    else
        print("^3[SKIP]^7 sem custom/<fw>.lua para este framework (caso normal).")
    end

    print(("^3Custom: %d/%d^7"):format(passed, total))
    if failed > 0 then print(("^1%d falharam^7"):format(failed)) else print("^2OK^7") end
end)
