SELECT
    CASE
        WHEN EXISTS (
            SELECT
                uid
            FROM
                account
            WHERE
                uid = :account_uid
        ) THEN 'true'
        ELSE 'false'
    END
