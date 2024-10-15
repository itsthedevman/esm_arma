-- Adds `esm_custom_id` to territory. This field is used for storing the custom ID set by the `set_id` command
ALTER TABLE territory
ADD COLUMN `esm_custom_id` VARCHAR(100) NULL AFTER `id`,
ADD UNIQUE INDEX `esm_custom_id_UNIQUE` (`esm_custom_id` ASC);

-- Adds `esm_payment_counter` to territory. This field is used to track how many times a territory has been paid for by using ESM
ALTER TABLE territory
ADD COLUMN `esm_payment_counter` INT(11) UNSIGNED NOT NULL DEFAULT '0' AFTER `moderators`;

-- Adds `xm8_notification` table. This table stores all outbound XM8 notifications
CREATE TABLE xm8_notification (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    recipient_uid VARCHAR(32) NOT NULL,
    type VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    attempt_count INT DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_attempt_at DATETIME,
    acknowledged_at DATETIME,
    INDEX idx_recipient_uid (recipient_uid),
    INDEX idx_last_attempt_acknowledged (last_attempt_at, acknowledged_at, attempt_count),
    CONSTRAINT fk_recipient_account FOREIGN KEY (recipient_uid) REFERENCES account (uid) ON DELETE CASCADE
) DEFAULT CHARSET = utf8mb4;
