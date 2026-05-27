-- =====================================================
-- Заполнение тестовыми данными
-- =====================================================

-- 1. Спутники (4 записи)
INSERT INTO satellites (name, norad_id, launch_date, status) VALUES
    ('CubeSat-1', 51001, '2023-06-15', 'operational'),
    ('CubeSat-2', 51002, '2023-09-20', 'operational'),
    ('CubeSat-3', 51003, '2024-01-10', 'maintenance'),
    ('TechDemo-1', 51004, '2022-11-05', 'safe_mode');

-- 2. Подсистемы (10 записей)
DO $$
DECLARE
    sat1_id INT; sat2_id INT; sat3_id INT; sat4_id INT;
BEGIN
    SELECT id INTO sat1_id FROM satellites WHERE name = 'CubeSat-1';
    SELECT id INTO sat2_id FROM satellites WHERE name = 'CubeSat-2';
    SELECT id INTO sat3_id FROM satellites WHERE name = 'CubeSat-3';
    SELECT id INTO sat4_id FROM satellites WHERE name = 'TechDemo-1';
    
    INSERT INTO subsystems (satellite_id, name, parent_subsystem_id) VALUES
        (sat1_id, 'Power System', NULL),
        (sat1_id, 'OBC', NULL),
        (sat1_id, 'Comm System', NULL),
        (sat2_id, 'Power System', NULL),
        (sat2_id, 'OBC', NULL),
        (sat2_id, 'ADCS', NULL),
        (sat3_id, 'Power System', NULL),
        (sat3_id, 'Comm System', NULL),
        (sat4_id, 'Power System', NULL),
        (sat4_id, 'OBC', NULL);
END $$;

-- 3. Датчики (14 записей)
DO $$
DECLARE
    power1_id INT; obc1_id INT; comm1_id INT;
    power2_id INT; obc2_id INT; adcs2_id INT;
    power3_id INT; comm3_id INT;
    power4_id INT; obc4_id INT;
BEGIN
    SELECT id INTO power1_id FROM subsystems WHERE name = 'Power System' AND satellite_id = (SELECT id FROM satellites WHERE name = 'CubeSat-1');
    SELECT id INTO obc1_id FROM subsystems WHERE name = 'OBC' AND satellite_id = (SELECT id FROM satellites WHERE name = 'CubeSat-1');
    SELECT id INTO comm1_id FROM subsystems WHERE name = 'Comm System' AND satellite_id = (SELECT id FROM satellites WHERE name = 'CubeSat-1');
    SELECT id INTO power2_id FROM subsystems WHERE name = 'Power System' AND satellite_id = (SELECT id FROM satellites WHERE name = 'CubeSat-2');
    SELECT id INTO obc2_id FROM subsystems WHERE name = 'OBC' AND satellite_id = (SELECT id FROM satellites WHERE name = 'CubeSat-2');
    SELECT id INTO adcs2_id FROM subsystems WHERE name = 'ADCS' AND satellite_id = (SELECT id FROM satellites WHERE name = 'CubeSat-2');
    SELECT id INTO power3_id FROM subsystems WHERE name = 'Power System' AND satellite_id = (SELECT id FROM satellites WHERE name = 'CubeSat-3');
    SELECT id INTO comm3_id FROM subsystems WHERE name = 'Comm System' AND satellite_id = (SELECT id FROM satellites WHERE name = 'CubeSat-3');
    SELECT id INTO power4_id FROM subsystems WHERE name = 'Power System' AND satellite_id = (SELECT id FROM satellites WHERE name = 'TechDemo-1');
    SELECT id INTO obc4_id FROM subsystems WHERE name = 'OBC' AND satellite_id = (SELECT id FROM satellites WHERE name = 'TechDemo-1');
    
    INSERT INTO sensors (subsystem_id, sensor_type, unit, min_val, max_val, description) VALUES
        (power1_id, 'temperature', '°C', -20, 50, 'Battery temperature'),
        (power1_id, 'voltage', 'V', 6.0, 8.4, 'Bus voltage'),
        (power1_id, 'current', 'A', 0, 5, 'Battery current'),
        (obc1_id, 'temperature', '°C', -30, 70, 'CPU temperature'),
        (comm1_id, 'temperature', '°C', -20, 60, 'Transceiver temp'),
        (power2_id, 'voltage', 'V', 6.0, 8.4, 'Bus voltage'),
        (power2_id, 'current', 'A', 0, 5, 'Battery current'),
        (obc2_id, 'temperature', '°C', -30, 70, 'CPU temperature'),
        (adcs2_id, 'orientation', 'deg', 0, 360, 'Yaw angle'),
        (power3_id, 'voltage', 'V', 5.5, 8.4, 'Bus voltage'),
        (comm3_id, 'temperature', '°C', -20, 60, 'Transceiver temp'),
        (power4_id, 'voltage', 'V', 4.0, 8.4, 'Bus voltage (degraded)'),
        (obc4_id, 'temperature', '°C', -30, 70, 'CPU temperature'),
        (power1_id, 'radiation', 'mGy', 0, 100, 'Total ionizing dose');
