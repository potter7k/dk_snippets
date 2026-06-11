# dk_snippets

Biblioteca de utilitários para FiveM da DK Development. A partir da **v3.0.0** o
recurso usa um **ponto de entrada único** via `require`, com módulos carregados
sob demanda.

> **Breaking change (2.x → 3.0.0):** os globais (`DkNotify`, `Class`, `JSON`,
> `SQL`/`DB`, `Framework`, `table.map`, `ParseInt`, ...) e os exports nativos
> (`exports.dk_snippets:framework/DB/request`) **foram removidos**. O consumo
> agora é exclusivamente via `require '@dk_snippets/snippets'`. Veja
> [INSTALLATION.md](INSTALLATION.md) para migrar.

## Uso rápido

No `fxmanifest.lua` do seu recurso:

```lua
dependencies { 'dk_snippets' }
shared_script '@dk_snippets/init.lua'
```

No código:

```lua
---@type dk.snippets
local snippets = require '@dk_snippets/snippets'

snippets.notify.send(src, 'green', 'Bem-vindo!')      -- server (com source)
local player = snippets.framework.getPlayer(src)
if player.online then
    player.notify('green', 'Compra efetuada!')        -- açúcar: já sabe a source
end
```

## Módulos disponíveis

Acessados via `snippets.<modulo>` (carregados sob demanda na primeira utilização).

| Módulo | Lado | Descrição |
|---|---|---|
| `snippets.table` | shared | `map`, `find`, `slice`, `count`, `indexOf`, `contains`, `forEach` (isolados; não tocam a `table` nativa) |
| `snippets.string` | shared | `Split`, `Sanitize`, `Join`, `ParseFormat`, `Match`, `Dump` |
| `snippets.number` | shared | `ParseInt`, `Round` |
| `snippets.class` | shared | `class(defaults, parent?)` — classes com herança |
| `snippets.cooldown` | shared | classe `Cooldown` |
| `snippets.callbacks` | shared | `RegisterServerCallback`, `TriggerClientCallback`, etc. (popula só o lado atual) |
| `snippets.notify` | shared | `notify.send(...)`, `notify.hint(...)`, `notify.modes` |
| `snippets.request` | shared | callable lado-ciente; server dispara confirmação no client |
| `snippets.json` | server | classe `JSON` para persistência em arquivo |
| `snippets.db` | server | `db()` retorna a interface `SQL` (detecta oxmysql/ghmatti/mysql-async) |
| `snippets.framework` | server | `FWData` do framework detectado (`getPlayer`, `getPlayerById`, `getPlayersByPermission`, `getFramework`) |

### Açúcar no `Player`

Todo `Player` **online** retornado pelo framework ganha métodos que já conhecem a
source:

```lua
player.notify(mode, message, duration?)
player.hint(action, id, description, control?, configs?)
player.request(description, timer?, acceptText?, denyText?) -- retorna boolean
```

Em jogadores offline (`online == false`) esses métodos não existem.

## Frameworks suportados

Detecção automática e carregamento sob demanda (somente o framework ativo é
carregado): **ESX**, **QBCore**, **vRP** (variantes crnetwork, crv3, crv5, vrpex) e
fallback **sem framework**.

## Documentação

- [INSTALLATION.md](INSTALLATION.md) — instalação e migração
- [EXAMPLES.md](EXAMPLES.md) — exemplos por módulo

---

Discord: https://discord.gg/NJjUn8Ad3P
