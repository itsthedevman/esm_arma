use super::*;

#[derive(Debug, Deserialize)]
pub struct Arguments {
    #[serde(rename = "uid")]
    pub player_uid: String,
}

impl FromArguments for Arguments {}

pub async fn command_reset_player(
    context: &Database,
    connection: &mut Conn,
    arguments: Arguments,
) -> QueryResult {
    let result = connection
        .exec_drop(
            &context.sql.command_reset_player,
            params! { "uid" => arguments.player_uid },
        )
        .await;

    match result {
        Ok(_) => Ok(vec![]),
        Err(e) => Err(QueryError::System(format!("Query failed - {}", e))),
    }
}
