-- =====================================================
-- 20 SQL-ЗАПРОСОВ ДЛЯ БД МОНИТОРИНГА CubeSat
-- =====================================================

-- =====================================================
-- 1. Простая выборка: список всех спутников
-- =====================================================
SELECT id, name, norad_id, launch_date, status
FROM satellites
ORDER BY launch_date;

-- =====================================================
-- 2. Простая выборка: все наземные станции
-- =====================================================
SELECT name, latitude, longitude, elevation_meters
FROM ground_stations;

-- =====================================================
-- 3. Фильтрация (WHERE): нерешённые аномалии высокой критичности
-- =====================================================
SELECT id, satellite_id, timestamp, severity, description
FROM anomalies
WHERE resolved = false AND severity IN ('high', 'critical')
ORDER BY timestamp DESC;

-- =====================================================
-- 4. Фильтрация (WHERE): спутники в безопасном режиме
-- =====================================================
SELECT name, norad_id, status
FROM satellites
WHERE status = 'safe_mode';

-- =====================================================
-- 5. JOIN 2 таблиц: спутники и их аномалии
-- =====================================================
SELECT s.name AS satellite_name, a.timestamp, a.severity, a.description
FROM anomalies a
JOIN satellites s ON a.satellite_id = s.id
ORDER BY a.timestamp DESC;

-- =====================================================
-- 6. JOIN 3 таблиц: датчики с привязкой к спутнику и подсистеме
-- =====================================================
SELECT s.name AS satellite_name, sub.name AS subsystem_name, sen.sensor_type, sen.unit
FROM satellites s
JOIN subsystems sub ON s.id = sub.satellite_id
JOIN sensors sen ON sub.id = sen.subsystem_id
ORDER BY s.name, sub.name, sen.sensor_type;

-- =====================================================
-- 7. JOIN 4 таблиц: детальный отчёт по сеансам связи
-- =====================================================
SELECT 
    s.name AS satellite_name,
    gs.name AS ground_station,
    vw.start_time,
    vw.end_time,
    pp.operator_name,
    pp.priority,
    pp.status
FROM planned_passes pp
JOIN visibility_windows vw ON pp.window_id = vw.id
JOIN satellites s ON vw.satellite_id = s.id
JOIN ground_stations gs ON vw.station_id = gs.id
ORDER BY vw.start_time;

-- =====================================================
-- 8. Агрегация (GROUP BY + COUNT): количество аномалий по спутникам
-- =====================================================
SELECT s.name, COUNT(a.id) AS anomaly_count
FROM satellites s
LEFT JOIN anomalies a ON s.id = a.satellite_id
GROUP BY s.id, s.name
ORDER BY anomaly_count DESC;

-- =====================================================
-- 9. Агрегация (AVG, MIN, MAX): статистика телеметрии по датчикам
-- =====================================================
SELECT 
    sensor_id,
    COUNT(*) AS readings,
    ROUND(AVG(value)::numeric, 2) AS avg_value,
    ROUND(MIN(value)::numeric, 2) AS min_value,
    ROUND(MAX(value)::numeric, 2) AS max_value
FROM telemetry
GROUP BY sensor_id
ORDER BY sensor_id;

-- =====================================================
-- 10. HAVING: датчики со средней температурой выше 40°C
-- =====================================================
SELECT 
    t.sensor_id,
    sen.sensor_type,
    ROUND(AVG(t.value)::numeric, 2) AS avg_temp
FROM telemetry t
JOIN sensors sen ON t.sensor_id = sen.id
WHERE sen.sensor_type = 'temp'
GROUP BY t.sensor_id, sen.sensor_type
HAVING AVG(t.value) > 40
ORDER BY avg_temp DESC;

-- =====================================================
-- 11. HAVING: спутники, у которых больше 1 аномалии
-- =====================================================
SELECT s.name, COUNT(a.id) AS anomaly_count
FROM satellites s
JOIN anomalies a ON s.id = a.satellite_id
GROUP BY s.id, s.name
HAVING COUNT(a.id) > 1;

-- =====================================================
-- 12. Подзапрос (скалярный): спутники с телеметрией выше среднего
-- =====================================================
SELECT DISTINCT s.name
FROM satellites s
JOIN subsystems sub ON s.id = sub.satellite_id
JOIN sensors sen ON sub.id = sen.subsystem_id
JOIN telemetry t ON sen.id = t.sensor_id
WHERE t.value > (SELECT AVG(value) FROM telemetry);

