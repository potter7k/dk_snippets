# Customização de Framework

Esta pasta permite **sobrescrever** e **adicionar** funções do framework do
`dk_snippets` sem editar os arquivos base (`esx.lua`, `qbcore.lua`, `vrp/*`,
`nofw.lua`). Suas customizações **sobrevivem a atualizações** (`git pull`).

## Como customizar

1. Escolha o arquivo do seu framework e copie o `.example` removendo o sufixo:
   - ESX → copie `esx.lua.example` para `esx.lua`
   - QBCore → `qbcore.lua.example` → `qbcore.lua`
   - vRP (qualquer variante) → `vrp.lua.example` → `vrp.lua`
   - Sem framework → `nofw.lua.example` → `nofw.lua`
2. Edite o arquivo `.lua` que você criou (o `.example` é só referência).
3. Reinicie o recurso: `restart dk_snippets`.

> Seu `<framework>.lua` está no `.gitignore` — não é versionado e **não é
> sobrescrito** quando você atualiza o dk_snippets. Os `.example` podem mudar
> entre versões; reveja-os após updates para ver novidades.

## Formato

Cada arquivo retorna uma tabela com duas seções opcionais:

```lua
return {
    functions = { ... }, -- funções de nível FW (snippets.framework.*)
    player = { ... },    -- métodos de cada Player online
}
```

### `functions` — nível do framework

Substituem ou adicionam funções em `snippets.framework.*`. Recebem `(fw, ...)`,
onde `fw` é o `FWData` (dá pra chamar `fw.getPlayer`, etc.).

```lua
functions = {
    getVip = function(fw, source)
        local p = fw.getPlayer(source)
        return p.online and p.hasPermission('vip') or false
    end,
}
-- uso: snippets.framework.getVip(source)
```

### `player` — métodos de Player

Aplicados a cada `Player` **online**. Recebem `(player, ...)`. O comportamento
original fica acessível em `player.__original.<nome>` (é `nil` se você estiver
**adicionando** um método novo, não sobrescrevendo).

```lua
player = {
    giveItem = function(player, item, amount, notify)
        -- estende o original
        return player.__original.giveItem(item, amount, notify)
    end,
    isStaff = function(player) -- método novo
        return player.isAdmin()
    end,
}
-- uso: local p = snippets.framework.getPlayer(src); p.isStaff()
```

## Notas

- O custom é carregado **só** para o framework detectado, sob demanda. Sem custom
  = comportamento padrão (a ausência do arquivo é normal, não gera erro).
- `vrp.lua` vale para **todas** as variantes do vRP. Use `fw.getFramework()`
  (ex.: `"vrp.crv3"`) se precisar distinguir.
- Erros de sintaxe/runtime no seu arquivo aparecem no console apontando o
  `custom/<fw>.lua` — corrija lá.
- Toda a customização é **server-side** (o framework é server-only).
