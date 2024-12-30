use super::*;

#[derive(Debug, Deserialize)]
pub struct Arguments {
    pub player_uid: String,
}

impl FromArguments for Arguments {}

pub async fn check_if_account_exists(
    context: &Database,
    connection: &mut Conn,
    arguments: Arguments,
) -> Result<bool, QueryError> {
    let existence_check: Option<String> = connection
        .exec_first(
            &context.sql.check_if_account_exists,
            params! {
                "account_uid" => arguments.player_uid
            },
        )
        .await
        .map_err(|e| QueryError::System(e.to_string()))?;

    match existence_check {
        Some(exists) => Ok(exists == "true"),
        None => Ok(false),
    }
}
