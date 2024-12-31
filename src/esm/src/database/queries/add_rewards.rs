use super::*;
use queries::check_if_account_exists::Arguments as AccountArguments;

use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct Arguments {
    pub uid: String,
    pub items: Vec<RewardItem>,
}

impl FromArguments for Arguments {}

#[derive(Debug, Deserialize)]
pub struct RewardItem {
    #[serde(rename = "type")]
    pub reward_type: String,

    pub classname: Option<String>,
    pub quantity: u64,
    pub source: String,
    pub expires_at: Option<DateTime<Utc>>,
}

pub async fn add_rewards(
    context: &Database,
    connection: &mut Conn,
    arguments: Arguments,
) -> QueryResult {
    let player_uid = &arguments.uid;

    if !queries::check_if_account_exists(
        context,
        connection,
        AccountArguments {
            player_uid: player_uid.to_owned(),
        },
    )
    .await?
    {
        return Err(QueryError::Code("target_account_does_not_exist".into()));
    }

    let result = connection
        .exec_batch(
            &context.sql.add_reward,
            arguments.items.into_iter().map(|item| {
                params! {
                    "public_id" => &Uuid::new_v4().to_string()[28..],
                    "account_uid" => &player_uid,
                    "reward_type" => item.reward_type,
                    "classname" => item.classname,
                    "quantity" => item.quantity,
                    "source" => item.source,
                    "expires_at" => item.expires_at.map(|v| v.naive_utc()),
                }
            }),
        )
        .await;

    match result {
        Ok(_) => Ok(vec![]),
        Err(e) => Err(QueryError::System(e.to_string())),
    }
}
