-- --------------------------------------------------------

-- Host:                         127.0.0.1

-- Server version:               5.6.26-log - MySQL Community Server (GPL)

-- Server OS:                    Win64

-- HeidiSQL Version:             9.2.0.4970

-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */

;

/*!40101 SET NAMES utf8mb4 */

;

/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */

;

/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */

;

-- Dumping database structure for exile

CREATE DATABASE
    IF NOT EXISTS `exile_esm`
    /*!40100 DEFAULT CHARACTER SET utf8mb4 */
;

USE `exile_esm`;

-- Dumping structure for table exile.account

CREATE TABLE
    IF NOT EXISTS `account` (
        `uid` varchar(32) NOT NULL,
        `clan_id` int(11) unsigned DEFAULT NULL,
        `name` varchar(64) NOT NULL,
        `score` int(11) NOT NULL DEFAULT '0',
        `kills` int(11) unsigned NOT NULL DEFAULT '0',
        `deaths` int(11) unsigned NOT NULL DEFAULT '0',
        `locker` int(11) NOT NULL DEFAULT '0',
        `first_connect_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `last_connect_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `last_disconnect_at` datetime DEFAULT NULL,
        `total_connections` int(11) unsigned NOT NULL DEFAULT '1',
        PRIMARY KEY (`uid`),
        KEY `clan_id` (`clan_id`),
        CONSTRAINT `account_ibfk_1` FOREIGN KEY (`clan_id`) REFERENCES `clan` (`id`) ON DELETE
        SET
            NULL
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Data exporting was unselected.

-- Dumping structure for table exile.clan

CREATE TABLE
    IF NOT EXISTS `clan` (
        `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `name` varchar(64) NOT NULL,
        `leader_uid` varchar(32) NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `leader_uid` (`leader_uid`),
        CONSTRAINT `clan_ibfk_1` FOREIGN KEY (`leader_uid`) REFERENCES `account` (`uid`) ON DELETE CASCADE
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Data exporting was unselected.

-- Dumping structure for table exile.clan_map_marker

CREATE TABLE
    IF NOT EXISTS `clan_map_marker` (
        `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `clan_id` int(11) unsigned NOT NULL,
        `markerType` tinyint(4) NOT NULL DEFAULT '-1',
        `positionArr` text NOT NULL,
        `color` varchar(255) NOT NULL,
        `icon` varchar(255) NOT NULL,
        `iconSize` float unsigned NOT NULL,
        `label` varchar(255) NOT NULL,
        `labelSize` float unsigned NOT NULL,
        PRIMARY KEY (`id`),
        KEY `clan_id` (`clan_id`),
        CONSTRAINT `clan_map_marker_ibfk_1` FOREIGN KEY (`clan_id`) REFERENCES `clan` (`id`) ON DELETE CASCADE
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Data exporting was unselected.

-- Dumping structure for table exile.construction

CREATE TABLE
    IF NOT EXISTS `construction` (
        `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `class` varchar(64) NOT NULL,
        `account_uid` varchar(32) NOT NULL,
        `spawned_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `position_x` double NOT NULL DEFAULT '0',
        `position_y` double NOT NULL DEFAULT '0',
        `position_z` double NOT NULL DEFAULT '0',
        `direction_x` double NOT NULL DEFAULT '0',
        `direction_y` double NOT NULL DEFAULT '0',
        `direction_z` double NOT NULL DEFAULT '0',
        `up_x` double NOT NULL DEFAULT '0',
        `up_y` double NOT NULL DEFAULT '0',
        `up_z` double NOT NULL DEFAULT '0',
        `is_locked` tinyint(1) NOT NULL DEFAULT '0',
        `pin_code` varchar(6) NOT NULL DEFAULT '000000',
        `damage` tinyint(1) unsigned NULL DEFAULT '0',
        `territory_id` int(11) unsigned DEFAULT NULL,
        `last_updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime DEFAULT NULL,
        PRIMARY KEY (`id`),
        KEY `account_uid` (`account_uid`),
        KEY `territory_id` (`territory_id`),
        CONSTRAINT `construction_ibfk_1` FOREIGN KEY (`account_uid`) REFERENCES `account` (`uid`) ON DELETE CASCADE,
        CONSTRAINT `construction_ibfk_2` FOREIGN KEY (`territory_id`) REFERENCES `territory` (`id`) ON DELETE CASCADE
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Data exporting was unselected.

-- Dumping structure for table exile.container

CREATE TABLE
    IF NOT EXISTS `container` (
        `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `class` varchar(64) NOT NULL,
        `spawned_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `account_uid` varchar(32) DEFAULT NULL,
        `is_locked` tinyint(1) NOT NULL DEFAULT '0',
        `position_x` double NOT NULL DEFAULT '0',
        `position_y` double NOT NULL DEFAULT '0',
        `position_z` double NOT NULL DEFAULT '0',
        `direction_x` double NOT NULL DEFAULT '0',
        `direction_y` double NOT NULL DEFAULT '0',
        `direction_z` double NOT NULL DEFAULT '0',
        `up_x` double NOT NULL DEFAULT '0',
        `up_y` double NOT NULL DEFAULT '0',
        `up_z` double NOT NULL DEFAULT '1',
        `cargo_items` text NOT NULL,
        `cargo_magazines` text NOT NULL,
        `cargo_weapons` text NOT NULL,
        `cargo_container` text NOT NULL,
        `last_updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `pin_code` varchar(6) NOT NULL DEFAULT '000000',
        `territory_id` int(11) unsigned DEFAULT NULL,
        `deleted_at` datetime DEFAULT NULL,
        `money` int(11) unsigned NOT NULL DEFAULT '0',
        `abandoned` datetime DEFAULT NULL,
        PRIMARY KEY (`id`),
        KEY `account_uid` (`account_uid`),
        KEY `territory_id` (`territory_id`),
        CONSTRAINT `container_ibfk_1` FOREIGN KEY (`account_uid`) REFERENCES `account` (`uid`) ON DELETE CASCADE,
        CONSTRAINT `container_ibfk_2` FOREIGN KEY (`territory_id`) REFERENCES `territory` (`id`) ON DELETE CASCADE
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 ROW_FORMAT = COMPACT;

-- Data exporting was unselected.

-- Dumping structure for table exile.player

CREATE TABLE
    IF NOT EXISTS `player` (
        `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `name` varchar(64) NOT NULL,
        `account_uid` varchar(32) NOT NULL,
        `money` int(11) unsigned NOT NULL DEFAULT '0',
        `damage` double unsigned NOT NULL DEFAULT '0',
        `hunger` double unsigned NOT NULL DEFAULT '100',
        `thirst` double unsigned NOT NULL DEFAULT '100',
        `alcohol` double unsigned NOT NULL DEFAULT '0',
        `temperature` double NOT NULL DEFAULT '37',
        `wetness` double unsigned NOT NULL DEFAULT '0',
        `oxygen_remaining` double unsigned NOT NULL DEFAULT '1',
        `bleeding_remaining` double unsigned NOT NULL DEFAULT '0',
        `hitpoints` varchar(1024) NOT NULL DEFAULT '[]',
        `direction` double NOT NULL DEFAULT '0',
        `position_x` double NOT NULL DEFAULT '0',
        `position_y` double NOT NULL DEFAULT '0',
        `position_z` double NOT NULL DEFAULT '0',
        `spawned_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `assigned_items` text NOT NULL,
        `backpack` varchar(64) NOT NULL,
        `backpack_items` text NOT NULL,
        `backpack_magazines` text NOT NULL,
        `backpack_weapons` text NOT NULL,
        `current_weapon` varchar(64) NOT NULL,
        `goggles` varchar(64) NOT NULL,
        `handgun_items` text NOT NULL,
        `handgun_weapon` varchar(64) NOT NULL,
        `headgear` varchar(64) NOT NULL,
        `binocular` varchar(64) NOT NULL,
        `loaded_magazines` text NOT NULL,
        `primary_weapon` varchar(64) NOT NULL,
        `primary_weapon_items` text NOT NULL,
        `secondary_weapon` varchar(64) NOT NULL,
        `secondary_weapon_items` text NOT NULL,
        `uniform` varchar(64) NOT NULL,
        `uniform_items` text NOT NULL,
        `uniform_magazines` text NOT NULL,
        `uniform_weapons` text NOT NULL,
        `vest` varchar(64) NOT NULL,
        `vest_items` text NOT NULL,
        `vest_magazines` text NOT NULL,
        `vest_weapons` text NOT NULL,
        `last_updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `player_uid` (`account_uid`),
        CONSTRAINT `player_ibfk_1` FOREIGN KEY (`account_uid`) REFERENCES `account` (`uid`) ON DELETE CASCADE
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Data exporting was unselected.

-- Dumping structure for table exile.player_history

CREATE TABLE
    IF NOT EXISTS `player_history` (
        `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `account_uid` varchar(32) NOT NULL,
        `name` varchar(64) NOT NULL,
        `died_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `position_x` double NOT NULL,
        `position_y` double NOT NULL,
        `position_z` double NOT NULL,
        PRIMARY KEY (`id`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Data exporting was unselected.

-- Dumping structure for table exile.territory

CREATE TABLE
    IF NOT EXISTS `territory` (
        `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `owner_uid` varchar(32) NOT NULL,
        `name` varchar(64) NOT NULL,
        `position_x` double NOT NULL,
        `position_y` double NOT NULL,
        `position_z` double NOT NULL,
        `radius` double NOT NULL,
        `level` int(11) NOT NULL,
        `flag_texture` varchar(255) NOT NULL,
        `flag_stolen` tinyint(1) NOT NULL DEFAULT '0',
        `flag_stolen_by_uid` varchar(32) DEFAULT NULL,
        `flag_stolen_at` datetime DEFAULT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `last_paid_at` datetime DEFAULT CURRENT_TIMESTAMP,
        `xm8_protectionmoney_notified` tinyint(1) NOT NULL DEFAULT '0',
        `build_rights` varchar(4000) NOT NULL DEFAULT '[]',
        `moderators` varchar(4000) NOT NULL DEFAULT '[]',
        `deleted_at` datetime DEFAULT NULL,
        PRIMARY KEY (`id`),
        KEY `owner_uid` (`owner_uid`),
        KEY `flag_stolen_by_uid` (`flag_stolen_by_uid`),
        CONSTRAINT `territory_ibfk_1` FOREIGN KEY (`owner_uid`) REFERENCES `account` (`uid`) ON DELETE CASCADE,
        CONSTRAINT `territory_ibfk_2` FOREIGN KEY (`flag_stolen_by_uid`) REFERENCES `account` (`uid`) ON DELETE
        SET
            NULL
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Data exporting was unselected.

-- Dumping structure for table exile.vehicle

CREATE TABLE
    IF NOT EXISTS `vehicle` (
        `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `class` varchar(64) NOT NULL,
        `spawned_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `account_uid` varchar(32) DEFAULT NULL,
        `is_locked` tinyint(1) NOT NULL DEFAULT '0',
        `fuel` double unsigned NOT NULL DEFAULT '0',
        `damage` double unsigned NOT NULL DEFAULT '0',
        `hitpoints` text NOT NULL,
        `position_x` double NOT NULL DEFAULT '0',
        `position_y` double NOT NULL DEFAULT '0',
        `position_z` double NOT NULL DEFAULT '0',
        `direction_x` double NOT NULL DEFAULT '0',
        `direction_y` double NOT NULL DEFAULT '0',
        `direction_z` double NOT NULL DEFAULT '0',
        `up_x` double NOT NULL DEFAULT '0',
        `up_y` double NOT NULL DEFAULT '0',
        `up_z` double NOT NULL DEFAULT '1',
        `cargo_items` text NOT NULL,
        `cargo_magazines` text NOT NULL,
        `cargo_weapons` text NOT NULL,
        `cargo_container` text NOT NULL,
        `last_updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `pin_code` varchar(6) NOT NULL DEFAULT '000000',
        `deleted_at` datetime DEFAULT NULL,
        `money` int(11) unsigned NOT NULL DEFAULT '0',
        `vehicle_texture` text NOT NULL,
        `territory_id` int(11) unsigned DEFAULT NULL,
        `nickname` varchar(64) NOT NULL DEFAULT '',
        PRIMARY KEY (`id`),
        KEY `account_uid` (`account_uid`),
        KEY `vehicle_ibfk_2_idx` (`territory_id`),
        CONSTRAINT `vehicle_ibfk_1` FOREIGN KEY (`account_uid`) REFERENCES `account` (`uid`) ON DELETE CASCADE,
        CONSTRAINT `vehicle_ibfk_2` FOREIGN KEY (`territory_id`) REFERENCES `territory` (`id`) ON DELETE CASCADE
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Data exporting was unselected.

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */

;

/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */

;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */

;
