use super::*;
use queries::check_if_account_exists::Arguments as AccountArguments;

use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct Arguments {
    #[serde(rename = "type")]
    pub reward_type: String,

    pub uid: String,
    pub classname: Option<String>,
    pub amount: u64,
    pub source: String,
    pub expires_at: Option<DateTime<Utc>>,
}

impl FromArguments for Arguments {}

pub async fn add_reward(
    context: &Database,
    connection: &mut Conn,
    arguments: Arguments,
) -> QueryResult {
    if !queries::check_if_account_exists(
        context,
        connection,
        AccountArguments {
            player_uid: arguments.uid.to_owned(),
        },
    )
    .await?
    {
        return Err(QueryError::Code("target_account_does_not_exist".into()));
    }

    let result = connection
        .exec_drop(
            &context.sql.add_reward,
            params! {
                "public_id" => &Uuid::new_v4().to_string()[28..],
                "account_uid" => arguments.uid,
                "reward_type" => arguments.reward_type,
                "classname" => arguments.classname,
                "amount" => arguments.amount,
                "source" => arguments.source,
                "expires_at" => arguments.expires_at.map(|v| v.naive_utc()),
            },
        )
        .await;

    match result {
        Ok(_) => Ok(vec![]),
        Err(e) => Err(QueryError::System(e.to_string())),
    }
}
