-- =====================================================
-- 10 аналитических SQL-запросов
-- =====================================================

-- 1. Простая выборка: список всех операциональных спутников
SELECT id, name, norad_id, launch_date, status 
FROM satellites 
WHERE status = 'operational';

-- 2. WHERE + фильтрация: аномалии критического уровня за последние 7 дней
SELECT * FROM anomalies 
WHERE severity IN ('critical', 'emergency')
  AND timestamp > NOW() - INTERVAL '7 days'
ORDER BY timestamp DESC;

-- 3. JOIN 3+ таблиц: телеметрия температуры + датчик + подсистема + спутник
SELECT 
    s.name AS satellite_name,
    sub.name AS subsystem_name,
    sens.sensor_type,
    t.timestamp,
    t.value AS temperature_celsius
FROM telemetry t
JOIN sensors sens ON t.sensor_id = sens.id
JOIN subsystems sub ON sens.subsystem_id = sub.id
JOIN satellites s ON sub.satellite_id = s.id
WHERE sens.sensor_type = 'temperature'
  AND t.timestamp > NOW() - INTERVAL '1 day'
ORDER BY t.timestamp DESC
LIMIT 20;

-- 4. Агрегация + GROUP BY: средняя температура по каждому спутнику за последние 24 часа
SELECT 
    s.name AS satellite_name,
    ROUND(AVG(t.value), 2) AS avg_temperature_celsius,
    COUNT(t.id) AS readings_count
FROM telemetry t
JOIN sensors sens ON t.sensor_id = sens.id
JOIN subsystems sub ON sens.subsystem_id = sub.id
JOIN satellites s ON sub.satellite_id = s.id
WHERE sens.sensor_type = 'temperature'
  AND t.timestamp > NOW() - INTERVAL '24 hours'
GROUP BY s.id, s.name
ORDER BY avg_temperature_celsius DESC;

-- 5. JOIN 4 таблиц + сортировка: спутники → сеансы → станции
SELECT 
    s.name AS satellite_name,
    gs.name AS ground_station,
    vw.start_time,
    vw.end_time,
    vw.max_elevation,
    pp.status AS planned_status,
    ap.data_volume_mb
FROM visibility_windows vw
JOIN satellites s ON vw.satellite_id = s.id
JOIN ground_stations gs ON vw.station_id = gs.id
LEFT JOIN planned_passes pp ON vw.id = pp.window_id
LEFT JOIN actual_passes ap ON pp.id = ap.planned_pass_id
ORDER BY vw.start_time DESC;

-- 6. Оконная функция (LAG): сравнение текущей температуры с предыдущей
SELECT 
    s.name AS satellite_name,
    t.timestamp,
    t.value AS current_temp,
    LAG(t.value) OVER (PARTITION BY t.sensor_id ORDER BY t.timestamp) AS previous_temp,
    t.value - LAG(t.value) OVER (PARTITION BY t.sensor_id ORDER BY t.timestamp) AS delta
FROM telemetry t
JOIN sensors sens ON t.sensor_id = sens.id
JOIN subsystems sub ON sens.subsystem_id = sub.id
JOIN satellites s ON sub.satellite_id = s.id
WHERE sens.sensor_type = 'temperature'
  AND s.name = 'CubeSat-1'
ORDER BY t.timestamp DESC
LIMIT 10;

-- 7. HAVING: спутники со средней температурой выше 50°C
SELECT 
    s.name AS satellite_name,
    ROUND(AVG(t.value), 2) AS avg_temp
FROM telemetry t
JOIN sensors sens ON t.sensor_id = sens.id
JOIN subsystems sub ON sens.subsystem_id = sub.id
JOIN satellites s ON sub.satellite_id = s.id
WHERE sens.sensor_type = 'temperature'
GROUP BY s.id, s.name
HAVING AVG(t.value) > 50;

-- 8. Подзапрос с EXISTS: станции с непроведёнными запланированными сеансами
SELECT DISTINCT gs.name 
FROM ground_stations gs
WHERE EXISTS (
    SELECT 1 
    FROM visibility_windows vw
    JOIN planned_passes pp ON vw.id = pp.window_id
    WHERE vw.station_id = gs.id
      AND pp.status = 'planned'
      AND NOT EXISTS (
          SELECT 1 FROM actual_passes ap WHERE ap.planned_pass_id = pp.id
      )
);

-- 9. WITH (CTE) + агрегация: топ-2 спутников по количеству аномалий
WITH anomaly_counts AS (
    SELECT 
        s.name AS satellite_name,
        COUNT(a.id) AS total_anomalies,
        RANK() OVER (ORDER BY COUNT(a.id) DESC) AS rank
    FROM anomalies a
    JOIN satellites s ON a.satellite_id = s.id
    GROUP BY s.id, s.name
)
SELECT satellite_name, total_anomalies
FROM anomaly_counts
WHERE rank <= 2
ORDER BY total_anomalies DESC;

-- 10. Вызов пользовательской функции (из functions.sql)
SELECT * FROM get_upcoming_passes(
    (SELECT id FROM satellites WHERE name = 'CubeSat-1'), 
    48
);

-- Дополнительный запрос (для демонстрации здоровья спутника)
SELECT * FROM get_satellite_health(
    (SELECT id FROM satellites WHERE name = 'CubeSat-1'),
    24
);