SELECT
    CASE
        WHEN EXISTS (
            SELECT
                id
            FROM
                account
            WHERE
                uid = :account_uid
        ) THEN 'true'
        ELSE 'false'
    END
