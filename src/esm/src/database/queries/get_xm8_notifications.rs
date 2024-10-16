use super::*;

pub async fn get_xm8_notifications(
    _context: &Database,
    _connection: &mut Conn,
) -> Result<(), Error> {
    // // Execute the query
    // let result = connection
    //     .exec_batch(
    //         &context.sql.get_xm8_notifications,
    //     )
    //     .await;

    // match result {
    //     Ok(_) => Ok(()),
    //     Err(e) => Err(e.to_string().into()),
    // }
    Ok(())
}