-- =====================================================
-- 13. EXISTS: спутники с неподтверждёнными командами
-- =====================================================
SELECT s.name, s.status
FROM satellites s
WHERE EXISTS (
    SELECT 1 
    FROM command_log cl
    JOIN commands c ON cl.command_id = c.id
    WHERE c.satellite_id = s.id AND cl.status = 'sent'
);

-- =====================================================
-- 14. CTE (WITH): последние 3 показания телеметрии по каждому датчику
-- =====================================================
WITH ranked_telemetry AS (
    SELECT 
        sensor_id,
        timestamp,
        value,
        ROW_NUMBER() OVER (PARTITION BY sensor_id ORDER BY timestamp DESC) AS rn
    FROM telemetry
)
SELECT 
    rt.sensor_id,
    sen.sensor_type,
    rt.timestamp,
    rt.value
FROM ranked_telemetry rt
JOIN sensors sen ON rt.sensor_id = sen.id
WHERE rt.rn <= 3
ORDER BY rt.sensor_id, rt.timestamp DESC;

-- =====================================================
-- 15. Оконная функция (LAG): сравнение с предыдущим значением
-- =====================================================
SELECT 
    t.timestamp,
    t.value,
    LAG(t.value) OVER (ORDER BY t.timestamp) AS prev_value,
    t.value - LAG(t.value) OVER (ORDER BY t.timestamp) AS delta
FROM telemetry t
WHERE t.sensor_id = 1
ORDER BY t.timestamp;

-- =====================================================
-- 16. Оконная функция (RANK): топ датчиков по средней температуре
-- =====================================================
WITH sensor_avg AS (
    SELECT 
        sen.id,
        sen.sensor_type,
        AVG(t.value) AS avg_value,
        RANK() OVER (ORDER BY AVG(t.value) DESC) AS rank
    FROM sensors sen
    JOIN telemetry t ON sen.id = t.sensor_id
    WHERE sen.sensor_type = 'temp'
    GROUP BY sen.id, sen.sensor_type
)
SELECT * FROM sensor_avg WHERE rank <= 3;

-- =====================================================
-- 17. ORDER BY + LIMIT: 5 самых свежих аномалий
-- =====================================================
SELECT a.id, s.name, a.timestamp, a.severity, a.description
FROM anomalies a
JOIN satellites s ON a.satellite_id = s.id
ORDER BY a.timestamp DESC
LIMIT 5;

-- =====================================================
-- 18. ORDER BY + LIMIT: топ-3 самых загруженных операторов
-- =====================================================
SELECT operator_name, COUNT(*) AS passes_count
FROM planned_passes
GROUP BY operator_name
ORDER BY passes_count DESC
LIMIT 3;

-- =====================================================
-- 19. Сложный запрос с CASE: классификация аномалий по критичности
-- =====================================================
SELECT 
    s.name,
    a.timestamp,
    a.severity,
    a.description,
    CASE 
        WHEN a.severity = 'critical' THEN 'ТРЕБУЕТ НЕМЕДЛЕННОГО ВМЕШАТЕЛЬСТВА'
        WHEN a.severity = 'high' THEN 'Высокий приоритет'
        WHEN a.severity = 'medium' THEN 'Средний приоритет'
        ELSE 'Низкий приоритет'
    END AS priority_label
FROM anomalies a
JOIN satellites s ON a.satellite_id = s.id
WHERE a.resolved = false
ORDER BY 
    CASE a.severity
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        ELSE 4
    END;

-- =====================================================
-- 20. UNION: объединение аномалий и критических команд
-- =====================================================
SELECT 
    'anomaly' AS event_type,
    satellite_id,
    timestamp,
    description AS details
FROM anomalies
WHERE severity IN ('high', 'critical')
UNION ALL
SELECT 
    'critical_command' AS event_type,
    c.satellite_id,
    cl.sent_at AS timestamp,
    c.command_code || ': ' || c.description AS details
FROM command_log cl
JOIN commands c ON cl.command_id = c.id
WHERE c.is_critical = true
ORDER BY timestamp DESC;