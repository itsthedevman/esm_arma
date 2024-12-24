use super::*;

pub fn send_message(
    id: String,
    message_type: String,
    data: String,
    metadata: String,
    errors: String,
) {
    if !READY.load(Ordering::SeqCst) {
        error!(
            "[send_message] ❌ This endpoint cannot be accessed before we're connected to the bot"
        );
        return;
    }

    let timer = std::time::Instant::now();
    trace!(
        "[send_message]\nid: {:?}\ntype: {:?}\ndata: {:?}\nmetadata: {:?}\nerrors: {:?}",
        id,
        message_type,
        data,
        metadata,
        errors
    );

    let message = match Message::from_arma(id, message_type, data, metadata, errors) {
        Ok(m) => m,
        Err(e) => return error!("[send_message] ❌ {}", e),
    };

    if let Err(e) = BotRequest::send(message) {
        error!("[send_message] ❌ {}", e);
    };

    debug!("[send_message] ⏲ Took {:.2?}", timer.elapsed());
}
