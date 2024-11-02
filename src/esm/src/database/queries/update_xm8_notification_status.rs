use super::*;

// Limit tampering
fn query() -> &'static str {
    r#"
    UPDATE
        xm8_notification
    SET
        status = :status,
        acknowledged_at = CURRENT_TIME()
    WHERE
        uuid = :uuid;
    "#
}

pub async fn update_xm8_notification_status(
    _context: &Database,
    connection: &mut Conn,
    status_by_uuid: &HashMap<String, String>,
) -> Result<(), Error> {
    connection
        .exec_batch(
            query(),
            status_by_uuid.iter().map(|(uuid, status)| {
                params! {
                    "uuid" => uuid,
                    "status" => status,
                }
            }),
        )
        .await
        .map_err(|e| e.to_string().into())
}
