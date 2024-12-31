INSERT INTO
    reward (
        public_id,
        account_uid,
        reward_type,
        classname,
        total_quantity,
        remaining_quantity,
        source,
        expires_at
    )
VALUES
    (
        :public_id,
        :account_uid,
        :reward_type,
        :classname,
        :quantity,
        :quantity,
        :source,
        :expires_at
    );
