## Callback System for FiveM

The callback system simplifies the process of calling functions across the client-server boundary. It includes utilities to:
- Register server-side callbacks that can be triggered by clients.
- Register client-side callbacks that can be triggered by the server.
- Handle timeout scenarios to ensure reliable operations.

## License

This callback system is based on the implementation by [PiterMcFlebor](https://github.com/pitermcflebor/pmc-callbacks) and is provided under the MIT License. The full license text can be found in the source code.

## Features

- **Server-side callbacks**: Allow clients to request data or execute server logic.
- **Client-side callbacks**: Enable the server to call client-side logic.
- **Timeout management**: Handle scenarios where a callback response might not arrive in time.
- **Error handling**: Ensure type safety and proper use of arguments.

---

## Implementation Details

### Server-Side Functions

#### `RegisterServerCallback(eventName, eventCallback)`
**Description**: Registers a callback function on the server that can be triggered by the client.

**Parameters:**
- `eventName` (string): The name of the event.
- `eventCallback` (function): The function to execute when the event is triggered.

**Usage Example:**
```lua
RegisterServerCallback('getVehName', function(source, vehId)
    local vehNames = {
        [1] = "abc",
        [2] = "def"
    }

    return vehNames[vehId]
end)
```

#### `TriggerServerCallback(eventName, args, eventCallback, timeout, timedout)`
**Description**: Triggers a server-side callback from the client.

**Parameters:**
- `eventName` (string): The name of the event.
- `args` (table, optional): Arguments to pass to the callback.
- `eventCallback` (function, optional): Function to handle the callback result.
- `timeout` (number, optional): Timeout in seconds.
- `timedout` (function, optional): Function to handle timeout scenarios.

**Usage Example:**
```lua
local vehName = TriggerServerCallback('getVehName', {
    2
})

print(vehName) -- "def"
```

#### `UnregisterServerCallback(eventData)`
**Description**: Unregisters a server callback to free up resources.

**Parameters:**
- `eventData`: The event handler returned by `RegisterServerCallback`.

#### `TriggerClientCallback(source, eventName, args, eventCallback, timeout, timedout)`
**Description**: Triggers a client-side callback from the server.

**Parameters:**
- `source` (number|string): The client ID.
- `eventName` (string): The name of the event.
- `args` (table, optional): Arguments to pass to the callback.
- `eventCallback` (function, optional): Function to handle the callback result.
- `timeout` (number, optional): Timeout in seconds.
- `timedout` (function, optional): Function to handle timeout scenarios.

**Usage Example:**
```lua
TriggerClientCallback(1, 'getPlayerInput', {prompt = "Enter your name"}, function(response)
    print("Player input:", response)
end, 10, function()
    print("Player did not respond in time.")
end)
```

### Client-Side Functions

#### `RegisterClientCallback(eventName, eventCallback)`
**Description**: Registers a callback function on the client that can be triggered by the server.

**Parameters:**
- `eventName` (string): The name of the event.
- `eventCallback` (function): The function to execute when the event is triggered.

**Usage Example:**
```lua
RegisterClientCallback('displayNotification', function(message)
    ShowNotification(message)
    return true
end)
```

#### `UnregisterClientCallback(eventData)`
**Description**: Unregisters a client callback to free up resources.

**Parameters:**
- `eventData`: The event handler returned by `RegisterClientCallback`.

---

## Cooldown System

The `Cooldown` class provides a simple interface for managing cooldowns in your scripts. Below are its functions and usage details.

### Cooldown Class Functions

#### `Cooldown:new(timer)`
**Description**: Creates a new `Cooldown` instance.

**Parameters:**
- `timer` (integer|nil): The default cooldown duration in seconds (optional).

**Returns:**
- A new `Cooldown` instance.

**Usage Example:**
```lua
local myCooldown = Cooldown:new(10) -- 10 seconds default cooldown
```

#### `Cooldown:start(timer)`
**Description**: Starts a cooldown.

**Parameters:**
- `timer` (integer|nil): The cooldown duration in seconds (optional). Defaults to the value set in `Cooldown:new`.

**Usage Example:**
```lua
myCooldown:start(5) -- Start a 5-second cooldown
```

#### `Cooldown:reset()`
**Description**: Resets the cooldown, effectively stopping it.

**Usage Example:**
```lua
myCooldown:reset()
```

#### `Cooldown:check()`
**Description**: Checks if the cooldown is active and returns the remaining time.

**Returns:**
- Remaining time in seconds (integer), or `nil` if the cooldown is not active.

**Usage Example:**
```lua
local remaining = myCooldown:check()
if remaining then
    print("Cooldown active. Remaining time:", remaining, "seconds")
else
    print("Cooldown is not active.")
end
```

#### `Cooldown:checkAndCreate(timer, func)`
**Description**: Checks if a cooldown is active. If not, starts a new cooldown and executes an optional function.

**Parameters:**
- `timer` (integer|nil): The cooldown duration in seconds (optional).
- `func` (function|nil): A function to execute if the cooldown is active. Receives the remaining time as an argument.

**Returns:**
- `true` if a new cooldown was started.
- `false` if the cooldown is still active.

**Usage Example:**
```lua
local success = myCooldown:checkAndCreate(10, function(remaining)
    print("Cooldown active for", remaining, "more seconds.")
end)
if success then
    print("Cooldown started.")
else
    print("Cooldown is still active.")
end
```

---

## Utility Functions

#### `DkNotify(...)`
**Description**: Sends notifications to both the client and server sides.

**Parameters:**
- `...` (any): Arguments to pass to the notification.

**Usage Example:**
```lua
--client
DkNotify("red", "Payment error!", 5000)

--server
DkNotify(source, "red", "Payment error!", 5000)
```
#### `Dump(value, depth, key)`
**Description**: Dumps the content of a variable in a readable format.

**Parameters:**
- `value` (any): The value to dump.
- `depth` (integer): The current depth of the dump (optional).
- `key` (any): The key associated with the value (optional).

**Usage Example:**
```lua
local tbl = {name = "John", age = 30, nested = {key = "value"}}
Dump(tbl)
--[[
    [name] = "John",
    [age] = 30,
    [nested]
        [key] = "value"
]]
```

#### `Match(str, datas)`
**Description**: Matches a string with a corresponding value in a table.

**Parameters:**
- `str` (string): The string to match.
- `datas` (table): The table containing the data.

**Returns:**
- The corresponding value or the result of the function if the value is a function. Returns `nil` if no match is found and no default value is provided.

**Usage Example:**
```lua
local result = Match("key1", {
    key1 = "value1", 
    key2 = 2,
    key3 = {"can", "be", "a", "table"}, 
    default = function()
        return "defaultValue"
    end
})
print(result) -- "value1"
```

#### `Ensure(obj, typeof, opt_typeof, errMessage)`
**Description**: Ensures the type of an object matches the expected types and throws an error if it doesn't.

**Parameters:**
- `obj` (any): The object to check.
- `typeof` (string|function): The primary type to check against.
- `opt_typeof` (string|nil): An optional secondary type to check against.
- `errMessage` (string|nil): An optional custom error message.

**Returns**: 
- Throws an error if the type of the object does not match the expected types.

**Usage Example:**
```lua
Ensure(123, "number", "string")
-- No error

Ensure("hello", "number", "string", "Custom error message")
-- Error: Custom error message
```

---

### Table Utility Functions

#### `function table.count(self)`
**Description**: Counts the number of elements in a table.

**Parameters:**
- `self` (table): The table to count elements in.

**Returns:**
- The number of elements in the table.

**Usage Example:**
```lua
local count = table.count({1, 2, 3})
print(count) -- 3
```

#### `table.map(self, func, preventIndex)`
**Description**: Maps a function to each element in a table and optionally prevents indexing.

**Parameters:**
- `self` (table): The table to map over.
- `func` (function): The function to apply.
- `preventIndex` (boolean): Whether to prevent indexing.

**Returns:**
- A new table with the mapped values.

**Usage Example:**
```lua
local result = table.map({1, 2, 3}, function(value)
    return value * 2
end)
print(result) -- {2, 4, 6}
```

#### `table.forEach(self, func)`
**Description**: Iterates over each element in a table and applies a function.

**Parameters:**
- `self` (table): The table to iterate over.
- `func` (function): The function to apply.

**Usage Example:**
```lua
table.forEach({1, 2, 3}, function(value)
    print(value) -- 1, 2, 3
end)
```

#### `table.find(self, func, keepIndex)`
**Description**: Finds elements in a table that match a function's criteria.

**Parameters:**
- `self` (table): The table to search.
- `func` (function): The criteria function.
- `keepIndex` (boolean): Whether to keep the original indices.

**Returns:**
- A table of matching elements.

**Usage Example:**
```lua
local matches = table.find({1, 2, 3}, function(value)
    return value > 1
end)
print(matches) -- {2, 3}
```

#### `table.indexOf(self, o)`
**Description**: Finds the index of an element in a table.

**Parameters:**
- `self` (table): The table to search.
- `o` (any): The element to find.

**Returns:**
- The index of the element, or `nil` if not found.

**Usage Example:**
```lua
local index = table.indexOf({"a", "b", "c"}, "b")
print(index) -- 2
```