-- ============================================================================
-- GYPSY FRAMEWORK - COMPLETE DATABASE SETUP
-- ============================================================================
-- Этот файл создает все необходимые таблицы для Gypsy Framework
-- Запускайте этот скрипт после каждого пересоздания Docker контейнера
-- ============================================================================

-- Создание базы данных (если не существует)
CREATE DATABASE IF NOT EXISTS `qbcore` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `qbcore`;

-- ============================================================================
-- ОСНОВНАЯ ТАБЛИЦА ИГРОКОВ
-- ============================================================================
CREATE TABLE IF NOT EXISTS `players` (
  `citizenid` varchar(50) NOT NULL,
  `license` varchar(50) NOT NULL,
  `name` varchar(50) DEFAULT NULL,
  `money` text DEFAULT NULL,
  `charinfo` text DEFAULT NULL,
  `job` text DEFAULT NULL,
  `gang` text DEFAULT NULL,
  `position` text DEFAULT NULL,
  `metadata` text DEFAULT NULL,
  `inventory` longtext DEFAULT NULL,
  `last_login` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`),
  KEY `license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ТАБЛИЦА ТРАНСПОРТА
-- ============================================================================
CREATE TABLE IF NOT EXISTS `gypsy_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `vehicle` varchar(50) NOT NULL,
  `plate` varchar(15) NOT NULL,
  `garage` varchar(50) DEFAULT 'pillboxgarage',
  `state` int(11) DEFAULT 0,
  `fuel` int(11) DEFAULT 100,
  `engine` float DEFAULT 1000,
  `body` float DEFAULT 1000,
  `mods` longtext DEFAULT NULL,
  `impound_fee` int(11) DEFAULT 0,
  `impounded_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Обновление для существующих таблиц (если поля отсутствуют)
-- CALL: ALTER TABLE `gypsy_vehicles` ADD COLUMN IF NOT EXISTS `impound_fee` int(11) DEFAULT 0;
-- CALL: ALTER TABLE `gypsy_vehicles` ADD COLUMN IF NOT EXISTS `impounded_at` timestamp NULL DEFAULT NULL;

-- ============================================================================
-- ТАБЛИЦА ИНВЕНТАРЯ
-- ============================================================================
CREATE TABLE IF NOT EXISTS `gypsy_inventory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `items` longtext DEFAULT NULL,
  `maxweight` int(11) DEFAULT 100000,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ГОТОВО!
-- ============================================================================
-- Все таблицы созданы успешно
-- Теперь можно запускать FiveM сервер
