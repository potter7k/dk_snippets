# 🖥️ Documentação Server-Side

Esta documentação detalha todas as funcionalidades disponíveis no lado do servidor (server-side) do DK Snippets.

## 📋 Índice

- [Database Operations](#-database-operations)
- [JSON File Handler](#-json-file-handler)
- [Callbacks Server-Side](#-callbacks-server-side)
- [Framework Detection](#-framework-detection)
- [Request System](#-request-system)

---

## 🗄️ Database Operations

Sistema completo para operações de banco de dados com suporte a múltiplos drivers SQL.

### Inicialização

```lua
local db = exports["dk_snippets"]:DB()
```

### Drivers Suportados

O script detecta automaticamente o driver SQL ativo:
- ✅ **oxmysql**
- ✅ **ghmattimysql** / **GHMattiMySQL**
- ✅ **mysql-async**

---

### Métodos Disponíveis

#### `db.hasTable(name)`

Verifica se uma tabela existe no banco de dados.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `name` | string | Nome da tabela |

**Retorno:** `boolean` - `true` se a tabela existe

**Exemplo:**
```lua
if db.hasTable("users") then
    print("A tabela 'users' existe!")
else
    print("Tabela não encontrada")
end
```

---

#### `db.hasColumn(table, column)`

Verifica se uma coluna existe em uma tabela específica.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `table` | string | Nome da tabela |
| `column` | string | Nome da coluna |

**Retorno:** `boolean` - `true` se a coluna existe

**Exemplo:**
```lua
if db.hasColumn("users", "email") then
    print("A coluna 'email' existe na tabela 'users'")
end
```

---

#### `db.execute(sql, params)`

Executa uma query SQL.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `sql` | string | Query SQL |
| `params` | table | Parâmetros da query (opcional) |

**Retorno:** `any` - Resultado da query

**Exemplos:**
```lua
-- SELECT simples
local users = db.execute("SELECT * FROM users WHERE age > ?", {25})
for _, user in ipairs(users) do
    print("Usuário: " .. user.name .. " - Idade: " .. user.age)
end

-- UPDATE
local affectedRows = db.execute("UPDATE users SET money = money + ? WHERE id = ?", {500, 1})
print("Linhas afetadas: " .. affectedRows)

-- DELETE
db.execute("DELETE FROM users WHERE banned = ?", {1})

-- INSERT
local insertId = db.execute("INSERT INTO users (name, age) VALUES (?, ?)", {"John", 30})
print("ID inserido: " .. insertId)
```

---

#### `db.insert(table_name, data, operation)`

Insere dados em uma tabela de forma simplificada.

**Parâmetros:**
| Parâmetro | Tipo | Descrição | Obrigatório |
|-----------|------|-----------|-------------|
| `table_name` | string | Nome da tabela | ✅ |
| `data` | table | Dados a inserir | ✅ |
| `operation` | string | Operação SQL (padrão: 'INSERT') | ❌ |

**Retorno:** `number` - ID do registro inserido

**Exemplos:**
```lua
-- INSERT simples
local userId = db.insert("users", {
    name = "John Doe",
    age = 30,
    email = "john@example.com"
})
print("Usuário criado com ID: " .. userId)

-- INSERT com REPLACE
db.insert("users", {
    id = 1,
    name = "Updated Name"
}, "REPLACE")

-- INSERT IGNORE
db.insert("users", {
    email = "existing@email.com"
}, "INSERT IGNORE")

-- INSERT múltiplo
local players = {
    {name = "Player1", level = 1},
    {name = "Player2", level = 5},
    {name = "Player3", level = 10}
}

for _, player in ipairs(players) do
    db.insert("players", player)
end
```

---

### Exemplo Completo: Sistema de Economia

```lua
-- Adicionar dinheiro ao jogador
local function addMoney(user_id, amount)
    if not db.hasTable("users") then
        print("Tabela 'users' não existe!")
        return false
    end
    
    if not db.hasColumn("users", "money") then
        print("Coluna 'money' não existe!")
        return false
    end
    
    local result = db.execute(
        "UPDATE users SET money = money + ? WHERE id = ?",
        {amount, user_id}
    )
    
    return result > 0
end

-- Registrar transação
local function logTransaction(user_id, type, amount)
    db.insert("transactions", {
        user_id = user_id,
        type = type,
        amount = amount,
        date = os.date("%Y-%m-%d %H:%M:%S")
    })
end

-- Uso
RegisterServerCallback('bank:deposit', function(source, amount)
    local user = FW.getPlayer(source)
    if not user then return {success = false, message = "Jogador não encontrado"} end
    
    local user_id = user.userId()
    
    if addMoney(user_id, amount) then
        logTransaction(user_id, "deposit", amount)
        return {success = true, message = "Depósito realizado!"}
    else
        return {success = false, message = "Erro ao depositar"}
    end
end)
```

---

## 📄 JSON File Handler

Sistema avançado para manipulação de arquivos JSON como banco de dados.

### Inicialização

```lua
local jsonData = JSON:fetch(filePath)
```

**Parâmetro:**
- `filePath` (string): Caminho do arquivo JSON (sem extensão .json)

---

### Métodos Disponíveis

#### `JSON:fetch(filePath)`

Carrega dados de um arquivo JSON.

**Exemplo:**
```lua
local users = JSON:fetch("data/users")
-- Carrega: dk_snippets/data/users.json
```

---

#### `JSON:where(key, data, keepIndex)`

Filtra dados baseado em critérios.

**Parâmetros:**
| Parâmetro | Tipo | Descrição | Obrigatório |
|-----------|------|-----------|-------------|
| `key` | string | Chave a buscar | ✅ |
| `data` | table | Critérios de filtro | ✅ |
| `keepIndex` | boolean | Manter índices originais | ❌ |

**Retorno:** `table` - Dados filtrados

**Exemplos:**
```lua
local jsonData = JSON:fetch("data/users")

-- Filtro simples
local adults = jsonData:where("users", {age = 30})

-- Filtro múltiplo
local admins = jsonData:where("users", {
    role = "admin",
    active = true
})

-- Manter índices
local specificUsers = jsonData:where("users", {level = 5}, true)
```

---

#### `JSON:insert(key, data)`

Insere um novo registro com ID auto-incremental.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `key` | string | Chave onde inserir |
| `data` | table | Dados a inserir |

**Retorno:** `table` - Informações da inserção (id, success)

**Exemplos:**
```lua
local jsonData = JSON:fetch("data/users")

-- Inserir usuário
local result = jsonData:insert("users", {
    name = "Alice",
    age = 25,
    email = "alice@example.com"
})

if result.success then
    print("Usuário criado com ID: " .. result.id)
end

-- Inserir múltiplos
for i = 1, 5 do
    jsonData:insert("users", {
        name = "User " .. i,
        level = i * 10
    })
end
```

---

#### `JSON:update(key, data, newData, replace)`

Atualiza registros existentes.

**Parâmetros:**
| Parâmetro | Tipo | Descrição | Obrigatório |
|-----------|------|-----------|-------------|
| `key` | string | Chave a atualizar | ✅ |
| `data` | table | Critérios de busca | ✅ |
| `newData` | table | Novos dados | ✅ |
| `replace` | boolean | Substituir registro completo | ❌ |

**Retorno:** `table` - Informações da atualização (affected, success)

**Exemplos:**
```lua
local jsonData = JSON:fetch("data/users")

-- Atualizar campo específico
local result = jsonData:update("users", 
    {name = "Alice"}, 
    {age = 26}
)
print("Registros atualizados: " .. result.affected)

-- Atualizar múltiplos campos
jsonData:update("users",
    {role = "user"},
    {role = "member", verified = true}
)

-- Substituir registro completo
jsonData:update("users",
    {id = 1},
    {name = "New Name", age = 30, email = "new@email.com"},
    true
)
```

---

#### `JSON:delete(key, data)`

Deleta registros baseado em critérios.

**Parâmetros:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `key` | string | Chave onde deletar |
| `data` | table | Critérios de filtro |

**Retorno:** `table` - Informações da deleção (affected, success)

**Exemplos:**
```lua
local jsonData = JSON:fetch("data/users")

-- Deletar por nome
local result = jsonData:delete("users", {name = "Alice"})
print("Registros deletados: " .. result.affected)

-- Deletar múltiplos
jsonData:delete("users", {banned = true})

-- Deletar por ID
jsonData:delete("users", {id = 5})
```

---

#### `JSON:tableExists(key)`

Verifica se uma chave existe no JSON.

**Exemplo:**
```lua
local jsonData = JSON:fetch("data/config")

if jsonData:tableExists("settings") then
    print("Settings existe!")
end
```

---

#### `JSON:findAll(key)`

Retorna todos os registros de uma chave.

**Exemplo:**
```lua
local jsonData = JSON:fetch("data/users")

local allUsers = jsonData:findAll("users")
for _, user in ipairs(allUsers) do
    print("ID: " .. user.id .. " - Nome: " .. user.name)
end
```

---

### Exemplo Completo: Sistema de Inventário

```lua
local inventory = JSON:fetch("data/inventory")

-- Adicionar item
local function addItem(user_id, item_name, amount)
    local userItems = inventory:where("items", {user_id = user_id, name = item_name})
    
    if #userItems > 0 then
        -- Item já existe, atualizar quantidade
        inventory:update("items",
            {user_id = user_id, name = item_name},
            {amount = userItems[1].amount + amount}
        )
    else
        -- Novo item
        inventory:insert("items", {
            user_id = user_id,
            name = item_name,
            amount = amount
        })
    end
end

-- Remover item
local function removeItem(user_id, item_name, amount)
    local userItems = inventory:where("items", {user_id = user_id, name = item_name})
    
    if #userItems > 0 then
        local currentAmount = userItems[1].amount
        
        if currentAmount <= amount then
            inventory:delete("items", {user_id = user_id, name = item_name})
        else
            inventory:update("items",
                {user_id = user_id, name = item_name},
                {amount = currentAmount - amount}
            )
        end
        return true
    end
    return false
end

-- Listar inventário
local function getInventory(user_id)
    return inventory:where("items", {user_id = user_id})
end

-- Callbacks
RegisterServerCallback('inventory:add', function(source, item_name, amount)
    local user = FW.getPlayer(source)
    if not user then return {success = false} end
    
    local user_id = user.userId()
    addItem(user_id, item_name, amount)
    return {success = true}
end)

RegisterServerCallback('inventory:get', function(source)
    local user = FW.getPlayer(source)
    if not user then return {} end
    
    local user_id = user.userId()
    return getInventory(user_id)
end)
```

---

## 🔄 Callbacks Server-Side

Sistema de callbacks para comunicação entre server e clients.

### Registrar Callback Server

```lua
RegisterServerCallback(eventName, callback)
```

### Disparar Callback Client

```lua
TriggerClientCallback(source, eventName, args, callback, timeout, timedoutCallback)
```

### Exemplos

```lua
-- Registrar callback
RegisterServerCallback('getPlayerMoney', function(source)
    local user = FW.getPlayer(source)
    if not user then return 0 end
    
    local user_id = user.userId()
    local money = db.execute("SELECT money FROM users WHERE id = ?", {user_id})[1].money
    return money
end)

-- Chamar callback de um client
RegisterServerCallback('admin:freeze', function(source, targetId)
    TriggerClientCallback(targetId, 'freezePlayer', {}, function(success)
        if success then
            print("Jogador " .. targetId .. " foi congelado")
        end
    end, 10, function()
        print("Timeout ao congelar jogador")
    end)
end)
```

Veja mais detalhes em [SHARED.md](../shared/SHARED.md#-callbacks)

---

## 🎯 Framework Detection

Veja documentação completa em [FRAMEWORK.md](framework/FRAMEWORK.md)

---

## 📨 Request System (Server)

### Enviar Request para Client

```lua
DkNotify(source, mode, message, time, title)
```

**Exemplo:**
```lua
RegisterCommand('alert', function(source, args)
    local targetId = tonumber(args[1])
    DkNotify(targetId, "yellow", "Você recebeu um aviso!", 5000, "Administração")
end)
```

---

<div align="center">

**[⬅️ Client Docs](../client/CLIENT.md)** | **[➡️ Shared Docs](../shared/SHARED.md)**

</div>