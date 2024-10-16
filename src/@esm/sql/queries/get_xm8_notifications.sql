SELECT
    id,
    recipient_uid,
    type,
    content,
    created_at
FROM
    xm8_notification
WHERE
WHERE
    acknowledged_at IS NULL
    AND (
        last_attempt_at IS NULL
        OR last_attempt_at < DATE_SUB(NOW(), INTERVAL 1 HOUR)
    )
    AND attempt_count < 5
ORDER BY
    created_at DESC;
