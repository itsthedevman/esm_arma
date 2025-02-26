use std::collections::HashMap;

use chrono::prelude::*;
use compiler::{Compiler, CompilerError, Data};
use heck::{ToLowerCamelCase, ToSnakeCase};
use lazy_static::lazy_static;
use regex::Captures;
use serde_json::Value;

lazy_static! {
    static ref CONSTANTS: HashMap<String, Value> = {
        let file_path = crate::builder::GIT_PATH.join("src").join("constants.yml");

        let contents = std::fs::read_to_string(file_path)
            .expect("Missing file esm_arma/src/constants.yml");

        serde_yaml::from_str(&contents)
            .expect("Failed to parse content in constants.yml")
    };
}

type CompilerResult = Result<Option<String>, CompilerError>;

const NAME_CONST: &str = "const!";
const PATTERN_CONST: &str = r#"(\w+)"#;

const NAME_CURRENT_YEAR: &str = "current_year!";
const PATTERN_CURRENT_YEAR: &str = "";

const NAME_SERVER_FN: &str = "server_fn!";
const PATTERN_SERVER_FN: &str = r#""(\w+)?""#;

const NAME_DIG: &str = "dig!";
const PATTERN_DIG: &str = r#"(.+[^)])"#;

const NAME_EMPTY_NEGATED: &str = "!empty?";
const PATTERN_EMPTY_NEGATED: &str = r#"(\S+[^)])"#;

const NAME_EMPTY: &str = "empty?";
const PATTERN_EMPTY: &str = r#"(\S+[^)])"#;

const NAME_FILE_NAME: &str = "file_name!";
const PATTERN_FILE_NAME: &str = "";

const NAME_GET_WITH_DEFAULT: &str = "get!";
const PATTERN_GET_WITH_DEFAULT: &str = r"(.+),\s*(.+),\s*(.+[^)])";

const NAME_GET: &str = "get!";
const PATTERN_GET: &str = r"(.+)?,\s*(.+[^)])?";

const NAME_KEY: &str = "key?";
const PATTERN_KEY: &str = r#"(.+[^)])"#;

const NAME_LOCALIZE: &str = "localize!";
const PATTERN_LOCALIZE: &str = r#""(\w+)"((?:,\s*[\w\s"]+)*)"#;

const NAME_LOG_TRACE: &str = "trace!";
const NAME_LOG_DEBUG: &str = "debug!";
const NAME_LOG_INFO: &str = "info!";
const NAME_LOG_WARN: &str = "warn!";
const NAME_LOG_ERROR: &str = "error!";
const PATTERN_LOG_WITH_ARGS: &str = r#"(".+")*,\s*(.*)+"#;

const PATTERN_LOG: &str = r#"(.+)"#;

const NAME_NETWORK_FN: &str = "network_fn!";
const PATTERN_NETWORK_FN: &str = r#""(\w+)?""#;

const NAME_MISSION_FN: &str = "mission_fn!";
const PATTERN_MISSION_FN: &str = r#""(\w+)?""#;

const NAME_NIL_NEGATED: &str = "!nil?";
const PATTERN_NIL_NEGATED: &str = r#"(\w+)?"#;

const NAME_NIL: &str = "nil?";
const PATTERN_NIL: &str = r#"(\w+)?"#;

const NAME_NULL: &str = "null?";
const PATTERN_NULL: &str = r"(\w+)?";

const NAME_NULL_NEGATED: &str = "!null?";
const PATTERN_NULL_NEGATED: &str = r"(\w+)?";

const NAME_OS_PATH: &str = "os_path!";
const PATTERN_OS_PATH: &str = r"(.+,?)?";

const NAME_RETURNS_NIL: &str = "returns_nil!";
const PATTERN_RETURNS_NIL: &str = r#"(\w+)"#;

const NAME_RV_TYPE: &str = "rv_type!";
const PATTERN_RV_TYPE: &str = r"(ARRAY|BOOL|HASH|STRING|NIL)?";

const NAME_TYPE_CHECK_NEGATED: &str = "!type?";
const PATTERN_TYPE_CHECK_NEGATED: &str = r"(.+)?,\s*(ARRAY|BOOL|HASH|STRING|NIL)?";

