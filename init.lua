-- init.lua — ponto de entrada do dk_snippets.
-- Injeta o polyfill `require` (port do ox_lib) no ambiente do recurso que carrega
-- este arquivo. O polyfill entende `require '@recurso/modulo'` e preserva o
-- `require` nativo do CitizenFX como primeiro searcher.
--
-- IMPORTANTE: não usar `if not require` aqui — o servidor do CitizenFX já possui
-- um `require` nativo que NÃO entende a sintaxe `@recurso/modulo`. Precisamos
-- sempre instalar o polyfill (uma vez por recurso), usando um marcador próprio.
if not _dk_snippets_require_installed then
    local resource = 'dk_snippets'
    local chunk = LoadResourceFile(resource, 'lib/require.lua')
    if not chunk then
        error('dk_snippets: não foi possível carregar lib/require.lua')
    end
    local fn = load(chunk, ('@@%s/lib/require.lua'):format(resource), 't', _ENV)
    if not fn then
        error('dk_snippets: falha ao compilar lib/require.lua')
    end
    fn()
    ---@diagnostic disable-next-line: lowercase-global
    _dk_snippets_require_installed = true
end
