# 💻 Documentação Client-Side

Esta documentação detalha todas as funcionalidades disponíveis no lado do cliente (client-side) do DK Snippets.

## 📋 Índice

- [Notificações](#-notificações)
- [Hints (Dicas)](#-hints-dicas)
- [Sistema de Requests](#-sistema-de-requests)
- [Callbacks Client-Side](#-callbacks-client-side)

---

## 🎨 Notificações

Sistema de notificações customizável com suporte a diferentes modos e durações.

### Uso Básico

```lua
DkNotify(mode, message, time, title)
```

### Parâmetros

| Parâmetro | Tipo | Descrição | Obrigatório |
|-----------|------|-----------|-------------|
| `mode` | string | Modo da notificação (success, error, warning, info) | ✅ |
| `message` | string | Mensagem a ser exibida | ✅ |
| `time` | number | Duração em milissegundos | ❌ (padrão: 5000) |
| `title` | string | Título da notificação | ❌ |

### Modos Disponíveis

- `"green"` - Notificação de sucesso (verde)
- `"red"` - Notificação de erro (vermelho)
- `"yellow"` - Notificação de aviso (amarelo)
- `"blue"` - Notificação informativa (azul/indigo)

### Exemplos

```lua
-- Notificação simples de sucesso
DkNotify("green", "Operação realizada com sucesso!")

-- Notificação com duração customizada
DkNotify("red", "Você não tem permissão!", 8000)

-- Notificação completa com título
DkNotify("yellow", "Seu estoque está baixo!", 5000, "Atenção")

-- Notificação informativa
DkNotify("green", "Nova atualização disponível", 10000, "Sistema")
```

### Event Handler

Você também pode disparar notificações via events:

```lua
TriggerEvent('dk/notify', "green", "Mensagem", 5000, "Título")
```

---

## 💡 Hints (Dicas)

Sistema de hints para mostrar dicas de controles e ações na tela.

### Criar Hint

```lua
TriggerEvent('dk/hint', "create", id, description, control, configs)
```

### Parâmetros

| Parâmetro | Tipo | Descrição | Obrigatório |
|-----------|------|-----------|-------------|
| `id` | string | Identificador único do hint | ✅ |
| `description` | string | Texto descritivo do hint | ✅ |
| `control` | string | Tecla/controle associado | ❌ |
| `configs` | table | Configurações adicionais | ❌ |

### Remover Hint

```lua
TriggerEvent('dk/hint', "remove", id)
```

### Exemplos

```lua
-- Hint simples
TriggerEvent('dk/hint', "create", "interact_door", "Abrir porta", "E")

-- Hint sem tecla específica
TriggerEvent('dk/hint', "create", "loading", "Carregando dados...")

-- Hint com configurações customizadas
TriggerEvent('dk/hint', "create", "vehicle_hint", "Entrar no veículo", "F", {
    infoIcon = true,
    time = 5000
})

-- Hint será removida depois de 5 segundos
```

### Exemplo de Uso em Zona

```lua
local inZone = false

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        -- Verifica se está na zona
        local distance = #(coords - vector3(100.0, 100.0, 20.0))
        
        if distance < 2.0 then
            wait = 0
            if not inZone then
                inZone = true
                TriggerEvent('dk/hint', "create", "zone_hint", "Pressione E para interagir", "E")
            end
            
            if IsControlJustPressed(0, 38) then -- E key
                -- Ação ao pressionar E
                print("Interagiu!")
            end
        else
            if inZone then
                inZone = false
                TriggerEvent('dk/hint', "remove", "zone_hint")
            end
        end
        
        Citizen.Wait(wait)
    end
end)
```

---

## 📨 Sistema de Requests

Sistema de solicitações com interface gráfica que permite pedir confirmação do usuário.

### Função Principal

```lua
local accepted = exports["dk_snippets"]:request(description, timer, acceptText, denyText)
```

### Parâmetros

| Parâmetro | Tipo | Descrição | Obrigatório |
|-----------|------|-----------|-------------|
| `description` | string | Descrição da solicitação | ✅ |
| `timer` | number | Tempo em segundos para responder | ❌ (padrão: 20) |
| `acceptText` | string | Texto do botão aceitar | ❌ (padrão: "Aceitar") |
| `denyText` | string | Texto do botão recusar | ❌ (padrão: "Recusar") |

### Retorno

- `true` - Usuário aceitou a solicitação
- `false` - Usuário recusou ou o tempo expirou

### Controles Padrão

- **Y** - Aceitar solicitação
- **U** - Recusar solicitação

### Exemplos

```lua
-- Request simples
local accepted = exports["dk_snippets"]:request("Você aceita a proposta?")
if accepted then
    print("Usuário aceitou!")
else
    print("Usuário recusou!")
end

-- Request com tempo customizado
local accepted = exports["dk_snippets"]:request(
    "Deseja comprar este item por $500?",
    30  -- 30 segundos para responder
)

-- Request com textos customizados
local accepted = exports["dk_snippets"]:request(
    "Aceitar convite para grupo?",
    15,
    "Sim, aceito!",
    "Não, obrigado"
)

-- Request completo em um sistema de mecânica
local carPrice = 1500
local accepted = exports["dk_snippets"]:request(
    "Deseja consertar o veículo por $" .. carPrice .. "?",
    20,
    "Consertar",
    "Cancelar"
)

if accepted then
    TriggerServerEvent('mechanic:repair', carPrice)
    DkNotify("green", "Veículo consertado!", 5000)
else
    DkNotify("red", "Conserto cancelado", 3000)
end
```

---

## 🔄 Callbacks Client-Side

Sistema robusto de callbacks para comunicação entre client e server.

### Registrar Callback Client

```lua
RegisterClientCallback(eventName, callback)
```

### Disparar Callback Server

```lua
local result = TriggerServerCallback(eventName, args, timeout, timedoutCallback)
```

### Parâmetros

#### RegisterClientCallback

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `eventName` | string | Nome único do callback |
| `callback` | function | Função a ser executada |

#### TriggerServerCallback

| Parâmetro | Tipo | Descrição | Obrigatório |
|-----------|------|-----------|-------------|
| `eventName` | string | Nome do callback no server | ✅ |
| `args` | table | Argumentos para enviar | ❌ |
| `timeout` | number | Timeout em segundos | ❌ |
| `timedoutCallback` | function | Função se der timeout | ❌ |

### Exemplos

```lua
-- Registrar callback client-side
RegisterClientCallback('getPlayerPosition', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }
end)

-- Chamar callback do server
local playerData = TriggerServerCallback('getPlayerData', {})
print("Nome: " .. playerData.name)
print("Dinheiro: " .. playerData.money)

-- Callback com timeout
local data = TriggerServerCallback('requestData', {id = 123}, 10, function()
    print("Servidor não respondeu a tempo!")
    DkNotify("red", "Timeout ao buscar dados", 5000)
end)

-- Callback síncrono aguardando resposta
local inventory = TriggerServerCallback('getInventory', {})
if inventory then
    for k, v in pairs(inventory) do
        print("Item: " .. v.name .. " - Quantidade: " .. v.amount)
    end
end
```

### Exemplo Completo: Sistema de Teleporte

```lua
-- Client-side
RegisterCommand('tpto', function(source, args)
    local targetId = tonumber(args[1])
    
    if not targetId then
        DkNotify("red", "Use: /tpto [id]", 5000)
        return
    end
    
    local targetCoords = TriggerServerCallback('admin:getPlayerCoords', {targetId}, 5, function()
        DkNotify("red", "Não foi possível obter coordenadas", 5000)
    end)
    
    if targetCoords then
        local ped = PlayerPedId()
        SetEntityCoords(ped, targetCoords.x, targetCoords.y, targetCoords.z)
        DkNotify("green", "Teleportado para o jogador " .. targetId, 5000)
    end
end)

-- Server-side
RegisterServerCallback('admin:getPlayerCoords', function(source, targetId)
    local targetCoords = TriggerClientCallback(targetId, 'getPlayerPosition', {})
    return targetCoords
end)
```

---

## 🎯 Melhores Práticas

### 1. Sempre limpe hints quando não necessários
```lua
-- Evite acúmulo de hints na memória
if not inZone then
    TriggerEvent('dk/hint', "remove", "zone_hint")
end
```

### 2. Use IDs únicos para hints
```lua
-- Use prefixos para evitar conflitos
TriggerEvent('dk/hint', "create", "myscript_interact", "Pressione E", "E")
```

### 3. Defina timeouts apropriados para requests
```lua
-- Ações rápidas: 10-15 segundos
-- Ações importantes: 20-30 segundos
local accepted = exports["dk_snippets"]:request("Mensagem", 15)
```

### 4. Trate erros em callbacks
```lua
local data = TriggerServerCallback('getData', {}, 10, function()
    DkNotify("red", "Erro ao buscar dados", 5000)
end)

if data then
    -- Processa dados
end
```

---

## 🐛 Troubleshooting

### Notificações não aparecem
- Verifique se o resource está iniciado
- Confirme que o NUI está funcionando
- Verifique o console do navegador (F8)

### Hints não removem
- Certifique-se de usar o mesmo ID usado na criação
- Verifique se o event está sendo disparado corretamente

### Requests não respondem
- Verifique os keybindings (Y e U)
- Confirme que apenas um request está ativo por vez
- Verifique o console para erros

---

<div align="center">

**[⬅️ Voltar ao README](../../../README.md)** | **[➡️ Server Docs](../server/SERVER.md)**

</div>
