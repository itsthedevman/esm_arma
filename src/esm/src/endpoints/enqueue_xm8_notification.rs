use super::*;

pub fn enqueue_xm8_notification(
    notification_type: String,
    recipient_uids: String,
    content: String,
) -> Result<(), String> {
    let timer = std::time::Instant::now();

    trace!(
        "[enqueue_xm8_notification] notification_type: {:?} - recipient_uids: {:?} - content: {:?}",
        notification_type,
        recipient_uids,
        content
    );

    let result = TOKIO_RUNTIME.block_on(async {
        DATABASE
            .enqueue_xm8_notification(notification_type, recipient_uids, content)
            .await
            .map_err(|e| e.error_content)
    });

    debug!("[enqueue_xm8_notification] ⏲ Took {:.2?}", timer.elapsed());

    result
}