const NAME_TYPE_CHECK: &str = "type?";
const PATTERN_TYPE_CHECK: &str = r"(.+)?,\s*(ARRAY|BOOL|HASH|STRING|NIL)?";

pub fn bind_replacements(compiler: &mut Compiler) {
    compiler
        .replace_macro(NAME_CURRENT_YEAR, PATTERN_CURRENT_YEAR, current_year)
        .replace_macro(NAME_FILE_NAME, PATTERN_FILE_NAME, file_name)
        .replace_macro(NAME_LOG_DEBUG, PATTERN_LOG_WITH_ARGS, log)
        .replace_macro(NAME_LOG_DEBUG, PATTERN_LOG, log)
        .replace_macro(NAME_LOG_ERROR, PATTERN_LOG_WITH_ARGS, log)
        .replace_macro(NAME_LOG_ERROR, PATTERN_LOG, log)
        .replace_macro(NAME_LOG_INFO, PATTERN_LOG_WITH_ARGS, log)
        .replace_macro(NAME_LOG_INFO, PATTERN_LOG, log)
        .replace_macro(NAME_LOG_TRACE, PATTERN_LOG_WITH_ARGS, log)
        .replace_macro(NAME_LOG_TRACE, PATTERN_LOG, log)
        .replace_macro(NAME_LOG_WARN, PATTERN_LOG_WITH_ARGS, log)
        .replace_macro(NAME_LOG_WARN, PATTERN_LOG, log)
        .replace_macro(NAME_CONST, PATTERN_CONST, replace_const)
        .replace_macro(NAME_SERVER_FN, PATTERN_SERVER_FN, server_fn)
        .replace_macro(NAME_DIG, PATTERN_DIG, hash_dig)
        .replace_macro(NAME_EMPTY_NEGATED, PATTERN_EMPTY_NEGATED, not_empty)
        .replace_macro(NAME_EMPTY, PATTERN_EMPTY, empty)
        .replace_macro(NAME_GET_WITH_DEFAULT, PATTERN_GET_WITH_DEFAULT, hash_get)
        .replace_macro(NAME_GET, PATTERN_GET, hash_get)
        .replace_macro(NAME_KEY, PATTERN_KEY, hash_key)
        .replace_macro(NAME_LOCALIZE, PATTERN_LOCALIZE, localize)
        .replace_macro(NAME_NETWORK_FN, PATTERN_NETWORK_FN, network_fn)
        .replace_macro(NAME_MISSION_FN, PATTERN_MISSION_FN, mission_fn)
        .replace_macro(NAME_NIL_NEGATED, PATTERN_NIL_NEGATED, not_nil)
        .replace_macro(NAME_NIL, PATTERN_NIL, nil)
        .replace_macro(NAME_NULL_NEGATED, PATTERN_NULL_NEGATED, not_null)
        .replace_macro(NAME_NULL, PATTERN_NULL, null)
        .replace_macro(NAME_OS_PATH, PATTERN_OS_PATH, os_path)
        .replace_macro(NAME_RETURNS_NIL, PATTERN_RETURNS_NIL, returns_nil)
        .replace_macro(NAME_RV_TYPE, PATTERN_RV_TYPE, rv_type)
        .replace_macro(NAME_TYPE_CHECK_NEGATED, PATTERN_TYPE_CHECK_NEGATED, type_ne)
        .replace_macro(NAME_TYPE_CHECK, PATTERN_TYPE_CHECK, type_eq);
}

fn localize(_context: &Data, matches: &Captures) -> CompilerResult {
    let locale_name = match matches.get(1) {
        Some(c) => c.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expected 1",).into()
            )
        }
    };

    let default = format!(r#"localize "$STR_ESM_{locale_name}""#);

    let result = match matches.get(2) {
        Some(c) => {
            // arguments string starts with ,\s* if matched
            let arguments = c.as_str();

            // This will match on nothing
            if arguments.is_empty() {
                default
            } else {
                format!(r#"format[localize "$STR_ESM_{locale_name}"{arguments}]"#)
            }
        }
        None => default,
    };

    Ok(Some(result))
}

fn file_name(context: &Data, _matches: &Captures) -> CompilerResult {
    Ok(Some(format!("{:?}", context.file_name)))
}

// server_fn!("ESMs_util_log") -> ["ESMs_util_log", "\exile_server_manager\code\ESMs_util_log.sqf"]
fn server_fn(_context: &Data, matches: &Captures) -> CompilerResult {
    let function_name = match matches.get(1) {
        Some(c) => c.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expected 1",).into()
            )
        }
    };

    Ok(Some(format!(
        "[\"{function_name}\", \"{sep}exile_server_manager{sep}code{sep}{function_name}.sqf\"]",
        sep = "\\"
    )))
}

