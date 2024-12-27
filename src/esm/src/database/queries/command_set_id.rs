use super::*;

#[derive(Debug, Deserialize)]
pub struct Arguments {
    pub steam_uid: String,
    pub territory_id: String,
    pub new_territory_id: String,
}

impl FromArguments for Arguments {}

pub async fn command_set_id(
    context: &Database,
    connection: &mut Conn,
    arguments: Arguments,
) -> QueryResult {
    // This handles both hashed IDs or custom
    let territory_id =
        queries::decode_territory_id(context, connection, &arguments.territory_id)
            .await?;

    // Territory admins can bypass this check.
    // Otherwise, check to see if the steam_uid is the owner's
    if !arma::is_territory_admin(&arguments.steam_uid) {
        let is_owner = queries::check_if_territory_owner(
            context,
            connection,
            territory_id,
            &arguments.steam_uid,
        )
        .await?;

        if !is_owner {
            // This might seem odd but pretending the territory ID doesn't exist
            // means we're not accidentally exposing if an encoded/custom ID exists in the DB
            return Err(QueryError::Code("territory_id_does_not_exist".into()));
        }
    }

    let result = connection
        .exec_drop(
            &context.sql.command_set_id,
            params! {
                "territory_id" => territory_id,
                "custom_id" => &arguments.new_territory_id
            },
        )
        .await;

    match result {
        Ok(_) => Ok(vec![]),
        Err(e) => Err(QueryError::System(format!("Query failed - {}", e))),
    }
}