END $$;

-- 4. Телеметрия (40 записей)
DO $$
DECLARE
    sensors_rec RECORD;
    ts TIMESTAMP;
    i INT;
BEGIN
    FOR sensors_rec IN SELECT id FROM sensors LOOP
        FOR i IN 1..3 LOOP
            ts = NOW() - (i * INTERVAL '1 hour') - (random() * INTERVAL '10 minutes');
            INSERT INTO telemetry (sensor_id, timestamp, value) VALUES
                (sensors_rec.id, ts, 20 + random() * 30);
        END LOOP;
    END LOOP;
END $$;

-- 5. Наземные станции (3 записи)
INSERT INTO ground_stations (name, latitude, longitude, elevation_meters, status) VALUES
    ('Moscow Ground Station', 55.7558, 37.6173, 150.0, 'active'),
    ('Vladivostok Station', 43.1151, 131.8856, 80.0, 'active'),
    ('Kaliningrad Station', 54.7065, 20.5110, 30.0, 'maintenance');

-- 6. Окна видимости (8 записей)
DO $$
DECLARE
    sat1_id INT; sat2_id INT; moscow_id INT; vlad_id INT;
BEGIN
    SELECT id INTO sat1_id FROM satellites WHERE name = 'CubeSat-1';
    SELECT id INTO sat2_id FROM satellites WHERE name = 'CubeSat-2';
    SELECT id INTO moscow_id FROM ground_stations WHERE name = 'Moscow Ground Station';
    SELECT id INTO vlad_id FROM ground_stations WHERE name = 'Vladivostok Station';
    
    INSERT INTO visibility_windows (satellite_id, station_id, start_time, end_time, max_elevation) VALUES
        (sat1_id, moscow_id, '2025-01-15 10:00:00', '2025-01-15 10:15:00', 45.5),
        (sat1_id, moscow_id, '2025-01-15 12:30:00', '2025-01-15 12:48:00', 60.2),
        (sat1_id, vlad_id, '2025-01-15 23:00:00', '2025-01-15 23:12:00', 30.0),
        (sat2_id, moscow_id, '2025-01-15 11:00:00', '2025-01-15 11:20:00', 55.0),
        (sat2_id, vlad_id, '2025-01-15 22:30:00', '2025-01-15 22:45:00', 40.3),
        (sat1_id, moscow_id, '2025-01-16 09:45:00', '2025-01-16 10:05:00', 50.1),
        (sat2_id, moscow_id, '2025-01-16 13:15:00', '2025-01-16 13:35:00', 48.7),
        (sat1_id, vlad_id, '2025-01-16 21:00:00', '2025-01-16 21:18:00', 35.2);
END $$;

-- 7. Запланированные сеансы (6 записей)
DO $$
DECLARE
    win1 INT; win2 INT; win3 INT; win4 INT; win5 INT; win6 INT;
BEGIN
    SELECT id INTO win1 FROM visibility_windows ORDER BY id LIMIT 1 OFFSET 0;
    SELECT id INTO win2 FROM visibility_windows ORDER BY id LIMIT 1 OFFSET 1;
    SELECT id INTO win3 FROM visibility_windows ORDER BY id LIMIT 1 OFFSET 2;
    SELECT id INTO win4 FROM visibility_windows ORDER BY id LIMIT 1 OFFSET 3;
    SELECT id INTO win5 FROM visibility_windows ORDER BY id LIMIT 1 OFFSET 4;
    SELECT id INTO win6 FROM visibility_windows ORDER BY id LIMIT 1 OFFSET 5;
    
    INSERT INTO planned_passes (window_id, priority, status) VALUES
        (win1, 1, 'completed'),
        (win2, 2, 'completed'),
        (win3, 1, 'canceled'),
        (win4, 3, 'approved'),
        (win5, 2, 'planned'),
        (win6, 1, 'planned');