// mission_fn!("ESMc_util_log") -> ["ESMc_util_log", "exile_server_manager\code\ESMs_util_log.sqf"]
// Note the missing front slash
fn mission_fn(_context: &Data, matches: &Captures) -> CompilerResult {
    let function_name = match matches.get(1) {
        Some(c) => c.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expected 1",).into()
            )
        }
    };

    Ok(Some(format!(
        "[\"{function_name}\", \"exile_server_manager{sep}code{sep}{function_name}.sqf\"]",
        sep = "\\"
    )))
}

// network_fn!("ESMs_system_network_message")
//      -> ["ExileServer_system_network_esm_systemMessage", "ESMs_system_network_message"]
fn network_fn(_context: &Data, matches: &Captures) -> CompilerResult {
    let esm_function_name = matches
        .get(1)
        .ok_or(format!("Wrong number of arguments, given 0, expected 1",))?
        .as_str();

    let parts: Vec<&str> = esm_function_name.split('_').collect();

    let function_prefix = parts[0];
    let function_prefix = if function_prefix == "ESMs" {
        "ExileServer"
    } else if function_prefix == "ESMc" {
        "ExileClient"
    } else {
        return Err(format!(
            "Unexpected function name prefix: {:?}",
            function_prefix
        )
        .into());
    };

    let network_index = parts
        .iter()
        .position(|&p| p == "network")
        .ok_or(format!("'network' not found in function name",))?;

    // Just take the first part after ESMs as prefix
    let prefix = parts[1];

    let middle_parts = &parts[2..network_index];

    // If no middle parts, use prefix, otherwise use middle parts
    let first_part = if middle_parts.is_empty() {
        prefix
    } else {
        &middle_parts.join("_")
    };

    let suffix = format!("{}_{}", first_part, parts[network_index + 1..].join("_"))
        .to_snake_case()
        .to_lower_camel_case();

    let exile_function_name =
        format!("{function_prefix}_esm_{prefix}_network_{suffix}");

    Ok(Some(format!(
        r#"["{}", "{}"]"#,
        exile_function_name, esm_function_name
    )))
}

// os_path!("my_mod", "some_dir") -> Windows: "my_mod\some_dir" - Linux: "my_mod/some_dir"
fn os_path(_context: &Data, matches: &Captures) -> CompilerResult {
    let path_chunks: Vec<String> = match matches.get(1) {
        Some(c) => c
            .as_str()
            .split(',')
            .map(|p| p.trim().replace('"', ""))
            .collect(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expected 1+",).into()
            )
        }
    };

    let separator = "\\";

    // Windows: \my_addon\path
    // Linux: my_addon\path
    Ok(Some(format!(
        "\"{separator}{}\"",
        path_chunks.join(separator)
    )))
}

// type?([], ARRAY) -> [] isEqualType []
// type?(_some_var, HASH) -> _some_var isEqualType createHashMap
fn type_eq(_context: &Data, matches: &Captures) -> CompilerResult {
    let comparee = match matches.get(1) {
        Some(c) => c.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expected 2",).into()
            )
        }
    };

    let arma_type = match matches.get(2) {
        Some(t) => match t.as_str() {
            "ARRAY" => "[]",
            "BOOL" => "false",
            "HASH" => "createHashMap",
            "STRING" => "\"\"",
            "NIL" => "nil",
            t => return Err(format!("Unsupported type provided: {t}",).into()),
        },
        None => {
            return Err(
                format!("Wrong number of arguments, given 1, expected 2",).into()
            )
        }
    };

    Ok(Some(format!("{comparee} isEqualType {arma_type}")))
}

