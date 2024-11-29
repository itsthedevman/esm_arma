SELECT
    a.uid,
    a.locker,
    a.score,
    a.name,
    a.kills,
    a.deaths,
    COALESCE(
        JSON_ARRAYAGG(JSON_OBJECT('id', t.id, 'name', t.name)),
        JSON_ARRAY()
    ) as territories
FROM
    account a
    LEFT JOIN territory t ON (
        t.deleted_at IS NULL
        AND (
            t.owner_uid = :player_uid
            OR t.build_rights LIKE :wildcard_uid
            OR t.moderators LIKE :wildcard_uid
        )
    )
WHERE
    a.uid = :player_uid
GROUP BY
    a.uid;
