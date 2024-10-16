use super::*;

#[derive(Serialize, Deserialize, Debug)]
pub struct Notification {
    id: String,
    recipient_uid: String,

    #[serde(rename = "type")]
    notification_type: String,
    
    content: String,
    created_at: NaiveDateTime,
}

impl Notification {
    fn from_tuple(tuple: (String, String, String, String, NaiveDateTime)) -> Self {
        Self {
            id: tuple.0,
            recipient_uid: tuple.1,
            notification_type: tuple.2,
            content: tuple.3,
            created_at: tuple.4,
        }
    }
}

// Limit tampering
fn query() -> &'static str {
    r#"
        SELECT
            id,
            recipient_uid,
            type,
            content,
            created_at
        FROM
            xm8_notification
        WHERE
            acknowledged_at IS NULL
            AND (
                last_attempt_at IS NULL
                OR last_attempt_at < DATE_SUB(NOW(), INTERVAL 30 SECOND)
            )
            AND attempt_count < 10
        ORDER BY
            created_at DESC
        LIMIT
            100;
    "#
}

pub async fn get_xm8_notifications(
    _context: &Database,
    connection: &mut Conn,
) -> Result<Vec<Notification>, Error> {
    connection
        .query_map(query(), |r| Notification::from_tuple(r))
        .await
        .map_err(|e| e.to_string().into())
}