// !type?([], ARRAY) -> !([] isEqualType [])
// !type?(_some_var, HASH) -> !(_some_var isEqualType createHashMap)
fn type_ne(_context: &Data, matches: &Captures) -> CompilerResult {
    let comparee = match matches.get(1) {
        Some(c) => c.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expected 2",).into()
            )
        }
    };

    let arma_type = match matches.get(2) {
        Some(t) => match t.as_str() {
            "ARRAY" => "[]",
            "BOOL" => "false",
            "HASH" => "createHashMap",
            "STRING" => "\"\"",
            "NIL" => "nil",
            t => return Err(format!("Unsupported type provided: {t}",).into()),
        },
        None => {
            return Err(
                format!("Wrong number of arguments, given 1, expected 2",).into()
            )
        }
    };

    Ok(Some(format!("!({comparee} isEqualType {arma_type})")))
}

// rv_type!(ARRAY) -> []
// rv_type!(HASH) -> createHashMap
fn rv_type(_context: &Data, matches: &Captures) -> CompilerResult {
    Ok(Some(
        match matches.get(1) {
            Some(m) => match m.as_str() {
                "ARRAY" => "[]",
                "BOOL" => "false",
                "HASH" => "createHashMap",
                "STRING" => "\"\"",
                "NIL" => "nil",
                t => {
                    return Err(format!("Invalid type provided to type: {t}",).into())
                }
            },
            None => {
                return Err(format!(
                    "Wrong number of arguments, given 0, expected 1",
                )
                .into())
            }
        }
        .into(),
    ))
}

// get!(_hash_map, "key") -> _hash_map getOrDefault ["key", nil];
// get!(createHashMap, "key", 1) -> createHashMap getOrDefault ["key", 1];
fn hash_get(_context: &Data, matches: &Captures) -> CompilerResult {
    let hash_map = match matches.get(1) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expect 2..3",).into()
            )
        }
    };

    let key = match matches.get(2) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 1, expect 2..3",).into()
            )
        }
    };

    let default = match matches.get(3) {
        Some(default) => default.as_str(),
        None => "nil",
    };

    Ok(Some(format!(
        "{} getOrDefault [{}, {}]",
        hash_map, key, default
    )))
}

fn hash_dig(_context: &Data, matches: &Captures) -> CompilerResult {
    let contents = match matches.get(1) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expect 1..",).into()
            )
        }
    };

    Ok(Some(format!("[{}] call ESMs_util_hashmap_dig", contents)))
}

fn hash_key(_context: &Data, matches: &Captures) -> CompilerResult {
    let contents = match matches.get(1) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expect 1..",).into()
            )
        }
    };

    Ok(Some(format!("[{}] call ESMs_util_hashmap_key", contents)))
}

// info!(_my_var) -> ["file_name", format["%1", _my_var], "info"] call ESMs_util_log;
// debug!("Its %1 me, %2", _a, "mario") -> ["file_name", format["Its %1 me, %2", _a, "mario"], "debug"] call ESMs_util_log;
fn log(context: &Data, matches: &Captures) -> CompilerResult {
    // Without the "!" at the end
    let log_level = &context.name[..context.name.len() - 1].to_string();

    let content = match matches.get(1) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expect 1..2",).into()
            )
        }
    };

    Ok(Some(match matches.get(2) {
        Some(args) => format!(
            "[\"{}\", format[{}, {}], \"{}\"] call ESMs_util_log",
            context.file_name,
            content,
            args.as_str(),
            log_level
        ),
        None => format!(
            "[\"{}\", format[\"%1\", {}], \"{}\"] call ESMs_util_log",
            context.file_name, content, log_level
        ),
    }))
}

fn empty(_context: &Data, matches: &Captures) -> CompilerResult {
    let contents = match matches.get(1) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expect 1",).into()
            )
        }
    };

    Ok(Some(format!("count({}) isEqualTo 0", contents)))
}

fn not_empty(_context: &Data, matches: &Captures) -> CompilerResult {
    let contents = match matches.get(1) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expect 1",).into()
            )
        }
    };

    Ok(Some(format!("count({}) isNotEqualTo 0", contents)))
}

fn returns_nil(_context: &Data, matches: &Captures) -> CompilerResult {
    let variable = match matches.get(1) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expect 1",).into()
            )
        }
    };

    Ok(Some(format!(
        r#"if (isNil "{variable}") then {{ nil }} else {{ {variable} }}"#
    )))
}

