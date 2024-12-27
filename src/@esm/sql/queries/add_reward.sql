INSERT INTO
    reward (
        public_id,
        account_uid,
        reward_type,
        classname,
        amount,
        source,
        expires_at
    )
VALUES
    (
        :public_id,
        :account_uid,
        :reward_type,
        :classname,
        :amount,
        :source,
        :expires_at
    );
