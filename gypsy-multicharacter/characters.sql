-- Character System Database Schema
-- Run this in your MySQL database

CREATE TABLE IF NOT EXISTS `characters` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) UNIQUE NOT NULL,
    `license` VARCHAR(255) NOT NULL,
    `slot` INT NOT NULL DEFAULT 1,
    `charinfo` LONGTEXT DEFAULT NULL COMMENT 'JSON: firstname, lastname, birthdate, gender, nationality, appearance',
    `metadata` LONGTEXT DEFAULT NULL COMMENT 'JSON: hunger, thirst, stress, health, armor',
    `money` LONGTEXT DEFAULT NULL COMMENT 'JSON: cash, bank',
    `job` LONGTEXT DEFAULT NULL COMMENT 'JSON: name, label, grade',
    `position` LONGTEXT DEFAULT NULL COMMENT 'JSON: x, y, z, heading',
    `inventory` LONGTEXT DEFAULT NULL COMMENT 'JSON: items array',
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `license_idx` (`license`),
    INDEX `citizenid_idx` (`citizenid`),
    UNIQUE KEY `license_slot` (`license`, `slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
