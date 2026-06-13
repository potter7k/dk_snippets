-- DIAGNÓSTICO temporário — remover depois.
CreateThread(function()
    Wait(1000)
    print("^5[DIAG]^7 GetCurrentResourceName = " .. tostring(GetCurrentResourceName()))
    print("^5[DIAG]^7 require existe? " .. tostring(type(require)))
    print("^5[DIAG]^7 package existe? " .. tostring(type(package)))
    if type(package) == "table" then
        print("^5[DIAG]^7 package.path = " .. tostring(package.path))
        print("^5[DIAG]^7 package.searchers (polyfill nosso?) = " .. tostring(type(package.searchers)))
    end
    print("^5[DIAG]^7 marcador instalado? = " .. tostring(_dk_snippets_require_installed))

    -- Tenta ler o snippets.lua diretamente
    local raw = LoadResourceFile(GetCurrentResourceName(), "snippets.lua")
    print("^5[DIAG]^7 LoadResourceFile(self, 'snippets.lua') = " .. (raw and ("OK len=" .. #raw) or "NIL"))

    local raw2 = LoadResourceFile("dk_snippets", "snippets.lua")
    print("^5[DIAG]^7 LoadResourceFile('dk_snippets', 'snippets.lua') = " .. (raw2 and ("OK len=" .. #raw2) or "NIL"))

    local raw3 = LoadResourceFile("dk_snippets", "lib/require.lua")
    print("^5[DIAG]^7 LoadResourceFile('dk_snippets', 'lib/require.lua') = " .. (raw3 and ("OK len=" .. #raw3) or "NIL"))

    -- Tenta o require de fato, capturando o erro completo
    local ok, err = pcall(require, "@dk_snippets/snippets")
    print("^5[DIAG]^7 pcall(require, '@dk_snippets/snippets') ok=" .. tostring(ok))
    if not ok then
        print("^1[DIAG]^7 erro: " .. tostring(err))
    end
end)
