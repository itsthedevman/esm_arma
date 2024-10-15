use super::*;

pub async fn enqueue_xm8_notifications(
    context: &Database,
    connection: &mut Conn,
    notification_type: String,
    recipient_uids: String,
    content: String,
) -> Result<(), Error> {
    let recipient_uids: Vec<String> = match serde_json::from_str(&recipient_uids) {
        Ok(u) => u,
        Err(e) => return Err(e.to_string().into()),
    };

    // Execute the query
    let result = connection
        .exec_batch(
            &context.sql.xm8_enqueue_notifications,
            recipient_uids.iter().map(|uid| {
                params! {
                    "uid" => &uid,
                    "type" => &notification_type,
                    "content" => &content,
                }
            }),
        )
        .await;

    match result {
        Ok(_) => Ok(()),
        Err(e) => Err(e.to_string().into()),
    }
}
