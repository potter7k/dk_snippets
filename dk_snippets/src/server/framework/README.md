# 🏗️ Framework Detection & Integration

Sistema completo de detecção e integração de frameworks para FiveM.

## 📋 Índice

- [Uso Básico](#-uso-básico)
- [Frameworks Suportados](#-frameworks-suportados)
- [Funções Predefinidas](#-funções-predefinidas)
- [Adicionar Framework Customizado](#-adicionar-framework-customizado)
- [Funções Dinâmicas](#-funções-dinâmicas)

---

## 🚀 Uso Básico

### Exportar Framework Detection

```lua
local frameworkName, FW = exports["dk_snippets"]:framework()
```

**Retorno:**
- `frameworkName` (string|nil): Nome do framework detectado (`"vrp"`, `"esx"`, `"qbcore"`, `nil`)
- `FW` (table): Objeto com funções predefinidas do framework

### Configurar Metatable para Funções Dinâmicas

```lua
local frameworkName, FW = exports["dk_snippets"]:framework()

-- Configurar metatable
FW.__index = function(self, name)
    self[name] = function(...)
        return FW._custom(name, ...)
    end
    return self[name]
end
setmetatable(FW, FW)

-- Agora pode usar qualquer função do framework
local user = FW.getPlayer(source)
if user then
    local user_id = user.userId()
    local isAdmin = user.isAdmin()
end
```

---

## 🎯 Frameworks Suportados

### vRP

**Variações Suportadas:**
- ✅ Creative Network (crnetwork)
- ✅ Creative v3 (crv3)
- ✅ Creative v5 (crv5)
- ✅ vRP EX (vrpex)
- ✅ vRP com InteliSense

**Detecção:**
O script detecta automaticamente qual variação do vRP está ativa no servidor.

### ESX

> 🔄 **Em desenvolvimento**

### QBCore

**Detecção:** O script detecta automaticamente o QBCore verificando o resource `qb-core`.

**Funções Suportadas:**
- ✅ `getPlayer(source)` — Retorna objeto do jogador
- ✅ `getPlayerById(citizenid)` — Busca jogador pelo CitizenID
- ✅ `getPlayersByPermission(perm)` — Lista jogadores com determinada permissão
- ✅ `getPlayersByJob(jobName)` — Lista jogadores com determinado job
- ✅ `_custom(name, ...)` — Chamadas dinâmicas ao `QBCore.Functions`

**Métodos do Jogador (QBCore):**
- `userId()` — Retorna o CitizenID
- `userSource()` — Retorna o source
- `isAdmin()` — Verifica permissão de admin
- `paymentBank(amount)` — Paga usando dinheiro do banco
- `giveBank(amount)` — Adiciona dinheiro ao banco
- `paymentCash(amount)` — Paga usando dinheiro em mãos
- `giveCash(amount)` — Adiciona dinheiro em mãos
- `itemAmount(item)` — Quantidade de um item no inventário
- `takeItem(item, amount, notify)` — Remove item do inventário
- `giveItem(item, amount, notify)` — Adiciona item ao inventário
- `getJob()` — Retorna dados do job
- `getGang()` — Retorna dados da gang
- `hasJob(jobName)` — Verifica se possui determinado job
- `isOnDuty()` — Verifica se está em serviço

### Sem Framework

Se nenhum framework for detectado, o sistema ainda funciona, mas você precisará implementar funções customizadas.

---

## 📚 Funções Predefinidas

As funções predefinidas variam dependendo do framework detectado.

### Funções Comuns (vRP)

#### `FW.getPlayer(source)`
Obtém o objeto do jogador pelo source.

**Parâmetros:**
- `source` (number): Source do jogador

**Retorno:** Objeto com métodos do jogador ou `nil`

**Exemplo:**
```lua
local user = FW.getPlayer(source)
if user then
    local user_id = user.userId()
    local isAdmin = user.isAdmin()
    local money = user.getMoney()
end
```

---

#### `user.userId()`
Obtém o ID do usuário.

**Exemplo:**
```lua
local user = FW.getPlayer(source)
if user then
    local user_id = user.userId()
    print("User ID: " .. user_id)
end
```

---

#### `user.userSource()`
Obtém o source do usuário.

**Exemplo:**
```lua
local user = FW.getPlayer(source)
if user then
    local src = user.userSource()
    print("Source: " .. src)
end
```

---

#### `user.isAdmin()`
Verifica se o jogador é admin.

**Exemplo:**
```lua
local user = FW.getPlayer(source)
if user and user.isAdmin() then
    print("Jogador é admin")
else
    print("Jogador não é admin")
end
```

---

#### `user.getMoney()`
Obtém o dinheiro do jogador.

**Exemplo:**
```lua
local user = FW.getPlayer(source)
if user then
    local money = user.getMoney()
    print("Dinheiro: $" .. money)
end
```

---

#### `FW.getPlayerById(user_id)`
Obtém o objeto do jogador pelo user_id.

**Parâmetros:**
- `user_id` (number): ID do usuário

**Retorno:** Objeto com métodos do jogador ou `nil`

**Exemplo:**
```lua
local targetUserId = 5
local targetUser = FW.getPlayerById(targetUserId)
if targetUser then
    local source = targetUser.userSource()
    local money = targetUser.getMoney()
    print("Jogador " .. targetUserId .. " tem $" .. money)
end
```

---

#### `user.addMoney(amount)`
Adiciona dinheiro ao jogador.

**Exemplo:**
```lua
local user = FW.getPlayer(source)
if user then
    user.addMoney(500)
    print("Adicionado $500")
end
```

---

#### `user.removeMoney(amount)`
Remove dinheiro do jogador.

**Exemplo:**
```lua
local user = FW.getPlayer(source)
if user then
    if user.removeMoney(100) then
        print("Removido $100")
    else
        print("Dinheiro insuficiente")
    end
end
```

---

### Funções Específicas por Framework

Cada framework pode ter funções adicionais específicas. Consulte a documentação do seu framework.

---

## 🔧 Adicionar Framework Customizado

Se você usa um framework não suportado ou uma versão customizada, pode adicionar suporte facilmente.

### Passo 1: Criar Arquivo do Framework

Crie um arquivo em `dk_snippets/src/server/framework/[seu_framework]/`

Exemplo: `dk_snippets/src/server/framework/myframework/myframework.lua`

```lua
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")

local framework = {
    name = "myframework"
}

-- Funções customizadas
function framework.userId(source)
    local user_id = vRP.getUserId({source})
    return user_id
end

function framework.source(user_id)
    local source = vRP.getUserSource({user_id})
    return source
end

function framework.isAdmin(source)
    local user_id = framework.userId(source)
    return vRP.hasPermission({user_id, "admin.permission"})
end

function framework.getMoney(source)
    local user_id = framework.userId(source)
    return vRP.getMoney({user_id})
end

function framework.addMoney(source, amount)
    local user_id = framework.userId(source)
    vRP.giveMoney({user_id, amount})
    return true
end

function framework.removeMoney(source, amount)
    local user_id = framework.userId(source)
    if vRP.tryPayment({user_id, amount}) then
        return true
    end
    return false
end

-- Função para chamadas dinâmicas
function framework._custom(funcName, ...)
    local args = {...}
    
    -- Mapear função para vRP
    if vRP[funcName] then
        return vRP[funcName](args)
    end
    
    print("^3[DK Snippets]^7 Função não encontrada: " .. funcName)
    return nil
end

return framework
```

### Passo 2: Registrar no Handler

Edite `dk_snippets/src/server/framework/!handler.lua`:

```lua
local frameworks = {
    -- Frameworks existentes...
    
    myframework = function()
        -- Condição para detectar seu framework
        if GetResourceState("myframework_resource") == "started" then
            return require("myframework/myframework")
        end
        return nil
    end
}
```

### Passo 3: Adicionar ao fxmanifest

Se necessário, adicione o arquivo ao `fxmanifest.lua`:

```lua
server_scripts {
    'src/server/*',
    'src/server/framework/**/*',
    'src/server/framework/myframework/*'  -- Adicione esta linha
}
```

---

## 🎨 Funções Dinâmicas

O sistema permite chamar funções do framework que não estão predefinidas.

### Exemplo: Função Customizada

```lua
local frameworkName, FW = exports["dk_snippets"]:framework()

-- Configurar metatable
FW.__index = function(self, name)
    self[name] = function(...)
        return FW._custom(name, ...)
    end
    return self[name]
end
setmetatable(FW, FW)

-- Usar função que não está predefinida
local groups = FW.getUserGroups(user_id)  -- Chama direto do framework
local hasLicense = FW.hasDriverLicense(source)
```

### Definir Funções Customizadas

#### `FW:set(name, func)`

Define uma função customizada.

**Exemplo:**
```lua
FW:set("getVip", function(source)
    local user = FW.getPlayer(source)
    if not user then return false end
    
    local user_id = user.userId()
    -- Sua lógica de VIP aqui
    return vRP.hasGroup({user_id, "vip"})
end)

-- Usar
if FW.getVip(source) then
    print("Jogador é VIP")
end
```

#### `FW:get(name)`

Executa uma função previamente definida.

**Exemplo:**
```lua
FW:set("customFunction", function()
    return "Hello World"
end)

local result = FW:get("customFunction")
print(result)  -- "Hello World"
```

---

## 🧪 Exemplos Práticos

### Exemplo 1: Sistema Multi-Framework

```lua
local frameworkName, FW = exports["dk_snippets"]:framework()

-- Configurar
FW.__index = function(self, name)
    self[name] = function(...)
        return FW._custom(name, ...)
    end
    return self[name]
end
setmetatable(FW, FW)

RegisterServerCallback('system:checkPermission', function(source, permission)
    local user = FW.getPlayer(source)
    if not user then return false end
    
    local user_id = user.userId()
    
    if frameworkName == "vrp" then
        return user.hasPermission(permission)
    elseif frameworkName == "esx" then
        return user.hasGroup(permission)
    elseif frameworkName == "qbcore" then
        return QBCore.Functions.HasPermission(source, permission)
    else
        -- Framework não suportado, usar lógica customizada
        return false
    end
end)
```

### Exemplo 2: Sistema de Pagamento Universal

```lua
local frameworkName, FW = exports["dk_snippets"]:framework()

FW.__index = function(self, name)
    self[name] = function(...)
        return FW._custom(name, ...)
    end
    return self[name]
end
setmetatable(FW, FW)

local function payPlayer(source, amount)
    if not frameworkName then
        print("Nenhum framework detectado!")
        return false
    end
    
    local user = FW.getPlayer(source)
    if not user then
        DkNotify(source, "red", "Jogador não encontrado", 5000)
        return false
    end
    
    local money = user.getMoney()
    
    if money < amount then
        DkNotify(source, "red", "Dinheiro insuficiente", 5000)
        return false
    end
    
    if user.removeMoney(amount) then
        -- Log da transação
        print(string.format("Jogador %s pagou $%d", GetPlayerName(source), amount))
        return true
    end
    
    return false
end

RegisterServerCallback('shop:buy', function(source, itemId, price)
    if payPlayer(source, price) then
        -- Dar item
        exports["dk_snippets"]:inventory:addItem(source, itemId, 1)
        return {success = true, message = "Item comprado!"}
    end
    
    return {success = false, message = "Falha no pagamento"}
end)
```

### Exemplo 3: Admin Check Multi-Framework

```lua
local frameworkName, FW = exports["dk_snippets"]:framework()

FW.__index = function(self, name)
    self[name] = function(...)
        return FW._custom(name, ...)
    end
    return self[name]
end
setmetatable(FW, FW)

-- Definir função de admin customizada
FW:set("isStaff", function(source)
    local user = FW.getPlayer(source)
    if not user then return false end
    
    if frameworkName == "vrp" then
        return user.isAdmin() or user.hasModerator()
    elseif frameworkName == "esx" then
        return user.hasGroup("admin") or user.hasGroup("mod")
    elseif frameworkName == "qbcore" then
        return user.isAdmin()
    else
        -- Lista estática de admins
        local adminList = {1, 2, 3}  -- User IDs
        local user_id = user.userId()
        return table.indexOf(adminList, user_id) ~= nil
    end
end)

-- Usar em callbacks
RegisterServerCallback('admin:action', function(source)
    if not FW.isStaff(source) then
        return {success = false, message = "Sem permissão"}
    end
    
    -- Ação de admin
    return {success = true}
end)
```

---

## 🔍 Debugging

### Verificar Framework Detectado

```lua
local frameworkName, FW = exports["dk_snippets"]:framework()

print("Framework: " .. tostring(frameworkName))

if FW then
    print("Funções disponíveis:")
    for k, v in pairs(FW) do
        if type(v) == "function" then
            print("  - " .. k)
        end
    end
end
```

### Testar Funções

```lua
RegisterCommand('testfw', function(source)
    local user = FW.getPlayer(source)
    if not user then
        print("Jogador não encontrado")
        return
    end
    
    local user_id = user.userId()
    local isAdmin = user.isAdmin()
    local money = user.getMoney()
    
    print("=== Framework Test ===")
    print("User ID: " .. user_id)
    print("Is Admin: " .. tostring(isAdmin))
    print("Money: $" .. money)
end, true)
```

---

## 📝 Notas Importantes

1. **Ordem de Inicialização**: Certifique-se de que o framework está iniciado antes do dk_snippets no `server.cfg`

2. **Funções Customizadas**: Use `FW:set()` para adicionar funções específicas do seu servidor

3. **Compatibilidade**: Teste todas as funções após adicionar suporte a um novo framework

4. **Performance**: Evite chamar funções do framework em loops intensivos

---

<div align="center">

**[⬅️ Server Docs](../SERVER.md)** | **[➡️ Voltar ao README](../../../../README.md)**

</div>