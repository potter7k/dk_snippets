-- ============================================
-- TESTES — UTILS (number/table/string/class/cooldown/assert)
-- Nova API: tudo via require '@dk_snippets/snippets'
-- ============================================
---@diagnostic disable: undefined-field, inject-field -- testes sondam campos dinamicamente
---@type dk.snippets
local snippets = require '@dk_snippets/snippets'

local passed, failed, total = 0, 0, 0
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

CreateThread(function()
    Wait(2000)
    print("^3======================================^7")
    print("^3  dk_snippets — Testes de Utils       ^7")
    print("^3======================================^7")

    -- =====================
    --        number
    -- =====================
    local number = snippets.number
    test("ParseInt — inteiro", number.ParseInt(42) == 42, number.ParseInt(42), 42)
    test("ParseInt — string", number.ParseInt("123") == 123, number.ParseInt("123"), 123)
    test("ParseInt — float floor", number.ParseInt(3.7) == 3, number.ParseInt(3.7), 3)
    test("ParseInt — negativo floor", number.ParseInt(-5.9) == -6, number.ParseInt(-5.9), -6)
    test("ParseInt — inválida → 0", number.ParseInt("abc") == 0, number.ParseInt("abc"), 0)
    test("ParseInt — nil → 0", number.ParseInt(nil) == 0, number.ParseInt(nil), 0)
    test("Round — 2 casas", number.Round(3.14159, 2) == 3.14, number.Round(3.14159, 2), 3.14)
    test("Round — 0 casas", number.Round(3.14159, 0) == 3, number.Round(3.14159, 0), 3)
    test("Round — 2.5 half-up", number.Round(2.5, 0) == 3, number.Round(2.5, 0), 3)

    -- =====================
    --        table
    -- =====================
    local tbl = snippets.table
    test("table.count", tbl.count({1,2,3}) == 3, tbl.count({1,2,3}), 3)
    do
        local r = tbl.map({1,2,3}, function(v) return v * 2 end)
        test("table.map", r[1] == 2 and r[2] == 4 and r[3] == 6, table.concat(r, ","), "2,4,6")
    end
    do
        local r = tbl.find({1,2,3,4}, function(v) return v % 2 == 0 end)
        test("table.find", #r == 2 and r[1] == 2 and r[2] == 4, table.concat(r, ","), "2,4")
    end
    test("table.indexOf", tbl.indexOf({"a","b","c"}, "b") == 2, tbl.indexOf({"a","b","c"}, "b"), 2)
    test("table.contains true", tbl.contains({"a","b"}, "a") == true, true, true)
    test("table.contains false", tbl.contains({"a","b"}, "z") == false, false, false)
    do
        local r = tbl.slice({10,20,30,40}, 2, 3)
        test("table.slice", #r == 2 and r[1] == 20 and r[2] == 30, table.concat(r, ","), "20,30")
    end

    -- =====================
    --        string
    -- =====================
    local str = snippets.string
    test("Split por -", (function() local v = str.Split("a-b-c", "-"); return #v==3 and v[1]=="a" and v[3]=="c" end)(), "a,b,c", "a,b,c")
    test("Sanitize allow", str.Sanitize("abc123!@#", "abc123", true) == "abc123", str.Sanitize("abc123!@#", "abc123", true), "abc123")
    test("Sanitize deny", str.Sanitize("abc123!@#", "!@#", false) == "abc123", str.Sanitize("abc123!@#", "!@#", false), "abc123")
    test("Join vírgula", str.Join({"a","b","c"}, ",") == "a, b, c", str.Join({"a","b","c"}, ","), "a, b, c")
    test("Join único", str.Join({"hello"}, ",") == "hello", str.Join({"hello"}, ","), "hello")
    test("ParseFormat 1000", str.ParseFormat(1000) == "1.000", str.ParseFormat(1000), "1.000")
    test("ParseFormat 1000000", str.ParseFormat(1000000) == "1.000.000", str.ParseFormat(1000000), "1.000.000")

    -- =====================
    --        class
    -- =====================
    local Class = snippets.class
    do
        local Animal = Class({ name = "Unknown", sound = "..." })
        function Animal:constructor(name, sound) self.name = name; self.sound = sound end
        function Animal:speak() return self.name .. " says " .. self.sound end
        local dog = Animal:new("Dog", "Woof")
        test("Class — name", dog.name == "Dog", dog.name, "Dog")
        test("Class — método", dog:speak() == "Dog says Woof", dog:speak(), "Dog says Woof")
        local cat = Animal:new("Cat", "Meow")
        test("Class — instâncias independentes", cat.name == "Cat" and dog.name == "Dog", cat.name.."/"..dog.name, "Cat/Dog")
    end
    do
        local Counter = Class({ count = 0 })
        function Counter:constructor(initial) self.count = initial or 0 end
        function Counter:increment() self.count = self.count + 1 end
        local c = Counter:new(10); c:increment(); c:increment()
        test("Class — estado mutável", c.count == 12, c.count, 12)
    end

    -- =====================
    --       cooldown
    -- =====================
    local Cooldown = snippets.cooldown
    do
        local cd = Cooldown:new(5)
        test("Cooldown — defaultTimer ms", cd.defaultTimer == 5000, cd.defaultTimer, 5000)
        test("Cooldown — timer inicial 0", cd.timer == 0, cd.timer, 0)
        test("Cooldown — check inativo nil", cd:check() == nil, cd:check(), nil)
        cd:start()
        test("Cooldown — check após start > 0", (cd:check() or 0) > 0, cd:check(), "> 0")
        cd:reset()
        test("Cooldown — reset limpa", cd:check() == nil, cd:check(), nil)
    end
    do
        local cd = Cooldown:new(5)
        test("Cooldown — checkAndCreate inativo true", cd:checkAndCreate() == true, true, true)
        local called = false
        local r = cd:checkAndCreate(nil, function() called = true end)
        test("Cooldown — checkAndCreate ativo false", r == false, r, false)
        test("Cooldown — callback chamado", called == true, called, true)
    end

    -- =====================
    --        assert
    -- =====================
    local A = require '@dk_snippets/modules/shared/assert'
    test("Ensure — tipo ok não erra", pcall(A.Ensure, {}, {"table"}) == true, true, true)
    test("Ensure — tipo errado erra", pcall(A.Ensure, 5, {"table"}) == false, false, false)
    test("Ensure — string ok", pcall(A.Ensure, "x", {"string"}) == true, true, true)

    -- =====================
    --       json/db (shape)
    -- =====================
    local JSON = snippets.json
    test("json — é tabela/classe", type(JSON) == "table", type(JSON), "table")
    test("json — tem :fetch", type(JSON.fetch) == "function", type(JSON.fetch), "function")
    test("db — snippets.db é função DB()", type(snippets.db) == "function", type(snippets.db), "function")

    -- =====================
    --      callbacks (shape)
    -- =====================
    local cb = snippets.callbacks
    if IsDuplicityVersion() then
        test("callbacks — RegisterServerCallback (server)", type(cb.RegisterServerCallback) == "function", type(cb.RegisterServerCallback), "function")
        test("callbacks — TriggerClientCallback (server)", type(cb.TriggerClientCallback) == "function", type(cb.TriggerClientCallback), "function")
    end

    -- =====================
    --       RESULTADO
    -- =====================
    print("^3======================================^7")
    print(("^3  Resultado: %d/%d testes passaram^7"):format(passed, total))
    if failed > 0 then print(("^1  %d teste(s) falharam!^7"):format(failed))
    else print("^2  Todos os testes passaram!^7") end
    print("^3======================================^7")
end)
