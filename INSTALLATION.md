# 📦 Guia de Instalação - DK Snippets

Este guia detalha o processo completo de instalação e configuração do DK Snippets.

## 📋 Índice

- [Requisitos](#-requisitos)
- [Instalação Básica](#-instalação-básica)
- [Configuração](#-configuração)
- [Verificação](#-verificação)
- [Problemas Comuns](#-problemas-comuns)
- [Atualização](#-atualização)

---

## 🔧 Requisitos

### Requisitos Obrigatórios

- **FiveM Server** (Build atual recomendado)
- **Windows** ou **Linux** (servidor)

### Requisitos Opcionais

Dependendo dos módulos que você pretende usar:

#### Para usar o módulo de Database:
- Um dos seguintes drivers SQL:
  - ✅ [oxmysql](https://github.com/overextended/oxmysql) (Recomendado)
  - ✅ [ghmattimysql](https://github.com/GHMatti/ghmattimysql)
  - ✅ [mysql-async](https://github.com/brouznouf/fivem-mysql-async)

#### Para usar Framework Detection:
- Um dos frameworks suportados:
  - ✅ vRP (múltiplas versões)
  - ✅ ESX (em breve)
  - Ou nenhum framework (também suportado)

---

## 📥 Instalação Básica

### Método 1: Download Manual

1. **Download do Repositório**
   ```
   Acesse: https://github.com/potter7k/dk_snippets
   Clique em "Code" > "Download ZIP"
   ```

2. **Extrair Arquivos**
   - Extraia o arquivo ZIP
   - Renomeie a pasta para `dk_snippets` (se necessário)

3. **Mover para o Servidor**
   ```
   Mova a pasta para: resources/[dk]
   ```
   
   Estrutura final:
   ```
   server/
   └── resources/
       └── [dk]/
               └── dk_snippets/
                  ├── fxmanifest.lua
                  ├── src/
                  └── web/
   ```

4. **Adicionar ao server.cfg**
   ```cfg
   # DK Development Scripts
   start [dk]
   ```

### Método 2: Git Clone

```bash
cd resources/[dk]/
git clone https://github.com/potter7k/dk_snippets.git
```

Adicione ao `server.cfg`:
```cfg
start [dk]
```

---

## ⚙️ Configuração

### 1. Configuração Básica

O DK Snippets funciona sem configuração adicional, mas você pode personalizar alguns aspectos.

#### Configurar UI (Opcional)

Edite os arquivos CSS em `dk_snippets/web/css/` para customizar:
- `ui.css` - Estilos gerais da UI
- `hints.css` - Estilos dos hints
- `requests.css` - Estilos das solicitações

### 2. Configuração de Database

Se você for usar o módulo de database:

1. **Certifique-se de ter um driver SQL instalado**
   ```cfg
   # No seu server.cfg, ANTES do dk_snippets:
   ensure oxmysql  # ou ghmattimysql, ou mysql-async
   ```

### 3. Configuração de Framework

O DK Snippets detecta automaticamente o framework, mas você pode configurar funções customizadas:

Edite `dk_snippets/src/server/framework/!handler.lua` se necessário.

Veja mais em [FRAMEWORK.md](dk_snippets/src/server/framework/FRAMEWORK.md)

### 4. Ordem de Inicialização no server.cfg

É importante manter a ordem correta:

```cfg
# 1. Database (se usar)
ensure oxmysql

# 2. Framework (se usar)
ensure vrp

# 3. DK Snippets
ensure dk_snippets

# 4. Seus outros scripts que usam dk_snippets
ensure seu_script
```

---

## ✅ Verificação

### 1. Verificar Inicialização

Inicie o servidor e verifique o console:

```
[   script:dk_snippets] Resource started.
```

Se houver erros, veja a seção [Problemas Comuns](#-problemas-comuns)

### 2. Testar Funcionalidades

#### Teste 1: Notificação (Client)

Entre no servidor e execute no console F8:
```lua
DkNotify("green", "DK Snippets funcionando!", 5000)
```

Você deve ver uma notificação na tela.

#### Teste 2: Callback (Client)

```lua
RegisterClientCallback('test', function()
    return "Funcionou!"
end)

local result = TriggerServerCallback('test', {})
print(result)
```

#### Teste 3: Database (Server)

No console do servidor:
```lua
local db = exports["dk_snippets"]:DB()
print(db.hasTable("users"))
```

#### Teste 4: Framework (Server)

```lua
local fw, FW = exports["dk_snippets"]:framework()
print("Framework detectado: " .. tostring(fw))
```

### 3. Teste Completo

Crie um arquivo de teste: `resources/test_dk/client.lua`

```lua
RegisterCommand('testdk', function()
    -- Teste de notificação
    DkNotify("green", "Iniciando testes...", 3000)
    
    Wait(1000)
    
    -- Teste de hint
    TriggerEvent('dk/hint', "create", "test_hint", "Teste de Hint", "E")
    
    Wait(3000)
    TriggerEvent('dk/hint', "remove", "test_hint")
    
    -- Teste de request
    local accepted = exports["dk_snippets"]:request("Você aceita o teste?", 10)
    
    if accepted then
        DkNotify("green", "Teste aceito!", 3000)
    else
        DkNotify("red", "Teste recusado!", 3000)
    end
end)
```

`fxmanifest.lua`:
```lua
fx_version 'adamant'
game 'gta5'

client_script 'client.lua'
```

Execute `/testdk` no jogo.

---

## ⚠️ Problemas Comuns

### Problema 1: Resource não inicia

**Sintoma:**
```
Error loading script: dk_snippets
```

**Soluções:**
1. Verifique se o caminho está correto
2. Verifique se o `fxmanifest.lua` existe
3. Verifique permissões da pasta

### Problema 2: Notificações não aparecem

**Sintoma:** Comando não mostra notificação

**Soluções:**
1. Verifique o console do navegador (F8)
2. Verifique se o NUI está funcionando
3. Certifique-se de que os arquivos `web/` existem

### Problema 3: Database não funciona

**Sintoma:** `db.execute` retorna erro

**Soluções:**
1. Verifique se o driver SQL está instalado e iniciado
2. Verifique a ordem no `server.cfg`
3. Confirme que a conexão do banco está configurada

```lua
-- Teste no servidor
local db = exports["dk_snippets"]:DB()
if db then
    print("DB conectado!")
else
    print("DB não encontrado!")
end
```

### Problema 4: Callbacks não funcionam

**Sintoma:** `TriggerServerCallback` não retorna nada

**Soluções:**
1. Verifique se o callback está registrado antes de ser chamado
2. Confirme que o nome do callback está correto
3. Verifique timeout

```lua
-- Server
RegisterServerCallback('test', function(source)
    print("Callback recebido!")
    return "ok"
end)

-- Client
Citizen.CreateThread(function()
    Wait(1000)  -- Aguardar resource iniciar
    local result = TriggerServerCallback('test', {})
    print("Resultado: " .. tostring(result))
end)
```

### Problema 5: Framework não detectado

**Sintoma:** `framework()` retorna `nil`

**Soluções:**
1. Verifique se o framework está iniciado antes do dk_snippets
2. Confirme que o framework é suportado
3. Adicione suporte customizado

Veja [FRAMEWORK.md](dk_snippets/src/server/framework/FRAMEWORK.md) para adicionar suporte.

---

## 🔄 Atualização

### Atualizar via Git

Se instalou via git clone:

```bash
cd resources/[dk]/dk_snippets
git pull origin main
```

Reinicie o resource:
```
restart dk_snippets
```

### Atualizar Manualmente

1. **Backup das configurações customizadas**
   - Salve modificações em `web/css/` se houver

2. **Download da nova versão**
   - Baixe do GitHub
   
3. **Substitua os arquivos**
   - Mantenha suas customizações
   
4. **Reinicie o resource**
   ```
   restart dk_snippets
   ```

### Verificar Versão

Verifique o `fxmanifest.lua`:
```lua
version '1.2.0'
```

---

## 🔍 Logs e Debug

### Ativar Logs Detalhados

Para debugar problemas, você pode adicionar prints:

```lua
-- No seu script
Citizen.CreateThread(function()
    print("^2[DEBUG]^7 Testando dk_snippets...")
    
    local fw, FW = exports["dk_snippets"]:framework()
    print("^2[DEBUG]^7 Framework: " .. tostring(fw))
    
    if FW then
        print("^2[DEBUG]^7 FW table existe")
        Dump(FW)  -- Mostra todas as funções
    end
end)
```

### Verificar NUI Errors

Abra o console do navegador (F8) e verifique a aba Console para erros JavaScript.

---

## 📞 Suporte

Se você encontrou um problema não listado aqui:

1. **Verifique a documentação completa**
   - [README.md](README.md)
   - [EXAMPLES.md](EXAMPLES.md)

2. **Discord da Comunidade**
   - https://discord.gg/NJjUn8Ad3P

3. **GitHub Issues**
   - Reporte bugs: https://github.com/potter7k/dk_snippets/issues

4. **Informações Úteis ao Pedir Ajuda**
   - Versão do FiveM
   - Versão do dk_snippets
   - Framework usado
   - Driver SQL usado
   - Mensagens de erro completas
   - Código que está tentando executar

---

## ✨ Próximos Passos

Após a instalação bem-sucedida:

1. **📖 Leia a documentação**
   - [CLIENT.md](dk_snippets/src/client/CLIENT.md) - Funções client-side
   - [SERVER.md](dk_snippets/src/server/SERVER.md) - Funções server-side
   - [SHARED.md](dk_snippets/src/shared/SHARED.md) - Funções compartilhadas

2. **🎓 Veja os exemplos**
   - [EXAMPLES.md](EXAMPLES.md) - Casos de uso práticos

3. **🛠️ Comece a desenvolver**
   - Use as funções no seu script
   - Explore as possibilidades

---

<div align="center">

**[⬅️ Voltar ao README](README.md)** | **[➡️ Ver Exemplos](EXAMPLES.md)**

</div>
