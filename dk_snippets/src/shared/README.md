# 🔄 Documentação Shared (Client & Server)

Esta documentação detalha todas as funcionalidades compartilhadas disponíveis tanto no cliente quanto no servidor.

## 📋 Índice

- [Callbacks System](#-callbacks-system)
- [Cooldown Manager](#-cooldown-manager)
- [Utility Functions](#-utility-functions)
- [Table Extensions](#-table-extensions)

---

## 📡 Callbacks System

Sistema robusto de callbacks para comunicação bidirecional entre client e server com suporte a timeout.

### Licença

Baseado na implementação de [PiterMcFlebor](https://github.com/pitermcflebor/pmc-callbacks) sob licença MIT.

---

### Funções Server-Side

#### `RegisterServerCallback(eventName, callback)`

Registra um callback no servidor que pode ser chamado pelo cliente.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `eventName` | string | Nome único do evento |
| `callback` | function | Função a ser executada |

**Exemplo:**
```lua
RegisterServerCallback('getVehicleName', function(source, vehId)
    local vehicleNames = {
        [1] = "Sultan",
        [2] = "Adder",
        [3] = "Zentorno"
    }
    return vehicleNames[vehId] or "Unknown"
end)

-- Com lógica de banco de dados
RegisterServerCallback('getUserData', function(source)
    local user = FW.getPlayer(source)
    if not user then return nil end
    
    local user_id = user.userId()
    local db = exports["dk_snippets"]:DB()
    
    local userData = db.execute("SELECT * FROM users WHERE id = ?", {user_id})[1]
    return {
        name = userData.name,
        money = userData.money,
        bank = userData.bank
    }
end)
```

---

#### `TriggerClientCallback(source, eventName, args, callback, timeout, timedout)`

Dispara um callback no cliente a partir do servidor.

**Parâmetros:**
| Parâmetro | Tipo | Descrição | Obrigatório |
|-----------|------|-----------|-------------|
| `source` | number | ID do jogador | ✅ |
| `eventName` | string | Nome do callback client | ✅ |
| `args` | table | Argumentos a passar | ❌ |
| `callback` | function | Função para processar resposta | ❌ |
| `timeout` | number | Timeout em segundos | ❌ (padrão: 30) |
| `timedout` | function | Função se der timeout | ❌ |

**Exemplos:**
```lua
-- Obter posição do jogador
TriggerClientCallback(source, 'getPlayerCoords', {}, function(coords)
    print("Jogador está em: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
end)

-- Com timeout customizado
TriggerClientCallback(source, 'confirmAction', {action = "delete_character"}, 
    function(confirmed)
        if confirmed then
            -- Executar ação
        end
    end,
    15,  -- 15 segundos de timeout
    function()
        print("Jogador não respondeu a tempo")
    end
)

-- Verificar se jogador está em veículo
TriggerClientCallback(source, 'isInVehicle', {}, function(inVehicle, vehicleModel)
    if inVehicle then
        print("Jogador está em: " .. vehicleModel)
    end
end)
```

---

#### `UnregisterServerCallback(eventData)`

Remove um callback do servidor.

**Exemplo:**
```lua
local callback = RegisterServerCallback('tempEvent', function(source)
    return "data"
end)

-- Depois de usar, desregistrar
UnregisterServerCallback(callback)
```

---

### Funções Client-Side

#### `RegisterClientCallback(eventName, callback)`

Registra um callback no cliente que pode ser chamado pelo servidor.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `eventName` | string | Nome único do evento |
| `callback` | function | Função a ser executada |

**Exemplos:**
```lua
-- Callback simples
RegisterClientCallback('getPlayerCoords', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }
end)

-- Callback com lógica
RegisterClientCallback('isInVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 then
        local model = GetEntityModel(vehicle)
        return true, GetDisplayNameFromVehicleModel(model)
    end
    
    return false, nil
end)

-- Callback que retorna dados complexos
RegisterClientCallback('getVehicleInfo', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 then
        return {
            model = GetEntityModel(vehicle),
            plate = GetVehicleNumberPlateText(vehicle),
            health = GetVehicleEngineHealth(vehicle),
            fuel = GetVehicleFuelLevel(vehicle)
        }
    end
    
    return nil
end)
```

---

#### `TriggerServerCallback(eventName, args, callback, timeout, timedout)`

Chama um callback do servidor a partir do cliente.

**Parâmetros:**
| Parâmetro | Tipo | Descrição | Obrigatório |
|-----------|------|-----------|-------------|
| `eventName` | string | Nome do callback server | ✅ |
| `args` | table | Argumentos a passar | ❌ |
| `callback` | function | Função para processar resposta | ❌ |
| `timeout` | number | Timeout em segundos | ❌ (padrão: 30) |
| `timedout` | function | Função se der timeout | ❌ |

**Exemplos:**
```lua
-- Uso síncrono (aguarda resposta)
local money = TriggerServerCallback('getPlayerMoney', {})
print("Seu dinheiro: $" .. money)

-- Uso com callback assíncrono
TriggerServerCallback('buyItem', {itemId = 123, amount = 5}, function(success, message)
    if success then
        DkNotify("green", message, 5000)
    else
        DkNotify("red", message, 5000)
    end
end)

-- Com timeout
local data = TriggerServerCallback('heavyOperation', {}, nil, 60, function()
    DkNotify("red", "Operação demorou muito tempo", 5000)
end)
```

---

#### `UnregisterClientCallback(eventData)`

Remove um callback do cliente.

**Exemplo:**
```lua
local callback = RegisterClientCallback('tempEvent', function()
    return "data"
end)

UnregisterClientCallback(callback)
```

---

### Exemplo Completo: Sistema de Troca

```lua
-- Server-side
local tradeRequests = {}

RegisterServerCallback('trade:request', function(source, targetId)
    if tradeRequests[targetId] then
        return {success = false, message = "Jogador já tem uma solicitação pendente"}
    end
    
    tradeRequests[targetId] = source
    
    TriggerClientCallback(targetId, 'trade:confirm', {senderId = source}, function(accepted)
        if accepted then
            -- Iniciar troca
            TriggerClientEvent('trade:start', source, targetId)
            TriggerClientEvent('trade:start', targetId, source)
        else
            TriggerClientEvent('trade:denied', source)
        end
        tradeRequests[targetId] = nil
    end, 20, function()
        TriggerClientEvent('trade:timeout', source)
        tradeRequests[targetId] = nil
    end)
    
    return {success = true, message = "Solicitação enviada"}
end)

-- Client-side
RegisterClientCallback('trade:confirm', function(data)
    local senderId = data.senderId
    local accepted = exports["dk_snippets"]:request(
        "Jogador " .. senderId .. " quer trocar itens com você",
        20,
        "Aceitar",
        "Recusar"
    )
    return accepted
end)

RegisterCommand('trade', function(source, args)
    local targetId = tonumber(args[1])
    
    if not targetId then
        DkNotify("red", "Use: /trade [id]", 5000)
        return
    end
    
    local result = TriggerServerCallback('trade:request', {targetId})
    DkNotify(result.success and "green" or "red", result.message, 5000)
end)
```

---

## ⏱️ Cooldown Manager

Sistema de gerenciamento de cooldowns com métodos simples e eficientes.

### Classe Cooldown

#### `Cooldown:new(timer)`

Cria uma nova instância de cooldown.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `timer` | number | Duração padrão em segundos (opcional) |

**Retorno:** Instância de Cooldown

**Exemplo:**
```lua
local skillCooldown = Cooldown:new(30)  -- 30 segundos padrão
```

---

#### `Cooldown:start(timer)`

Inicia um cooldown.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `timer` | number | Duração em segundos (opcional, usa o padrão) |

**Exemplo:**
```lua
skillCooldown:start(45)  -- Inicia com 45 segundos
skillCooldown:start()    -- Usa o valor padrão (30)
```

---

#### `Cooldown:reset()`

Reseta/para o cooldown.

**Exemplo:**
```lua
skillCooldown:reset()
```

---

#### `Cooldown:check()`

Verifica se o cooldown está ativo e retorna tempo restante.

**Retorno:** `number|nil` - Segundos restantes ou `nil` se inativo

**Exemplo:**
```lua
local remaining = skillCooldown:check()
if remaining then
    print("Cooldown ativo. Faltam " .. remaining .. " segundos")
else
    print("Cooldown não está ativo")
end
```

---

#### `Cooldown:checkAndCreate(timer, func)`

Verifica cooldown e, se inativo, inicia um novo. Se ativo, executa função callback.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `timer` | number | Duração em segundos (opcional) |
| `func` | function | Função a executar se cooldown ativo |

**Retorno:** `boolean` - `true` se iniciou cooldown, `false` se já estava ativo

**Exemplos:**
```lua
local success = cooldown:checkAndCreate(nil, function(remaining)
    DkNotify("yellow", "Aguarde " .. remaining .. " segundos", 3000)
end)

if success then
    -- Executar habilidade
    print("Habilidade usada!")
end
```

---

### Exemplos Práticos de Cooldown

#### Exemplo 1: Sistema de Habilidades

```lua
-- Server-side
local playerCooldowns = {}

RegisterServerCallback('skill:use', function(source, skillName)
    local user = FW.getPlayer(source)
    if not user then return {success = false} end
    
    local user_id = user.userId()
    
    -- Criar cooldown se não existir
    if not playerCooldowns[user_id] then
        playerCooldowns[user_id] = {}
    end
    
    if not playerCooldowns[user_id][skillName] then
        playerCooldowns[user_id][skillName] = Cooldown:new()
    end
    
    local cooldown = playerCooldowns[user_id][skillName]
    
    local success = cooldown:checkAndCreate(60, function(remaining)
        TriggerClientEvent('dk/notify', source, "warning", 
            "Aguarde " .. remaining .. " segundos para usar novamente", 3000)
    end)
    
    if success then
        -- Executar habilidade
        TriggerClientEvent('skill:execute', source, skillName)
        return {success = true}
    end
    
    return {success = false}
end)
```

#### Exemplo 2: Comando com Cooldown

```lua
-- Client-side
local commandCooldown = Cooldown:new(300)  -- 5 minutos

RegisterCommand('evento', function()
    local success = commandCooldown:checkAndCreate(nil, function(remaining)
        local minutes = math.floor(remaining / 60)
        local seconds = remaining % 60
        DkNotify("red", string.format("Aguarde %dm %ds", minutes, seconds), 5000)
    end)
    
    if success then
        TriggerServerEvent('evento:start')
    end
end)
```

#### Exemplo 3: Cooldown Individual por Jogador

```lua
-- Server-side
local robberySystem = {
    cooldowns = {}
}

function robberySystem:canRob(user_id)
    if not self.cooldowns[user_id] then
        self.cooldowns[user_id] = Cooldown:new(1800)  -- 30 minutos
    end
    
    local remaining = self.cooldowns[user_id]:check()
    if remaining then
        return false, remaining
    end
    
    return true
end

function robberySystem:startRobbery(source)
    local user = FW.getPlayer(source)
    if not user then
        return {success = false, message = "Jogador não encontrado"}
    end
    
    local user_id = user.userId()
    local canRob, remaining = self:canRob(user_id)
    
    if not canRob then
        return {
            success = false,
            message = "Aguarde " .. math.floor(remaining / 60) .. " minutos"
        }
    end
    
    self.cooldowns[user_id]:start()
    -- Lógica do roubo
    
    return {success = true, message = "Roubo iniciado!"}
end

RegisterServerCallback('robbery:start', function(source)
    return robberySystem:startRobbery(source)
end)
```

---

## 🛠️ Utility Functions

Coleção de funções auxiliares úteis para desenvolvimento.

### `DkNotify(...)`

Envia notificações para client ou server.

**Client-side:**
```lua
DkNotify(mode, message, time, title)
```

**Server-side:**
```lua
DkNotify(source, mode, message, time, title)
```

**Exemplos:**
```lua
-- Client
DkNotify("green", "Ação realizada!", 5000)

-- Server
DkNotify(source, "red", "Sem permissão", 5000, "Admin")
```

---

### `Dump(value, depth, key)`

Exibe o conteúdo de uma variável de forma legível.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `value` | any | Valor a exibir |
| `depth` | number | Profundidade atual (opcional) |
| `key` | any | Chave associada (opcional) |

**Exemplos:**
```lua
local playerData = {
    name = "John",
    age = 30,
    inventory = {
        {item = "water", amount = 5},
        {item = "bread", amount = 3}
    }
}

Dump(playerData)
--[[
Saída:
    [name] = "John",
    [age] = 30,
    [inventory]
        [1]
            [item] = "water"
            [amount] = 5
        [2]
            [item] = "bread"
            [amount] = 3
]]
```

---

### `Match(str, datas)`

Faz correspondência de string com valores em uma tabela (similar ao switch/case).

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `str` | string | String a corresponder |
| `datas` | table | Tabela com correspondências |

**Retorno:** Valor correspondente ou executa função, retorna `default` se não encontrar

**Exemplos:**
```lua
-- Match simples
local result = Match("admin", {
    admin = "Administrador",
    mod = "Moderador",
    user = "Usuário",
    default = "Desconhecido"
})
print(result)  -- "Administrador"

-- Match com funções
local action = Match(userRole, {
    admin = function()
        return "Acesso total"
    end,
    mod = function()
        return "Acesso limitado"
    end,
    default = function()
        return "Sem acesso"
    end
})

-- Match para permissões
local permission = Match(command, {
    kick = "admin.kick",
    ban = "admin.ban",
    tp = "admin.teleport",
    default = nil
})
```

---

### `Ensure(obj, typeof, opt_typeof, errMessage)`

Garante que um objeto é do tipo esperado, lança erro se não for.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `obj` | any | Objeto a verificar |
| `typeof` | string\|function | Tipo primário esperado |
| `opt_typeof` | string | Tipo secundário (opcional) |
| `errMessage` | string | Mensagem de erro customizada |

**Exemplos:**
```lua
-- Validação simples
Ensure(userId, "number")

-- Validação com tipo alternativo
Ensure(value, "string", "number")

-- Validação com mensagem customizada
Ensure(callback, "function", nil, "Callback deve ser uma função")

-- Uso em função
function setPlayerMoney(user_id, amount)
    Ensure(user_id, "number", nil, "user_id deve ser um número")
    Ensure(amount, "number", nil, "amount deve ser um número")
    
    -- Lógica da função
end
```

---

## 📊 Table Extensions

Extensões úteis para manipulação de tabelas.

### `table.count(self)`

Conta elementos em uma tabela.

**Exemplo:**
```lua
local items = {apple = 1, banana = 2, orange = 3}
print(table.count(items))  -- 3

local arr = {1, 2, 3, 4, 5}
print(table.count(arr))  -- 5
```

---

### `table.map(self, func, preventIndex)`

Mapeia uma função para cada elemento.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `self` | table | Tabela a mapear |
| `func` | function | Função a aplicar |
| `preventIndex` | boolean | Prevenir indexação |

**Exemplos:**
```lua
local numbers = {1, 2, 3, 4, 5}
local doubled = table.map(numbers, function(value)
    return value * 2
end)
-- doubled = {2, 4, 6, 8, 10}

local players = {
    {name = "John", level = 5},
    {name = "Jane", level = 10}
}
local names = table.map(players, function(player)
    return player.name
end)
-- names = {"John", "Jane"}
```

---

### `table.forEach(self, func)`

Itera sobre cada elemento.

**Exemplo:**
```lua
local items = {"water", "bread", "phone"}
table.forEach(items, function(item)
    print("Item: " .. item)
end)
```

---

### `table.find(self, func, keepIndex)`

Encontra elementos que correspondem a critérios.

**Exemplos:**
```lua
local numbers = {1, 2, 3, 4, 5, 6}
local evens = table.find(numbers, function(num)
    return num % 2 == 0
end)
-- evens = {2, 4, 6}

local players = {
    {name = "John", vip = true},
    {name = "Jane", vip = false},
    {name = "Bob", vip = true}
}
local vips = table.find(players, function(player)
    return player.vip
end)
-- vips contém John e Bob
```

---

### `table.indexOf(self, o)`

Encontra o índice de um elemento.

**Exemplo:**
```lua
local fruits = {"apple", "banana", "orange"}
local index = table.indexOf(fruits, "banana")
print(index)  -- 2
```

---

<div align="center">

**[⬅️ Server Docs](../server/SERVER.md)** | **[➡️ Voltar ao README](../../../README.md)**

</div>