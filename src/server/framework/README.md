
## Exportando a Identificação do Framework

Você pode usar o export para identificar o framework do servidor da seguinte maneira:

```lua
local frameworkName, predefinedFunctions = exports["dk_snippets"]:framework()
```

- **Retorno**:
  - `frameworkName`: Nome do framework detectado.
  - `predefinedFunctions`: Funções predefinidas disponíveis no script para o framework identificado.

### Frameworks Suportados
Atualmente, o script suporta os seguintes frameworks:
- **vRP**: Se detectado, o retorno será `"vrp"`.
- **Sem Framework**: Se nenhum framework for encontrado, o retorno será `nil`.

## Adicionando Funções Customizadas
Caso você queira adicionar funções para frameworks, o script permite utilizar métodos já existentes no próprio framework. Se a função chamada não estiver definida como predefinida no script, ele buscará automaticamente essa função no framework detectado.

Utilize o seguinte padrão:

```lua
FW = predefinedFunctions
FW.__index = function(self, name)
    self[name] = function(...)
        return FW._custom(name, ...)
    end
    return self[name]
end
setmetatable(FW, FW)

local isAdmin = FW.isAdmin(source)
local user_id = FW.userId(source)

print(isAdmin) -- true/false
print(user_id) -- 1

```

- **Explicação**:
  - Caso a função chamada não esteja nas funções predefinidas do script, o sistema utilizará as funções diretamente do framework configurado no servidor.
  - Você também pode definir funções customizadas dinâmicas através de `FW._custom`, onde `name` é o nome da função e `...` são os argumentos passados.

### Registrar novos frameworks (adicione diretamente na pasta do script)

#### `FW:set(name, func)`
Define uma função customizada para o framework.

**Parâmetros**:
- `name` (string): Nome da função.
- `func` (function): A função que será executada.

**Exemplo**:
```lua
FW:set("customFunction", function()
    print("Função customizada executada!")
end)
```

#### `FW:get(name)`
Obtém e executa uma função previamente definida.

**Parâmetros**:
- `name` (string): Nome da função.

**Exemplo**:
```lua
FW:get("customFunction")
```
