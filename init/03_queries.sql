-- =====================================================
-- Аналитические запросы: Система мониторинга телеметрии CubeSat
-- =====================================================

-- =====================================================
-- ЗАПРОС №1: Простая выборка (реестр спутников)
-- =====================================================
-- Название: Список всех спутников с их текущим статусом
-- Тип: SELECT (простая выборка)
SELECT id, name, norad_id, launch_date, status
FROM satellites
ORDER BY launch_date;

-- =====================================================
-- ЗАПРОС №2: Простая выборка + фильтрация (WHERE)
-- =====================================================
-- Название: Все активные (нерешённые) аномалии высокой критичности
-- Тип: SELECT + WHERE
SELECT id, satellite_id, timestamp, severity, description
FROM anomalies
WHERE resolved = false AND severity IN ('high', 'critical')
ORDER BY timestamp DESC;

-- =====================================================
-- ЗАПРОС №3: Объединение таблиц (JOIN) — 3 таблицы
-- =====================================================
-- Название: Датчики с привязкой к спутнику и подсистеме
-- Тип: JOIN
SELECT 
    s.name AS satellite_name,
    sub.name AS subsystem_name,
    sen.sensor_type,
    sen.unit,
    sen.min_val,
    sen.max_val
FROM satellites s
JOIN subsystems sub ON s.id = sub.satellite_id
JOIN sensors sen ON sub.id = sen.subsystem_id
ORDER BY s.name, sub.name, sen.sensor_type;

-- =====================================================
-- ЗАПРОС №4: Агрегация данных (GROUP BY + COUNT/AVG)
-- =====================================================
-- Название: Статистика телеметрии по каждому датчику
-- Тип: GROUP BY + COUNT + AVG + MIN + MAX
SELECT 
    sensor_id,
    COUNT(*) AS readings_count,
    ROUND(AVG(value)::numeric, 2) AS avg_value,
    ROUND(MIN(value)::numeric, 2) AS min_value,
    ROUND(MAX(value)::numeric, 2) AS max_value
FROM telemetry
GROUP BY sensor_id
ORDER BY sensor_id;

-- =====================================================
-- ЗАПРОС №5: Условие HAVING
-- =====================================================
-- Название: Датчики со средней температурой выше 40°C (перегрев)
-- Тип: GROUP BY + HAVING
SELECT 
    sensor_id,
    ROUND(AVG(value)::numeric, 2) AS avg_temperature
FROM telemetry
WHERE sensor_id IN (1, 4, 5)
GROUP BY sensor_id
HAVING AVG(value) > 40
ORDER BY avg_temperature DESC;

-- =====================================================
-- ЗАПРОС №6: Обобщённое табличное выражение (CTE) + оконная функция (ROW_NUMBER)
-- =====================================================
-- Название: Последнее показание телеметрии по каждому датчику
-- Тип: WITH (CTE) + ROW_NUMBER() OVER()
WITH latest_telemetry AS (
    SELECT 
        t.*,
        ROW_NUMBER() OVER (PARTITION BY t.sensor_id ORDER BY t.timestamp DESC) AS rn
    FROM telemetry t
)
SELECT 
    lt.sensor_id,
    s.sensor_type,
    lt.value,
    lt.timestamp
FROM latest_telemetry lt
JOIN sensors s ON lt.sensor_id = s.id
WHERE lt.rn = 1
ORDER BY lt.sensor_id;

-- =====================================================
-- ЗАПРОС №7: Подзапрос с EXISTS
-- =====================================================
-- Название: Спутники, у которых есть неподтверждённые команды
-- Тип: Подзапрос + EXISTS
SELECT 
    s.id,
    s.name,
    s.status
FROM satellites s
WHERE EXISTS (
    SELECT 1 
    FROM command_log cl
    JOIN commands c ON cl.command_id = c.id
    WHERE c.satellite_id = s.id AND cl.status = 'sent'
)
ORDER BY s.name;

-- =====================================================
-- ЗАПРОС №8: Оконная функция LAG (сравнение с предыдущим значением)
-- =====================================================
-- Название: Скачки температуры (разница с предыдущим измерением)
-- Тип: LAG() OVER() + оконная функция
SELECT 
    t.id,
    sen.sensor_type,
    t.timestamp,
    t.value,
    LAG(t.value) OVER (PARTITION BY t.sensor_id ORDER BY t.timestamp) AS prev_value,
    ROUND((t.value - LAG(t.value) OVER (PARTITION BY t.sensor_id ORDER BY t.timestamp))::numeric, 2) AS delta,
    CASE 
        WHEN ABS(t.value - LAG(t.value) OVER (PARTITION BY t.sensor_id ORDER BY t.timestamp)) > 5 
        THEN 'CRITICAL JUMP'
        ELSE 'normal'
    END AS jump_status
FROM telemetry t
JOIN sensors sen ON t.sensor_id = sen.id
WHERE sen.sensor_type = 'temp'
ORDER BY sen.sensor_type, t.timestamp;

-- =====================================================
-- ЗАПРОС №9: Сортировка и ограничение (ORDER BY + LIMIT)
-- =====================================================
-- Название: Топ-5 самых свежих аномалий с деталями спутника
-- Тип: ORDER BY + LIMIT + JOIN
SELECT 
    a.id,
    s.name AS satellite_name,
    a.timestamp,
    a.severity,
    a.description,
    CASE WHEN a.resolved THEN 'YES' ELSE 'NO' END AS resolved
FROM anomalies a
JOIN satellites s ON a.satellite_id = s.id
ORDER BY a.timestamp DESC
LIMIT 5;

-- =====================================================
-- ЗАПРОС №10: Сложный JOIN 4 таблиц + агрегация
-- =====================================================
-- Название: Детальный отчёт по плановым сеансам связи
-- Тип: Многотабличный JOIN + агрегация + сортировка
SELECT 
    s.name AS satellite_name,
    gs.name AS ground_station,
    vw.start_time AS window_start,
    vw.end_time AS window_end,
    vw.max_elevation_deg,
    pp.operator_name,
    pp.priority,
    pp.status AS pass_status,
    ap.actual_start,
    ap.actual_end,
    ap.data_volume_mb,
    ROUND(EXTRACT(EPOCH FROM (ap.actual_end - ap.actual_start)) / 60, 2) AS actual_duration_min
FROM planned_passes pp
JOIN visibility_windows vw ON pp.window_id = vw.id
JOIN satellites s ON vw.satellite_id = s.id
JOIN ground_stations gs ON vw.station_id = gs.id
LEFT JOIN actual_passes ap ON pp.id = ap.planned_pass_id
ORDER BY vw.start_time DESC;