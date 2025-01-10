# SQF Compiler Macros

ESM's build tool includes macros that are expanded during compilation. These are defined in `src/build/host/src/compiler.rs`.

> **Note**: Due to Regex-based implementation, macros currently only support single-line usage.
> Macro arguments support both SQF code and other macros.

## Core Macros

### Constant Access
#### `const!(constant_name)`
Retrieves the corresponding value defined in constants.jsonc
```sqf
const!("EXAMPLE_STRING")
// ->
"Hello world!"
```

#### `current_year!()`
Gets current year at compile time. Primarily used for copyright notices.
```sqf
current_year!()
// ->
2024
```

### File/Path Handling
#### `file_name!()`
Returns the name of the current file without extension. Useful for logging and file operations.
```sqf
file_name!()
// ->
"my_file"
```

#### `os_path!(path_fragments...)`
Creates OS-appropriate file paths for CfgFunctions. Handles path separator differences between Windows and Linux.
```sqf
os_path!("my_mod", "code")
// ->
"/my_mod/code" // Linux

os_path!("my_mod", "code")
// ->
"\my_mod\code" // Windows
```

### Function Definition
#### `define_fn!(function_name)`
Creates Exile function definition array required by `fn_preInit.sqf`. Automatically handles OS-specific path separators.
```sqf
define_fn!("ESMs_util_test_myFunction")
// ->
["ESMs_util_test_myFunction", "/exile_server_manager/code/ESMs_util_test_myFunction.sqf"]
```

#### `network_fn!(function_name)`
Creates an Exile-formatted network function name pair. Requires 'network' in the name and valid parts before/after it.
```sqf
network_fn!("ESMs_system_reward_network_loadAll")
// ->
["ExileServer_system_network_esm_rewardLoadAll", "ESMs_system_reward_network_loadAll"]
```

### HashMap Operations
#### `dig!(hash, keys...)`
Recursively searches HashMap for nested keys. Shorthand for ESMs_util_hashmap_dig.
```sqf
dig!(_myHash, "foo", "bar")
// ->
[_myHash, "foo", "bar"] call ESMs_util_hashmap_dig
```

#### `get!(hashmap, value, ?default)`
Gets HashMap value with optional default. Uses `nil` if no default provided.
```sqf
get!(_map, "foo")
// ->
_map getOrDefault ["foo", nil]

get!(_map, "foo", 0)
// ->
_map getOrDefault ["foo", 0]
```

### Type Checking
#### `type?(object, TYPE)` / `!type?(object, TYPE)`
Checks object type. Supports: ARRAY, BOOL, HASH, STRING, NIL
```sqf
type?(_obj, STRING)
// ->
_obj isEqualType ""

!type?(_obj, ARRAY)
// ->
!(_obj isEqualType [])
```

#### `empty?(object)` / `!empty?(object)`
Checks if object has zero elements using count comparison.
```sqf
empty?(_obj)
// ->
count(_obj) isEqualTo 0

!empty?(_obj)
// ->
count(_obj) isNotEqualTo 0
```

#### `nil?(variable)` / `!nil?(variable)`
Checks if variable is `nil`. Important for Arma's variable handling.
```sqf
nil?(_var)
// ->
isNil "_var"

!nil?(_var)
// ->
!(isNil "_var")
```

#### `null?(object)`
Checks if object is null. Distinct from `nil` in Arma - `null` objects (`objNull`, `locationNull`, etc.) are not considered `nil`.
```sqf
null?(_obj)
// ->
isNull _obj
```

#### `!null?(object)`
Checks if object is not null. Distinct from `nil` in Arma - `null` objects (`objNull`, `locationNull`, etc.) are not considered `nil`.
```sqf
!null?(_obj)
// ->
!(isNull _obj)
```

### Return Value Helpers
#### `returns_nil!(object)`
Safe nil return handler. Works around Arma's limitation with referencing variables that contain `nil`
```sqf
returns_nil!(_obj)
// ->
if (isNil "_obj") then { nil } else { _obj }
```

#### `rv_type!(TYPE)`
Returns default value for specified type. Used primarily with the `params` command.
```sqf
rv_type!(ARRAY)
// ->
[]

rv_type!(STRING)
// ->
""
```

### Logging
#### `<level>!(message, replacements...)`
Logging with string interpolation support. Levels: trace, debug, info, warn, error.
Non-string objects are automatically formatted.
```sqf
info!("Hello %1", _name)
// ->
["file", format["Hello %1", _name], "info"] call ESMs_util_log

debug!(_object)
// ->
["file", format["%1", _object], "debug"] call ESMs_util_log
```

### Localization
#### `localize!(key_without_prefix, replacements...)`
String localization with optional interpolation. Automatically adds "STR_ESM_" prefix.
```sqf
localize!("Key")
// ->
localize "$STR_ESM_Key"

localize!("Key", _val)
// ->
format[localize "$STR_ESM_Key", _val]
```
