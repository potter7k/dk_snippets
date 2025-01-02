## Database Export

This script also supports database operations using popular SQL drivers.

### Basic Usage

To access the database, use the following export:

```lua
local db = exports["dk_snippets"]:DB()
```

### Available Methods

#### `SQL.hasTable(name)`
Checks if a table exists.

**Parameters**:
- `name` (string): Table name.

**Return**:
- (boolean): `true` if the table exists, otherwise `false`.

**Example**:
```lua
if db.hasTable("users") then
    print("The 'users' table exists!")
end
```

#### `SQL.hasColumn(table, column)`
Checks if a column exists in a table.

**Parameters**:
- `table` (string): Table name.
- `column` (string): Column name.

**Return**:
- (boolean): `true` if the column exists, otherwise `false`.

**Example**:
```lua
if db.hasColumn("users", "name") then
    print("The 'name' column exists in the 'users' table!")
end
```

#### `SQL.execute(sql, params)`
Executes an SQL query.

**Parameters**:
- `sql` (string): SQL query.
- `params` (table): Parameters for the query.

**Return**:
- (any): Query result.

**Example**:
```lua
local result = db.execute("SELECT * FROM users WHERE age > ?", {25})
print(json.encode(result))
```

#### `SQL.insert(table_name, data, operation)`
Inserts data into a table.

**Parameters**:
- `table_name` (string): Table name.
- `data` (table): Data to insert.
- `operation` (string, optional): SQL operation (default: 'INSERT').

**Example**:
```lua
db.insert("users", {name = "John", age = 30})
```

### Supported Drivers
Currently, the following SQL drivers are supported:
- **oxmysql**
- **ghmattimysql**
- **GHMattiMySQL**
- **mysql-async**

The script automatically selects the active driver on the server.

## JSON File Handling

The script provides methods for directly handling JSON files.

### JSON Class

#### `JSON:fetch(filePath)`
Loads data from a JSON file and initializes the object.

**Parameters**:
- `filePath` (string): Path to the JSON file.

**Return**:
- (JSON): Initialized JSON object.

**Example**:
```lua
local jsonData = JSON:fetch("data/users")
```

#### `JSON:where(key, data, keepIndex)`
Filters data based on criteria.

**Parameters**:
- `key` (string): Key to search.
- `data` (table): Matching criteria.
- `keepIndex` (boolean): Retain original indexes.

**Return**:
- (table): Filtered data.

**Example**:
```lua
local users = jsonData:where("users", {age = 30})
```

#### `JSON:insert(key, data)`
Inserts a new record with an auto-incremental ID.

**Parameters**:
- `key` (string): Key to insert.
- `data` (table): Data to insert.

**Return**:
- (table): Information about the insertion.

**Example**:
```lua
jsonData:insert("users", {name = "Alice", age = 25})
```

#### `JSON:update(key, data, newData, replace)`
Updates existing records based on criteria.

**Parameters**:
- `key` (string): Key to update.
- `data` (table): Matching criteria.
- `newData` (table): New data.
- `replace` (boolean): Replace the entire record.

**Return**:
- (table): Information about the update.

**Example**:
```lua
jsonData:update("users", {name = "Alice"}, {age = 26})
```

#### `JSON:delete(key, data)`
Deletes records based on criteria.

**Parameters**:
- `key` (string): Key to delete.
- `data` (table): Matching criteria.

**Return**:
- (table): Information about the deletion.

**Example**:
```lua
jsonData:delete("users", {name = "Alice"})
```

#### `JSON:tableExists(key)`
Checks if a table exists.

**Parameters**:
- `key` (string): Key to check.

**Return**:
- (boolean): `true` if the table exists, otherwise `false`.

**Example**:
```lua
if jsonData:tableExists("users") then
    print("The 'users' table exists!")
end
```

#### `JSON:findAll(key)`
Returns all records from a key.

**Parameters**:
- `key` (string): Key to search records.

**Return**:
- (table): All records from the key.

**Example**:
```lua
local allUsers = jsonData:findAll("users")
```