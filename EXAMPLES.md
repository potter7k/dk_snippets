# 🎓 Exemplos de Uso - DK Snippets

Este guia apresenta exemplos práticos e completos de como usar o DK Snippets em diferentes cenários.

## 📋 Índice

- [Sistema de Economia](#-sistema-de-economia)
- [Sistema de Inventário](#-sistema-de-inventário)
- [Sistema de Admin](#-sistema-de-admin)
- [Sistema de Veículos](#-sistema-de-veículos)
- [Sistema de Trabalhos](#-sistema-de-trabalhos)
- [Sistema de Lojas](#-sistema-de-lojas)
- [Sistema de Gangues](#-sistema-de-gangues)

---

## 💰 Sistema de Economia

Sistema completo de economia com banco de dados e notificações.

### Server-Side (`economy_server.lua`)

```lua
local db = exports["dk_snippets"]:DB()
local fw, FW = exports["dk_snippets"]:framework()

-- Verificar e criar tabela
if not db.hasTable("bank_accounts") then
    db.execute([[
        CREATE TABLE bank_accounts (
            user_id INT PRIMARY KEY,
            balance DECIMAL(15,2) DEFAULT 0,
            savings DECIMAL(15,2) DEFAULT 0
        )
    ]])
end

-- Obter saldo
RegisterServerCallback('bank:getBalance', function(source)
    local user = FW.getPlayer(source)
    if not user then return nil end
    
    local user_id = user.userId()
    local result = db.execute("SELECT * FROM bank_accounts WHERE user_id = ?", {user_id})
    
    if #result > 0 then
        return result[1]
    else
        -- Criar conta se não existir
        db.insert("bank_accounts", {
            user_id = user_id,
            balance = 0,
            savings = 0
        })
        return {balance = 0, savings = 0}
    end
end)

-- Depositar dinheiro
RegisterServerCallback('bank:deposit', function(source, amount)
    local user = FW.getPlayer(source)
    if not user then return {success = false, message = "Jogador não encontrado"} end
    
    local user_id = user.userId()
    amount = tonumber(amount)
    
    if not amount or amount <= 0 then
        return {success = false, message = "Valor inválido"}
    end
    
    -- Verificar se tem dinheiro
    local canPay = user.paymentBank(amount)
    if not canPay then
        return {success = false, message = "Dinheiro insuficiente"}
    end
    
    db.execute("UPDATE bank_accounts SET balance = balance + ? WHERE user_id = ?", {amount, user_id})
    
    -- Log da transação
    db.insert("bank_transactions", {
        user_id = user_id,
        type = "deposit",
        amount = amount,
        date = os.date("%Y-%m-%d %H:%M:%S")
    })
    
    return {success = true, message = "Depósito realizado!"}
end)

-- Sacar dinheiro
RegisterServerCallback('bank:withdraw', function(source, amount)
    local user = FW.getPlayer(source)
    if not user then return {success = false, message = "Jogador não encontrado"} end
    
    local user_id = user.userId()
    amount = tonumber(amount)
    
    if not amount or amount <= 0 then
        return {success = false, message = "Valor inválido"}
    end
    
    -- Verificar saldo
    local account = db.execute("SELECT balance FROM bank_accounts WHERE user_id = ?", {user_id})[1]
    if account.balance < amount then
        return {success = false, message = "Saldo insuficiente"}
    end
    
    -- Remover do banco e adicionar dinheiro
    db.execute("UPDATE bank_accounts SET balance = balance - ? WHERE user_id = ?", {amount, user_id})
    user.giveBank(amount)
    
    return {success = true, message = "Saque realizado!"}
end)

-- Transferir dinheiro
RegisterServerCallback('bank:transfer', function(source, targetId, amount)
    local user = FW.getPlayer(source)
    if not user then return {success = false, message = "Jogador não encontrado"} end
    
    local user_id = user.userId()
    amount = tonumber(amount)
    
    if not amount or amount <= 0 then
        return {success = false, message = "Valor inválido"}
    end
    
    -- Verificar saldo
    local account = db.execute("SELECT balance FROM bank_accounts WHERE user_id = ?", {user_id})[1]
    if account.balance < amount then
        return {success = false, message = "Saldo insuficiente"}
    end
    
    -- Transferir
    db.execute("UPDATE bank_accounts SET balance = balance - ? WHERE user_id = ?", {amount, user_id})
    db.execute("UPDATE bank_accounts SET balance = balance + ? WHERE user_id = ?", {amount, targetId})
    
    -- Notificar ambos
    DkNotify(source, "green", "Transferência realizada: $" .. amount, 5000)
    
    local targetUser = FW.getPlayerById(targetId)
    if targetUser then
        DkNotify(targetUser.userSource(), "green", "Você recebeu: $" .. amount, 5000)
    end
    
    return {success = true, message = "Transferência concluída!"}
end)
```

### Client-Side (`economy_client.lua`)

```lua
local atmCoords = {
    vector3(147.4, -1035.8, 29.3),
    vector3(-56.9, -1752.1, 29.4),
    vector3(-261.8, -2012.3, 30.1)
}

-- Menu do ATM
local function openATMMenu()
    local balance = TriggerServerCallback('bank:getBalance', {})
    
    -- Aqui você integraria com seu sistema de menu
    -- Exemplo simplificado
    
    print("=== BANCO ===")
    print("Saldo: $" .. balance.balance)
    print("Poupança: $" .. balance.savings)
end

-- Threads de ATMs
Citizen.CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        for _, atmPos in ipairs(atmCoords) do
            local distance = #(coords - atmPos)
            
            if distance < 2.0 then
                wait = 0
                TriggerEvent('dk/hint', "create", "atm_hint", "Pressione E para acessar o ATM", "E")
                
                if IsControlJustPressed(0, 38) then
                    openATMMenu()
                end
            end
        end
        
        if wait == 1000 then
            TriggerEvent('dk/hint', "remove", "atm_hint")
        end
        
        Citizen.Wait(wait)
    end
end)

-- Comando de depósito rápido
RegisterCommand('depositar', function(source, args)
    local amount = tonumber(args[1])
    
    if not amount then
        DkNotify("red", "Use: /depositar [valor]", 5000)
        return
    end
    
    local result = TriggerServerCallback('bank:deposit', {amount})
    DkNotify(result.success and "green" or "red", result.message, 5000)
end)

-- Comando de saque
RegisterCommand('sacar', function(source, args)
    local amount = tonumber(args[1])
    
    if not amount then
        DkNotify("red", "Use: /sacar [valor]", 5000)
        return
    end
    
    local result = TriggerServerCallback('bank:withdraw', {amount})
    DkNotify(result.success and "green" or "red", result.message, 5000)
end)
```

---

## 👮 Sistema de Admin

Sistema completo de administração com cooldowns e permissões.

### Server-Side (`admin_server.lua`)

```lua
local fw, FW = exports["dk_snippets"]:framework()
local adminCooldowns = {}

-- Verificar permissão admin
local function isAdmin(source)
    local user = FW.getPlayer(source)
    if not user then return false end
    return user.isAdmin()
end

-- Teleportar para jogador
RegisterServerCallback('admin:tpToPlayer', function(source, targetId)
    if not isAdmin(source) then
        return {success = false, message = "Sem permissão"}
    end
    
    -- Obter coordenadas do alvo usando nativas server-side
    local targetPed = GetPlayerPed(targetId)
    local coords = GetEntityCoords(targetPed)
    
    TriggerClientEvent('admin:teleport', source, {x = coords.x, y = coords.y, z = coords.z})
    DkNotify(source, "green", "Teleportado para jogador " .. targetId, 3000)
    
    return {success = true}
end)

-- Teleportar jogador até você
RegisterServerCallback('admin:tpPlayerToMe', function(source, targetId)
    if not isAdmin(source) then
        return {success = false, message = "Sem permissão"}
    end

    -- Usando nativas server-side para pegar coords do admin e teleportar o alvo
    local adminPed = GetPlayerPed(source)
    local coords = GetEntityCoords(adminPed)

    TriggerClientEvent('admin:teleport', targetId, { x = coords.x, y = coords.y, z = coords.z })

    DkNotify(source, "green", "Jogador " .. targetId .. " teleportado até você", 3000)
    DkNotify(targetId, "green", "Você foi teleportado por um admin", 5000)

    return {success = true}
end)

-- Congelar jogador
RegisterServerCallback('admin:freeze', function(source, targetId)
    if not isAdmin(source) then
        return {success = false, message = "Sem permissão"}
    end
    
    TriggerClientEvent('admin:toggleFreeze', targetId)
    return {success = true, message = "Estado de congelamento alternado"}
end)

-- Dar dinheiro com cooldown
RegisterServerCallback('admin:giveMoney', function(source, targetId, amount)
    if not isAdmin(source) then
        return {success = false, message = "Sem permissão"}
    end
    
    local user = FW.getPlayer(source)
    if not user then return {success = false, message = "Jogador não encontrado"} end
    
    local user_id = user.userId()
    
    -- Cooldown de 60 segundos
    if not adminCooldowns[user_id] then
        adminCooldowns[user_id] = Cooldown:new(60)
    end
    
    local success = adminCooldowns[user_id]:checkAndCreate(nil, function(remaining)
        DkNotify(source, "yellow", "Aguarde " .. remaining .. " segundos", 3000)
    end)
    
    if not success then
        return {success = false, message = "Cooldown ativo"}
    end
    
    -- Dar dinheiro
    local targetUser = FW.getPlayer(targetId)
    if not targetUser then
        return {success = false, message = "Jogador alvo não encontrado"}
    end
    
    targetUser.giveBank(amount)
    DkNotify(source, "green", "Você deu $" .. amount .. " ao jogador " .. targetId, 5000)
    DkNotify(targetId, "green", "Você recebeu $" .. amount, 5000)
    
    return {success = true}
end)

-- Kick com motivo
RegisterServerCallback('admin:kick', function(source, targetId, reason)
    if not isAdmin(source) then
        return {success = false, message = "Sem permissão"}
    end
    
    reason = reason or "Sem motivo especificado"
    
    DropPlayer(targetId, "Você foi kickado: " .. reason)
    
    -- Log
    print(string.format("[ADMIN] %s kickou %s - Motivo: %s", 
        GetPlayerName(source), GetPlayerName(targetId), reason))
    
    return {success = true, message = "Jogador kickado"}
end)

-- Anúncio global com cooldown
local announceCooldown = Cooldown:new(120)  -- 2 minutos

RegisterServerCallback('admin:announce', function(source, message)
    if not isAdmin(source) then
        return {success = false, message = "Sem permissão"}
    end
    
    local success = announceCooldown:checkAndCreate(nil, function(remaining)
        DkNotify(source, "yellow", "Aguarde " .. remaining .. " segundos", 3000)
    end)
    
    if not success then
        return {success = false}
    end
    
    -- Enviar para todos
    TriggerClientEvent('admin:showAnnouncement', -1, message)
    
    return {success = true}
end)
```

### Client-Side (`admin_client.lua`)

```lua
local frozen = false

-- Teleportar
RegisterNetEvent('admin:teleport')
AddEventHandler('admin:teleport', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
    DkNotify("green", "Teleportado!", 3000)
end)

-- Toggle congelar
RegisterNetEvent('admin:toggleFreeze')
AddEventHandler('admin:toggleFreeze', function()
    frozen = not frozen
    local ped = PlayerPedId()
    
    FreezeEntityPosition(ped, frozen)
    
    if frozen then
        DkNotify("yellow", "Você foi congelado", 5000)
    else
        DkNotify("green", "Você foi descongelado", 5000)
    end
end)

-- Mostrar anúncio
RegisterNetEvent('admin:showAnnouncement')
AddEventHandler('admin:showAnnouncement', function(message)
    DkNotify("green", message, 10000, "📢 ANÚNCIO")
end)

-- Comandos
RegisterCommand('tpto', function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        DkNotify("red", "Use: /tpto [id]", 5000)
        return
    end
    
    TriggerServerCallback('admin:tpToPlayer', {targetId})
end)

RegisterCommand('tptome', function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        DkNotify("red", "Use: /tptome [id]", 5000)
        return
    end
    
    TriggerServerCallback('admin:tpPlayerToMe', {targetId})
end)

RegisterCommand('congelar', function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        DkNotify("red", "Use: /congelar [id]", 5000)
        return
    end
    
    local result = TriggerServerCallback('admin:freeze', {targetId})
    DkNotify(result.success and "green" or "red", result.message, 5000)
end)

RegisterCommand('dargrana', function(source, args)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount then
        DkNotify("red", "Use: /dargrana [id] [valor]", 5000)
        return
    end
    
    local result = TriggerServerCallback('admin:giveMoney', {targetId, amount})
    if not result.success then
        DkNotify("red", result.message, 5000)
    end
end)

RegisterCommand('anuncio', function(source, args)
    local message = table.concat(args, " ")
    
    if message == "" then
        DkNotify("red", "Use: /anuncio [mensagem]", 5000)
        return
    end
    
    TriggerServerCallback('admin:announce', {message})
end)
```

---

## 🚗 Sistema de Veículos

Sistema de garagem com database e spawn de veículos.

### Server-Side (`vehicles_server.lua`)

```lua
local db = exports["dk_snippets"]:DB()
local fw, FW = exports["dk_snippets"]:framework()

-- Criar tabela se não existir
if not db.hasTable("player_vehicles") then
    db.execute([[
        CREATE TABLE player_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT,
            vehicle_model VARCHAR(50),
            vehicle_plate VARCHAR(10) UNIQUE,
            vehicle_color VARCHAR(50),
            stored BOOLEAN DEFAULT 1,
            INDEX(user_id)
        )
    ]])
end

-- Obter veículos do jogador
RegisterServerCallback('garage:getVehicles', function(source)
    local user = FW.getPlayer(source)
    if not user then return {} end
    
    local user_id = user.userId()
    local vehicles = db.execute("SELECT * FROM player_vehicles WHERE user_id = ?", {user_id})
    
    return vehicles
end)

-- Comprar veículo
RegisterServerCallback('garage:buyVehicle', function(source, model, price)
    local user = FW.getPlayer(source)
    if not user then return {success = false, message = "Jogador não encontrado"} end
    
    local user_id = user.userId()
    
    -- Verificar dinheiro
    if not user.paymentBank(price) then
        return {success = false, message = "Dinheiro insuficiente"}
    end
    
    -- Gerar placa
    local plate = "DK" .. math.random(1000, 9999)
    
    -- Adicionar veículo
    db.insert("player_vehicles", {
        user_id = user_id,
        vehicle_model = model,
        vehicle_plate = plate,
        vehicle_color = "0,0,0",
        stored = 1
    })
    
    return {success = true, message = "Veículo comprado!", plate = plate}
end)

-- Spawnar veículo
RegisterServerCallback('garage:spawnVehicle', function(source, vehicleId)
    local user = FW.getPlayer(source)
    if not user then return {success = false, message = "Jogador não encontrado"} end
    
    local user_id = user.userId()
    
    -- Verificar se é dono
    local vehicle = db.execute(
        "SELECT * FROM player_vehicles WHERE id = ? AND user_id = ?",
        {vehicleId, user_id}
    )[1]
    
    if not vehicle then
        return {success = false, message = "Veículo não encontrado"}
    end
    
    if vehicle.stored == 0 then
        return {success = false, message = "Veículo já está fora"}
    end
    
    -- Marcar como fora da garagem
    db.execute("UPDATE player_vehicles SET stored = 0 WHERE id = ?", {vehicleId})
    
    return {
        success = true,
        model = vehicle.vehicle_model,
        plate = vehicle.vehicle_plate,
        color = vehicle.vehicle_color
    }
end)

-- Guardar veículo
RegisterServerCallback('garage:storeVehicle', function(source, plate)
    local user = FW.getPlayer(source)
    if not user then return {success = false, message = "Jogador não encontrado"} end
    
    local user_id = user.userId()
    
    -- Verificar se é dono
    local vehicle = db.execute(
        "SELECT * FROM player_vehicles WHERE vehicle_plate = ? AND user_id = ?",
        {plate, user_id}
    )[1]
    
    if not vehicle then
        return {success = false, message = "Este não é seu veículo"}
    end
    
    -- Guardar
    db.execute("UPDATE player_vehicles SET stored = 1 WHERE vehicle_plate = ?", {plate})
    
    return {success = true, message = "Veículo guardado"}
end)
```

### Client-Side (`vehicles_client.lua`)

```lua
local garageCoords = vector3(215.9, -805.1, 30.8)
local spawnPoint = vector4(229.7, -800.1, 30.6, 160.0)

-- Menu da garagem
local function openGarageMenu()
    local vehicles = TriggerServerCallback('garage:getVehicles', {})
    
    if #vehicles == 0 then
        DkNotify("green", "Você não tem veículos", 5000)
        return
    end
    
    -- Aqui integraria com sistema de menu
    print("=== GARAGEM ===")
    for _, veh in ipairs(vehicles) do
        local status = veh.stored == 1 and "Guardado" or "Fora"
        print(veh.vehicle_model .. " - " .. veh.vehicle_plate .. " [" .. status .. "]")
    end
end

-- Spawnar veículo
local function spawnVehicle(vehicleId)
    local result = TriggerServerCallback('garage:spawnVehicle', {vehicleId})
    
    if not result.success then
        DkNotify("red", result.message, 5000)
        return
    end
    
    -- Spawn do veículo
    local modelHash = GetHashKey(result.model)
    RequestModel(modelHash)
    
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end
    
    local vehicle = CreateVehicle(
        modelHash,
        spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w,
        true, false
    )
    
    SetVehicleNumberPlateText(vehicle, result.plate)
    
    -- Cor (RGB string para RGB)
    local colorData = split(result.color, ",")
    SetVehicleCustomPrimaryColour(vehicle, colorData[1], colorData[2], colorData[3])
    
    -- Colocar jogador no veículo
    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, vehicle, -1)
    
    DkNotify("green", "Veículo retirado!", 5000)
end

-- Guardar veículo
local function storeCurrentVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        DkNotify("red", "Você não está em um veículo", 5000)
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local result = TriggerServerCallback('garage:storeVehicle', {plate})
    
    if result.success then
        DeleteVehicle(vehicle)
        DkNotify("green", result.message, 5000)
    else
        DkNotify("red", result.message, 5000)
    end
end

-- Thread da garagem
Citizen.CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(coords - garageCoords)
        
        if distance < 10.0 then
            wait = 0
            
            if distance < 2.0 then
                TriggerEvent('dk/hint', "create", "garage_hint", "Pressione E para acessar", "E")
                
                if IsControlJustPressed(0, 38) then
                    openGarageMenu()
                end
            else
                TriggerEvent('dk/hint', "remove", "garage_hint")
            end
        end
        
        Citizen.Wait(wait)
    end
end)

-- Comando para guardar
RegisterCommand('guardar', function()
    storeCurrentVehicle()
end)

-- Função auxiliar
function split(str, delimiter)
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, tonumber(match) or match)
    end
    return result
end
```

---

## 📦 Mais Exemplos

Para mais exemplos práticos, consulte:

- **[CLIENT.md](dk_snippets/src/client/CLIENT.md)** - Exemplos client-side específicos
- **[SERVER.md](dk_snippets/src/server/SERVER.md)** - Exemplos server-side avançados
- **[SHARED.md](dk_snippets/src/shared/SHARED.md)** - Exemplos de callbacks e utilities

---

<div align="center">

**[⬅️ Voltar ao README](README.md)** | **[📖 Ver Instalação](INSTALLATION.md)**

Se estes exemplos foram úteis, considere deixar uma ⭐ no repositório!

**[Discord](https://discord.gg/NJjUn8Ad3P)** | **[GitHub](https://github.com/potter7k/dk_snippets)**

</div>
