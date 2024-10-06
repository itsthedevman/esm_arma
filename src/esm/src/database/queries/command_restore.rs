use super::*;

pub async fn command_restore(
    context: &Database,
    connection: &mut Conn,
    arguments: &HashMap<String, String>,
) -> DatabaseResult {
    let Some(territory_id) = arguments.get("territory_id") else {
        error!("[command_restore] ❌ Missing key `territory_id` in provided query arguments");
        return Err("error".into());
    };

    // This handles both hashed IDs or custom IDs
    let territory_id = queries::decode_territory_id(context, connection, territory_id).await?;

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
) -> Result<(), Error> {
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
        Err(e) => {
            error!("[command_restore] ❌ Query failed - {}", e);
            Err("error".into())
        }
    }
}
