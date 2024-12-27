local supportedFrameworks = {
    vrp = function() return FW:get("vrp") end
}

FW = {
    list = {},
}

function FW:set(name, func)
    self.list[name] = func
end

function FW:get(name)
    return self.list[name] ()
end

function Framework()
    for name, handler in pairs(supportedFrameworks) do
        if GetResourceState(name) ~= 'missing' then
            return handler()
        end
    end
    return FW:get("_nofw")
end

exports("framework", Framework)
