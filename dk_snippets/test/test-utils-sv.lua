-- ============================================
-- 🧪 TESTES AUTOMATIZADOS — UTILS & COOLDOWNS
-- ============================================

local passed = 0
local failed = 0
local total  = 0

--- Registra um teste e exibe o resultado no console.
---@param name string
---@param condition boolean
---@param got any
---@param expected any
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
    --       ParseInt
    -- =====================
    do
        local v = ParseInt(42)
        test("ParseInt — inteiro positivo", v == 42, v, 42)
    end
    do
        local v = ParseInt("123")
        test("ParseInt — string numérica", v == 123, v, 123)
    end
    do
        local v = ParseInt(3.7)
        test("ParseInt — float trunca (floor)", v == 3, v, 3)
    end
    do
        local v = ParseInt(-5.9)
        test("ParseInt — negativo trunca (floor)", v == -6, v, -6)
    end
    do
        local v = ParseInt("abc")
        test("ParseInt — string inválida retorna 0", v == 0, v, 0)
    end
    do
        local v = ParseInt(nil)
        test("ParseInt — nil retorna 0", v == 0, v, 0)
    end
    do
        local v = ParseInt(0)
        test("ParseInt — zero retorna 0", v == 0, v, 0)
    end

    -- =====================
    --     SanitizeString
    -- =====================
    do
        local v = SanitizeString("abc123!@#", "abc123", true)
        test("SanitizeString — allow policy", v == "abc123", v, "abc123")
    end
    do
        local v = SanitizeString("abc123!@#", "!@#", false)
        test("SanitizeString — deny policy", v == "abc123", v, "abc123")
    end
    do
        local v = SanitizeString("", "abc", true)
        test("SanitizeString — string vazia", v == "", v, "")
    end
    do
        local v = SanitizeString("hello", "xyz", true)
        test("SanitizeString — nenhum char permitido", v == "", v, "")
    end
    do
        local v = SanitizeString("hello", "xyz", false)
        test("SanitizeString — nenhum char bloqueado", v == "hello", v, "hello")
    end
    do
        local v = SanitizeString("A1B2C3", "ABC", true)
        test("SanitizeString — só letras permitidas", v == "ABC", v, "ABC")
    end

    -- =====================
    --     SplitString
    -- =====================
    do
        local v = SplitString("a-b-c", "-")
        test("SplitString — split por '-'", #v == 3 and v[1] == "a" and v[2] == "b" and v[3] == "c", table.concat(v, ","), "a,b,c")
    end
    do
        local v = SplitString("hello world", " ")
        test("SplitString — split por espaço", #v == 2 and v[1] == "hello" and v[2] == "world", table.concat(v, ","), "hello,world")
    end
    do
        local v = SplitString("onlyone", "-")
        test("SplitString — sem delimitador encontrado", #v == 1 and v[1] == "onlyone", table.concat(v, ","), "onlyone")
    end
    do
        local v = SplitString("a|b|c", "|")
        test("SplitString — split por '|'", #v == 3 and v[1] == "a" and v[3] == "c", table.concat(v, ","), "a,b,c")
    end

    -- =====================
    --     ParseFormat
    -- =====================
    do
        local v = ParseFormat(1000)
        test("ParseFormat — 1000 → 1.000", v == "1.000", v, "1.000")
    end
    do
        local v = ParseFormat(1000000)
        test("ParseFormat — 1000000 → 1.000.000", v == "1.000.000", v, "1.000.000")
    end
    do
        local v = ParseFormat(500)
        test("ParseFormat — 500 sem separador", v == "500", v, "500")
    end
    do
        local v = ParseFormat(0)
        test("ParseFormat — zero", v == "0", v, "0")
    end
    do
        local v = ParseFormat("25000")
        test("ParseFormat — string '25000'", v == "25.000", v, "25.000")
    end

    -- =====================
    --        Join
    -- =====================
    do
        local v = Join({"a", "b", "c"}, ",")
        test("Join — vírgula", v == "a, b, c", v, "a, b, c")
    end
    do
        local v = Join({"hello"}, ",")
        test("Join — elemento único", v == "hello", v, "hello")
    end
    do
        local v = Join({}, ",")
        test("Join — tabela vazia", v == "", v, "")
    end
    do
        local v = Join({"x", "y"}, " |")
        test("Join — pipe separator", v == "x | y", v, "x | y")
    end

    -- =====================
    --       Round
    -- =====================
    do
        local v = Round(3.14159, 2)
        test("Round — 2 decimais", v == 3.14, v, 3.14)
    end
    do
        local v = Round(3.14159, 0)
        test("Round — 0 decimais", v == 3, v, 3)
    end
    do
        local v = Round(2.5, 0)
        test("Round — 2.5 floor", v == 3, v, 3)
    end
    do
        local v = Round(100, 2)
        test("Round — inteiro sem mudança", v == 100, v, 100)
    end
    do
        local v = Round(-3.7, 1)
        test("Round — negativo", v == -3.7, v, -3.7)
    end

    -- =====================
    --       Class
    -- =====================
    do
        ---@class TempAnimal:Class
        local Animal = Class({
            name = "Unknown",
            sound = "..."
        })

        function Animal:constructor(name, sound)
            self.name = name
            self.sound = sound
        end

        function Animal:speak()
            return self.name .. " says " .. self.sound
        end

        local dog = Animal:new("Dog", "Woof")
        test("Class — instância criada", dog ~= nil, dog ~= nil, true)
        test("Class — propriedade name", dog.name == "Dog", dog.name, "Dog")
        test("Class — propriedade sound", dog.sound == "Woof", dog.sound, "Woof")
        test("Class — método speak", dog:speak() == "Dog says Woof", dog:speak(), "Dog says Woof")

        local cat = Animal:new("Cat", "Meow")
        test("Class — segunda instância independente", cat.name == "Cat" and dog.name == "Dog", cat.name .. "/" .. dog.name, "Cat/Dog")
    end
    do
        ---@class TempCounter:Class
        local Counter = Class({count = 0})

        function Counter:constructor(initial)
            self.count = initial or 0
        end

        function Counter:increment()
            self.count = self.count + 1
        end

        local c = Counter:new(10)
        c:increment()
        c:increment()
        test("Class — estado mutável", c.count == 12, c.count, 12)
    end
    do
        local Empty = Class({})
        local obj = Empty:new()
        test("Class — classe sem propriedades", obj ~= nil, obj ~= nil, true)
    end

    -- =====================
    --      Cooldown
    -- =====================
    do
        local cd = Cooldown:new(5)
        test("Cooldown — criado com timer 5s", cd.defaultTimer == 5000, cd.defaultTimer, 5000)
        test("Cooldown — timer inicial é 0", cd.timer == 0, cd.timer, 0)
    end
    do
        local cd = Cooldown:new(5)
        local result = cd:check()
        test("Cooldown — check sem cooldown ativo retorna nil", result == nil, result, nil)
    end
    do
        local cd = Cooldown:new(5)
        cd:start()
        local remaining = cd:check()
        test("Cooldown — check após start retorna tempo", remaining ~= nil and remaining > 0, remaining, "> 0")
    end
    do
        local cd = Cooldown:new(5)
        cd:start()
        cd:reset()
        local result = cd:check()
        test("Cooldown — reset limpa cooldown", result == nil, result, nil)
    end
    do
        local cd = Cooldown:new(5)
        local result = cd:checkAndCreate()
        test("Cooldown — checkAndCreate retorna true quando inativo", result == true, result, true)
        local remaining = cd:check()
        test("Cooldown — checkAndCreate ativa o cooldown", remaining ~= nil and remaining > 0, remaining, "> 0")
    end
    do
        local cd = Cooldown:new(5)
        cd:start()
        local callbackCalled = false
        local result = cd:checkAndCreate(nil, function(seconds)
            callbackCalled = true
        end)
        test("Cooldown — checkAndCreate retorna false quando ativo", result == false, result, false)
        test("Cooldown — checkAndCreate chama callback quando ativo", callbackCalled == true, callbackCalled, true)
    end
    do
        local cd = Cooldown:new(2)
        cd:start(10000) -- 10 segundos custom
        local remaining = cd:check()
        test("Cooldown — start com timer custom", remaining ~= nil and remaining > 5, remaining, "> 5")
    end
    do
        local cd = Cooldown:new()
        test("Cooldown — sem timer padrão (0)", cd.defaultTimer == 0, cd.defaultTimer, 0)
    end

    -- =====================
    --      RESULTADO
    -- =====================
    print("^3======================================^7")
    print(("^3  Resultado: %d/%d testes passaram^7"):format(passed, total))
    if failed > 0 then
        print(("^1  %d teste(s) falharam!^7"):format(failed))
    else
        print("^2  Todos os testes passaram!^7")
    end
    print("^3======================================^7")
end)