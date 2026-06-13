# Instalação & Migração

## Requisitos

- FiveM com `lua54 'yes'` (já configurado no recurso).
- Para `snippets.db`: um driver SQL iniciado — `oxmysql` (recomendado),
  `ghmattimysql`, `GHMattiMySQL` ou `mysql-async`.
- Para `snippets.framework`: o framework do servidor (ESX / QBCore / vRP) iniciado
  **antes** dos recursos que consomem o dk_snippets.

## Ordem no server.cfg

```
ensure oxmysql
ensure es_extended      # ou qb-core / vrp
ensure dk_snippets
# ... seus recursos que dependem do dk_snippets
```

## Consumindo o dk_snippets em outro recurso

No `fxmanifest.lua` do seu recurso, adicione a dependência e o ponto de entrada:

```lua
dependencies { 'dk_snippets' }

shared_script '@dk_snippets/init.lua'
```

`@dk_snippets/init.lua` injeta a função global `require` no seu recurso. A partir
daí, carregue o que precisar:

```lua
---@type dk.snippets
local snippets = require '@dk_snippets/snippets'
```

> A linha `---@type dk.snippets` é opcional em runtime, mas dá autocomplete e
> assinaturas completas no editor (LuaLS/sumneko) — os tipos vêm do `types.lua`
> do dk_snippets, sem nenhuma configuração extra.

> Você **não** precisa mais listar `@dk_snippets/src/shared/utils.lua`,
> `@dk_snippets/src/server/json.lua`, etc. Apenas `init.lua`. Os módulos são
> carregados sob demanda via `require`.

## Migração da v2.x → v3.0.0

A v3 é uma quebra total de API. Tabela de equivalência:

| Antes (v2.x — global/export) | Agora (v3 — require) |
|---|---|
| `DkNotify(src, mode, msg, dur)` | `snippets.notify.send(src, mode, msg, dur)` |
| `DkHint(src, action, ...)` | `snippets.notify.hint(src, action, ...)` |
| `DkRequest(src, desc, ...)` | `snippets.request(src, desc, ...)` |
| `Class(defaults, parent)` | `snippets.class(defaults, parent)` |
| `Cooldown:new(...)` | `snippets.cooldown:new(...)` |
| `ParseInt(v)` / `Round(v, d)` | `snippets.number.ParseInt(v)` / `snippets.number.Round(v, d)` |
| `SplitString/SanitizeString/Join/ParseFormat` | `snippets.string.Split/Sanitize/Join/ParseFormat` |
| `table.map/find/slice/...` | `snippets.table.map/find/slice/...` |
| `RegisterServerCallback(...)` | `snippets.callbacks.RegisterServerCallback(...)` |
| `TriggerClientCallback(...)` | `snippets.callbacks.TriggerClientCallback(...)` |
| `JSON:fetch(path)` | `snippets.json:fetch(path)` |
| `DB()` / `exports.dk_snippets:DB()` | `snippets.db()` |
| `Framework()` / `exports.dk_snippets:framework()` | `snippets.framework` (já é o `FWData`) |

### Exemplo de migração do manifest

Antes:

```lua
shared_scripts {
    '@dk_snippets/src/shared/utils.lua',
    '@dk_snippets/src/shared/callbacks.lua',
    '@dk_snippets/src/shared/cooldowns.lua',
}
server_scripts { '@dk_snippets/src/server/json.lua' }
```

Depois:

```lua
shared_script '@dk_snippets/init.lua'
-- e no código: local snippets = require '@dk_snippets/snippets'
```
