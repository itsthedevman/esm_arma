use serde::de::DeserializeOwned;
use serde_json::Value as JSONValue;
use unicode_segmentation::UnicodeSegmentation;

pub struct Parser {}

impl Parser {
    pub fn from_arma<T: DeserializeOwned>(input: &str) -> Result<T, String> {
        let input = replace_arma_characters(input);

        let input: JSONValue = match serde_json::from_str(&input) {
            Ok(v) => v,
            Err(e) => {
                return Err(format!(
                    "[esm_message::parser::from_arma] Failed to convert input into JSON. Reason: {e}. Input: {input}"
                ))
            }
        };

        let json = validate_content(&input);
        let json = match serde_json::to_string(&json) {
            Ok(j) => j,
            Err(e) => return Err(format!("[esm_message::parser::from_arma] Failed to convert to final JSON. Reason: {e}. Input: \"{input}\"")),
        };

        let output: T = match serde_json::from_str(&json) {
            Ok(t) => t,
            Err(e) => return Err(format!("[esm_message::parser::from_arma] Failed to convert to Data/Metadata. Reason: {e}. Input: \"{input}\" ")),
        };

        Ok(output)
    }
}

pub fn validate_content(input: &JSONValue) -> JSONValue {
    match input {
        JSONValue::Array(a) => {
            if a.is_empty() {
                JSONValue::Array(vec![])
            } else {
                match convert_arma_array_to_object(a) {
                    Ok(v) => v,
                    Err(_) => input.to_owned(),
                }
            }
        }
        _ => input.to_owned(),
    }
}

fn convert_arma_array_to_object(input: &Vec<JSONValue>) -> Result<JSONValue, String> {
    if !input
        .iter()
        .all(|i| i.is_array() && i.as_array().unwrap().len() == 2)
    {
        return Err(format!("[esm_message::parser::convert_arma_array_to_object] Input must consist of key/value pairs. Input: {input:?}"));
    }

    let mut object = serde_json::map::Map::new();
    for pair in input {
        let pair = match pair.as_array() {
            Some(a) => a,
            None => return Err(format!("[esm_message::parser::convert_arma_array_to_object] Failed to convert key/value pair. Pair: {pair:?}")),
        };

        let key = match pair.get(0) {
            Some(k) => match k.as_str() {
                Some(k) => k,
                None => return Err(format!("[esm_message::parser::convert_arma_array_to_object] Failed to convert key to string. Pair: {pair:?}"))
            },
            None => return Err(format!("[esm_message::parser::convert_arma_array_to_object] Failed to extract key from {pair:?}"))
        };

        let value = match pair.get(1) {
            Some(v) => v,
            None => return Err(format!("[esm_message::parser::convert_arma_array_to_object] Failed to extract value from {pair:?}"))
        };

        object.insert(key.to_string(), validate_content(value));
    }

    Ok(JSONValue::Object(object))
}

