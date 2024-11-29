use super::*;

// territory_id
pub async fn command_territory_info(
    context: &Database,
    connection: &mut Conn,
    arguments: &HashMap<String, String>,
) -> QueryResult {
    let territory_id = arguments.get("territory_id").ok_or(QueryError::User(
        "Missing key `territory_id` in provided query arguments".into(),
    ))?;
}
