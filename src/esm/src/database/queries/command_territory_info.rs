use super::*;

#[derive(Debug, Deserialize)]
pub struct Arguments {
    pub territory_id: String,
}

impl FromArguments for Arguments {}

pub async fn command_territory_info(
    context: &Database,
    connection: &mut Conn,
    arguments: Arguments,
) -> QueryResult {
    let territory_id =
        queries::decode_territory_id(context, connection, &arguments.territory_id)
            .await?;

    let result = connection
        .exec_map(
            &context.sql.command_territory_info,
            params! { territory_id },
            map_territory_results,
        )
        .await;

    match result {
        Ok(territories) => {
            if territories.is_empty() {
                return Ok(vec![]);
            }

            let errors = territories
                .iter()
                .filter_map(|result| result.as_ref().err())
                .map(|err| err.to_string())
                .collect::<Vec<String>>()
                .join(", ");

            if !errors.is_empty() {
                return Err(QueryError::System(format!(
                    "Query failed - {}",
                    errors
                )));
            }

            let territories: Vec<Territory> =
                territories.into_iter().filter_map(Result::ok).collect();

            let territories: Vec<String> =
                update_id_and_names(context, connection, territories)
                    .await?
                    .into_iter()
                    .filter_map(|t| serde_json::to_string(&t).ok())
                    .collect();

            Ok(territories)
        }
        Err(e) => Err(QueryError::System(format!("Query failed - {}", e))),
    }
}
