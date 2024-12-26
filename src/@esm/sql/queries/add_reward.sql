INSERT INTO
    reward (
        account_uid code reward_type classname amount source expires_at
    )
VALUES
    (
        :account_uid,
        :code,
        :reward_type,
        :classname,
        :amount,
        :source,
        :expires_at
    );
