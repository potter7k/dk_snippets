--https://github.com/overextended/ox_lib/blob/master/imports/table/shared.lua
local loaded = {}
-- modName → coroutine que está executando o load. Distingue ciclo verdadeiro
-- (a MESMA coroutine reentra) de carga concorrente (outra coroutine pede o módulo
-- enquanto um load que yielda — ex.: framework/init — ainda não terminou).
local loadingBy = {}
local _require = require

package = {
    path = './?.lua;./?/init.lua',
    preload = {},
    loaded = setmetatable({}, {
        __index = loaded,
        __newindex = nil,
        __metatable = false,
    })
}

---@param modName string
---@return string
---@return string
local function getModuleInfo(modName)
    local resource = modName:match('^@(.-)/.+') --[[@as string?]]

    if resource then
        return resource, modName:sub(#resource + 3)
    end

    local idx = 4 -- call stack depth (kept slightly lower than expected depth "just in case")

    while true do
        local info = debug.getinfo(idx, 'S')

        if not info then
            return "", modName
        end

        local src = info.source

        if not src then
            return "", modName
        end

        resource = src:match('^@@([^/]+)/.+')

        if resource and not src:find('^@@ox_lib/imports/require') then
            return resource, modName
        end

        idx = idx + 1
    end
end

local tempData = {}

---@param name string
---@param path string
---@return string? filename
---@return string? errmsg
---@diagnostic disable-next-line: duplicate-set-field
function package.searchpath(name, path)
    local resource, modName = getModuleInfo(name:gsub('%.', '/'))
    local tried = {}

    for template in path:gmatch('[^;]+') do
        local fileName = template:gsub('^%./', ''):gsub('?', modName:gsub('%.', '/') or modName)
        local file = LoadResourceFile(resource, fileName)

        if file then
            tempData[1] = file
            tempData[2] = resource
            return fileName
        end

        tried[#tried + 1] = ("no file '@%s/%s'"):format(resource, fileName)
    end

    return nil, table.concat(tried, "\n\t")
end

---Attempts to load a module at the given path relative to the resource root directory.\
---Returns a function to load the module chunk, or a string containing all tested paths.
---@param modName string
---@param env? table
local function loadModule(modName, env)
    local fileName, err = package.searchpath(modName, package.path)

    if fileName then
        local file = tempData[1]
        local resource = tempData[2]

        table.wipe(tempData)
        return assert(load(file, ('@@%s/%s'):format(resource, fileName), 't', env or _ENV))
    end

    return nil, err or 'unknown error'
end

---@alias PackageSearcher
---| fun(modName: string): function|boolean loader
---| fun(modName: string): nil, string errmsg

---@type PackageSearcher[]
package.searchers = {
    function(modName)
        local ok, result = pcall(_require, modName)

        if ok then return result end

        return ok, result
    end,
    function(modName)
        if package.preload[modName] ~= nil then
            return package.preload[modName]
        end

        return nil, ("no field package.preload['%s']"):format(modName)
    end,
    function(modName) return loadModule(modName) end,
}

---Loads the given module, returns any value returned by the seacher (`true` when `nil`).\
---Passing `@resourceName.modName` loads a module from a remote resource.
---@param modName string
---@return unknown
function require(modName)
    if type(modName) ~= 'string' then
        error(("module name must be a string (received '%s')"):format(modName), 3)
    end

    local module = loaded[modName]

    if module == '__loading' then
        if loadingBy[modName] == coroutine.running() then
            error(("^1circular-dependency occurred when loading module '%s'^0"):format(modName), 2)
        end

        -- Outra coroutine está no meio do load (que yieldou): aguarda concluir
        -- em vez de reportar falso ciclo, e devolve o resultado dela.
        repeat Wait(0) until loaded[modName] ~= '__loading'

        return require(modName)
    end

    if module ~= nil then return module end

    loaded[modName] = '__loading'
    loadingBy[modName] = coroutine.running()

    local err = {}

    for i = 1, #package.searchers do
        local result, errMsg = package.searchers[i](modName)

        if result then
            if type(result) == 'function' then
                local ok, value = pcall(result)

                if not ok then
                    -- Limpa a sentinela: um load que falhou não pode deixar os
                    -- próximos requires (ou quem está aguardando) presos em '__loading'.
                    loaded[modName] = nil
                    loadingBy[modName] = nil
                    error(value, 0)
                end

                result = value
            end

            loaded[modName] = result or result == nil
            loadingBy[modName] = nil

            return loaded[modName]
        end

        err[#err + 1] = errMsg
    end

    loaded[modName] = nil
    loadingBy[modName] = nil
    error(("%s"):format(table.concat(err, "\n\t")))
end
