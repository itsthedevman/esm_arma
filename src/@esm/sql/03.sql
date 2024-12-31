-- Adds `reward` table.
-- This table stores the rewards that players can redeem
CREATE TABLE reward (
    id INT PRIMARY KEY AUTO_INCREMENT,
    public_id CHAR(8) NOT NULL,
    account_uid VARCHAR(32) NOT NULL,
    reward_type ENUM('poptabs', 'respect', 'classname') NOT NULL,
    classname VARCHAR(64) NULL,
    total_quantity INT NOT NULL,
    remaining_quantity INT NOT NULL,
    source VARCHAR(32) NOT NULL,
    expires_at DATETIME,
    redeemed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unq_account_public_id (account_uid, public_id),
    INDEX idx_account_active (account_uid, remaining_quantity, expires_at),
    INDEX idx_expires_at (expires_at),
    INDEX idx_source (source),
    FOREIGN KEY (account_uid) REFERENCES account (uid)
);
