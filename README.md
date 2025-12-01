# 🚀 DK Snippets

[![FiveM](https://img.shields.io/badge/FiveM-Resource-blue)](https://fivem.net/)
[![Version](https://img.shields.io/badge/version-1.2.0-green)](https://github.com/potter7k/dk_snippets)
[![Discord](https://img.shields.io/badge/Discord-Join-7289da)](https://discord.gg/NJjUn8Ad3P)

**DK Snippets** é uma biblioteca completa e moderna para FiveM que oferece ferramentas essenciais para o desenvolvimento de scripts, incluindo:

- 🎯 **Framework Detection**: Identificação automática e inteligente de frameworks (vRP, ESX, etc)
- 🗄️ **Database Operations**: Suporte completo para múltiplos drivers SQL (oxmysql, ghmattimysql, mysql-async)
- 📄 **JSON File Handler**: Manipulação avançada de arquivos JSON com métodos CRUD
- 🔄 **Callback System**: Sistema robusto de callbacks entre client e server
- ⏱️ **Cooldown Manager**: Gerenciamento inteligente de cooldowns
- 🎨 **UI Components**: Sistema de notificações, hints e requests customizáveis
- 🛠️ **Utility Functions**: Coleção de funções auxiliares para desenvolvimento

## 📋 Índice

- [Instalação](#-instalação)
- [Recursos](#-recursos)
- [Documentação](#-documentação)
- [Exemplos de Uso](#-exemplos-de-uso)
- [Suporte](#-suporte)
- [Contribuindo](#-contribuindo)
- [Licença](#-licença)

## 📦 Instalação

1. Faça o download ou clone este repositório
2. Coloque a pasta `dk_snippets` em `resources/[dk]/`
3. Adicione ao seu `server.cfg`:
```cfg
ensure dk_snippets
```

**Requisitos:**
- FiveM Server atualizado
- Um driver SQL (oxmysql, ghmattimysql, ou mysql-async) - apenas se for usar o módulo de database

## ✨ Recursos

### 🎯 Framework Detection
Detecta automaticamente o framework do servidor e fornece funções padronizadas:
```lua
local frameworkName, FW = exports["dk_snippets"]:framework()
local user = FW.getPlayer(source)
local user_id = user.userId()
local isAdmin = user.isAdmin()
```

### 🗄️ Database Operations
Interface unificada para operações de banco de dados:
```lua
local db = exports["dk_snippets"]:DB()
local users = db.execute("SELECT * FROM users WHERE age > ?", {25})
db.insert("users", {name = "John", age = 30})
```

### 📄 JSON File Handler
Manipule arquivos JSON como se fossem bancos de dados:
```lua
local jsonData = JSON:fetch("data/users")
jsonData:insert("users", {name = "Alice", age = 25})
local users = jsonData:where("users", {age = 30})
```

### 🔄 Callback System
Comunicação simplificada entre client e server:
```lua
-- Server
RegisterServerCallback('getData', function(source, param)
    return someData
end)

-- Client
local data = TriggerServerCallback('getData', {param})
```

### 🎨 UI Components

**Notificações:**
```lua
DkNotify("green", "Operação realizada!", 5000)
```

**Hints:**
```lua
TriggerEvent('dk/hint', "create", "hint_id", "Pressione E para interagir", "E")
```

**Requests:**
```lua
local accept = exports["dk_snippets"]:request("Você aceita?", 20, "Sim", "Não")
```

## 📚 Documentação

A documentação completa está organizada nos seguintes arquivos:

- **[📖 INSTALLATION.md](INSTALLATION.md)** - Guia detalhado de instalação e configuração
- **[💻 CLIENT.md](dk_snippets/src/client/CLIENT.md)** - Documentação das funções client-side
- **[🖥️ SERVER.md](dk_snippets/src/server/SERVER.md)** - Documentação das funções server-side
- **[🔄 SHARED.md](dk_snippets/src/shared/SHARED.md)** - Documentação das funções compartilhadas
- **[🎓 EXAMPLES.md](EXAMPLES.md)** - Exemplos práticos de uso
- **[🏗️ FRAMEWORK.md](dk_snippets/src/server/framework/FRAMEWORK.md)** - Guia de frameworks

## 🎓 Exemplos de Uso

### Exemplo Completo: Sistema de Admin Check
```lua
-- Server-side
local frameworkName, FW = exports["dk_snippets"]:framework()

RegisterServerCallback('checkAdminStatus', function(source)
    local user = FW.getPlayer(source)
    if not user then return nil end
    
    return user.isAdmin()
end)

-- Client-side
local isAdmin = TriggerServerCallback('checkAdminStatus', {})
if isAdmin then
    DkNotify("green", "Você é um administrador!", 5000)
else
    DkNotify("red", "Acesso negado!", 5000)
end
```

Veja mais exemplos em **[EXAMPLES.md](EXAMPLES.md)**

## 💬 Suporte

- 🎮 **Discord**: [https://discord.gg/NJjUn8Ad3P](https://discord.gg/NJjUn8Ad3P)

## 🤝 Contribuindo

Contribuições são muito bem-vindas! Para contribuir:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

Por favor, siga os padrões de código existentes e documente suas mudanças.

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

O sistema de callbacks é baseado na implementação de [PiterMcFlebor](https://github.com/pitermcflebor/pmc-callbacks).

---

<div align="center">

**Desenvolvido por [DK Development](https://discord.gg/NJjUn8Ad3P)**

Se este projeto foi útil, considere deixar uma ⭐!

</div>
