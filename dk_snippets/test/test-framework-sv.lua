-- =====================================================
-- 🧪 TESTES AUTOMATIZADOS — FRAMEWORK SYSTEM
-- Seguro para produção: apenas leitura, sem alterar
-- dados de jogadores. Cooldown entre etapas.
-- =====================================================

local passed = 0
local failed = 0
local skipped = 0
local total  = 0

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

---@param name string
---@param reason string
local function skip(name, reason)
    total = total + 1
    skipped = skipped + 1
    print(("^3[SKIP]^7 %s — %s"):format(name, reason))
end

--- Dump seguro de uma tabela (somente leitura, sem recursão infinita).
---@param label string
---@param tbl table
---@param maxDepth? integer
local function dump(label, tbl, maxDepth)
    maxDepth = maxDepth or 3

    ---@param t any
    ---@param depth integer
    ---@param indent string
    ---@return string
    local function serialize(t, depth, indent)
        if type(t) ~= "table" then
            return tostring(t)
        end
        if depth > maxDepth then
            return "{...}"
        end

        local parts = {}
        local nextIndent = indent .. "  "
        for k, v in pairs(t) do
            local keyStr = type(k) == "number" and ("[" .. k .. "]") or tostring(k)
            if type(v) == "function" then
                parts[#parts + 1] = nextIndent .. keyStr .. " = function()"
            else
                parts[#parts + 1] = nextIndent .. keyStr .. " = " .. serialize(v, depth + 1, nextIndent)
            end
        end

        if #parts == 0 then
            return "{}"
        end

        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
    end

    print(("^5[DUMP]^7 %s:\n%s"):format(label, serialize(tbl, 1, "")))
end

CreateThread(function()
    Wait(5000) -- Esperar utils, framework e recursos carregarem
    print("")
    print("^3=============================================^7")
    print("^3  dk_snippets — Testes de Framework          ^7")
    print("^3  Modo: READ-ONLY (seguro para produção)     ^7")
    print("^3=============================================^7")
    print("")

    -- ==============================
    --  ETAPA 1: Estrutura do FW
    -- ==============================
    print("^6[ETAPA 1/5]^7 Estrutura do FW")
    do
        test("FW — tabela global existe", FW ~= nil and type(FW) == "table", type(FW), "table")
        test("FW — FW.list é tabela", type(FW.list) == "table", type(FW.list), "table")
        test("FW — FW.versions é tabela", type(FW.versions) == "table", type(FW.versions), "table")

        -- Dump dos frameworks registrados
        local registeredFWs = {}
        for name, _ in pairs(FW.list) do
            registeredFWs[#registeredFWs + 1] = name
        end
        print(("^5[INFO]^7 Frameworks registrados: %s"):format(#registeredFWs > 0 and table.concat(registeredFWs, ", ") or "nenhum"))

        local registeredVersions = {}
        for name, _ in pairs(FW.versions) do
            registeredVersions[#registeredVersions + 1] = name
        end
        print(("^5[INFO]^7 Versões registradas: %s"):format(#registeredVersions > 0 and table.concat(registeredVersions, ", ") or "nenhuma"))
    end

    Wait(500)

    -- ==============================
    --  ETAPA 2: Detecção automática
    -- ==============================
    print("")
    print("^6[ETAPA 2/5]^7 Framework() — detecção automática")
    ---@type string
    local fwName
    ---@type FWData
    local fwData

    do
        fwName, fwData = Framework()
        test("Framework() — retorna nome (string)", type(fwName) == "string", type(fwName), "string")
        test("Framework() — retorna dados (table)", type(fwData) == "table", type(fwData), "table")
        test("Framework() — nome não é vazio", fwName ~= "", fwName, "non-empty")
        print(("^5[INFO]^7 Framework detectado: ^2%s^7"):format(fwName))
    end
    do
        local eName, eData = exports["dk_snippets"]:framework()
        test("exports:framework() — retorna nome", type(eName) == "string", type(eName), "string")
        test("exports:framework() — retorna dados", type(eData) == "table", type(eData), "table")
        test("exports:framework() — consistente com Framework()", eName == fwName, eName, fwName)
    end

    -- Dump da estrutura do FWData (só chaves e tipos)
    do
        local fwKeys = {}
        for k, v in pairs(fwData) do
            fwKeys[k] = type(v)
        end
        dump("FWData — estrutura", fwKeys)
    end

    Wait(500)

    -- ==============================
    --  ETAPA 3: Player — READ-ONLY
    -- ==============================
    print("")
    print("^6[ETAPA 3/5]^7 Player Interface — somente leitura")
    do
        local players = GetPlayers()
        ---@type integer|nil
        local targetSource = nil
        for _, playerSrc in ipairs(players) do
            local src = tonumber(playerSrc)
            if src and src > 0 then
                targetSource = src
                break
            end
        end

        if not targetSource then
            skip("Player — getPlayer", "nenhum jogador online")
            skip("Player — userId", "nenhum jogador online")
            skip("Player — userSource", "nenhum jogador online")
            skip("Player — isAdmin", "nenhum jogador online")
            skip("Player — itemAmount", "nenhum jogador online")
            skip("Player — identidade (dump)", "nenhum jogador online")
            print("^3[INFO]^7 Entre no servidor para executar testes completos de Player.")
        else
            print(("^5[INFO]^7 Jogador alvo: source %d | nome: %s"):format(targetSource, GetPlayerName(targetSource) or "??"))

            ---@type Player|nil
            local player = fwData.getPlayer(targetSource)
            test("Player — getPlayer retorna tabela", type(player) == "table", type(player), "table")

            if player then
                test("Player — online é true", player.online == true, player.online, true)

                Wait(300)

                -- userId (somente leitura)
                local uid = player.userId()
                test("Player — userId() retorna valor", uid ~= nil, tostring(uid), "non-nil")
                test("Player — userId() tipo válido", type(uid) == "string" or type(uid) == "number", type(uid), "string|number")

                -- userSource (somente leitura)
                local src = player.userSource()
                test("Player — userSource() retorna source correta", src == targetSource, src, targetSource)

                Wait(300)

                -- isAdmin (somente leitura)
                local admin = player.isAdmin()
                test("Player — isAdmin() retorna boolean", type(admin) == "boolean", type(admin), "boolean")

                -- itemAmount (somente leitura, não altera inventário)
                local itemAmt = player.itemAmount("water")
                test("Player — itemAmount() retorna número", type(itemAmt) == "number", type(itemAmt), "number")

                -- ── DUMP: identidade do jogador ──
                print("")
                print("^6[DUMP]^7 Identidade do jogador:")
                local identifiers = GetPlayerIdentifiers(targetSource) --[[@as table]]
                local identityInfo = {
                    source      = targetSource,
                    name        = GetPlayerName(targetSource),
                    userId      = uid,
                    isAdmin     = admin,
                    itemWater   = itemAmt,
                    identifiers = {}
                }
                -- for _, id in ipairs(identifiers) do
                --     local prefix = id:match("^([^:]+)")
                --     identityInfo.identifiers[prefix or "unknown"] = id
                -- end
                dump("Player Identity", identityInfo)

                Wait(300)

                -- ── DUMP: tokens do jogador (quantidade, sem expor valores) ──
                local tokens = GetPlayerTokens(targetSource) --[[@as table]]
                print(("^5[INFO]^7 Tokens do jogador: %d token(s) registrado(s)"):format(#tokens))

                -- getPlayerById (somente leitura)
                if uid then
                    Wait(300)
                    local playerById = fwData.getPlayerById(uid)
                    test("Player — getPlayerById retorna tabela", type(playerById) == "table", type(playerById), "table")
                    if playerById then
                        test("Player — getPlayerById online é true", playerById.online == true, playerById.online, true)
                        if playerById.online and playerById.userSource then
                            test("Player — getPlayerById source bate", playerById.userSource() == targetSource, playerById.userSource(), targetSource)
                        end
                    end
                end

                Wait(300)

                -- getPlayersByPermission (somente leitura)
                local adminPlayers = fwData.getPlayersByPermission("admin")
                test("Player — getPlayersByPermission retorna tabela", type(adminPlayers) == "table", type(adminPlayers), "table")
                print(("^5[INFO]^7 Players com permissão 'admin': %d"):format(#adminPlayers))

                -- ── DUMP: lista de admins online ──
                if #adminPlayers > 0 then
                    local adminList = {}
                    for i, adm in ipairs(adminPlayers) do
                        if type(adm) == "table" and adm.userId and adm.userSource then
                            adminList[#adminList + 1] = {
                                userId = adm.userId(),
                                source = adm.userSource()
                            }
                        end
                    end
                    dump("Admins Online", adminList)
                end
            end
        end
    end

    Wait(500)

    -- ==============================
    --  ETAPA 4: Player offline
    -- ==============================
    print("")
    print("^6[ETAPA 4/5]^7 Player offline / inexistente")
    do
        local offlinePlayer = fwData.getPlayerById("__dk_test_invalid_id_999__")
        test("Player — getPlayerById inválido retorna tabela", type(offlinePlayer) == "table", type(offlinePlayer), "table")
        if offlinePlayer then
            test("Player — player inexistente online=false", offlinePlayer.online == false, offlinePlayer.online, false)

            -- Dump da tabela retornada para player offline
            dump("Player Offline", offlinePlayer)
        end
    end
    do
        -- getPlayer com source inválida (9999) deve retornar nil
        local nilPlayer = fwData.getPlayer(9999)
        test("Player — getPlayer(9999) retorna nil", nilPlayer == nil, tostring(nilPlayer), "nil")
    end

    Wait(500)

    -- ==============================
    --  ETAPA 5: Dump geral do server
    -- ==============================
    print("")
    print("^6[ETAPA 5/5]^7 Dump geral — informações do servidor")
    do
        local players = GetPlayers()
        local playerCount = #players

        local serverInfo = {
            framework        = fwName,
            resource         = GetCurrentResourceName(),
            playerCount      = playerCount,
            maxPlayers       = GetConvarInt("sv_maxclients", 0),
            gameBuild        = GetConvarInt("sv_enforceGameBuild", 0),
        }
        dump("Server Info", serverInfo)

        -- ── DUMP: lista de todos os jogadores online ──
        if playerCount > 0 then
            print("")
            print(("^5[INFO]^7 Jogadores online: %d"):format(playerCount))
            local playerList = {}
            for _, playerSrc in ipairs(players) do
                local src = tonumber(playerSrc)
                if src then
                    local entry = {
                        source = src,
                        name   = GetPlayerName(src) or "??",
                        ping   = GetPlayerPing(src),
                    }

                    -- Tentar pegar identidade pelo framework (somente leitura)
                    local ok, fwPlayer = pcall(fwData.getPlayer, src)
                    if ok and fwPlayer and fwPlayer.userId then
                        local okId, uid = pcall(fwPlayer.userId)
                        if okId then
                            entry.userId = uid
                        end
                    end

                    playerList[#playerList + 1] = entry
                end
            end
            dump("Players Online", playerList)
        end
    end

    -- =====================
    --       RESULTADO
    -- =====================
    print("")
    print("^3=============================================^7")
    print(("^3  Resultado: %d/%d testes passaram^7"):format(passed, total))
    if skipped > 0 then
        print(("^3  %d teste(s) pulados (sem jogador online)^7"):format(skipped))
    end
    if failed > 0 then
        print(("^1  %d teste(s) falharam!^7"):format(failed))
    else
        print("^2  Todos os testes executados passaram!^7")
    end
    print("^3=============================================^7")
end)
