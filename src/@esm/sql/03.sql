-- Adds `reward` table.
-- This table stores the rewards that players can redeem
CREATE TABLE reward (
    id INT PRIMARY KEY AUTO_INCREMENT,
    account_uid VARCHAR(32) NOT NULL,
    code CHAR(4) NOT NULL,
    reward_type ENUM('poptabs', 'respect', 'vehicle', 'item') NOT NULL,
    classname VARCHAR(64) NULL,
    amount INT NOT NULL,
    source VARCHAR(32) NOT NULL,
    expires_at DATETIME NOT NULL,
    redeemed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unq_account_code (account_uid, code),
    INDEX idx_account_unredeemed (account_uid, redeemed_at),
    INDEX idx_expires_at (expires_at),
    INDEX idx_source (source),
    FOREIGN KEY (account_uid) REFERENCES account (uid)
);
