use super::*;

#[derive(Debug, Serialize)]
struct Territory {
    pub id: String,
    pub custom_id: Option<String>,
    pub name: String,
    pub level: isize,
    pub vehicle_count: isize,
}

pub async fn command_reward_territories(
    context: &Database,
    connection: &mut Conn,
    arguments: &HashMap<String, String>,
) -> QueryResult {
    let player_uid = arguments.get("uid").ok_or(QueryError::User(
        "Missing key `uid` in provided query arguments".into(),
    ))?;

    let territories = connection
        .exec_map(
            &context.sql.command_reward_territories,
            params! { "player_uid" => player_uid, "wildcard_uid" => format!("%{}%", player_uid) },
            |row| map_results(row, context)
        )
        .await
        .map_err(|e| QueryError::User(e.to_string()))?
        .into_iter()
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| QueryError::System(format!("Query failed - {}", e)))?;

    let territories = territories
        .into_iter()
        .filter_map(|t| serde_json::to_string(&t).ok())
        .collect::<Vec<String>>();

    Ok(territories)
}

fn map_results(mut row: Row, context: &Database) -> Result<Territory, Error> {
    let id: isize = select_column(&mut row, "id")?;

    Ok(Territory {
        id: context.encode_territory_id(&id.to_string()),
        custom_id: select_column(&mut row, "custom_id")?,
        name: select_column(&mut row, "name")?,
        level: select_column(&mut row, "level")?,
        vehicle_count: select_column(&mut row, "vehicle_count")?,
    })
}
