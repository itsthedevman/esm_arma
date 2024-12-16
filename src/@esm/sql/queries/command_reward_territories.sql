SELECT
    t.id,
    t.esm_custom_id as custom_id,
    t.name,
    t.level,
    COALESCE(v.vehicle_count, 0) as vehicle_count
FROM
    territory t
    LEFT JOIN (
        SELECT
            territory_id,
            COUNT(*) as vehicle_count
        FROM
            vehicle
        GROUP BY
            territory_id
    ) v ON v.territory_id = t.id
WHERE
    t.deleted_at IS NULL
    AND (
        t.owner_uid = :player_uid
        OR t.build_rights LIKE :wildcard_uid
        OR t.moderators LIKE :wildcard_uid
    )
