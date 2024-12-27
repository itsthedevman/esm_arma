use super::*;

#[derive(Debug, Serialize)]
struct TerritoryResult {
    id: String,
    esm_custom_id: Option<String>,
    territory_name: String,
    owner_uid: String,
    owner_name: String,
}

#[derive(Debug, Deserialize)]
pub struct Arguments {}
impl FromArguments for Arguments {}

pub async fn command_all_territories(
    context: &Database,
    connection: &mut Conn,
    _arguments: Arguments,
) -> QueryResult {
    let result = connection
        .exec_map(
            &context.sql.command_all_territories,
            Params::Empty,
            |(id, esm_custom_id, territory_name, owner_uid, owner_name)| {
                let id: String = id;
                TerritoryResult {
                    id: context.encode_territory_id(&id),
                    esm_custom_id,
                    territory_name,
                    owner_uid,
                    owner_name,
                }
            },
        )
        .await;

    match result {
        Ok(r) => {
            let results: Vec<String> = r
                .into_iter()
                .filter_map(|t| serde_json::to_string(&t).ok())
                .collect();

            Ok(results)
        }
        Err(e) => Err(QueryError::System(format!("Query failed - {}", e))),
    }
}
