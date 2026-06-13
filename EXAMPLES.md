# Exemplos

Todos os exemplos assumem:

```lua
---@type dk.snippets
local snippets = require '@dk_snippets/snippets'
```

## notify (base)

```lua
-- Server (com source)
snippets.notify.send(src, snippets.notify.modes.GREEN, 'Compra efetuada!', 4000)

-- Client (sem source)
snippets.notify.send('red', 'Saldo insuficiente', 3000)
```

## hint

```lua
-- Server
snippets.notify.hint(src, 'create', 'open_door', 'Pressione ~INPUT_CONTEXT~ para abrir', 'E')
snippets.notify.hint(src, 'remove', 'open_door')
```

## request (confirmação)

```lua
-- Server: pergunta ao jogador e aguarda a resposta (boolean)
local aceitou = snippets.request(src, 'Deseja comprar este item por $500?', 15)
if aceitou then
    -- prosseguir
end
```

## framework + Player (com açúcar)

```lua
local fw = snippets.framework
print('Framework:', fw.getFramework())

local player = fw.getPlayer(src)
if player.online then
    local id = player.userId()
    if player.isAdmin() then
        player.notify('blue', 'Bem-vindo, admin!')
    end

    -- Açúcar: notify/hint/request já sabem a source
    if player.paymentBank(500) then
        player.giveItem('water', 1, true)
        player.notify('green', 'Compra concluída!')
    else
        player.notify('red', 'Saldo insuficiente')
    end
end
```

## cooldown

```lua
local Cooldown = snippets.cooldown
local cd = Cooldown:new(30) -- 30 segundos

if cd:checkAndCreate(nil, function(seconds)
    print('Aguarde ' .. seconds .. 's')
end) then
    -- liberado: executa a ação
end
```

## class

```lua
local Class = snippets.class

local Animal = Class({ name = 'Unknown' })
function Animal:constructor(name) self.name = name end
function Animal:speak() return 'Sou ' .. self.name end

local dog = Animal:new('Rex')
print(dog:speak()) -- Sou Rex

-- Herança
local Dog = Animal:extend({ legs = 4 })
```

## table / string / number

```lua
local tbl = snippets.table
local doubled = tbl.map({1, 2, 3}, function(v) return v * 2 end) -- {2,4,6}
local evens = tbl.find({1,2,3,4}, function(v) return v % 2 == 0 end) -- {2,4}

local str = snippets.string
local parts = str.Split('a-b-c', '-')      -- {"a","b","c"}
local money = str.ParseFormat(1000000)     -- "1.000.000"

local number = snippets.number
print(number.ParseInt('42'))   -- 42
print(number.Round(3.14159, 2)) -- 3.14
```

## callbacks

```lua
local cb = snippets.callbacks

-- Server
cb.RegisterServerCallback('shop:buy', function(source, itemId, price)
    local player = snippets.framework.getPlayer(source)
    if player.online and player.paymentBank(price) then
        return { success = true }
    end
    return { success = false }
end)

-- Client
local result = cb.TriggerServerCallback('shop:buy', { 'water', 500 })
```

## json (persistência em arquivo)

```lua
local db = snippets.json:fetch('data/economy') -- lê data/economy.json
db:insert('accounts', { name = 'Rex', balance = 100 })
local found = db:where('accounts', { name = 'Rex' })
db:update('accounts', { name = 'Rex' }, { balance = 200 })
```

## db (SQL)

```lua
local SQL = snippets.db()  -- inicializa o driver e retorna a interface

local rows = SQL.select('users', { { identifier = 'abc' } }, nil, 1)
SQL.insert('users', { identifier = 'abc', name = 'Rex' })
SQL.update('users', { name = 'Novo' }, { { identifier = 'abc' } })
```
