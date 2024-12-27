SELECT
    r.public_id as id,
    r.reward_type as "type",
    r.classname,
    r.amount,
    r.expires_at
FROM
    reward r
WHERE
    r.account_uid = :account_uid
    AND (
        r.expires_at IS NULL
        OR r.expires_at > NOW()
    )
    AND redeemed_at IS NULL
ORDER BY
    -- NULL expires_at last, then sort by closest to expiring
    expires_at IS NULL ASC,
    expires_at ASC