fn not_nil(_context: &Data, matches: &Captures) -> CompilerResult {
    let content = match matches.get(1) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expect 1",).into()
            )
        }
    };

    Ok(Some(format!("!(isNil \"{content}\")")))
}

fn nil(_context: &Data, matches: &Captures) -> CompilerResult {
    let content = match matches.get(1) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expect 1",).into()
            )
        }
    };

    Ok(Some(format!("isNil \"{content}\"")))
}

fn null(_context: &Data, matches: &Captures) -> CompilerResult {
    let content = match matches.get(1) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expect 1",).into()
            )
        }
    };

    Ok(Some(format!("isNull {content}")))
}

// !null?(objNull)
fn not_null(context: &Data, matches: &Captures) -> CompilerResult {
    let content = null(context, matches)?.ok_or("No content found")?;

    Ok(Some(format!("!({content})")))
}

fn replace_const(_context: &Data, matches: &Captures) -> CompilerResult {
    let content = match matches.get(1) {
        Some(m) => m.as_str(),
        None => {
            return Err(
                format!("Wrong number of arguments, given 0, expect 1",).into()
            )
        }
    };

    // Load the constant
    let constant = match CONSTANTS.get(content) {
        Some(c) => c,
        None => return Err(format!("\"{content}\" is not defined",).into()),
    };

    let replacement = match constant {
        Value::Null => "nil".to_owned(),
        Value::Object(_) => {
            return Err(format!(
            "\"{content}\" contains an object. These are not supported at this time",
        )
            .into())
        }
        v => serde_json::to_string(v).unwrap(),
    };

    // Replace
    Ok(Some(replacement))
}

fn current_year(_context: &Data, _matches: &Captures) -> CompilerResult {
    Ok(Some(format!("{}", chrono::Utc::now().year())))
}

#[cfg(test)]
mod tests {
    use super::*;
    use compiler::Data;
    use compiler::*;
    use regex::Regex;