// Handles Arma's double quote escape characters and its various nil types
fn replace_arma_characters(input: &str) -> String {
    let str_terminators = ["[", "]", ",", ""];
    let mut new_string_chars: Vec<String> = Vec::new();
    let mut in_string = false;
    let mut quote_series_counter = 1_usize;

    let chars = input.graphemes(true).collect::<Vec<&str>>();
    for (index, current_char) in chars.iter().enumerate() {
        // This skips over the extra quotes in a series
        if quote_series_counter.saturating_sub(1) > 0 {
            quote_series_counter = quote_series_counter.saturating_sub(1);
            continue;
        };

        let mut char_to_add = current_char.to_string();
        let previous_char = chars.get(index.saturating_sub(1)).unwrap_or(&"");
        let next_char = chars.get(index.saturating_add(1)).unwrap_or(&"");

        if current_char.eq(&"\"") {
            if str_terminators.contains(previous_char) && !in_string {
                in_string = true;
            } else if str_terminators.contains(next_char) && in_string {
                in_string = false;
            } else if in_string {
                // Detect how many double quotes are in this series and replace them with escape characters
                for char in &chars[(index + 1)..] {
                    if !char.eq(&"\"") {
                        break;
                    }

                    quote_series_counter = quote_series_counter.saturating_add(1);
                }

                // There can only ever be a equal number of quotes to escape
                // This handles an ending series of quotes -> """tada"""
                if (quote_series_counter % 2) != 0 {
                    quote_series_counter = quote_series_counter.saturating_sub(1);
                }

                char_to_add = format!("{}\"", "\\".repeat(quote_series_counter.saturating_sub(1)));
            }
        }

        // Handles escaping the escape characters
        if current_char.eq(&"\\") && !next_char.eq(&"\\") {
            char_to_add = "\\\\".into();
        }

        new_string_chars.push(char_to_add);

        // Replaces `any`, `null`, and `<null>` that are not inside a string
        // Replacement occurs when the last char is detected
        if !in_string {
            let allowed_prefix_chars = ["", " ", ",", "["];
            let allowed_suffix_chars = ["]", "", " "];
            let index = new_string_chars.len().saturating_sub(1);

            let detect_and_replace_word = |word: &str, chars: &mut Vec<String>| {
                let word_size = word.len() - 1;
                let starting_index = index.saturating_sub(word_size);
                let slice = &chars[starting_index..=index].join("");
                let previous_char = &chars[starting_index.saturating_sub(1)];

                if slice.eq(&word)
                    && allowed_prefix_chars.contains(&previous_char.as_str())
                    && allowed_suffix_chars.contains(next_char)
                {
                    for _ in 0..=word_size {
                        chars.pop();
                    }

                    for c in "null".chars().map(String::from) {
                        chars.push(c);
                    }
                }
            };

            detect_and_replace_word("any", &mut new_string_chars);
            detect_and_replace_word("nil", &mut new_string_chars);
            detect_and_replace_word("<null>", &mut new_string_chars);
        }
    }

    new_string_chars.join("")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{data, Data};
    use arma_rs::IntoArma;
    use serde_json::json;

    #[test]
    fn it_converts_arma_hash_correctly() {
        let input = json!([
            json!(["key_1", "value_1"]),
            json!(["key_2", 2_i32]),
            json!(["key_3", true]),
            json!(["key_4", vec![json!(["sub_key_1", "sub_value_1"])]])
        ]);

        let result = validate_content(&input);
        assert_eq!(
            result,
            json!({
                "key_1": json!("value_1"),
                "key_2": json!(2_i32),
                "key_3": json!(true),
                "key_4": json!({ "sub_key_1": "sub_value_1" })
            })
        )
    }

    #[test]
    fn it_does_not_convert_empty_arrays() {
        let input = json!([]);
        let result = validate_content(&input);
        assert_eq!(result, input);
    }

    #[test]
    fn it_converts_to_data_struct() {
        let input = json!([
            json!(["type", "test"]),
            json!(["content", json!([json!(["foo", "bar"])])])
        ])
        .to_arma()
        .to_string();

        let result: Result<Data, String> = Parser::from_arma(&input);

        assert_eq!(
            result.unwrap(),
            Data::Test(data::Test {
                foo: "bar".to_string()
            })
        );

        let input = json!([json!(["type", "empty"])]).to_arma().to_string();

        let result: Result<Data, String> = Parser::from_arma(&input);

        assert_eq!(result.unwrap(), Data::Empty);
    }

    #[test]
    fn it_handles_escaped_strings() {
        let input = "[[\"type\",\"sqf_result\"],[\"content\",[[\"result\",\"[[\"\"key_1\"\",\"\"value_1\"\"],[\"\"key_2\"\",true],[\"\"key_3\"\",[[\"\"key_4\"\",false],[\"\"key_5\"\",[[\"\"key_6\"\",any],[\"\"key_7\"\",<null>]]]]]]\"]]]]";

        let result: Result<Data, String> = Parser::from_arma(input);

        assert_eq!(
            result.unwrap(),
            Data::SqfResult(data::SqfResult {
                result: Some("[[\"key_1\",\"value_1\"],[\"key_2\",true],[\"key_3\",[[\"key_4\",false],[\"key_5\",[[\"key_6\",any],[\"key_7\",<null>]]]]]]".to_string())
            })
        );
    }

    #[test]
    fn it_handles_null_characters() {
        let input = r#"[["type","reward"],["content",[["items",<null>],["locker_poptabs",nil],["player_poptabs",any],["respect","1"],["vehicles",[]]]]]"#;
        let result: Result<Data, String> = Parser::from_arma(input);
        assert_eq!(
            result.unwrap(),
            Data::Reward(data::Reward {
                items: None,
                locker_poptabs: None,
                player_poptabs: None,
                respect: Some("1".to_string()),
                vehicles: Some(vec![])
            })
        );
    }
}
