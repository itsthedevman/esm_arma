use super::*;

#[derive(Debug, Deserialize)]
pub struct Arguments {
    pub territory_id: String,
}

impl FromArguments for Arguments {}

pub async fn command_restore(
    context: &Database,
    connection: &mut Conn,
    arguments: Arguments,
) -> QueryResult {
    // This handles both hashed IDs or custom IDs
    let territory_id =
        queries::decode_territory_id(context, connection, &arguments.territory_id)
            .await?;

    // Three separate SQL queries
    // The driver doesn't support preparing and executing a multi-command statement
    execute_statement(
        connection,
        &context.sql.command_restore_territory,
        territory_id,
    )
    .await?;

    execute_statement(
        connection,
        &context.sql.command_restore_construction,
        territory_id,
    )
    .await?;

    execute_statement(
        connection,
        &context.sql.command_restore_container,
        territory_id,
    )
    .await?;

    Ok(vec![])
}

async fn execute_statement(
    connection: &mut Conn,
    statement: &str,
    territory_id: u64,
) -> Result<(), QueryError> {
    let result = connection
        .exec_drop(
            statement,
            params! {
                "territory_id" => territory_id
            },
        )
        .await;

    match result {
        Ok(_) => Ok(()),
        Err(e) => Err(QueryError::System(format!("Query failed - {}", e))),
    }
}