    #[macro_export]
    macro_rules! compile {
        ($code:expr, $name:expr, $pattern:expr, $parsing_method:ident) => {{
            let regex = Replacement::create_regex($name, $pattern);

            let replacement = Replacement {
                name: $name.into(),
                callback: Box::new($parsing_method),
                regex,
            };

            let mut file = File {
                content: $code.to_string(),
                ..File::default()
            };

            file.replace(&replacement, &Data::default()).unwrap();
            file.content
        }};

        ($code:expr, $name:expr, $pattern:expr, $parsing_method:ident, $data:expr) => {{
            let full_pattern = if $pattern.is_empty() {
                format!(r#"{}(?:\(\))"#, regex::escape($name))
            } else {
                format!(r#"{}\({}(?:\))"#, regex::escape($name), $pattern)
            };

            let regex = Regex::new(&full_pattern).unwrap();
            let replacement = Replacement {
                name: $name.into(),
                callback: Box::new($parsing_method),
                regex,
            };

            let mut file = File {
                content: $code.to_string(),
                ..File::default()
            };

            file.replace(&replacement, &$data).unwrap();
            file.content
        }};
    }

    #[test]
    fn it_replaces_localize() {
        let output = compile!(
            r#"localize!("Foo_Barrington")"#,
            NAME_LOCALIZE,
            PATTERN_LOCALIZE,
            localize
        );
        assert_eq!(output, r#"localize "$STR_ESM_Foo_Barrington""#);
    }

    #[test]
    fn it_replaces_localize_format() {
        let output = compile!(
            r#"localize!("Foo_Barrington", _foo, _bar, "baz", false)"#,
            NAME_LOCALIZE,
            PATTERN_LOCALIZE,
            localize
        );

        assert_eq!(
            output,
            r#"format[localize "$STR_ESM_Foo_Barrington", _foo, _bar, "baz", false]"#
        );
    }

    #[test]
    fn it_replaces_file_name() {
        let mut data = Data::default();
        data.file_name = "ESMs_test".into();

        let output = compile!(
            r#"file_name!()"#,
            NAME_FILE_NAME,
            PATTERN_FILE_NAME,
            file_name,
            data
        );
        assert_eq!(output, r#""ESMs_test""#);
    }

    #[test]
    fn it_replaces_server_fn() {
        let output = compile!(
            r#"server_fn!("MY_Awesome_Method")"#,
            NAME_SERVER_FN,
            PATTERN_SERVER_FN,
            server_fn
        );

        assert_eq!(
            output,
            r#"["MY_Awesome_Method", "\exile_server_manager\code\MY_Awesome_Method.sqf"]"#
        );
    }

    #[test]
    fn it_replaces_mission_fn() {
        let output = compile!(
            r#"mission_fn!("MY_Awesome_Method")"#,
            NAME_MISSION_FN,
            PATTERN_MISSION_FN,
            mission_fn
        );

        assert_eq!(
            output,
            r#"["MY_Awesome_Method", "exile_server_manager\code\MY_Awesome_Method.sqf"]"#
        );
    }

    #[test]
    fn it_replaces_network_fn() {
        let output = compile!(
            r#"network_fn!("ESMs_system_network_message")"#,
            NAME_NETWORK_FN,
            PATTERN_NETWORK_FN,
            network_fn
        );

        assert_eq!(
            output,
            r#"["ExileServer_esm_system_network_systemMessage", "ESMs_system_network_message"]"#
        );

        let output = compile!(
            r#"network_fn!("ESMs_object_iceCreamMachine_network_dispenseSoftServe")"#,
            NAME_NETWORK_FN,
            PATTERN_NETWORK_FN,
            network_fn
        );

        assert_eq!(
            output,
            r#"["ExileServer_esm_object_network_iceCreamMachineDispenseSoftServe", "ESMs_object_iceCreamMachine_network_dispenseSoftServe"]"#
        );

        let output = compile!(
            r#"network_fn!("ESMs_object_player_network_import")"#,
            NAME_NETWORK_FN,
            PATTERN_NETWORK_FN,
            network_fn
        );

        assert_eq!(
            output,
            r#"["ExileServer_esm_object_network_playerImport", "ESMs_object_player_network_import"]"#
        );

        let output = compile!(
            r#"network_fn!("ESMs_util_encryptionKey_network_updateSignature")"#,
            NAME_NETWORK_FN,
            PATTERN_NETWORK_FN,
            network_fn
        );

        assert_eq!(
            output,
            r#"["ExileServer_esm_util_network_encryptionKeyUpdateSignature", "ESMs_util_encryptionKey_network_updateSignature"]"#
        );

        let output = compile!(
            r#"network_fn!("ESMc_system_reward_network_loadAllResponse")"#,
            NAME_NETWORK_FN,
            PATTERN_NETWORK_FN,
            network_fn
        );

        assert_eq!(
            output,
            r#"["ExileClient_esm_system_network_rewardLoadAllResponse", "ESMc_system_reward_network_loadAllResponse"]"#
        );
    }

    #[test]
    fn it_replaces_type() {
        let output = compile!(
            r#"type?(_variable, STRING);"#,
            NAME_TYPE_CHECK,
            PATTERN_TYPE_CHECK,
            type_eq
        );
        assert_eq!(output, r#"_variable isEqualType "";"#);
    }

    #[test]
    fn it_replaces_not_type() {
        let output = compile!(
            r#"!type?(VARIABLE, HASH);"#,
            NAME_TYPE_CHECK_NEGATED,
            PATTERN_TYPE_CHECK_NEGATED,
            type_ne
        );
        assert_eq!(output, r#"!(VARIABLE isEqualType createHashMap);"#);
    }

    #[test]
    fn it_replaces_get() {
        let output = compile!(
            r#"
            private _hash_map = createHashMap;

            (get!(_hash_map, "key"));
        "#,
            NAME_GET,
            PATTERN_GET,
            hash_get
        );

        assert_eq!(
            output,
            r#"
            private _hash_map = createHashMap;

            (_hash_map getOrDefault ["key", nil]);
        "#
        )
    }

    #[test]
    fn it_replaces_get_with_default() {
        let output = compile!(
            r#"
            private _hash_map = createHashMap;

            get!(_hash_map, "key", "this is the default");
        "#,
            NAME_GET_WITH_DEFAULT,
            PATTERN_GET_WITH_DEFAULT,
            hash_get
        );

        assert_eq!(
            output,
            r#"
            private _hash_map = createHashMap;

            _hash_map getOrDefault ["key", "this is the default"];
        "#
        )
    }

    #[test]
    fn it_replaces_hash_dig() {
        let output = compile!(
            r#"
            private _hash_map = createHashMap;

            dig!(_hash_map, "key_1");
            dig!(_hash_map, "key_1", "key_2");
            dig!([] call ESMs_util_hashmap_fromArray, "key1", _key2, "key_3");
        "#,
            NAME_DIG,
            PATTERN_DIG,
            hash_dig
        );

        assert_eq!(
            output,
            r#"
            private _hash_map = createHashMap;

            [_hash_map, "key_1"] call ESMs_util_hashmap_dig;
            [_hash_map, "key_1", "key_2"] call ESMs_util_hashmap_dig;
            [[] call ESMs_util_hashmap_fromArray, "key1", _key2, "key_3"] call ESMs_util_hashmap_dig;
        "#
        )
    }

    #[test]
    fn it_replaces_hash_key() {
        let output = compile!(
            r#"
            private _hash_map = createHashMap;

            key?(_hash_map, "key_1");
            key?(_hash_map, "key_1", "key_2");
            key?([] call ESMs_util_hashmap_fromArray, "key1", _key2, "key_3");
        "#,
            NAME_KEY,
            PATTERN_KEY,
            hash_key
        );

        assert_eq!(
            output,
            r#"
            private _hash_map = createHashMap;

            [_hash_map, "key_1"] call ESMs_util_hashmap_key;
            [_hash_map, "key_1", "key_2"] call ESMs_util_hashmap_key;
            [[] call ESMs_util_hashmap_fromArray, "key1", _key2, "key_3"] call ESMs_util_hashmap_key;
        "#
        )
    }

    #[test]
    fn it_replaces_log() {
        let data = &Data {
            file_name: "ESMs_compiler_test".into(),
            ..Data::default()
        };

        let output = compile!(
            r#"trace!("Trace");"#,
            NAME_LOG_TRACE,
            PATTERN_LOG,
            log,
            data
        );

        assert_eq!(
            output,
            r#"["ESMs_compiler_test", format["%1", "Trace"], "trace"] call ESMs_util_log;"#
        );

        let output = compile!(
            r#"debug!("Debug");"#,
            NAME_LOG_DEBUG,
            PATTERN_LOG,
            log,
            data
        );

        assert_eq!(
            output,
            r#"["ESMs_compiler_test", format["%1", "Debug"], "debug"] call ESMs_util_log;"#
        );

        let output =
            compile!(r#"info!("Info");"#, NAME_LOG_INFO, PATTERN_LOG, log, data);

        assert_eq!(
            output,
            r#"["ESMs_compiler_test", format["%1", "Info"], "info"] call ESMs_util_log;"#
        );

        let output = compile!(
            r#"
            private _testing = "foo";
            warn!(_testing);
            "#,
            NAME_LOG_WARN,
            PATTERN_LOG,
            log,
            data
        );

        assert_eq!(
            output,
            r#"
            private _testing = "foo";
            ["ESMs_compiler_test", format["%1", _testing], "warn"] call ESMs_util_log;
            "#
        );

        let output = compile!(
            r#"error!([true, false]);"#,
            NAME_LOG_ERROR,
            PATTERN_LOG,
            log,
            data
        );

        assert_eq!(
            output,
            r#"["ESMs_compiler_test", format["%1", [true, false]], "error"] call ESMs_util_log;"#
        );
    }

    #[test]
    fn it_replaces_log_with_args() {
        let data = &Data {
            file_name: "ESMs_compiler_test".into(),
            ..Data::default()
        };

        let output = compile!(
            r#"
            private _testing = "foo";
            private _variables = "bar";

            debug!("Testing - %1bar - foo%2", _testing, _variables);
        "#,
            NAME_LOG_DEBUG,
            PATTERN_LOG_WITH_ARGS,
            log,
            data
        );

        assert_eq!(
            output,
            r#"
            private _testing = "foo";
            private _variables = "bar";

            ["ESMs_compiler_test", format["Testing - %1bar - foo%2", _testing, _variables], "debug"] call ESMs_util_log;
        "#
        )
    }

    #[test]
    fn it_replaces_empty() {
        let output = compile!(
            r#"
            empty?(_foo)
            (empty?([]))
            if ((empty?(foo)) then {};
        "#,
            NAME_EMPTY,
            PATTERN_EMPTY,
            empty
        );

        assert_eq!(
            output,
            r#"
            count(_foo) isEqualTo 0
            (count([]) isEqualTo 0)
            if ((count(foo) isEqualTo 0) then {};
        "#
        )
    }

    #[test]
    fn it_replaces_not_empty() {
        let output = compile!(
            r#"
            !empty?(_foo)
            (!empty?([]))
            if ((!empty?(foo)) then {};
        "#,
            NAME_EMPTY_NEGATED,
            PATTERN_EMPTY_NEGATED,
            not_empty
        );

        assert_eq!(
            output,
            r#"
            count(_foo) isNotEqualTo 0
            (count([]) isNotEqualTo 0)
            if ((count(foo) isNotEqualTo 0) then {};
        "#
        )
    }

    #[test]
    fn it_replaces_returns_nil() {
        let output = compile!(
            r#"returns_nil!(_variable);"#,
            NAME_RETURNS_NIL,
            PATTERN_RETURNS_NIL,
            returns_nil
        );

        assert_eq!(
            output,
            r#"if (isNil "_variable") then { nil } else { _variable };"#
        )
    }

    #[test]
    fn it_replaces_nil() {
        let output = compile!(r#"nil?(_variable);"#, NAME_NIL, PATTERN_NIL, nil);
        assert_eq!(output, r#"isNil "_variable";"#)
    }

    #[test]
    fn it_replaces_not_nil() {
        let output = compile!(
            r#"!nil?(_variable);"#,
            NAME_NIL_NEGATED,
            PATTERN_NIL_NEGATED,
            not_nil
        );
        assert_eq!(output, r#"!(isNil "_variable");"#)
    }

    #[test]
    fn it_replaces_null() {
        let output = compile!(r#"null?(objNull);"#, NAME_NULL, PATTERN_NULL, null);
        assert_eq!(output, r#"isNull objNull;"#);

        let output = compile!(
            r#"if (null?(_playerObject)) then"#,
            NAME_NULL,
            PATTERN_NULL,
            null
        );

        assert_eq!(output, r#"if (isNull _playerObject) then"#);

        let output =
            compile!(r#"null?(_playerObject);"#, NAME_NULL, PATTERN_NULL, null);
        assert_eq!(output, r#"isNull _playerObject;"#);
    }

    #[test]
    fn it_replaces_not_null() {
        let output = compile!(
            r#"!null?(objNull);"#,
            NAME_NULL_NEGATED,
            PATTERN_NULL_NEGATED,
            not_null
        );

        assert_eq!(output, r#"!(isNull objNull);"#);

        let output = compile!(
            r#"!null?(_playerObject);"#,
            NAME_NULL_NEGATED,
            PATTERN_NULL_NEGATED,
            not_null
        );

        assert_eq!(output, r#"!(isNull _playerObject);"#);
    }

    #[test]
    fn it_replaces_constants() {
        let output = compile!(
            r#"const!(EXAMPLE_STRING);"#,
            NAME_CONST,
            PATTERN_CONST,
            replace_const
        );

        assert_eq!(output, r#""Hello world!";"#);

        let output = compile!(
            r#"const!(EXAMPLE_ARRAY);"#,
            NAME_CONST,
            PATTERN_CONST,
            replace_const
        );

        assert_eq!(output, r#"[1,2,3];"#);

        let output = compile!(
            r#"const!(EXAMPLE_NUMBER);"#,
            NAME_CONST,
            PATTERN_CONST,
            replace_const
        );
        assert_eq!(output, r#"69;"#); // Nice

        let output = compile!(
            r#"const!(EXAMPLE_BOOL);"#,
            NAME_CONST,
            PATTERN_CONST,
            replace_const
        );
        assert_eq!(output, r#"false;"#)
    }

    #[test]
    fn it_replaces_current_year() {
        let output = compile!(
            r#"current_year!();"#,
            NAME_CURRENT_YEAR,
            PATTERN_CURRENT_YEAR,
            current_year
        );

        let regex = Regex::new(r"\d{4}").unwrap();
        assert!(regex.is_match(&output))
    }
}
