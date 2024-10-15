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

    let query = replace_list(
        &context.sql.xm8_enqueue_notifications,
        ":notifications",
        recipient_uids.len(),
    );

    let params: Vec<String> = recipient_uids
        .iter()
        .map(|uid| format!("({uid:?}, {notification_type:?}, {content:?})"))
        .collect();

    // Execute the query
    let result = connection.exec_drop(&query, params).await;

    match result {
        Ok(_) => Ok(()),
        Err(e) => Err(e.to_string().into()),
    }
}
