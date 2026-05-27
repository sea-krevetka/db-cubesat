-- =====================================================
-- Тестовые данные: Система мониторинга телеметрии CubeSat
-- =====================================================

-- 1. Спутники
INSERT INTO satellites (name, norad_id, launch_date, status) VALUES
('CubeSat-1', 40001, '2023-01-15', 'operational'),
('CubeSat-2', 40002, '2023-06-20', 'degraded'),
('CubeSat-3', 40003, '2024-02-10', 'safe_mode');

-- 2. Подсистемы
INSERT INTO subsystems (satellite_id, name) VALUES
(1, 'EPS'),
(1, 'OBC'),
(1, 'COM'),
(2, 'EPS'),
(2, 'OBC'),
(2, 'ADCS');

-- 3. Датчики
INSERT INTO sensors (subsystem_id, sensor_type, unit, min_val, max_val) VALUES
(1, 'temp', 'C', -20, 85),
(1, 'voltage', 'V', 0, 12),
(1, 'current', 'A', 0, 10),
(2, 'temp', 'C', -30, 70),
(4, 'temp', 'C', -20, 85),
(4, 'voltage', 'V', 0, 12),
(5, 'voltage', 'V', 0, 5),
(6, 'orientation', 'deg', 0, 360);

-- 4. Телеметрия
INSERT INTO telemetry (sensor_id, timestamp, value) VALUES
(1, '2025-01-10 12:00:00', 32.5),
(1, '2025-01-10 13:00:00', 33.1),
(1, '2025-01-10 14:00:00', 34.2),
(1, '2025-01-10 15:00:00', 35.0),
(2, '2025-01-10 12:00:00', 11.8),
(2, '2025-01-10 13:00:00', 11.7),
(2, '2025-01-10 14:00:00', 11.6),
(2, '2025-01-10 15:00:00', 11.5),
(3, '2025-01-10 12:00:00', 2.3),
(3, '2025-01-10 13:00:00', 2.5),
(3, '2025-01-10 14:00:00', 2.4),
(3, '2025-01-10 15:00:00', 2.6),
(4, '2025-01-10 12:00:00', 42.0),
(4, '2025-01-10 13:00:00', 42.5),
(4, '2025-01-10 14:00:00', 43.1),
(4, '2025-01-10 15:00:00', 43.8),
(5, '2025-01-10 12:00:00', 55.0),
(5, '2025-01-10 13:00:00', 56.2),
(5, '2025-01-10 14:00:00', 57.1),
(5, '2025-01-10 15:00:00', 58.5),
(6, '2025-01-10 12:00:00', 10.2),
(6, '2025-01-10 13:00:00', 10.0),
(6, '2025-01-10 14:00:00', 9.8),
(6, '2025-01-10 15:00:00', 9.7),
(7, '2025-01-10 12:00:00', 3.3),
(7, '2025-01-10 13:00:00', 3.2),
(7, '2025-01-10 14:00:00', 3.1),
(7, '2025-01-10 15:00:00', 3.0),
(8, '2025-01-10 12:00:00', 45.0),
(8, '2025-01-10 13:00:00', 47.5);

-- 5. Наземные станции
INSERT INTO ground_stations (name, latitude, longitude, elevation_meters) VALUES
('Moscow', 55.7558, 37.6173, 150),
('Krasnoyarsk', 56.0153, 92.8932, 250),
('Vladivostok', 43.1155, 131.8855, 50);

-- 6. Окна видимости
INSERT INTO visibility_windows (satellite_id, station_id, start_time, end_time, max_elevation_deg) VALUES
(1, 1, '2025-01-10 12:30:00', '2025-01-10 12:45:00', 45.0),
(1, 1, '2025-01-10 14:00:00', '2025-01-10 14:15:00', 50.0),
(1, 2, '2025-01-10 16:00:00', '2025-01-10 16:20:00', 35.0),
(2, 1, '2025-01-10 13:00:00', '2025-01-10 13:30:00', 60.0),
(2, 3, '2025-01-10 22:00:00', '2025-01-10 22:15:00', 25.0),
(3, 2, '2025-01-11 01:00:00', '2025-01-11 01:30:00', 40.0);

-- 7. Плановые сеансы
INSERT INTO planned_passes (window_id, operator_name, priority, status) VALUES
(1, 'Ivanov', 2, 'completed'),
(2, 'Petrov', 3, 'planned'),
(3, 'Sidorov', 1, 'planned'),
(4, 'Ivanov', 5, 'completed'),
(5, 'Petrov', 2, 'cancelled'),
(6, 'Kuznetsov', 4, 'planned');

-- 8. Фактические сеансы
INSERT INTO actual_passes (planned_pass_id, actual_start, actual_end, data_volume_mb) VALUES
(1, '2025-01-10 12:31:00', '2025-01-10 12:44:00', 125.5),
(4, '2025-01-10 13:02:00', '2025-01-10 13:28:00', 89.3),
(2, '2025-01-10 14:00:00', '2025-01-10 14:15:00', 250.0);

-- 9. Команды
INSERT INTO commands (satellite_id, command_code, description, is_critical) VALUES
(1, 'REBOOT_OBC', 'Reboot onboard computer', true),
(1, 'DOWNLOAD_LOG', 'Download system log', false),
(1, 'DEPLOY_ANTENNA', 'Deploy communication antenna', true),
(2, 'RESET_EPS', 'Reset power supply system', true),
(2, 'TAKE_PHOTO', 'Capture Earth image', false),
(3, 'SAFE_MODE_EXIT', 'Exit safe mode and recover', true);

-- 10. Журнал команд
INSERT INTO command_log (command_id, planned_pass_id, sent_at, acked_at, status) VALUES
(1, 1, '2025-01-10 12:32:00', '2025-01-10 12:32:05', 'acked'),
(2, 1, '2025-01-10 12:33:00', '2025-01-10 12:33:12', 'acked'),
(4, 4, '2025-01-10 13:10:00', '2025-01-10 13:10:08', 'acked'),
(5, 4, '2025-01-10 13:15:00', NULL, 'sent'),
(3, 2, '2025-01-10 14:05:00', '2025-01-10 14:05:20', 'acked'),
(6, 6, '2025-01-11 01:10:00', NULL, 'sent');

-- 11. Аномалии
INSERT INTO anomalies (satellite_id, timestamp, severity, description, resolved) VALUES
(2, '2025-01-09 08:00:00', 'high', 'Overvoltage on EPS bus', false),
(3, '2025-01-08 22:00:00', 'critical', 'Communication lost', false),
(1, '2025-01-07 14:30:00', 'low', 'Temperature spike on OBC', true),
(2, '2025-01-10 09:00:00', 'medium', 'Unexpected current draw on ADCS', false),
(1, '2025-01-09 23:45:00', 'high', 'Battery undervoltage', true),
(3, '2025-01-05 10:00:00', 'critical', 'Solar panel deployment failure', true);