END $$;

-- 8. Фактические сеансы (3 записи)
DO $$
DECLARE
    planned1 INT; planned2 INT;
BEGIN
    SELECT id INTO planned1 FROM planned_passes WHERE status = 'completed' LIMIT 1 OFFSET 0;
    SELECT id INTO planned2 FROM planned_passes WHERE status = 'completed' LIMIT 1 OFFSET 1;
    
    INSERT INTO actual_passes (planned_pass_id, actual_start, actual_end, data_volume_mb, downlink_rate_kbps) VALUES
        (planned1, '2025-01-15 10:00:30', '2025-01-15 10:14:50', 125.5, 512.0),
        (planned2, '2025-01-15 12:31:00', '2025-01-15 12:47:30', 98.2, 450.0);
END $$;

-- 9. Команды (6 записей)
DO $$
DECLARE
    sat1_id INT; sat2_id INT; sat3_id INT;
BEGIN
    SELECT id INTO sat1_id FROM satellites WHERE name = 'CubeSat-1';
    SELECT id INTO sat2_id FROM satellites WHERE name = 'CubeSat-2';
    SELECT id INTO sat3_id FROM satellites WHERE name = 'CubeSat-3';
    
    INSERT INTO commands (satellite_id, command_code, description, is_critical) VALUES
        (sat1_id, 'RESET_OBC', 'Reset onboard computer', FALSE),
        (sat1_id, 'DOWNLOAD_TLM', 'Download telemetry buffer', FALSE),
        (sat2_id, 'REBOOT_ALL', 'Full system reboot', TRUE),
        (sat2_id, 'SAFE_MODE', 'Enter safe mode', TRUE),
        (sat3_id, 'UPLOAD_PATCH', 'Upload firmware patch', TRUE),
        (sat1_id, 'DEPLOY_ANTENNA', 'Deploy communication antenna', TRUE);
END $$;

-- 10. Журнал команд (6 записей)
DO $$
DECLARE
    cmd1 INT; cmd2 INT; cmd3 INT; planned_pass INT;
BEGIN
    SELECT id INTO cmd1 FROM commands WHERE command_code = 'RESET_OBC';
    SELECT id INTO cmd2 FROM commands WHERE command_code = 'DOWNLOAD_TLM';
    SELECT id INTO cmd3 FROM commands WHERE command_code = 'SAFE_MODE';
    SELECT id INTO planned_pass FROM planned_passes WHERE status = 'completed' LIMIT 1;
    
    INSERT INTO command_log (command_id, planned_pass_id, sent_at, acked_at, status, result) VALUES
        (cmd1, planned_pass, '2025-01-15 10:05:00', '2025-01-15 10:05:15', 'executed', 'OK'),
        (cmd2, planned_pass, '2025-01-15 10:10:00', '2025-01-15 10:10:08', 'executed', '125 MB transferred'),
        (cmd3, NULL, '2025-01-14 23:00:00', NULL, 'failed', 'No response');
END $$;

-- 11. Аномалии (4 записи)
DO $$
DECLARE
    sat1_id INT; sat2_id INT; sat4_id INT;
BEGIN
    SELECT id INTO sat1_id FROM satellites WHERE name = 'CubeSat-1';
    SELECT id INTO sat2_id FROM satellites WHERE name = 'CubeSat-2';
    SELECT id INTO sat4_id FROM satellites WHERE name = 'TechDemo-1';
    
    INSERT INTO anomalies (satellite_id, timestamp, severity, description, resolved, resolved_at) VALUES
        (sat1_id, '2025-01-14 08:00:00', 'warning', 'Temperature spike in OBC', TRUE, '2025-01-14 09:30:00'),
        (sat1_id, '2025-01-15 06:00:00', 'critical', 'Battery undervoltage', FALSE, NULL),
        (sat2_id, '2025-01-13 22:00:00', 'info', 'Minor attitude deviation', TRUE, '2025-01-13 22:30:00'),
        (sat4_id, '2025-01-10 00:00:00', 'emergency', 'Complete power loss', FALSE, NULL);
END $$;